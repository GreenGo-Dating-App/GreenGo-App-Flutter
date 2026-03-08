/**
 * Vocabulary Import Script
 *
 * Downloads word & sentence frequency data from OpenSubtitles GitHub repo,
 * filters to words with 3+ letters, randomly samples 100k per language,
 * and batch-writes to Firestore.
 *
 * Usage:
 *   cd functions && npm install
 *   cd .. && node scripts/import_vocabulary.js
 */

const admin = require('../functions/node_modules/firebase-admin');
const { GoogleAuth } = require('../functions/node_modules/google-auth-library');
const https = require('https');
const path = require('path');
const os = require('os');
const fs = require('fs');

// Use Firebase CLI's stored refresh token as application default credentials
const firebaseConfigPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
const firebaseConfig = JSON.parse(fs.readFileSync(firebaseConfigPath, 'utf8'));
const refreshToken = firebaseConfig.tokens.refresh_token;

// Write temporary ADC file so firebase-admin can authenticate
const adcPath = path.join(os.tmpdir(), 'adc_greengo.json');
fs.writeFileSync(adcPath, JSON.stringify({
  type: 'authorized_user',
  client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
  client_secret: 'j9iVZfS8kkCEFUPaAeJV0sAi',
  refresh_token: refreshToken,
}));
process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;

admin.initializeApp({
  projectId: 'greengo-chat',
});

const db = admin.firestore();

const BASE_URL = 'https://raw.githubusercontent.com/orgtre/top-open-subtitles-sentences/main/bld';
const LANGUAGES = ['en', 'es', 'de', 'fr', 'it', 'pt', 'pt_br'];
const TARGET_WORDS = 100000;
const BATCH_SIZE = 450;

function downloadCsv(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        return downloadCsv(res.headers.location).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) {
        reject(new Error(`HTTP ${res.statusCode} for ${url}`));
        return;
      }
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
      res.on('error', reject);
    }).on('error', reject);
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

    if (isNaN(count) || !text) continue;
    if (text.length < 3) continue;

    entries.push({ text, count });
  }

  // Sort by count descending
  entries.sort((a, b) => b.count - a.count);
  return entries;
}

function randomSample(arr, count) {
  if (arr.length <= count) return [...arr];

  const list = [...arr];
  for (let i = 0; i < count; i++) {
    const j = i + Math.floor(Math.random() * (list.length - i));
    [list[i], list[j]] = [list[j], list[i]];
  }
  return list.slice(0, count);
}

function computeFrequencyScore(rank, total) {
  if (total <= 1) return 100;
  return Math.max(1, 100 - Math.floor((rank - 1) * 100 / total));
}

async function deleteCollection(collectionPath, language) {
  const snapshot = await db.collection(collectionPath)
    .where('language', '==', language)
    .limit(450)
    .get();

  if (snapshot.empty) return 0;

  const batch = db.batch();
  snapshot.docs.forEach(doc => batch.delete(doc.ref));
  await batch.commit();

  const deleted = snapshot.docs.length;
  if (deleted >= 450) {
    const more = await deleteCollection(collectionPath, language);
    return deleted + more;
  }
  return deleted;
}

async function batchWriteEntries(collection, language, entries) {
  const total = entries.length;
  let written = 0;
  let batch = db.batch();
  let batchCount = 0;

  for (let i = 0; i < entries.length; i++) {
    const entry = entries[i];
    const rank = i + 1;
    const frequencyScore = computeFrequencyScore(rank, total);

    const docRef = db.collection(collection).doc();
    batch.set(docRef, {
      text: entry.text,
      language: language,
      count: entry.count,
      rank: rank,
      frequencyScore: frequencyScore,
    });

    batchCount++;
    if (batchCount >= BATCH_SIZE) {
      await batch.commit();
      written += batchCount;
      process.stdout.write(`\r  ${collection}/${language}: ${written}/${total} written`);
      batch = db.batch();
      batchCount = 0;
    }
  }

  if (batchCount > 0) {
    await batch.commit();
    written += batchCount;
  }
  console.log(`\r  ${collection}/${language}: ${written}/${total} complete`);
}

async function main() {
  console.log('=== Vocabulary Import ===\n');

  for (const lang of LANGUAGES) {
    console.log(`\n--- Processing: ${lang} ---`);

    // Delete existing data for this language
    console.log(`  Clearing old word data for ${lang}...`);
    const deletedWords = await deleteCollection('vocabulary_words', lang);
    console.log(`  Deleted ${deletedWords} old word docs`);

    console.log(`  Clearing old sentence data for ${lang}...`);
    const deletedSentences = await deleteCollection('vocabulary_sentences', lang);
    console.log(`  Deleted ${deletedSentences} old sentence docs`);

    // Import words
    console.log(`  Downloading words for ${lang}...`);
    try {
      const wordsCsv = await downloadCsv(`${BASE_URL}/top_words/${lang}_top_words.csv`);
      const allWords = parseCsv(wordsCsv);
      console.log(`  Parsed ${allWords.length} words (3+ letters)`);

      const sampledWords = randomSample(allWords, TARGET_WORDS);
      sampledWords.sort((a, b) => b.count - a.count);
      console.log(`  Sampled ${sampledWords.length} words`);

      await batchWriteEntries('vocabulary_words', lang, sampledWords);
    } catch (e) {
      console.error(`  Error importing words for ${lang}: ${e.message}`);
    }

    // Import sentences
    console.log(`  Downloading sentences for ${lang}...`);
    try {
      const sentencesCsv = await downloadCsv(`${BASE_URL}/top_sentences/${lang}_top_sentences.csv`);
      const allSentences = parseCsv(sentencesCsv);
      console.log(`  Parsed ${allSentences.length} sentences (3+ chars)`);

      await batchWriteEntries('vocabulary_sentences', lang, allSentences);
    } catch (e) {
      console.error(`  Error importing sentences for ${lang}: ${e.message}`);
    }
  }

  console.log('\n=== Import complete! ===');
  process.exit(0);
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
