/**
 * Setup Gemini API key in Firestore app_config/api_keys document.
 *
 * Usage:
 *   node scripts/setup_gemini_key.js YOUR_GEMINI_API_KEY
 *
 * Or to check current key:
 *   node scripts/setup_gemini_key.js --check
 */

const admin = require('../functions/node_modules/firebase-admin');
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

async function main() {
  const arg = process.argv[2];

  if (!arg) {
    console.log('Usage:');
    console.log('  node scripts/setup_gemini_key.js YOUR_API_KEY   # Set the key');
    console.log('  node scripts/setup_gemini_key.js --check        # Check current key');
    process.exit(1);
  }

  const docRef = db.collection('app_config').doc('api_keys');

  if (arg === '--check') {
    const doc = await docRef.get();
    if (doc.exists) {
      const key = doc.data().gemini_api_key;
      if (key) {
        console.log(`Gemini API key is SET (${key.substring(0, 8)}...${key.substring(key.length - 4)})`);
      } else {
        console.log('Document exists but gemini_api_key field is empty');
      }
    } else {
      console.log('app_config/api_keys document does NOT exist');
    }
  } else {
    await docRef.set({ gemini_api_key: arg }, { merge: true });
    console.log(`Gemini API key set successfully (${arg.substring(0, 8)}...${arg.substring(arg.length - 4)})`);
  }

  process.exit(0);
}

main().catch(err => { console.error('Error:', err); process.exit(1); });
