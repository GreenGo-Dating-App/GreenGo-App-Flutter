/**
 * Perceptual image hashes for re-upload blocking (NCII: TAKE IT DOWN Act /
 * Decreto 12.976/2026; CSAE: hash-matching of public uploads).
 *
 * No new dependency: the hash maths is plain TypeScript over a grayscale
 * pixel buffer, and decoding/resizing uses `sharp`, which the functions
 * already ship (media/imageCompression.ts, share/sharePreview.ts).
 *
 *  - dHash (difference hash, 64 bit): 9x8 grayscale, bit = left > right.
 *    Survives resizing, re-compression and small colour changes.
 *  - pHash (DCT hash, 64 bit): 32x32 grayscale -> 2-D DCT-II -> the 8x8
 *    lowest frequencies, bit = coefficient > median (DC excluded from the
 *    median). More robust to gamma / contrast changes than dHash.
 *  - sha256 / sha1 / md5 of the raw bytes for exact matches against
 *    industry lists (NCMEC shares MD5 / SHA-1 lists).
 *
 * Matching uses BOTH perceptual hashes (see isPerceptualMatch) so a single
 * accidental collision on a low-detail image cannot hide someone's photo.
 *
 * Lookup at scale (blocked_media_hashes / csam_hash_list): every perceptual
 * hash is split into 8 bands of 8 bits stored in an array field. If two
 * hashes differ in at most 7 bits, at least one of the 8 bands is identical
 * (pigeonhole), so one `array-contains-any` query on the bands returns every
 * candidate within the threshold; the exact Hamming distance is then
 * checked in code.
 */

import * as crypto from 'crypto';

export const HASH_BITS = 64;
/** Max Hamming distance for dHash (also the band-retrieval guarantee: 8 bands -> <= 7). */
export const DHASH_MAX_DISTANCE = 7;
/** Max Hamming distance for pHash (checked after a dHash/pHash band hit). */
export const PHASH_MAX_DISTANCE = 12;
const BANDS = 8;

/** 64-bit difference hash from a 9x8 grayscale buffer (row-major), as 16 hex chars. */
export function dHashFromGray(px: ArrayLike<number>, width = 9, height = 8): string {
  if (width !== 9 || height !== 8 || px.length < 72) {
    throw new Error('dHash needs a 9x8 grayscale buffer');
  }
  let bits = '';
  for (let y = 0; y < 8; y++) {
    for (let x = 0; x < 8; x++) {
      bits += px[y * 9 + x] > px[y * 9 + x + 1] ? '1' : '0';
    }
  }
  return bitsToHex(bits);
}

/** Cached cosine table for an N-point DCT-II. */
const cosCache = new Map<number, Float64Array>();
function cosTable(n: number): Float64Array {
  let t = cosCache.get(n);
  if (!t) {
    t = new Float64Array(n * n);
    for (let k = 0; k < n; k++) {
      for (let i = 0; i < n; i++) t[k * n + i] = Math.cos(((2 * i + 1) * k * Math.PI) / (2 * n));
    }
    cosCache.set(n, t);
  }
  return t;
}

/**
 * 2-D DCT-II of an NxN matrix, only the first [keep]x[keep] coefficients
 * (separable: rows, then columns). Unnormalised: only comparisons matter.
 */
export function dct2dLowFreq(px: ArrayLike<number>, n: number, keep: number): Float64Array {
  const c = cosTable(n);
  // Row transform, only `keep` frequencies per row.
  const rows = new Float64Array(n * keep);
  for (let y = 0; y < n; y++) {
    for (let k = 0; k < keep; k++) {
      let s = 0;
      for (let x = 0; x < n; x++) s += px[y * n + x] * c[k * n + x];
      rows[y * keep + k] = s;
    }
  }
  const out = new Float64Array(keep * keep);
  for (let ky = 0; ky < keep; ky++) {
    for (let kx = 0; kx < keep; kx++) {
      let s = 0;
      for (let y = 0; y < n; y++) s += rows[y * keep + kx] * c[ky * n + y];
      out[ky * keep + kx] = s;
    }
  }
  return out;
}

/** 64-bit DCT hash from a 32x32 grayscale buffer, as 16 hex chars. */
export function pHashFromGray(px: ArrayLike<number>, size = 32): string {
  if (size !== 32 || px.length < 1024) throw new Error('pHash needs a 32x32 grayscale buffer');
  const coeffs = dct2dLowFreq(px, 32, 8);
  const ac = Array.from(coeffs).slice(1).sort((a, b) => a - b);
  const median = (ac[31] + ac[32]) / 2;
  let bits = '';
  for (let i = 0; i < 64; i++) bits += coeffs[i] > median ? '1' : '0';
  return bitsToHex(bits);
}

