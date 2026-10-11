/**
 * Perceptual hashes used to block re-uploads of removed NCII / CSAE images.
 * Pure maths + sharp (already a functions dependency); no emulator needed.
 */
import sharp from 'sharp';
import {
  dHashFromGray, pHashFromGray, hammingHex, hashBands, isPerceptualMatch, isLowInformation,
  computeImageHashes, DHASH_MAX_DISTANCE, popcountHex,
} from '../../src/safety/takedowns/perceptualHash';

/** Deterministic "photo-like" RGB image: smooth gradients + blobs, seeded. */
function synthetic(seed: number, w = 320, h = 240): Buffer {
  const px = Buffer.alloc(w * h * 3);
  const blobs = Array.from({ length: 6 }, (_, i) => ({
    x: ((seed * 97 + i * 53) % 100) / 100 * w,
    y: ((seed * 31 + i * 71) % 100) / 100 * h,
    r: 20 + ((seed * 13 + i * 29) % 60),
    c: [(seed * 40 + i * 70) % 256, (seed * 90 + i * 30) % 256, (seed * 10 + i * 110) % 256],
  }));
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      let r = (x / w) * 200 * ((seed % 3) + 1) / 3;
      let g = (y / h) * 180;
      let b = 128 + 100 * Math.sin((x + seed * 17) / (15 + seed));
      for (const bl of blobs) {
        const d = Math.hypot(x - bl.x, y - bl.y);
        if (d < bl.r) { r = bl.c[0]; g = bl.c[1]; b = bl.c[2]; }
      }
      const o = (y * w + x) * 3;
      px[o] = Math.max(0, Math.min(255, r));
      px[o + 1] = Math.max(0, Math.min(255, g));
      px[o + 2] = Math.max(0, Math.min(255, b));
    }
  }
  return px;
}
const jpeg = (raw: Buffer, w = 320, h = 240, quality = 90) =>
  sharp(raw, { raw: { width: w, height: h, channels: 3 } }).jpeg({ quality }).toBuffer();

describe('dHash / pHash maths', () => {
  test('dHash: bit = left pixel brighter than right neighbour', () => {
    const desc = Array.from({ length: 72 }, (_, i) => 255 - (i % 9) * 10); // strictly decreasing rows
    expect(dHashFromGray(desc)).toBe('ffffffffffffffff');
    const asc = Array.from({ length: 72 }, (_, i) => (i % 9) * 10);
    expect(dHashFromGray(asc)).toBe('0000000000000000');
    expect(() => dHashFromGray([1, 2, 3])).toThrow();
  });

  test('pHash: 64 bits, about half set, stable for a scaled copy of the same signal', () => {
    const img = Array.from({ length: 1024 }, (_, i) => 128 + 100 * Math.sin((i % 32) / 3) * Math.cos(Math.floor(i / 32) / 5));
    const h = pHashFromGray(img);
    expect(h).toMatch(/^[0-9a-f]{16}$/);
    expect(popcountHex(h)).toBeGreaterThan(16);
    expect(popcountHex(h)).toBeLessThan(48);
    // A brightness/contrast change does not change the hash.
    expect(pHashFromGray(img.map((v) => v * 0.8 + 20))).toBe(h);
  });

  test('hamming distance', () => {
    expect(hammingHex('0000000000000000', '0000000000000000')).toBe(0);
    expect(hammingHex('0000000000000000', 'ffffffffffffffff')).toBe(64);
    expect(hammingHex('000000000000000f', '0000000000000001')).toBe(3);
    expect(hammingHex('00', '0000')).toBe(Infinity);
    expect(hammingHex('zz', '00')).toBe(Infinity);
  });

  test('bands: any two hashes within 7 bits share at least one band (pigeonhole)', () => {
    const a = '0123456789abcdef';
    let b = a.split('');
    // Flip 7 bits spread over 7 different bytes.
    for (const i of [0, 2, 4, 6, 8, 10, 12]) b[i] = (parseInt(b[i], 16) ^ 8).toString(16);
    const bs = b.join('');
    expect(hammingHex(a, bs)).toBe(DHASH_MAX_DISTANCE);
    const shared = hashBands(a, 'd').filter((x) => hashBands(bs, 'd').includes(x));
    expect(shared.length).toBeGreaterThanOrEqual(1);
    expect(hashBands(a, 'p')[0]).toBe('p0:01');
  });

  test('low-information hashes never match perceptually', () => {
    const blank = { dhash: '0000000000000000', phash: '0000000000000000' };
    expect(isLowInformation(blank.dhash)).toBe(true);
    expect(isPerceptualMatch(blank, blank).match).toBe(false);
  });
});

describe('computeImageHashes (sharp)', () => {
  test('same photo re-encoded, resized, rotated-by-EXIF-free PNG copy -> match; different photo -> no match', async () => {
    const rawA = synthetic(3);
    const a = await computeImageHashes(await jpeg(rawA));
    // Re-compressed at low quality.
    const a2 = await computeImageHashes(await jpeg(rawA, 320, 240, 40));
    // Downscaled to 50% and saved as PNG.
    const smallPng = await sharp(rawA, { raw: { width: 320, height: 240, channels: 3 } })
      .resize(160, 120).png().toBuffer();
    const a3 = await computeImageHashes(smallPng);
    // Slightly brighter.
    const bright = await sharp(rawA, { raw: { width: 320, height: 240, channels: 3 } })
      .modulate({ brightness: 1.08 }).jpeg({ quality: 85 }).toBuffer();
    const a4 = await computeImageHashes(bright);

    for (const v of [a2, a3, a4]) {
      const m = isPerceptualMatch(a, v);
      expect(m.match).toBe(true);
      expect(v.sha256).not.toBe(a.sha256); // bytes differ: only the perceptual hash can catch it
    }

    for (const seed of [5, 8, 11]) {
      const other = await computeImageHashes(await jpeg(synthetic(seed)));
      const m = isPerceptualMatch(a, other);
      expect(m.match).toBe(false);
      expect(m.distance.d + m.distance.p).toBeGreaterThan(20);
    }
  });

  test('exact hashes are the hashes of the raw bytes', async () => {
    const buf = await jpeg(synthetic(4));
    const h = await computeImageHashes(buf);
    expect(h.sha256).toMatch(/^[0-9a-f]{64}$/);
    expect(h.sha1).toMatch(/^[0-9a-f]{40}$/);
    expect(h.md5).toMatch(/^[0-9a-f]{32}$/);
    expect((await computeImageHashes(buf)).sha256).toBe(h.sha256);
  });
});
