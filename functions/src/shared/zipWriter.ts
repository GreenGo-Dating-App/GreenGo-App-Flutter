/**
 * Minimal streaming ZIP writer (deflate, UTF-8 names, ZIP32), no dependencies.
 *
 * Used by the data-subject export (auth/dataExport.ts). Each entry is given as
 * a complete Buffer, so CRC and sizes are known before the local header is
 * written (no data descriptors). Entries are written to the output stream one
 * at a time; only the central directory (a few dozen bytes per entry) stays in
 * memory, so memory is bounded by the largest single entry.
 *
 * Limits (ZIP32): < 65 535 entries and < 4 GiB in total. Callers cap below
 * that (MAX_ENTRIES / maxBytes).
 */

import * as zlib from 'zlib';
import type { Writable } from 'stream';

export const ZIP_MAX_ENTRIES = 65000;
const ZIP32_LIMIT = 0xffffffff;

let CRC_TABLE: Uint32Array | null = null;
function crc32Fallback(buf: Buffer): number {
  if (!CRC_TABLE) {
    CRC_TABLE = new Uint32Array(256);
    for (let n = 0; n < 256; n++) {
      let c = n;
      for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
      CRC_TABLE[n] = c >>> 0;
    }
  }
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

export function crc32(buf: Buffer): number {
  const native = (zlib as any).crc32 as ((b: Buffer) => number) | undefined;
  return native ? native(buf) >>> 0 : crc32Fallback(buf);
}

function dosDateTime(d: Date): { time: number; date: number } {
  const year = Math.max(1980, d.getUTCFullYear());
  return {
    time: (d.getUTCHours() << 11) | (d.getUTCMinutes() << 5) | Math.floor(d.getUTCSeconds() / 2),
    date: ((year - 1980) << 9) | ((d.getUTCMonth() + 1) << 5) | d.getUTCDate(),
  };
}

interface CentralEntry {
  name: Buffer;
  crc: number;
  compressedSize: number;
  size: number;
  method: number;
  offset: number;
  time: number;
  date: number;
}

export class ZipStreamWriter {
  private offset = 0;
  private entries: CentralEntry[] = [];
  private names = new Set<string>();
  private readonly when = dosDateTime(new Date());

  constructor(private readonly out: Writable) {}

  get entryCount(): number {
    return this.entries.length;
  }

  get bytesWritten(): number {
    return this.offset;
  }

  private write(buf: Buffer): Promise<void> {
    this.offset += buf.length;
    return new Promise((resolve, reject) => {
      const ok = this.out.write(buf, (err) => (err ? reject(err) : undefined));
      if (ok) resolve();
      else this.out.once('drain', () => resolve());
    });
  }

  /** Adds one file. Names are made unique (`name (2).ext`) and relative. */
  async add(rawName: string, data: Buffer | string): Promise<void> {
    if (this.entries.length >= ZIP_MAX_ENTRIES) throw new Error('zip: too many entries');
    const content = typeof data === 'string' ? Buffer.from(data, 'utf8') : data;
    let name = rawName.replace(/\\/g, '/').replace(/^\/+/, '').replace(/\.\.\//g, '');
    if (this.names.has(name)) {
      const dot = name.lastIndexOf('.');
      const [base, ext] = dot > name.lastIndexOf('/') ? [name.slice(0, dot), name.slice(dot)] : [name, ''];
      let i = 2;
      while (this.names.has(`${base} (${i})${ext}`)) i++;
      name = `${base} (${i})${ext}`;
    }
    this.names.add(name);

    const crc = crc32(content);
    const deflated = zlib.deflateRawSync(content, { level: 6 });
    const store = deflated.length >= content.length;
    const body = store ? content : deflated;
    const method = store ? 0 : 8;
    if (this.offset + body.length + 1024 > ZIP32_LIMIT) throw new Error('zip: archive too large');

    const nameBuf = Buffer.from(name, 'utf8');
    const h = Buffer.alloc(30);
    h.writeUInt32LE(0x04034b50, 0);
    h.writeUInt16LE(20, 4); // version needed
    h.writeUInt16LE(0x0800, 6); // UTF-8 names
    h.writeUInt16LE(method, 8);
    h.writeUInt16LE(this.when.time, 10);
    h.writeUInt16LE(this.when.date, 12);
    h.writeUInt32LE(crc, 14);
    h.writeUInt32LE(body.length, 18);
    h.writeUInt32LE(content.length, 22);
    h.writeUInt16LE(nameBuf.length, 26);
    h.writeUInt16LE(0, 28);

    const offset = this.offset;
    await this.write(Buffer.concat([h, nameBuf]));
    await this.write(body);
    this.entries.push({
      name: nameBuf, crc, compressedSize: body.length, size: content.length, method, offset,
      time: this.when.time, date: this.when.date,
    });
  }

  /** Writes the central directory and ends the stream; resolves when flushed. */
  async finish(): Promise<void> {
    const cdStart = this.offset;
    for (const e of this.entries) {
      const c = Buffer.alloc(46);
      c.writeUInt32LE(0x02014b50, 0);
      c.writeUInt16LE(20, 4); // version made by
      c.writeUInt16LE(20, 6); // version needed
      c.writeUInt16LE(0x0800, 8);
      c.writeUInt16LE(e.method, 10);
      c.writeUInt16LE(e.time, 12);
      c.writeUInt16LE(e.date, 14);
      c.writeUInt32LE(e.crc, 16);
      c.writeUInt32LE(e.compressedSize, 20);
      c.writeUInt32LE(e.size, 24);
      c.writeUInt16LE(e.name.length, 28);
      // extra, comment, disk, internal attrs = 0
      c.writeUInt32LE(0, 38); // external attrs
      c.writeUInt32LE(e.offset, 42);
      await this.write(Buffer.concat([c, e.name]));
    }
    const cdSize = this.offset - cdStart;
    const end = Buffer.alloc(22);
    end.writeUInt32LE(0x06054b50, 0);
    end.writeUInt16LE(this.entries.length, 8);
    end.writeUInt16LE(this.entries.length, 10);
    end.writeUInt32LE(cdSize, 12);
    end.writeUInt32LE(cdStart, 16);
    await this.write(end);
    await new Promise<void>((resolve, reject) => {
      this.out.once('error', reject);
      this.out.end(() => resolve());
    });
  }
}

/** Reads a ZIP produced above back into { name: Buffer } (tests, tooling). */
export function readZip(buf: Buffer): Record<string, Buffer> {
  const out: Record<string, Buffer> = {};
  const eocd = buf.lastIndexOf(Buffer.from([0x50, 0x4b, 0x05, 0x06]));
  if (eocd < 0) throw new Error('zip: no end of central directory');
  const count = buf.readUInt16LE(eocd + 10);
  let p = buf.readUInt32LE(eocd + 16);
  for (let i = 0; i < count; i++) {
    if (buf.readUInt32LE(p) !== 0x02014b50) throw new Error('zip: bad central entry');
    const method = buf.readUInt16LE(p + 10);
    const crc = buf.readUInt32LE(p + 16);
    const csize = buf.readUInt32LE(p + 20);
    const nlen = buf.readUInt16LE(p + 28);
    const elen = buf.readUInt16LE(p + 30);
    const clen = buf.readUInt16LE(p + 32);
    const local = buf.readUInt32LE(p + 42);
    const name = buf.slice(p + 46, p + 46 + nlen).toString('utf8');
    const lnlen = buf.readUInt16LE(local + 26);
    const lelen = buf.readUInt16LE(local + 28);
    const start = local + 30 + lnlen + lelen;
    const raw = buf.slice(start, start + csize);
    const data = method === 8 ? zlib.inflateRawSync(raw) : raw;
    if (crc32(data) !== crc) throw new Error(`zip: CRC mismatch for ${name}`);
    out[name] = data;
    p += 46 + nlen + elen + clen;
  }
  return out;
}
