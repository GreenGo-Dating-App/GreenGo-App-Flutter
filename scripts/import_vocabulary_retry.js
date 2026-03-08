/**
 * Retry import for failed languages (ES, EN sentences, DE sentences)
 */

const admin = require('../functions/node_modules/firebase-admin');
const https = require('https');
const path = require('path');
const os = require('os');
const fs = require('fs');

const firebaseConfigPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
const firebaseConfig = JSON.parse(fs.readFileSync(firebaseConfigPath, 'utf8'));
const refreshToken = firebaseConfig.tokens.refresh_token;

const adcPath = path.join(os.tmpdir(), 'adc_greengo.json');
fs.writeFileSync(adcPath, JSON.stringify({
  type: 'authorized_user',
  client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
  client_secret: 'j9iVZfS8kkCEFUPaAeJV0sAi',
  refresh_token: refreshToken,
}));
process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;

admin.initializeApp({ projectId: 'greengo-chat' });
const db = admin.firestore();

const BASE_URL = 'https://raw.githubusercontent.com/orgtre/top-open-subtitles-sentences/main/bld';
const BATCH_SIZE = 450;

function downloadCsv(url) {
  return new Promise((resolve, reject) => {
    const req = https.get(url, { timeout: 30000 }, (res) => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        return downloadCsv(res.headers.location).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) {
        reject(new Error(`HTTP ${res.statusCode}`));
        return;
      }
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
      res.on('error', reject);
    });
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('timeout')); });
  });
}

function parseCsv(csvData) {
  const lines = csvData.split('\n');
  const entries = [];
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;
    const lastComma = line.lastIndexOf(',');
    if (lastComma <= 0) continue;
    const text = line.substring(0, lastComma).trim();
    const count = parseInt(line.substring(lastComma + 1).trim(), 10);
    if (isNaN(count) || !text || text.length < 3) continue;
    entries.push({ text, count });
  }
  entries.sort((a, b) => b.count - a.count);
  return entries;
}

function computeFrequencyScore(rank, total) {
  if (total <= 1) return 100;
  return Math.max(1, 100 - Math.floor((rank - 1) * 100 / total));
}

async function batchWriteEntries(collection, language, entries) {
  const total = entries.length;
  let written = 0;
  let batch = db.batch();
  let batchCount = 0;
  for (let i = 0; i < entries.length; i++) {
    const entry = entries[i];
    const rank = i + 1;
    const docRef = db.collection(collection).doc();
    batch.set(docRef, {
      text: entry.text, language, count: entry.count,
      rank, frequencyScore: computeFrequencyScore(rank, total),
    });
    batchCount++;
    if (batchCount >= BATCH_SIZE) {
      await batch.commit();
      written += batchCount;
      process.stdout.write(`\r  ${collection}/${language}: ${written}/${total}`);
      batch = db.batch();
      batchCount = 0;
    }
  }
  if (batchCount > 0) { await batch.commit(); written += batchCount; }
  console.log(`\r  ${collection}/${language}: ${written}/${total} complete`);
}

async function importWithRetry(type, lang, maxRetries = 3) {
  const urlPart = type === 'words' ? 'top_words' : 'top_sentences';
  const collection = type === 'words' ? 'vocabulary_words' : 'vocabulary_sentences';
  const url = `${BASE_URL}/${urlPart}/${lang}_${urlPart.replace('top_', 'top_')}.csv`;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      console.log(`  Downloading ${type} for ${lang} (attempt ${attempt})...`);
      const csv = await downloadCsv(url);
      const entries = parseCsv(csv);
      console.log(`  Parsed ${entries.length} ${type}`);
      await batchWriteEntries(collection, lang, entries);
      return;
    } catch (e) {
      console.log(`  Attempt ${attempt} failed: ${e.message}`);
      if (attempt < maxRetries) {
        console.log(`  Waiting 5s before retry...`);
        await new Promise(r => setTimeout(r, 5000));
      }
    }
  }
  console.log(`  FAILED after ${maxRetries} attempts`);
}

async function main() {
  console.log('=== Retry failed imports ===\n');

  // ES words
  console.log('--- ES words ---');
  await importWithRetry('words', 'es');

  // EN sentences
  console.log('--- EN sentences ---');
  await importWithRetry('sentences', 'en');

  // DE sentences
  console.log('--- DE sentences ---');
  await importWithRetry('sentences', 'de');

  // ES sentences
  console.log('--- ES sentences ---');
  await importWithRetry('sentences', 'es');

  console.log('\n=== Retry complete! ===');
  process.exit(0);
}

main().catch(err => { console.error('Fatal:', err); process.exit(1); });