function bitsToHex(bits: string): string {
  let hex = '';
  for (let i = 0; i < bits.length; i += 4) hex += parseInt(bits.slice(i, i + 4), 2).toString(16);
  return hex;
}

const POPCOUNT4 = [0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4];

/** Hamming distance between two equal-length hex hashes (Infinity when malformed). */
export function hammingHex(a: string, b: string): number {
  if (typeof a !== 'string' || typeof b !== 'string' || a.length !== b.length || !/^[0-9a-f]+$/i.test(a + b)) {
    return Infinity;
  }
  let d = 0;
  for (let i = 0; i < a.length; i++) d += POPCOUNT4[parseInt(a[i], 16) ^ parseInt(b[i], 16)];
  return d;
}

/** Number of set bits in a hex hash. */
export function popcountHex(h: string): number {
  let n = 0;
  for (const ch of h) n += POPCOUNT4[parseInt(ch, 16)];
  return n;
}

/**
 * A near-blank / single-tone image hashes to (almost) all zeros or ones and
 * would "match" every other blank image. Such hashes are only matched
 * exactly (sha256), never perceptually.
 */
export function isLowInformation(dhash: string): boolean {
  const p = popcountHex(dhash);
  return p < 6 || p > 58;
}

/** 8 bands of 8 bits, tagged with the hash type: `d0:ab`, ..., `p7:ff`. */
export function hashBands(hex: string, tag: 'd' | 'p'): string[] {
  const out: string[] = [];
  for (let i = 0; i < BANDS; i++) out.push(`${tag}${i}:${hex.slice(i * 2, i * 2 + 2).toLowerCase()}`);
  return out;
}

export interface ImageHashes {
  dhash: string;
  phash: string;
  sha256: string;
  sha1: string;
  md5: string;
}

export interface PerceptualDistance {
  d: number;
  p: number;
}

/** Both perceptual hashes within their thresholds, and not a low-information image. */
export function isPerceptualMatch(
  a: Pick<ImageHashes, 'dhash' | 'phash'>,
  b: Pick<ImageHashes, 'dhash' | 'phash'>,
): { match: boolean; distance: PerceptualDistance } {
  const distance = { d: hammingHex(a.dhash, b.dhash), p: hammingHex(a.phash, b.phash) };
  if (isLowInformation(a.dhash) || isLowInformation(b.dhash)) return { match: false, distance };
  return { match: distance.d <= DHASH_MAX_DISTANCE && distance.p <= PHASH_MAX_DISTANCE, distance };
}

export function cryptoHashes(buf: Buffer): Pick<ImageHashes, 'sha256' | 'sha1' | 'md5'> {
  return {
    sha256: crypto.createHash('sha256').update(buf).digest('hex'),
    sha1: crypto.createHash('sha1').update(buf).digest('hex'),
    md5: crypto.createHash('md5').update(buf).digest('hex'),
  };
}

/**
 * All hashes of an encoded image (JPEG/PNG/WebP/GIF/HEIF as far as the
 * bundled libvips supports it). EXIF orientation is applied first so a
 * rotated re-upload of the same photo still matches.
 */
export async function computeImageHashes(buf: Buffer): Promise<ImageHashes> {
  // Lazy: sharp is native and only needed when an image is actually hashed.
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const sharp = require('sharp');
  const gray = async (w: number, h: number): Promise<Buffer> =>
    sharp(buf, { failOn: 'none' })
      .rotate()
      .flatten({ background: '#ffffff' })
      .greyscale()
      .resize(w, h, { fit: 'fill', kernel: 'lanczos3' })
      .raw()
      .toBuffer();
  const [g9, g32] = await Promise.all([gray(9, 8), gray(32, 32)]);
  // greyscale() + raw() yields 1 channel; guard against libvips returning more.
  const oneChannel = (b: Buffer, n: number): Uint8Array => {
    if (b.length === n) return b;
    const ch = Math.round(b.length / n);
    const out = new Uint8Array(n);
    for (let i = 0; i < n; i++) out[i] = b[i * ch];
    return out;
  };
  return {
    dhash: dHashFromGray(oneChannel(g9, 72)),
    phash: pHashFromGray(oneChannel(g32, 1024)),
    ...cryptoHashes(buf),
  };
}
