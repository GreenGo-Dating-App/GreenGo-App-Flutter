/**
 * Upload attraction image variants to Firebase Storage.
 *
 * Reads the staging manifest produced by transcode.py and uploads
 *   attractions/{ISO2}/{id}/{variant}-{hash}.webp
 * Each attraction gets ONE download token shared by its 4 variants, so the app
 * composes URLs from {base, hash, token} instead of storing 4 URLs per record.
 *
 * Objects are immutable (content-hashed name) => 1-year cache header.
 *
 * Usage:
 *   NODE_PATH=../../functions/node_modules node upload_images.cjs [--force]
 */
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'; // corp TLS MITM on this machine

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const admin = require('firebase-admin');

const SA = 'D:/Projects/GreenGo/firebase/greengo-chat-firebase-adminsdk.json';
const BUCKET = 'greengo-chat.firebasestorage.app';
const STAGING = 'C:/Users/Software Engineering/Desktop/Travel-Attractions-Dataset/_staging_webp';
const OUT_MANIFEST = path.join(__dirname, 'upload_manifest.json');
const FORCE = process.argv.includes('--force');
const CONCURRENCY = 8;

admin.initializeApp({
  credential: admin.credential.cert(require(SA)),
  storageBucket: BUCKET,
});
const bucket = admin.storage().bucket();

const VARIANTS = ['micro', 'thumb', 'card', 'hero'];

async function uploadOne(rec, existing) {
  const token = (existing && existing.token) || crypto.randomUUID();
  const base = rec.base; // attractions/{ISO2}/{id}
  for (const v of VARIANTS) {
    const local = path.join(STAGING, rec.iso, String(rec.id), `${v}-${rec.hash}.webp`);
    if (!fs.existsSync(local)) throw new Error(`missing local ${local}`);
    const dest = `${base}/${v}-${rec.hash}.webp`;
    if (!FORCE) {
      const [exists] = await bucket.file(dest).exists();
      if (exists) continue;
    }
    await bucket.upload(local, {
      destination: dest,
      metadata: {
        contentType: 'image/webp',
        cacheControl: 'public, max-age=31536000, immutable',
        metadata: { firebaseStorageDownloadTokens: token },
      },
    });
  }
  return { id: rec.id, iso: rec.iso, base, hash: rec.hash, token, kind: rec.kind };
}

(async () => {
  const man = JSON.parse(fs.readFileSync(path.join(STAGING, 'build_manifest.json'), 'utf8'));
  const recs = Object.values(man);
  let prev = {};
  if (fs.existsSync(OUT_MANIFEST)) {
    prev = JSON.parse(fs.readFileSync(OUT_MANIFEST, 'utf8'));
    console.log(`resuming: ${Object.keys(prev).length} already uploaded`);
  }
  console.log(`attractions to upload: ${recs.length} (${recs.length * 4} objects)`);

  const out = { ...prev };
  let done = 0, failed = 0;
  const queue = recs.slice();

  async function worker() {
    for (;;) {
      const rec = queue.shift();
      if (!rec) return;
      const ex = prev[String(rec.id)];
      if (ex && ex.hash === rec.hash && !FORCE) { done++; continue; }
      try {
        out[String(rec.id)] = await uploadOne(rec, ex);
      } catch (e) {
        failed++;
        console.error(`  FAIL ${rec.id}: ${String(e.message).slice(0, 90)}`);
      }
      done++;
      if (done % 25 === 0) {
        console.log(`  ${done}/${recs.length}  failed=${failed}`);
        fs.writeFileSync(OUT_MANIFEST, JSON.stringify(out, null, 1));
      }
    }
  }

  await Promise.all(Array.from({ length: CONCURRENCY }, worker));
  fs.writeFileSync(OUT_MANIFEST, JSON.stringify(out, null, 1));

  const n = Object.keys(out).length;
  console.log('\n=== UPLOAD DONE ===');
  console.log(`attractions uploaded : ${n}`);
  console.log(`objects              : ${n * 4}`);
  console.log(`failed               : ${failed}`);
  const sample = out[Object.keys(out)[0]];
  if (sample) {
    const p = encodeURIComponent(`${sample.base}/hero-${sample.hash}.webp`);
    console.log(`sample URL           : https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${p}?alt=media&token=${sample.token}`);
  }
  process.exit(failed > 0 ? 1 : 0);
})().catch((e) => { console.error('FATAL', e); process.exit(1); });
