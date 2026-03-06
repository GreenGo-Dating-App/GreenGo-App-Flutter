/**
 * Seed IT→EN Constellation + Lesson Questions to Firestore (Production)
 *
 * Usage:
 *   node scripts/seed_constellation.js          # seed (skip if exists)
 *   node scripts/seed_constellation.js --force   # delete old + re-seed
 *
 * Requires: gcloud CLI logged in (`gcloud auth login`).
 */

const https = require('https');
const { execSync } = require('child_process');

const PROJECT_ID = 'greengo-chat';
const FORCE = process.argv.includes('--force');

function getAccessToken() {
  try {
    return execSync('gcloud auth print-access-token', { encoding: 'utf8' }).trim();
  } catch {
    throw new Error('Could not get access token. Run: gcloud auth login');
  }
}

function firestoreRequest(method, path, body, token) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const options = {
      hostname: 'firestore.googleapis.com',
      port: 443,
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents${path}`,
      method,
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {}),
      },
    };
    const req = https.request(options, (res) => {
      let result = '';
      res.on('data', (chunk) => (result += chunk));
      res.on('end', () => {
        try { resolve({ status: res.statusCode, data: JSON.parse(result) }); }
        catch { resolve({ status: res.statusCode, data: result }); }
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

function toFirestoreValue(val) {
  if (typeof val === 'string') return { stringValue: val };
  if (typeof val === 'number' && Number.isInteger(val)) return { integerValue: String(val) };
  if (typeof val === 'number') return { doubleValue: val };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (val === null) return { nullValue: null };
  return { stringValue: String(val) };
}

function toFirestoreFields(obj) {
  const fields = {};
  for (const [key, val] of Object.entries(obj)) {
    fields[key] = toFirestoreValue(val);
  }
  return { fields };
}

// ─── DELETE helpers ───

async function queryDocs(collection, fieldFilters, token) {
  const res = await firestoreRequest('POST', ':runQuery', {
    structuredQuery: {
      from: [{ collectionId: collection }],
      where: {
        compositeFilter: {
          op: 'AND',
          filters: fieldFilters.map(([field, value]) => ({
            fieldFilter: {
              field: { fieldPath: field },
              op: 'EQUAL',
              value: { stringValue: value },
            },
          })),
        },
      },
      limit: { value: 500 },
    },
  }, token);

  if (!Array.isArray(res.data)) return [];
  return res.data
    .filter(r => r.document)
    .map(r => r.document.name);
}

async function deleteDoc(fullPath, token) {
  const path = fullPath.replace(
    `projects/${PROJECT_ID}/databases/(default)/documents`, ''
  );
  await firestoreRequest('DELETE', path, null, token);
}

async function deleteCollection(collection, filters, token) {
  const docs = await queryDocs(collection, filters, token);
  if (docs.length === 0) return 0;
  for (let i = 0; i < docs.length; i++) {
    await deleteDoc(docs[i], token);
    process.stdout.write(`  Deleting ${i + 1}/${docs.length}\r`);
  }
  console.log(`\n  Deleted ${docs.length} docs from ${collection}`);
  return docs.length;
}

// ─── DATA ───

function node(unit, nodeIndex, nodeType, nodeTitle, xp = 15, coinCost = 0) {
  return {
    languageSource: 'IT', languageTarget: 'EN', unit, nodeIndex,
    unitTitle: 'Greetings & Basics', nodeType, nodeTitle, xp, coinCost,
  };
}

// quickHint: pipe-separated hints matching each "quoted word" or @word in question
function q(lesson, num, type, question, answers, rightAnswer, hint = '', quickHint = '') {
  return {
    languageSource: 'IT', languageTarget: 'EN', unit: 1,
    lesson, questionNumber: num, questionType: type,
    question, answers, rightAnswer, hint, media: '', quickHint,
  };
}

const constellationNodes = [
  node(1, 1, 'ClassicLesson', 'Hello & Goodbye', 15, 0),
  node(1, 2, 'ClassicLesson', 'How Are You?', 15, 0),
  node(1, 3, 'ClassicLesson', 'My Name Is...', 15, 10),
  node(1, 4, 'ClassicLesson', 'Numbers 1-10', 15, 10),
  node(1, 5, 'ClassicLesson', 'Please & Thank You', 15, 10),
  node(1, 6, 'ClassicLesson', 'Yes, No, Maybe', 15, 10),
  node(1, 7, 'ClassicLesson', 'Common Questions', 20, 10),
  node(1, 8, 'Quiz', 'Basics Quiz 1', 30, 0),
  node(1, 9, 'Flashcard', 'Review Cards', 10, 0),
  node(1, 10, 'ClassicLesson', 'Days of the Week', 15, 10),
  node(1, 11, 'ClassicLesson', 'Months & Seasons', 15, 10),
  node(1, 12, 'ClassicLesson', 'Colors', 15, 10),
  node(1, 13, 'ClassicLesson', 'Family Members', 15, 10),
  node(1, 14, 'ClassicLesson', 'At the Cafe', 20, 10),
  node(1, 15, 'ClassicLesson', 'Food & Drinks', 20, 10),
  node(1, 16, 'ClassicLesson', 'Ordering Food', 20, 10),
  node(1, 17, 'Quiz', 'Basics Quiz 2', 30, 0),
  node(1, 18, 'ClassicLesson', 'Weather Talk', 15, 10),
  node(1, 19, 'ClassicLesson', 'Telling Time', 15, 10),
  node(1, 20, 'ClassicLesson', 'Directions', 20, 10),
  node(1, 21, 'ClassicLesson', 'Shopping Basics', 20, 10),
  node(1, 22, 'ClassicLesson', 'Emergency Phrases', 20, 10),
  node(1, 23, 'Flashcard', 'Full Review', 10, 0),
  node(1, 24, 'Quiz', 'Basics Quiz 3', 30, 0),
  node(1, 25, 'AICoaching', 'AI Conversation', 40, 50),
  node(1, 26, 'FinalQuiz', 'Unit 1 Final', 50, 0),
];

// ── All lesson questions ──
// "quoted words" become gold-highlighted in the app.
// quickHint maps to each quoted word in order → long-press shows translation.
const lessonQuestions = [
  // ═══ LESSON 1: Hello & Goodbye — 24 questions ═══

  // 1-2: multiple_choice
  q(1, 1, 'multiple_choice', 'Come si dice "Ciao" in inglese?', 'Hello|Goodbye|Please|Sorry', 'Hello', '', 'Hello'),
  q(1, 2, 'multiple_choice', 'What does "Arrivederci" mean in English?', 'Goodbye|Hello|Good morning|See you', 'Goodbye', '', 'Addio'),

  // 3-4: fill_in_blank
  q(1, 3, 'fill_in_blank', 'In Italian, "goodbye" is "arrivederci". Complete: Good ___!', 'morning|afternoon|evening|night', 'morning', 'Morning greeting in English', 'addio|addio'),
  q(1, 4, 'fill_in_blank', '"Buonasera" means "Good ___" in English.', 'evening|morning|night|afternoon', 'evening', 'After 6 PM greeting', 'Good evening'),

  // 5-6: translation
  q(1, 5, 'translation', 'Traduci: "Buongiorno"', '', 'Good morning', 'Morning greeting', 'Good morning'),
  q(1, 6, 'translation', 'Traduci: "Buonanotte"', '', 'Good night', 'Before sleeping', 'Good night'),

  // 7-8: listening
  q(1, 7, 'listening', 'Listen and type what you hear in English.', '', 'Good morning', 'A common morning greeting', ''),
  q(1, 8, 'listening', 'Listen and type the English greeting.', '', 'Goodbye', 'A farewell word', ''),

  // 9-10: speaking
  q(1, 9, 'speaking', 'How do you say "Grazie" in English?', '', 'Thank you', '', 'Thanks'),
  q(1, 10, 'speaking', 'Say "Prego" in English.', '', "You're welcome", '', 'Response to thanks'),

  // 11-12: matching
  q(1, 11, 'matching', 'Match the Italian greetings to their English translations.', 'Ciao:Hello|Arrivederci:Goodbye|Buongiorno:Good morning|Grazie:Thank you', 'correct', '', ''),
  q(1, 12, 'matching', 'Match these "saluti" to English.', 'Buonasera:Good evening|Buonanotte:Good night|Per favore:Please|Scusa:Sorry', 'correct', '', 'greetings'),

  // 13-14: reorder_words
  q(1, 13, 'reorder_words', 'Reorder to make an English greeting:', 'morning|Good', 'Good morning', '', ''),
  q(1, 14, 'reorder_words', 'Put these words in the right order:', 'you|see|later', 'see you later', '', ''),

  // 15-16: true_false
  q(1, 15, 'true_false', '"Ciao" means "Goodbye" in English.', 'True|False', 'True', '"Ciao" can mean both Hello and Goodbye', 'Hello/Goodbye'),
  q(1, 16, 'true_false', '"Good night" is used as a morning greeting.', 'True|False', 'False', 'Used before sleeping', 'Buonanotte'),

  // 17-18: conversation_choice
  q(1, 17, 'conversation_choice', 'Someone says "Ciao!" to you. How do you reply?', 'Hello!|Thank you|Sorry|Please', 'Hello!', '', 'Hello/Goodbye'),
  q(1, 18, 'conversation_choice', 'Your friend is leaving. What do you say?', 'Goodbye!|Good morning!|Thank you!|Please!', 'Goodbye!', '', ''),

  // 19-20: free_response
  q(1, 19, 'free_response', 'Write a greeting in English that you would use in the morning.', '', 'Good morning', '', ''),
  q(1, 20, 'free_response', 'Write how you would say farewell to a friend in English.', '', 'Goodbye', '', ''),

  // 21-22: reading_comprehension
  q(1, 21, 'reading_comprehension',
    'PASSAGE: Maria walks into the cafe in the morning. She sees her friend Luca. "Buongiorno, Luca!" she says with a smile. Luca looks up and replies, "Ciao, Maria! Come stai?" Maria answers, "Sto bene, grazie! E tu?" Luca says he is fine too. They order two coffees. Before leaving, Maria says "Arrivederci!" and Luca waves goodbye.\n\nQUESTION: What greeting does Maria use when she arrives?',
    'Buongiorno|Ciao|Arrivederci|Buonanotte', 'Buongiorno', 'Read the passage carefully', ''),
  q(1, 22, 'reading_comprehension',
    'PASSAGE: Every morning, Paolo walks to school. He meets his teacher at the door. "Good morning, Paolo!" says the teacher. Paolo replies, "Good morning!" During the day, he says "please" and "thank you" many times. At the end of the day, Paolo says "Goodbye!" to his friends and walks home. His mother greets him: "Ciao, Paolo! How are you?" He answers, "I\'m fine, thank you!"\n\nQUESTION: What does Paolo say to his friends at the end of the day?',
    'Goodbye!|Good morning!|Thank you!|Please!', 'Goodbye!', 'Look at the end of the passage', ''),

  // 23-24: listening_comprehension
  q(1, 23, 'listening_comprehension',
    'PASSAGE: Anna meets her neighbor every morning. She always says "Good morning!" Her neighbor replies "Hello! How are you?" Anna says "I\'m fine, thank you!" Before going to work, she waves and says "See you later!" Her neighbor smiles and says "Goodbye!"\n\nQUESTION: How does Anna\'s neighbor respond to "Good morning"?',
    'Hello! How are you?|Goodbye!|Thank you!|Good night!', 'Hello! How are you?', 'Listen to the passage carefully', ''),
  q(1, 24, 'listening_comprehension',
    'PASSAGE: Marco is at a restaurant in Rome. The waiter comes and says "Buonasera!" Marco replies "Good evening!" The waiter asks "What would you like?" Marco says "A pizza, please." After eating, Marco says "Thank you very much!" and the waiter answers "You\'re welcome! Arrivederci!"\n\nQUESTION: What does the waiter say at the end?',
    "You're welcome! Arrivederci!|Good morning!|Thank you!|Hello!", "You're welcome! Arrivederci!", 'Listen for the farewell', ''),

  // ═══ LESSON 2: How Are You? ═══
  q(2, 1, 'multiple_choice', 'Come si dice "Come stai?" in inglese?', 'How are you?|What is your name?|Where are you?|How old are you?', 'How are you?', '', 'How are you?'),
  q(2, 2, 'multiple_choice', 'What does "Sto bene" mean?', "I'm fine|I'm tired|I'm hungry|I'm sorry", "I'm fine", '', 'I am well'),
  q(2, 3, 'translation', 'Traduci: "Non c\'e\' male"', '', 'Not bad', 'Neither good nor bad', 'Not bad'),
  q(2, 4, 'multiple_choice', '"I\'m great!" in italiano:', 'Sto benissimo!|Sto male|Non lo so|Sono stanco', 'Sto benissimo!', '', 'I feel great'),
  q(2, 5, 'fill_in_blank', 'How ___ you? (Come stai?)', 'are|is|do|can', 'are', '', ''),
  q(2, 6, 'true_false', '"I\'m so-so" significa "Sto benissimo".', 'True|False', 'False', '', 'Cosi cosi'),
  q(2, 7, 'multiple_choice', 'What is the formal way to ask "How are you?"', "How do you do?|What's up?|Hey!|Yo!", 'How do you do?', '', 'Come stai? (formale)'),
  q(2, 8, 'multiple_choice', '"And you?" si traduce come:', 'E tu?|E io?|E noi?|E loro?', 'E tu?', '', 'And you?'),

  // ═══ LESSON 3: My Name Is... ═══
  q(3, 1, 'multiple_choice', 'Come si dice "Mi chiamo Marco" in inglese?', 'My name is Marco|I am Marco years old|Marco is my friend|I like Marco', 'My name is Marco', '', 'My name is Marco'),
  q(3, 2, 'fill_in_blank', 'My ___ is Anna. (Mi chiamo Anna)', 'name|age|friend|home', 'name', '', ''),
  q(3, 3, 'multiple_choice', '"What is your name?" significa:', 'Come ti chiami?|Quanti anni hai?|Dove abiti?|Cosa fai?', 'Come ti chiami?', '', 'What is your name?'),
  q(3, 4, 'translation', 'Traduci: "Piacere di conoscerti"', '', 'Nice to meet you', 'When meeting someone for the first time', 'Nice to meet you'),
  q(3, 5, 'multiple_choice', 'How do you introduce yourself in English?', "I'm Maria|Maria I am called|Me Maria|Maria me", "I'm Maria", '', 'Mi chiamo Maria'),
  q(3, 6, 'true_false', '"I\'m" is the contraction of "I am".', 'True|False', 'True', '', 'I am'),
  q(3, 7, 'multiple_choice', '"Where are you from?" significa:', 'Di dove sei?|Dove vai?|Come stai?|Cosa mangi?', 'Di dove sei?', '', 'Where are you from?'),
  q(3, 8, 'fill_in_blank', "I'm ___ Italy. (Sono dall'Italia)", 'from|in|at|to', 'from', '', ''),

  // ═══ LESSON 4: Numbers 1-10 ═══
  q(4, 1, 'multiple_choice', 'Come si dice "tre" in inglese?', 'Three|Tree|Thee|Tray', 'Three', '', 'Three'),
  q(4, 2, 'multiple_choice', 'What number is "seven"?', '7|6|8|5', '7', '', 'sette'),
  q(4, 3, 'fill_in_blank', 'One, two, ___, four, five', 'three|tree|free|thee', 'three', '', ''),
  q(4, 4, 'multiple_choice', '"Dieci" in inglese:', 'Ten|Tin|Tan|Ton', 'Ten', '', 'Ten'),
  q(4, 5, 'true_false', '"Eight" has a silent "gh".', 'True|False', 'True', '', 'otto'),
  q(4, 6, 'multiple_choice', '"Five" comes after...', 'four|three|six|seven', 'four', '', 'cinque'),
  q(4, 7, 'translation', 'Traduci: "nove"', '', 'nine', '', 'nine'),
  q(4, 8, 'multiple_choice', 'Which is the correct spelling?', 'six|siks|sics|syx', 'six', '', 'sei'),

  // ═══ LESSON 5: Please & Thank You ═══
  q(5, 1, 'multiple_choice', 'Come si dice "Per favore" in inglese?', 'Please|Thanks|Sorry|Excuse me', 'Please', '', 'Please'),
  q(5, 2, 'multiple_choice', '"Thank you" significa:', 'Grazie|Prego|Scusa|Per favore', 'Grazie', '', 'Grazie'),
  q(5, 3, 'translation', 'Traduci: "Prego" (risposta a grazie)', '', "You're welcome", '', "You're welcome"),
  q(5, 4, 'fill_in_blank', 'Thank you very ___! (Grazie mille)', 'much|many|more|most', 'much', '', ''),
  q(5, 5, 'multiple_choice', '"Excuse me" in italiano:', 'Mi scusi|Mi piace|Mi chiamo|Mi fermo', 'Mi scusi', '', 'Mi scusi'),
  q(5, 6, 'true_false', '"Thanks" is the informal version of "Thank you".', 'True|False', 'True', '', 'Grazie (informale)'),
  q(5, 7, 'multiple_choice', 'Come si dice "Mi dispiace"?', "I'm sorry|I'm happy|I'm hungry|I'm tired", "I'm sorry", '', "I'm sorry"),
  q(5, 8, 'multiple_choice', '"No problem" si usa per:', 'Rispondere a "grazie"|Ordinare cibo|Chiedere indicazioni|Salutare', 'Rispondere a "grazie"', '', 'Nessun problema'),

  // ═══ LESSON 6: Yes, No, Maybe ═══
  q(6, 1, 'multiple_choice', 'Come si dice "Si" in inglese?', 'Yes|No|Maybe|Sure', 'Yes', '', 'Yes'),
  q(6, 2, 'multiple_choice', '"Maybe" in italiano:', 'Forse|Mai|Sempre|Adesso', 'Forse', '', 'Forse'),
  q(6, 3, 'fill_in_blank', 'Of ___! (Certo!)', 'course|curse|cause|coarse', 'course', '', ''),
  q(6, 4, 'true_false', '"Sure" and "Of course" have the same meaning.', 'True|False', 'True', '', 'Certo|Certo'),
  q(6, 5, 'multiple_choice', 'Come si dice "Non lo so"?', "I don't know|I don't like|I don't want|I don't have", "I don't know", '', "I don't know"),
  q(6, 6, 'translation', 'Traduci: "Penso di si"', '', 'I think so', '', 'I think so'),
  q(6, 7, 'multiple_choice', '"Absolutely!" esprime:', 'Forte accordo|Disaccordo|Dubbio|Tristezza', 'Forte accordo', '', 'Assolutamente'),
  q(6, 8, 'multiple_choice', '"Not really" in italiano:', 'Non proprio|Non mai|Non sempre|Non adesso', 'Non proprio', '', 'Non proprio'),

  // ═══ LESSON 7: Common Questions ═══
  q(7, 1, 'multiple_choice', 'Come si dice "Quanto costa?" in inglese?', 'How much does it cost?|How old are you?|How far is it?|How long does it take?', 'How much does it cost?', '', 'How much does it cost?'),
  q(7, 2, 'fill_in_blank', "___ is the bathroom? (Dov'e' il bagno?)", 'Where|What|Who|When', 'Where', '', ''),
  q(7, 3, 'multiple_choice', '"What time is it?" significa:', "Che ora e'?|Che giorno e'?|Che tempo fa?|Che cosa e'?", "Che ora e'?", '', "Che ora e'?"),
  q(7, 4, 'translation', 'Traduci: "Parli italiano?"', '', 'Do you speak Italian?', '', 'Do you speak Italian?'),
  q(7, 5, 'multiple_choice', '"Can you help me?" in italiano:', 'Puoi aiutarmi?|Puoi pagarmi?|Puoi chiamarmi?|Puoi aspettarmi?', 'Puoi aiutarmi?', '', 'Puoi aiutarmi?'),
  q(7, 6, 'true_false', '"What" is used to ask about things.', 'True|False', 'True', '', 'Cosa'),
  q(7, 7, 'multiple_choice', 'Which question word means "perche"?', 'Why|When|Who|Which', 'Why', '', 'perche'),
  q(7, 8, 'multiple_choice', '"How do you say ___ in English?" is used to:', 'Ask for a translation|Order food|Give directions|Introduce yourself', 'Ask for a translation', '', 'Come si dice...?'),
];

// ─── SEED ───

async function createDoc(collection, doc, token) {
  const body = toFirestoreFields(doc);
  const res = await firestoreRequest('POST', `/${collection}`, body, token);
  if (res.status !== 200) {
    throw new Error(`Failed to create doc in ${collection}: ${res.status} ${JSON.stringify(res.data)}`);
  }
}

async function checkExists(token) {
  const res = await firestoreRequest('POST', ':runQuery', {
    structuredQuery: {
      from: [{ collectionId: 'constellation' }],
      where: {
        compositeFilter: {
          op: 'AND',
          filters: [
            { fieldFilter: { field: { fieldPath: 'languageSource' }, op: 'EQUAL', value: { stringValue: 'IT' } } },
            { fieldFilter: { field: { fieldPath: 'languageTarget' }, op: 'EQUAL', value: { stringValue: 'EN' } } },
          ],
        },
      },
      limit: { value: 1 },
    },
  }, token);
  if (Array.isArray(res.data) && res.data.length > 0 && res.data[0].document) return true;
  return false;
}

async function seed() {
  console.log('Getting access token...');
  const token = getAccessToken();

  const exists = await checkExists(token);

  if (FORCE && exists) {
    console.log('--force: Deleting old IT→EN data...');
    await deleteCollection('lessons', [['languageSource', 'IT'], ['languageTarget', 'EN']], token);
    await deleteCollection('constellation', [['languageSource', 'IT'], ['languageTarget', 'EN']], token);
    console.log('Old data deleted.');
  } else if (exists && !FORCE) {
    console.log('IT→EN data already exists. Use --force to re-seed.');
    return;
  }

  console.log(`Seeding ${constellationNodes.length} constellation nodes...`);
  for (let i = 0; i < constellationNodes.length; i++) {
    await createDoc('constellation', constellationNodes[i], token);
    process.stdout.write(`  Node ${i + 1}/${constellationNodes.length}\r`);
  }
  console.log('\nConstellation nodes written.');

  console.log(`Seeding ${lessonQuestions.length} lesson questions...`);
  for (let i = 0; i < lessonQuestions.length; i++) {
    await createDoc('lessons', lessonQuestions[i], token);
    process.stdout.write(`  Question ${i + 1}/${lessonQuestions.length}\r`);
  }
  console.log('\nLesson questions written.');

  console.log('Done! IT→EN Unit 1 seeded successfully.');
}

seed().catch(err => {
  console.error('Seed failed:', err.message);
  process.exit(1);
});
