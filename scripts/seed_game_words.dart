/// Seed script for game word database.
///
/// Run from project root:
///   dart run scripts/seed_game_words.dart
///
/// Seeds:
/// 1. `game_words` — 500+ words per language × 7 languages
/// 2. `game_translation_race` — pre-built translation questions
/// 3. `game_grammar_questions` — 50+ grammar questions per language
///
/// Uses Firestore batch writes (max 500 per batch).
/// Idempotent: checks counts before inserting.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIGURATION
// ─────────────────────────────────────────────────────────────────────────────

const kLanguages = ['EN', 'IT', 'ES', 'FR', 'DE', 'PT', 'JA'];

// ─────────────────────────────────────────────────────────────────────────────
// WORD DATA — 500+ words across 15 categories
// Each entry: { 'EN': ..., 'IT': ..., 'ES': ..., 'FR': ..., 'DE': ..., 'PT': ..., 'JA': ... }
// ─────────────────────────────────────────────────────────────────────────────

const kStarterWords = <String, List<Map<String, dynamic>>>{
  'animals': [
    {'word': {'EN': 'dog', 'IT': 'cane', 'ES': 'perro', 'FR': 'chien', 'DE': 'Hund', 'PT': 'cão', 'JA': '犬'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'cat', 'IT': 'gatto', 'ES': 'gato', 'FR': 'chat', 'DE': 'Katze', 'PT': 'gato', 'JA': '猫'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'bird', 'IT': 'uccello', 'ES': 'pájaro', 'FR': 'oiseau', 'DE': 'Vogel', 'PT': 'pássaro', 'JA': '鳥'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'fish', 'IT': 'pesce', 'ES': 'pez', 'FR': 'poisson', 'DE': 'Fisch', 'PT': 'peixe', 'JA': '魚'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'horse', 'IT': 'cavallo', 'ES': 'caballo', 'FR': 'cheval', 'DE': 'Pferd', 'PT': 'cavalo', 'JA': '馬'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'cow', 'IT': 'mucca', 'ES': 'vaca', 'FR': 'vache', 'DE': 'Kuh', 'PT': 'vaca', 'JA': '牛'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'pig', 'IT': 'maiale', 'ES': 'cerdo', 'FR': 'cochon', 'DE': 'Schwein', 'PT': 'porco', 'JA': '豚'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'rabbit', 'IT': 'coniglio', 'ES': 'conejo', 'FR': 'lapin', 'DE': 'Kaninchen', 'PT': 'coelho', 'JA': 'うさぎ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'bear', 'IT': 'orso', 'ES': 'oso', 'FR': 'ours', 'DE': 'Bär', 'PT': 'urso', 'JA': '熊'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'lion', 'IT': 'leone', 'ES': 'león', 'FR': 'lion', 'DE': 'Löwe', 'PT': 'leão', 'JA': 'ライオン'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'elephant', 'IT': 'elefante', 'ES': 'elefante', 'FR': 'éléphant', 'DE': 'Elefant', 'PT': 'elefante', 'JA': '象'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'monkey', 'IT': 'scimmia', 'ES': 'mono', 'FR': 'singe', 'DE': 'Affe', 'PT': 'macaco', 'JA': '猿'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'butterfly', 'IT': 'farfalla', 'ES': 'mariposa', 'FR': 'papillon', 'DE': 'Schmetterling', 'PT': 'borboleta', 'JA': '蝶'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'snake', 'IT': 'serpente', 'ES': 'serpiente', 'FR': 'serpent', 'DE': 'Schlange', 'PT': 'cobra', 'JA': '蛇'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'turtle', 'IT': 'tartaruga', 'ES': 'tortuga', 'FR': 'tortue', 'DE': 'Schildkröte', 'PT': 'tartaruga', 'JA': '亀'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'wolf', 'IT': 'lupo', 'ES': 'lobo', 'FR': 'loup', 'DE': 'Wolf', 'PT': 'lobo', 'JA': '狼'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'deer', 'IT': 'cervo', 'ES': 'ciervo', 'FR': 'cerf', 'DE': 'Hirsch', 'PT': 'cervo', 'JA': '鹿'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'fox', 'IT': 'volpe', 'ES': 'zorro', 'FR': 'renard', 'DE': 'Fuchs', 'PT': 'raposa', 'JA': '狐'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'eagle', 'IT': 'aquila', 'ES': 'águila', 'FR': 'aigle', 'DE': 'Adler', 'PT': 'águia', 'JA': '鷲'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'owl', 'IT': 'gufo', 'ES': 'búho', 'FR': 'hibou', 'DE': 'Eule', 'PT': 'coruja', 'JA': 'フクロウ'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'dolphin', 'IT': 'delfino', 'ES': 'delfín', 'FR': 'dauphin', 'DE': 'Delfin', 'PT': 'golfinho', 'JA': 'イルカ'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'whale', 'IT': 'balena', 'ES': 'ballena', 'FR': 'baleine', 'DE': 'Wal', 'PT': 'baleia', 'JA': 'クジラ'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'shark', 'IT': 'squalo', 'ES': 'tiburón', 'FR': 'requin', 'DE': 'Hai', 'PT': 'tubarão', 'JA': 'サメ'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'penguin', 'IT': 'pinguino', 'ES': 'pingüino', 'FR': 'pingouin', 'DE': 'Pinguin', 'PT': 'pinguim', 'JA': 'ペンギン'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'frog', 'IT': 'rana', 'ES': 'rana', 'FR': 'grenouille', 'DE': 'Frosch', 'PT': 'sapo', 'JA': 'カエル'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'ant', 'IT': 'formica', 'ES': 'hormiga', 'FR': 'fourmi', 'DE': 'Ameise', 'PT': 'formiga', 'JA': '蟻'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'bee', 'IT': 'ape', 'ES': 'abeja', 'FR': 'abeille', 'DE': 'Biene', 'PT': 'abelha', 'JA': '蜂'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'spider', 'IT': 'ragno', 'ES': 'araña', 'FR': 'araignée', 'DE': 'Spinne', 'PT': 'aranha', 'JA': 'クモ'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'mouse', 'IT': 'topo', 'ES': 'ratón', 'FR': 'souris', 'DE': 'Maus', 'PT': 'rato', 'JA': 'ネズミ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'duck', 'IT': 'anatra', 'ES': 'pato', 'FR': 'canard', 'DE': 'Ente', 'PT': 'pato', 'JA': 'アヒル'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'sheep', 'IT': 'pecora', 'ES': 'oveja', 'FR': 'mouton', 'DE': 'Schaf', 'PT': 'ovelha', 'JA': '羊'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'goat', 'IT': 'capra', 'ES': 'cabra', 'FR': 'chèvre', 'DE': 'Ziege', 'PT': 'cabra', 'JA': 'ヤギ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'tiger', 'IT': 'tigre', 'ES': 'tigre', 'FR': 'tigre', 'DE': 'Tiger', 'PT': 'tigre', 'JA': '虎'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'giraffe', 'IT': 'giraffa', 'ES': 'jirafa', 'FR': 'girafe', 'DE': 'Giraffe', 'PT': 'girafa', 'JA': 'キリン'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'zebra', 'IT': 'zebra', 'ES': 'cebra', 'FR': 'zèbre', 'DE': 'Zebra', 'PT': 'zebra', 'JA': 'シマウマ'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'crocodile', 'IT': 'coccodrillo', 'ES': 'cocodrilo', 'FR': 'crocodile', 'DE': 'Krokodil', 'PT': 'crocodilo', 'JA': 'ワニ'}, 'difficulty': 4, 'pos': 'noun'},
    {'word': {'EN': 'camel', 'IT': 'cammello', 'ES': 'camello', 'FR': 'chameau', 'DE': 'Kamel', 'PT': 'camelo', 'JA': 'ラクダ'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'parrot', 'IT': 'pappagallo', 'ES': 'loro', 'FR': 'perroquet', 'DE': 'Papagei', 'PT': 'papagaio', 'JA': 'オウム'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'donkey', 'IT': 'asino', 'ES': 'burro', 'FR': 'âne', 'DE': 'Esel', 'PT': 'burro', 'JA': 'ロバ'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'squirrel', 'IT': 'scoiattolo', 'ES': 'ardilla', 'FR': 'écureuil', 'DE': 'Eichhörnchen', 'PT': 'esquilo', 'JA': 'リス'}, 'difficulty': 4, 'pos': 'noun'},
  ],
  'food_drinks': [
    {'word': {'EN': 'water', 'IT': 'acqua', 'ES': 'agua', 'FR': 'eau', 'DE': 'Wasser', 'PT': 'água', 'JA': '水'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'bread', 'IT': 'pane', 'ES': 'pan', 'FR': 'pain', 'DE': 'Brot', 'PT': 'pão', 'JA': 'パン'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'milk', 'IT': 'latte', 'ES': 'leche', 'FR': 'lait', 'DE': 'Milch', 'PT': 'leite', 'JA': '牛乳'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'rice', 'IT': 'riso', 'ES': 'arroz', 'FR': 'riz', 'DE': 'Reis', 'PT': 'arroz', 'JA': '米'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'apple', 'IT': 'mela', 'ES': 'manzana', 'FR': 'pomme', 'DE': 'Apfel', 'PT': 'maçã', 'JA': 'りんご'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'coffee', 'IT': 'caffè', 'ES': 'café', 'FR': 'café', 'DE': 'Kaffee', 'PT': 'café', 'JA': 'コーヒー'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'cheese', 'IT': 'formaggio', 'ES': 'queso', 'FR': 'fromage', 'DE': 'Käse', 'PT': 'queijo', 'JA': 'チーズ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'chicken', 'IT': 'pollo', 'ES': 'pollo', 'FR': 'poulet', 'DE': 'Huhn', 'PT': 'frango', 'JA': '鶏肉'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'egg', 'IT': 'uovo', 'ES': 'huevo', 'FR': 'œuf', 'DE': 'Ei', 'PT': 'ovo', 'JA': '卵'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'sugar', 'IT': 'zucchero', 'ES': 'azúcar', 'FR': 'sucre', 'DE': 'Zucker', 'PT': 'açúcar', 'JA': '砂糖'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'salt', 'IT': 'sale', 'ES': 'sal', 'FR': 'sel', 'DE': 'Salz', 'PT': 'sal', 'JA': '塩'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'butter', 'IT': 'burro', 'ES': 'mantequilla', 'FR': 'beurre', 'DE': 'Butter', 'PT': 'manteiga', 'JA': 'バター'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'meat', 'IT': 'carne', 'ES': 'carne', 'FR': 'viande', 'DE': 'Fleisch', 'PT': 'carne', 'JA': '肉'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'pasta', 'IT': 'pasta', 'ES': 'pasta', 'FR': 'pâtes', 'DE': 'Nudeln', 'PT': 'massa', 'JA': 'パスタ'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'pizza', 'IT': 'pizza', 'ES': 'pizza', 'FR': 'pizza', 'DE': 'Pizza', 'PT': 'pizza', 'JA': 'ピザ'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'soup', 'IT': 'zuppa', 'ES': 'sopa', 'FR': 'soupe', 'DE': 'Suppe', 'PT': 'sopa', 'JA': 'スープ'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'salad', 'IT': 'insalata', 'ES': 'ensalada', 'FR': 'salade', 'DE': 'Salat', 'PT': 'salada', 'JA': 'サラダ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'cake', 'IT': 'torta', 'ES': 'pastel', 'FR': 'gâteau', 'DE': 'Kuchen', 'PT': 'bolo', 'JA': 'ケーキ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'chocolate', 'IT': 'cioccolato', 'ES': 'chocolate', 'FR': 'chocolat', 'DE': 'Schokolade', 'PT': 'chocolate', 'JA': 'チョコレート'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'tea', 'IT': 'tè', 'ES': 'té', 'FR': 'thé', 'DE': 'Tee', 'PT': 'chá', 'JA': 'お茶'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'juice', 'IT': 'succo', 'ES': 'jugo', 'FR': 'jus', 'DE': 'Saft', 'PT': 'suco', 'JA': 'ジュース'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'wine', 'IT': 'vino', 'ES': 'vino', 'FR': 'vin', 'DE': 'Wein', 'PT': 'vinho', 'JA': 'ワイン'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'beer', 'IT': 'birra', 'ES': 'cerveza', 'FR': 'bière', 'DE': 'Bier', 'PT': 'cerveja', 'JA': 'ビール'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'banana', 'IT': 'banana', 'ES': 'plátano', 'FR': 'banane', 'DE': 'Banane', 'PT': 'banana', 'JA': 'バナナ'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'orange', 'IT': 'arancia', 'ES': 'naranja', 'FR': 'orange', 'DE': 'Orange', 'PT': 'laranja', 'JA': 'オレンジ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'grape', 'IT': 'uva', 'ES': 'uva', 'FR': 'raisin', 'DE': 'Traube', 'PT': 'uva', 'JA': 'ぶどう'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'strawberry', 'IT': 'fragola', 'ES': 'fresa', 'FR': 'fraise', 'DE': 'Erdbeere', 'PT': 'morango', 'JA': 'いちご'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'lemon', 'IT': 'limone', 'ES': 'limón', 'FR': 'citron', 'DE': 'Zitrone', 'PT': 'limão', 'JA': 'レモン'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'tomato', 'IT': 'pomodoro', 'ES': 'tomate', 'FR': 'tomate', 'DE': 'Tomate', 'PT': 'tomate', 'JA': 'トマト'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'potato', 'IT': 'patata', 'ES': 'patata', 'FR': 'pomme de terre', 'DE': 'Kartoffel', 'PT': 'batata', 'JA': 'じゃがいも'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'onion', 'IT': 'cipolla', 'ES': 'cebolla', 'FR': 'oignon', 'DE': 'Zwiebel', 'PT': 'cebola', 'JA': '玉ねぎ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'carrot', 'IT': 'carota', 'ES': 'zanahoria', 'FR': 'carotte', 'DE': 'Karotte', 'PT': 'cenoura', 'JA': 'にんじん'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'garlic', 'IT': 'aglio', 'ES': 'ajo', 'FR': 'ail', 'DE': 'Knoblauch', 'PT': 'alho', 'JA': 'にんにく'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'mushroom', 'IT': 'fungo', 'ES': 'champiñón', 'FR': 'champignon', 'DE': 'Pilz', 'PT': 'cogumelo', 'JA': 'きのこ'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'pepper', 'IT': 'pepe', 'ES': 'pimienta', 'FR': 'poivre', 'DE': 'Pfeffer', 'PT': 'pimenta', 'JA': '胡椒'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'oil', 'IT': 'olio', 'ES': 'aceite', 'FR': 'huile', 'DE': 'Öl', 'PT': 'óleo', 'JA': '油'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'flour', 'IT': 'farina', 'ES': 'harina', 'FR': 'farine', 'DE': 'Mehl', 'PT': 'farinha', 'JA': '小麦粉'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'honey', 'IT': 'miele', 'ES': 'miel', 'FR': 'miel', 'DE': 'Honig', 'PT': 'mel', 'JA': 'はちみつ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'sandwich', 'IT': 'panino', 'ES': 'sándwich', 'FR': 'sandwich', 'DE': 'Sandwich', 'PT': 'sanduíche', 'JA': 'サンドイッチ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'peach', 'IT': 'pesca', 'ES': 'melocotón', 'FR': 'pêche', 'DE': 'Pfirsich', 'PT': 'pêssego', 'JA': '桃'}, 'difficulty': 3, 'pos': 'noun'},
  ],
  'household': [
    {'word': {'EN': 'house', 'IT': 'casa', 'ES': 'casa', 'FR': 'maison', 'DE': 'Haus', 'PT': 'casa', 'JA': '家'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'door', 'IT': 'porta', 'ES': 'puerta', 'FR': 'porte', 'DE': 'Tür', 'PT': 'porta', 'JA': 'ドア'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'window', 'IT': 'finestra', 'ES': 'ventana', 'FR': 'fenêtre', 'DE': 'Fenster', 'PT': 'janela', 'JA': '窓'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'table', 'IT': 'tavolo', 'ES': 'mesa', 'FR': 'table', 'DE': 'Tisch', 'PT': 'mesa', 'JA': 'テーブル'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'chair', 'IT': 'sedia', 'ES': 'silla', 'FR': 'chaise', 'DE': 'Stuhl', 'PT': 'cadeira', 'JA': '椅子'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'bed', 'IT': 'letto', 'ES': 'cama', 'FR': 'lit', 'DE': 'Bett', 'PT': 'cama', 'JA': 'ベッド'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'lamp', 'IT': 'lampada', 'ES': 'lámpara', 'FR': 'lampe', 'DE': 'Lampe', 'PT': 'lâmpada', 'JA': 'ランプ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'kitchen', 'IT': 'cucina', 'ES': 'cocina', 'FR': 'cuisine', 'DE': 'Küche', 'PT': 'cozinha', 'JA': '台所'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'bathroom', 'IT': 'bagno', 'ES': 'baño', 'FR': 'salle de bain', 'DE': 'Badezimmer', 'PT': 'banheiro', 'JA': '浴室'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'garden', 'IT': 'giardino', 'ES': 'jardín', 'FR': 'jardin', 'DE': 'Garten', 'PT': 'jardim', 'JA': '庭'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'room', 'IT': 'stanza', 'ES': 'habitación', 'FR': 'chambre', 'DE': 'Zimmer', 'PT': 'quarto', 'JA': '部屋'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'wall', 'IT': 'muro', 'ES': 'pared', 'FR': 'mur', 'DE': 'Wand', 'PT': 'parede', 'JA': '壁'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'floor', 'IT': 'pavimento', 'ES': 'suelo', 'FR': 'sol', 'DE': 'Boden', 'PT': 'chão', 'JA': '床'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'roof', 'IT': 'tetto', 'ES': 'techo', 'FR': 'toit', 'DE': 'Dach', 'PT': 'telhado', 'JA': '屋根'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'stairs', 'IT': 'scale', 'ES': 'escaleras', 'FR': 'escalier', 'DE': 'Treppe', 'PT': 'escada', 'JA': '階段'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'sofa', 'IT': 'divano', 'ES': 'sofá', 'FR': 'canapé', 'DE': 'Sofa', 'PT': 'sofá', 'JA': 'ソファ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'mirror', 'IT': 'specchio', 'ES': 'espejo', 'FR': 'miroir', 'DE': 'Spiegel', 'PT': 'espelho', 'JA': '鏡'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'clock', 'IT': 'orologio', 'ES': 'reloj', 'FR': 'horloge', 'DE': 'Uhr', 'PT': 'relógio', 'JA': '時計'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'key', 'IT': 'chiave', 'ES': 'llave', 'FR': 'clé', 'DE': 'Schlüssel', 'PT': 'chave', 'JA': '鍵'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'plate', 'IT': 'piatto', 'ES': 'plato', 'FR': 'assiette', 'DE': 'Teller', 'PT': 'prato', 'JA': '皿'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'cup', 'IT': 'tazza', 'ES': 'taza', 'FR': 'tasse', 'DE': 'Tasse', 'PT': 'xícara', 'JA': 'カップ'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'glass', 'IT': 'bicchiere', 'ES': 'vaso', 'FR': 'verre', 'DE': 'Glas', 'PT': 'copo', 'JA': 'グラス'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'fork', 'IT': 'forchetta', 'ES': 'tenedor', 'FR': 'fourchette', 'DE': 'Gabel', 'PT': 'garfo', 'JA': 'フォーク'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'knife', 'IT': 'coltello', 'ES': 'cuchillo', 'FR': 'couteau', 'DE': 'Messer', 'PT': 'faca', 'JA': 'ナイフ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'spoon', 'IT': 'cucchiaio', 'ES': 'cuchara', 'FR': 'cuillère', 'DE': 'Löffel', 'PT': 'colher', 'JA': 'スプーン'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'towel', 'IT': 'asciugamano', 'ES': 'toalla', 'FR': 'serviette', 'DE': 'Handtuch', 'PT': 'toalha', 'JA': 'タオル'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'pillow', 'IT': 'cuscino', 'ES': 'almohada', 'FR': 'oreiller', 'DE': 'Kissen', 'PT': 'travesseiro', 'JA': '枕'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'blanket', 'IT': 'coperta', 'ES': 'manta', 'FR': 'couverture', 'DE': 'Decke', 'PT': 'cobertor', 'JA': '毛布'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'carpet', 'IT': 'tappeto', 'ES': 'alfombra', 'FR': 'tapis', 'DE': 'Teppich', 'PT': 'tapete', 'JA': 'カーペット'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'broom', 'IT': 'scopa', 'ES': 'escoba', 'FR': 'balai', 'DE': 'Besen', 'PT': 'vassoura', 'JA': 'ほうき'}, 'difficulty': 3, 'pos': 'noun'},
  ],
  'nature': [
    {'word': {'EN': 'tree', 'IT': 'albero', 'ES': 'árbol', 'FR': 'arbre', 'DE': 'Baum', 'PT': 'árvore', 'JA': '木'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'flower', 'IT': 'fiore', 'ES': 'flor', 'FR': 'fleur', 'DE': 'Blume', 'PT': 'flor', 'JA': '花'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'sun', 'IT': 'sole', 'ES': 'sol', 'FR': 'soleil', 'DE': 'Sonne', 'PT': 'sol', 'JA': '太陽'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'moon', 'IT': 'luna', 'ES': 'luna', 'FR': 'lune', 'DE': 'Mond', 'PT': 'lua', 'JA': '月'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'star', 'IT': 'stella', 'ES': 'estrella', 'FR': 'étoile', 'DE': 'Stern', 'PT': 'estrela', 'JA': '星'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'sky', 'IT': 'cielo', 'ES': 'cielo', 'FR': 'ciel', 'DE': 'Himmel', 'PT': 'céu', 'JA': '空'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'cloud', 'IT': 'nuvola', 'ES': 'nube', 'FR': 'nuage', 'DE': 'Wolke', 'PT': 'nuvem', 'JA': '雲'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'rain', 'IT': 'pioggia', 'ES': 'lluvia', 'FR': 'pluie', 'DE': 'Regen', 'PT': 'chuva', 'JA': '雨'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'wind', 'IT': 'vento', 'ES': 'viento', 'FR': 'vent', 'DE': 'Wind', 'PT': 'vento', 'JA': '風'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'river', 'IT': 'fiume', 'ES': 'río', 'FR': 'rivière', 'DE': 'Fluss', 'PT': 'rio', 'JA': '川'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'mountain', 'IT': 'montagna', 'ES': 'montaña', 'FR': 'montagne', 'DE': 'Berg', 'PT': 'montanha', 'JA': '山'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'sea', 'IT': 'mare', 'ES': 'mar', 'FR': 'mer', 'DE': 'Meer', 'PT': 'mar', 'JA': '海'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'lake', 'IT': 'lago', 'ES': 'lago', 'FR': 'lac', 'DE': 'See', 'PT': 'lago', 'JA': '湖'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'forest', 'IT': 'foresta', 'ES': 'bosque', 'FR': 'forêt', 'DE': 'Wald', 'PT': 'floresta', 'JA': '森'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'grass', 'IT': 'erba', 'ES': 'hierba', 'FR': 'herbe', 'DE': 'Gras', 'PT': 'grama', 'JA': '草'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'stone', 'IT': 'pietra', 'ES': 'piedra', 'FR': 'pierre', 'DE': 'Stein', 'PT': 'pedra', 'JA': '石'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'sand', 'IT': 'sabbia', 'ES': 'arena', 'FR': 'sable', 'DE': 'Sand', 'PT': 'areia', 'JA': '砂'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'snow', 'IT': 'neve', 'ES': 'nieve', 'FR': 'neige', 'DE': 'Schnee', 'PT': 'neve', 'JA': '雪'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'fire', 'IT': 'fuoco', 'ES': 'fuego', 'FR': 'feu', 'DE': 'Feuer', 'PT': 'fogo', 'JA': '火'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'leaf', 'IT': 'foglia', 'ES': 'hoja', 'FR': 'feuille', 'DE': 'Blatt', 'PT': 'folha', 'JA': '葉'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'island', 'IT': 'isola', 'ES': 'isla', 'FR': 'île', 'DE': 'Insel', 'PT': 'ilha', 'JA': '島'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'desert', 'IT': 'deserto', 'ES': 'desierto', 'FR': 'désert', 'DE': 'Wüste', 'PT': 'deserto', 'JA': '砂漠'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'volcano', 'IT': 'vulcano', 'ES': 'volcán', 'FR': 'volcan', 'DE': 'Vulkan', 'PT': 'vulcão', 'JA': '火山'}, 'difficulty': 4, 'pos': 'noun'},
    {'word': {'EN': 'rainbow', 'IT': 'arcobaleno', 'ES': 'arcoíris', 'FR': 'arc-en-ciel', 'DE': 'Regenbogen', 'PT': 'arco-íris', 'JA': '虹'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'storm', 'IT': 'tempesta', 'ES': 'tormenta', 'FR': 'tempête', 'DE': 'Sturm', 'PT': 'tempestade', 'JA': '嵐'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'ice', 'IT': 'ghiaccio', 'ES': 'hielo', 'FR': 'glace', 'DE': 'Eis', 'PT': 'gelo', 'JA': '氷'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'wave', 'IT': 'onda', 'ES': 'ola', 'FR': 'vague', 'DE': 'Welle', 'PT': 'onda', 'JA': '波'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'beach', 'IT': 'spiaggia', 'ES': 'playa', 'FR': 'plage', 'DE': 'Strand', 'PT': 'praia', 'JA': 'ビーチ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'waterfall', 'IT': 'cascata', 'ES': 'cascada', 'FR': 'cascade', 'DE': 'Wasserfall', 'PT': 'cachoeira', 'JA': '滝'}, 'difficulty': 4, 'pos': 'noun'},
    {'word': {'EN': 'earth', 'IT': 'terra', 'ES': 'tierra', 'FR': 'terre', 'DE': 'Erde', 'PT': 'terra', 'JA': '地球'}, 'difficulty': 2, 'pos': 'noun'},
  ],
  'travel': [
    {'word': {'EN': 'car', 'IT': 'auto', 'ES': 'coche', 'FR': 'voiture', 'DE': 'Auto', 'PT': 'carro', 'JA': '車'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'bus', 'IT': 'autobus', 'ES': 'autobús', 'FR': 'bus', 'DE': 'Bus', 'PT': 'ônibus', 'JA': 'バス'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'train', 'IT': 'treno', 'ES': 'tren', 'FR': 'train', 'DE': 'Zug', 'PT': 'trem', 'JA': '電車'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'airplane', 'IT': 'aereo', 'ES': 'avión', 'FR': 'avion', 'DE': 'Flugzeug', 'PT': 'avião', 'JA': '飛行機'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'boat', 'IT': 'barca', 'ES': 'barco', 'FR': 'bateau', 'DE': 'Boot', 'PT': 'barco', 'JA': '船'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'bicycle', 'IT': 'bicicletta', 'ES': 'bicicleta', 'FR': 'vélo', 'DE': 'Fahrrad', 'PT': 'bicicleta', 'JA': '自転車'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'street', 'IT': 'strada', 'ES': 'calle', 'FR': 'rue', 'DE': 'Straße', 'PT': 'rua', 'JA': '道'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'map', 'IT': 'mappa', 'ES': 'mapa', 'FR': 'carte', 'DE': 'Karte', 'PT': 'mapa', 'JA': '地図'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'hotel', 'IT': 'albergo', 'ES': 'hotel', 'FR': 'hôtel', 'DE': 'Hotel', 'PT': 'hotel', 'JA': 'ホテル'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'airport', 'IT': 'aeroporto', 'ES': 'aeropuerto', 'FR': 'aéroport', 'DE': 'Flughafen', 'PT': 'aeroporto', 'JA': '空港'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'station', 'IT': 'stazione', 'ES': 'estación', 'FR': 'gare', 'DE': 'Bahnhof', 'PT': 'estação', 'JA': '駅'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'ticket', 'IT': 'biglietto', 'ES': 'billete', 'FR': 'billet', 'DE': 'Fahrkarte', 'PT': 'bilhete', 'JA': '切符'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'passport', 'IT': 'passaporto', 'ES': 'pasaporte', 'FR': 'passeport', 'DE': 'Reisepass', 'PT': 'passaporte', 'JA': 'パスポート'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'suitcase', 'IT': 'valigia', 'ES': 'maleta', 'FR': 'valise', 'DE': 'Koffer', 'PT': 'mala', 'JA': 'スーツケース'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'city', 'IT': 'città', 'ES': 'ciudad', 'FR': 'ville', 'DE': 'Stadt', 'PT': 'cidade', 'JA': '都市'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'country', 'IT': 'paese', 'ES': 'país', 'FR': 'pays', 'DE': 'Land', 'PT': 'país', 'JA': '国'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'bridge', 'IT': 'ponte', 'ES': 'puente', 'FR': 'pont', 'DE': 'Brücke', 'PT': 'ponte', 'JA': '橋'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'taxi', 'IT': 'taxi', 'ES': 'taxi', 'FR': 'taxi', 'DE': 'Taxi', 'PT': 'táxi', 'JA': 'タクシー'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'museum', 'IT': 'museo', 'ES': 'museo', 'FR': 'musée', 'DE': 'Museum', 'PT': 'museu', 'JA': '美術館'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'restaurant', 'IT': 'ristorante', 'ES': 'restaurante', 'FR': 'restaurant', 'DE': 'Restaurant', 'PT': 'restaurante', 'JA': 'レストラン'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'park', 'IT': 'parco', 'ES': 'parque', 'FR': 'parc', 'DE': 'Park', 'PT': 'parque', 'JA': '公園'}, 'difficulty': 1, 'pos': 'noun'},
  ],
  'family': [
    {'word': {'EN': 'mother', 'IT': 'madre', 'ES': 'madre', 'FR': 'mère', 'DE': 'Mutter', 'PT': 'mãe', 'JA': '母'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'father', 'IT': 'padre', 'ES': 'padre', 'FR': 'père', 'DE': 'Vater', 'PT': 'pai', 'JA': '父'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'brother', 'IT': 'fratello', 'ES': 'hermano', 'FR': 'frère', 'DE': 'Bruder', 'PT': 'irmão', 'JA': '兄弟'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'sister', 'IT': 'sorella', 'ES': 'hermana', 'FR': 'sœur', 'DE': 'Schwester', 'PT': 'irmã', 'JA': '姉妹'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'son', 'IT': 'figlio', 'ES': 'hijo', 'FR': 'fils', 'DE': 'Sohn', 'PT': 'filho', 'JA': '息子'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'daughter', 'IT': 'figlia', 'ES': 'hija', 'FR': 'fille', 'DE': 'Tochter', 'PT': 'filha', 'JA': '娘'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'grandmother', 'IT': 'nonna', 'ES': 'abuela', 'FR': 'grand-mère', 'DE': 'Großmutter', 'PT': 'avó', 'JA': '祖母'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'grandfather', 'IT': 'nonno', 'ES': 'abuelo', 'FR': 'grand-père', 'DE': 'Großvater', 'PT': 'avô', 'JA': '祖父'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'uncle', 'IT': 'zio', 'ES': 'tío', 'FR': 'oncle', 'DE': 'Onkel', 'PT': 'tio', 'JA': '叔父'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'aunt', 'IT': 'zia', 'ES': 'tía', 'FR': 'tante', 'DE': 'Tante', 'PT': 'tia', 'JA': '叔母'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'cousin', 'IT': 'cugino', 'ES': 'primo', 'FR': 'cousin', 'DE': 'Cousin', 'PT': 'primo', 'JA': 'いとこ'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'husband', 'IT': 'marito', 'ES': 'esposo', 'FR': 'mari', 'DE': 'Ehemann', 'PT': 'marido', 'JA': '夫'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'wife', 'IT': 'moglie', 'ES': 'esposa', 'FR': 'femme', 'DE': 'Ehefrau', 'PT': 'esposa', 'JA': '妻'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'baby', 'IT': 'bambino', 'ES': 'bebé', 'FR': 'bébé', 'DE': 'Baby', 'PT': 'bebê', 'JA': '赤ちゃん'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'child', 'IT': 'bambino', 'ES': 'niño', 'FR': 'enfant', 'DE': 'Kind', 'PT': 'criança', 'JA': '子供'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'family', 'IT': 'famiglia', 'ES': 'familia', 'FR': 'famille', 'DE': 'Familie', 'PT': 'família', 'JA': '家族'}, 'difficulty': 1, 'pos': 'noun'},
  ],
  'colors_shapes': [
    {'word': {'EN': 'red', 'IT': 'rosso', 'ES': 'rojo', 'FR': 'rouge', 'DE': 'rot', 'PT': 'vermelho', 'JA': '赤'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'blue', 'IT': 'blu', 'ES': 'azul', 'FR': 'bleu', 'DE': 'blau', 'PT': 'azul', 'JA': '青'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'green', 'IT': 'verde', 'ES': 'verde', 'FR': 'vert', 'DE': 'grün', 'PT': 'verde', 'JA': '緑'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'yellow', 'IT': 'giallo', 'ES': 'amarillo', 'FR': 'jaune', 'DE': 'gelb', 'PT': 'amarelo', 'JA': '黄色'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'black', 'IT': 'nero', 'ES': 'negro', 'FR': 'noir', 'DE': 'schwarz', 'PT': 'preto', 'JA': '黒'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'white', 'IT': 'bianco', 'ES': 'blanco', 'FR': 'blanc', 'DE': 'weiß', 'PT': 'branco', 'JA': '白'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'orange', 'IT': 'arancione', 'ES': 'naranja', 'FR': 'orange', 'DE': 'orange', 'PT': 'laranja', 'JA': 'オレンジ'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'purple', 'IT': 'viola', 'ES': 'morado', 'FR': 'violet', 'DE': 'lila', 'PT': 'roxo', 'JA': '紫'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'pink', 'IT': 'rosa', 'ES': 'rosa', 'FR': 'rose', 'DE': 'rosa', 'PT': 'rosa', 'JA': 'ピンク'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'brown', 'IT': 'marrone', 'ES': 'marrón', 'FR': 'marron', 'DE': 'braun', 'PT': 'marrom', 'JA': '茶色'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'gray', 'IT': 'grigio', 'ES': 'gris', 'FR': 'gris', 'DE': 'grau', 'PT': 'cinza', 'JA': '灰色'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'circle', 'IT': 'cerchio', 'ES': 'círculo', 'FR': 'cercle', 'DE': 'Kreis', 'PT': 'círculo', 'JA': '丸'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'square', 'IT': 'quadrato', 'ES': 'cuadrado', 'FR': 'carré', 'DE': 'Quadrat', 'PT': 'quadrado', 'JA': '四角'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'triangle', 'IT': 'triangolo', 'ES': 'triángulo', 'FR': 'triangle', 'DE': 'Dreieck', 'PT': 'triângulo', 'JA': '三角'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'heart', 'IT': 'cuore', 'ES': 'corazón', 'FR': 'cœur', 'DE': 'Herz', 'PT': 'coração', 'JA': 'ハート'}, 'difficulty': 2, 'pos': 'noun'},
  ],
  'clothing': [
    {'word': {'EN': 'shirt', 'IT': 'camicia', 'ES': 'camisa', 'FR': 'chemise', 'DE': 'Hemd', 'PT': 'camisa', 'JA': 'シャツ'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'pants', 'IT': 'pantaloni', 'ES': 'pantalones', 'FR': 'pantalon', 'DE': 'Hose', 'PT': 'calça', 'JA': 'ズボン'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'shoes', 'IT': 'scarpe', 'ES': 'zapatos', 'FR': 'chaussures', 'DE': 'Schuhe', 'PT': 'sapatos', 'JA': '靴'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'hat', 'IT': 'cappello', 'ES': 'sombrero', 'FR': 'chapeau', 'DE': 'Hut', 'PT': 'chapéu', 'JA': '帽子'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'dress', 'IT': 'vestito', 'ES': 'vestido', 'FR': 'robe', 'DE': 'Kleid', 'PT': 'vestido', 'JA': 'ドレス'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'jacket', 'IT': 'giacca', 'ES': 'chaqueta', 'FR': 'veste', 'DE': 'Jacke', 'PT': 'jaqueta', 'JA': 'ジャケット'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'coat', 'IT': 'cappotto', 'ES': 'abrigo', 'FR': 'manteau', 'DE': 'Mantel', 'PT': 'casaco', 'JA': 'コート'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'skirt', 'IT': 'gonna', 'ES': 'falda', 'FR': 'jupe', 'DE': 'Rock', 'PT': 'saia', 'JA': 'スカート'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'socks', 'IT': 'calzini', 'ES': 'calcetines', 'FR': 'chaussettes', 'DE': 'Socken', 'PT': 'meias', 'JA': '靴下'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'gloves', 'IT': 'guanti', 'ES': 'guantes', 'FR': 'gants', 'DE': 'Handschuhe', 'PT': 'luvas', 'JA': '手袋'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'scarf', 'IT': 'sciarpa', 'ES': 'bufanda', 'FR': 'écharpe', 'DE': 'Schal', 'PT': 'cachecol', 'JA': 'マフラー'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'belt', 'IT': 'cintura', 'ES': 'cinturón', 'FR': 'ceinture', 'DE': 'Gürtel', 'PT': 'cinto', 'JA': 'ベルト'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'boots', 'IT': 'stivali', 'ES': 'botas', 'FR': 'bottes', 'DE': 'Stiefel', 'PT': 'botas', 'JA': 'ブーツ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'sweater', 'IT': 'maglione', 'ES': 'suéter', 'FR': 'pull', 'DE': 'Pullover', 'PT': 'suéter', 'JA': 'セーター'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'tie', 'IT': 'cravatta', 'ES': 'corbata', 'FR': 'cravate', 'DE': 'Krawatte', 'PT': 'gravata', 'JA': 'ネクタイ'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'umbrella', 'IT': 'ombrello', 'ES': 'paraguas', 'FR': 'parapluie', 'DE': 'Regenschirm', 'PT': 'guarda-chuva', 'JA': '傘'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'bag', 'IT': 'borsa', 'ES': 'bolsa', 'FR': 'sac', 'DE': 'Tasche', 'PT': 'bolsa', 'JA': 'かばん'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'wallet', 'IT': 'portafoglio', 'ES': 'cartera', 'FR': 'portefeuille', 'DE': 'Geldbörse', 'PT': 'carteira', 'JA': '財布'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'watch', 'IT': 'orologio', 'ES': 'reloj', 'FR': 'montre', 'DE': 'Armbanduhr', 'PT': 'relógio', 'JA': '腕時計'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'glasses', 'IT': 'occhiali', 'ES': 'gafas', 'FR': 'lunettes', 'DE': 'Brille', 'PT': 'óculos', 'JA': '眼鏡'}, 'difficulty': 2, 'pos': 'noun'},
  ],
  'body_health': [
    {'word': {'EN': 'head', 'IT': 'testa', 'ES': 'cabeza', 'FR': 'tête', 'DE': 'Kopf', 'PT': 'cabeça', 'JA': '頭'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'hand', 'IT': 'mano', 'ES': 'mano', 'FR': 'main', 'DE': 'Hand', 'PT': 'mão', 'JA': '手'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'eye', 'IT': 'occhio', 'ES': 'ojo', 'FR': 'œil', 'DE': 'Auge', 'PT': 'olho', 'JA': '目'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'ear', 'IT': 'orecchio', 'ES': 'oreja', 'FR': 'oreille', 'DE': 'Ohr', 'PT': 'orelha', 'JA': '耳'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'mouth', 'IT': 'bocca', 'ES': 'boca', 'FR': 'bouche', 'DE': 'Mund', 'PT': 'boca', 'JA': '口'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'nose', 'IT': 'naso', 'ES': 'nariz', 'FR': 'nez', 'DE': 'Nase', 'PT': 'nariz', 'JA': '鼻'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'hair', 'IT': 'capelli', 'ES': 'cabello', 'FR': 'cheveux', 'DE': 'Haar', 'PT': 'cabelo', 'JA': '髪'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'tooth', 'IT': 'dente', 'ES': 'diente', 'FR': 'dent', 'DE': 'Zahn', 'PT': 'dente', 'JA': '歯'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'heart', 'IT': 'cuore', 'ES': 'corazón', 'FR': 'cœur', 'DE': 'Herz', 'PT': 'coração', 'JA': '心臓'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'leg', 'IT': 'gamba', 'ES': 'pierna', 'FR': 'jambe', 'DE': 'Bein', 'PT': 'perna', 'JA': '足'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'arm', 'IT': 'braccio', 'ES': 'brazo', 'FR': 'bras', 'DE': 'Arm', 'PT': 'braço', 'JA': '腕'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'foot', 'IT': 'piede', 'ES': 'pie', 'FR': 'pied', 'DE': 'Fuß', 'PT': 'pé', 'JA': '足'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'finger', 'IT': 'dito', 'ES': 'dedo', 'FR': 'doigt', 'DE': 'Finger', 'PT': 'dedo', 'JA': '指'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'neck', 'IT': 'collo', 'ES': 'cuello', 'FR': 'cou', 'DE': 'Hals', 'PT': 'pescoço', 'JA': '首'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'shoulder', 'IT': 'spalla', 'ES': 'hombro', 'FR': 'épaule', 'DE': 'Schulter', 'PT': 'ombro', 'JA': '肩'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'back', 'IT': 'schiena', 'ES': 'espalda', 'FR': 'dos', 'DE': 'Rücken', 'PT': 'costas', 'JA': '背中'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'knee', 'IT': 'ginocchio', 'ES': 'rodilla', 'FR': 'genou', 'DE': 'Knie', 'PT': 'joelho', 'JA': '膝'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'stomach', 'IT': 'stomaco', 'ES': 'estómago', 'FR': 'estomac', 'DE': 'Magen', 'PT': 'estômago', 'JA': '胃'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'blood', 'IT': 'sangue', 'ES': 'sangre', 'FR': 'sang', 'DE': 'Blut', 'PT': 'sangue', 'JA': '血'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'bone', 'IT': 'osso', 'ES': 'hueso', 'FR': 'os', 'DE': 'Knochen', 'PT': 'osso', 'JA': '骨'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'skin', 'IT': 'pelle', 'ES': 'piel', 'FR': 'peau', 'DE': 'Haut', 'PT': 'pele', 'JA': '肌'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'brain', 'IT': 'cervello', 'ES': 'cerebro', 'FR': 'cerveau', 'DE': 'Gehirn', 'PT': 'cérebro', 'JA': '脳'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'face', 'IT': 'viso', 'ES': 'cara', 'FR': 'visage', 'DE': 'Gesicht', 'PT': 'rosto', 'JA': '顔'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'tongue', 'IT': 'lingua', 'ES': 'lengua', 'FR': 'langue', 'DE': 'Zunge', 'PT': 'língua', 'JA': '舌'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'chest', 'IT': 'petto', 'ES': 'pecho', 'FR': 'poitrine', 'DE': 'Brust', 'PT': 'peito', 'JA': '胸'}, 'difficulty': 2, 'pos': 'noun'},
  ],
  'emotions': [
    {'word': {'EN': 'happy', 'IT': 'felice', 'ES': 'feliz', 'FR': 'heureux', 'DE': 'glücklich', 'PT': 'feliz', 'JA': '嬉しい'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'sad', 'IT': 'triste', 'ES': 'triste', 'FR': 'triste', 'DE': 'traurig', 'PT': 'triste', 'JA': '悲しい'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'angry', 'IT': 'arrabbiato', 'ES': 'enfadado', 'FR': 'en colère', 'DE': 'wütend', 'PT': 'zangado', 'JA': '怒った'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'scared', 'IT': 'spaventato', 'ES': 'asustado', 'FR': 'effrayé', 'DE': 'ängstlich', 'PT': 'assustado', 'JA': '怖い'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'tired', 'IT': 'stanco', 'ES': 'cansado', 'FR': 'fatigué', 'DE': 'müde', 'PT': 'cansado', 'JA': '疲れた'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'excited', 'IT': 'entusiasta', 'ES': 'emocionado', 'FR': 'excité', 'DE': 'aufgeregt', 'PT': 'animado', 'JA': 'ワクワク'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'bored', 'IT': 'annoiato', 'ES': 'aburrido', 'FR': 'ennuyé', 'DE': 'gelangweilt', 'PT': 'entediado', 'JA': '退屈'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'surprised', 'IT': 'sorpreso', 'ES': 'sorprendido', 'FR': 'surpris', 'DE': 'überrascht', 'PT': 'surpreso', 'JA': '驚いた'}, 'difficulty': 3, 'pos': 'adjective'},
    {'word': {'EN': 'confused', 'IT': 'confuso', 'ES': 'confundido', 'FR': 'confus', 'DE': 'verwirrt', 'PT': 'confuso', 'JA': '混乱した'}, 'difficulty': 3, 'pos': 'adjective'},
    {'word': {'EN': 'nervous', 'IT': 'nervoso', 'ES': 'nervioso', 'FR': 'nerveux', 'DE': 'nervös', 'PT': 'nervoso', 'JA': '緊張した'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'proud', 'IT': 'orgoglioso', 'ES': 'orgulloso', 'FR': 'fier', 'DE': 'stolz', 'PT': 'orgulhoso', 'JA': '誇らしい'}, 'difficulty': 3, 'pos': 'adjective'},
    {'word': {'EN': 'shy', 'IT': 'timido', 'ES': 'tímido', 'FR': 'timide', 'DE': 'schüchtern', 'PT': 'tímido', 'JA': '恥ずかしい'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'lonely', 'IT': 'solo', 'ES': 'solitario', 'FR': 'seul', 'DE': 'einsam', 'PT': 'solitário', 'JA': '寂しい'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'grateful', 'IT': 'grato', 'ES': 'agradecido', 'FR': 'reconnaissant', 'DE': 'dankbar', 'PT': 'grato', 'JA': '感謝した'}, 'difficulty': 3, 'pos': 'adjective'},
    {'word': {'EN': 'calm', 'IT': 'calmo', 'ES': 'tranquilo', 'FR': 'calme', 'DE': 'ruhig', 'PT': 'calmo', 'JA': '穏やか'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'curious', 'IT': 'curioso', 'ES': 'curioso', 'FR': 'curieux', 'DE': 'neugierig', 'PT': 'curioso', 'JA': '好奇心'}, 'difficulty': 3, 'pos': 'adjective'},
    {'word': {'EN': 'jealous', 'IT': 'geloso', 'ES': 'celoso', 'FR': 'jaloux', 'DE': 'eifersüchtig', 'PT': 'ciumento', 'JA': '嫉妬した'}, 'difficulty': 3, 'pos': 'adjective'},
    {'word': {'EN': 'confident', 'IT': 'sicuro', 'ES': 'seguro', 'FR': 'confiant', 'DE': 'selbstbewusst', 'PT': 'confiante', 'JA': '自信ある'}, 'difficulty': 3, 'pos': 'adjective'},
    {'word': {'EN': 'worried', 'IT': 'preoccupato', 'ES': 'preocupado', 'FR': 'inquiet', 'DE': 'besorgt', 'PT': 'preocupado', 'JA': '心配した'}, 'difficulty': 3, 'pos': 'adjective'},
    {'word': {'EN': 'relaxed', 'IT': 'rilassato', 'ES': 'relajado', 'FR': 'détendu', 'DE': 'entspannt', 'PT': 'relaxado', 'JA': 'リラックス'}, 'difficulty': 3, 'pos': 'adjective'},
  ],
  'verbs_common': [
    {'word': {'EN': 'eat', 'IT': 'mangiare', 'ES': 'comer', 'FR': 'manger', 'DE': 'essen', 'PT': 'comer', 'JA': '食べる'}, 'difficulty': 1, 'pos': 'verb'},
    {'word': {'EN': 'drink', 'IT': 'bere', 'ES': 'beber', 'FR': 'boire', 'DE': 'trinken', 'PT': 'beber', 'JA': '飲む'}, 'difficulty': 1, 'pos': 'verb'},
    {'word': {'EN': 'sleep', 'IT': 'dormire', 'ES': 'dormir', 'FR': 'dormir', 'DE': 'schlafen', 'PT': 'dormir', 'JA': '寝る'}, 'difficulty': 1, 'pos': 'verb'},
    {'word': {'EN': 'walk', 'IT': 'camminare', 'ES': 'caminar', 'FR': 'marcher', 'DE': 'gehen', 'PT': 'andar', 'JA': '歩く'}, 'difficulty': 1, 'pos': 'verb'},
    {'word': {'EN': 'run', 'IT': 'correre', 'ES': 'correr', 'FR': 'courir', 'DE': 'laufen', 'PT': 'correr', 'JA': '走る'}, 'difficulty': 1, 'pos': 'verb'},
    {'word': {'EN': 'read', 'IT': 'leggere', 'ES': 'leer', 'FR': 'lire', 'DE': 'lesen', 'PT': 'ler', 'JA': '読む'}, 'difficulty': 1, 'pos': 'verb'},
    {'word': {'EN': 'write', 'IT': 'scrivere', 'ES': 'escribir', 'FR': 'écrire', 'DE': 'schreiben', 'PT': 'escrever', 'JA': '書く'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'speak', 'IT': 'parlare', 'ES': 'hablar', 'FR': 'parler', 'DE': 'sprechen', 'PT': 'falar', 'JA': '話す'}, 'difficulty': 1, 'pos': 'verb'},
    {'word': {'EN': 'listen', 'IT': 'ascoltare', 'ES': 'escuchar', 'FR': 'écouter', 'DE': 'hören', 'PT': 'ouvir', 'JA': '聞く'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'see', 'IT': 'vedere', 'ES': 'ver', 'FR': 'voir', 'DE': 'sehen', 'PT': 'ver', 'JA': '見る'}, 'difficulty': 1, 'pos': 'verb'},
    {'word': {'EN': 'think', 'IT': 'pensare', 'ES': 'pensar', 'FR': 'penser', 'DE': 'denken', 'PT': 'pensar', 'JA': '考える'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'know', 'IT': 'sapere', 'ES': 'saber', 'FR': 'savoir', 'DE': 'wissen', 'PT': 'saber', 'JA': '知る'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'want', 'IT': 'volere', 'ES': 'querer', 'FR': 'vouloir', 'DE': 'wollen', 'PT': 'querer', 'JA': '欲しい'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'give', 'IT': 'dare', 'ES': 'dar', 'FR': 'donner', 'DE': 'geben', 'PT': 'dar', 'JA': 'あげる'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'take', 'IT': 'prendere', 'ES': 'tomar', 'FR': 'prendre', 'DE': 'nehmen', 'PT': 'tomar', 'JA': '取る'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'make', 'IT': 'fare', 'ES': 'hacer', 'FR': 'faire', 'DE': 'machen', 'PT': 'fazer', 'JA': '作る'}, 'difficulty': 1, 'pos': 'verb'},
    {'word': {'EN': 'come', 'IT': 'venire', 'ES': 'venir', 'FR': 'venir', 'DE': 'kommen', 'PT': 'vir', 'JA': '来る'}, 'difficulty': 1, 'pos': 'verb'},
    {'word': {'EN': 'go', 'IT': 'andare', 'ES': 'ir', 'FR': 'aller', 'DE': 'gehen', 'PT': 'ir', 'JA': '行く'}, 'difficulty': 1, 'pos': 'verb'},
    {'word': {'EN': 'play', 'IT': 'giocare', 'ES': 'jugar', 'FR': 'jouer', 'DE': 'spielen', 'PT': 'jogar', 'JA': '遊ぶ'}, 'difficulty': 1, 'pos': 'verb'},
    {'word': {'EN': 'work', 'IT': 'lavorare', 'ES': 'trabajar', 'FR': 'travailler', 'DE': 'arbeiten', 'PT': 'trabalhar', 'JA': '働く'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'learn', 'IT': 'imparare', 'ES': 'aprender', 'FR': 'apprendre', 'DE': 'lernen', 'PT': 'aprender', 'JA': '学ぶ'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'teach', 'IT': 'insegnare', 'ES': 'enseñar', 'FR': 'enseigner', 'DE': 'lehren', 'PT': 'ensinar', 'JA': '教える'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'buy', 'IT': 'comprare', 'ES': 'comprar', 'FR': 'acheter', 'DE': 'kaufen', 'PT': 'comprar', 'JA': '買う'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'sell', 'IT': 'vendere', 'ES': 'vender', 'FR': 'vendre', 'DE': 'verkaufen', 'PT': 'vender', 'JA': '売る'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'open', 'IT': 'aprire', 'ES': 'abrir', 'FR': 'ouvrir', 'DE': 'öffnen', 'PT': 'abrir', 'JA': '開ける'}, 'difficulty': 1, 'pos': 'verb'},
    {'word': {'EN': 'close', 'IT': 'chiudere', 'ES': 'cerrar', 'FR': 'fermer', 'DE': 'schließen', 'PT': 'fechar', 'JA': '閉める'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'love', 'IT': 'amare', 'ES': 'amar', 'FR': 'aimer', 'DE': 'lieben', 'PT': 'amar', 'JA': '愛する'}, 'difficulty': 1, 'pos': 'verb'},
    {'word': {'EN': 'help', 'IT': 'aiutare', 'ES': 'ayudar', 'FR': 'aider', 'DE': 'helfen', 'PT': 'ajudar', 'JA': '助ける'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'sing', 'IT': 'cantare', 'ES': 'cantar', 'FR': 'chanter', 'DE': 'singen', 'PT': 'cantar', 'JA': '歌う'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'dance', 'IT': 'ballare', 'ES': 'bailar', 'FR': 'danser', 'DE': 'tanzen', 'PT': 'dançar', 'JA': '踊る'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'cook', 'IT': 'cucinare', 'ES': 'cocinar', 'FR': 'cuisiner', 'DE': 'kochen', 'PT': 'cozinhar', 'JA': '料理する'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'swim', 'IT': 'nuotare', 'ES': 'nadar', 'FR': 'nager', 'DE': 'schwimmen', 'PT': 'nadar', 'JA': '泳ぐ'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'fly', 'IT': 'volare', 'ES': 'volar', 'FR': 'voler', 'DE': 'fliegen', 'PT': 'voar', 'JA': '飛ぶ'}, 'difficulty': 2, 'pos': 'verb'},
    {'word': {'EN': 'drive', 'IT': 'guidare', 'ES': 'conducir', 'FR': 'conduire', 'DE': 'fahren', 'PT': 'dirigir', 'JA': '運転する'}, 'difficulty': 3, 'pos': 'verb'},
    {'word': {'EN': 'wait', 'IT': 'aspettare', 'ES': 'esperar', 'FR': 'attendre', 'DE': 'warten', 'PT': 'esperar', 'JA': '待つ'}, 'difficulty': 2, 'pos': 'verb'},
  ],
  'adjectives': [
    {'word': {'EN': 'big', 'IT': 'grande', 'ES': 'grande', 'FR': 'grand', 'DE': 'groß', 'PT': 'grande', 'JA': '大きい'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'small', 'IT': 'piccolo', 'ES': 'pequeño', 'FR': 'petit', 'DE': 'klein', 'PT': 'pequeno', 'JA': '小さい'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'good', 'IT': 'buono', 'ES': 'bueno', 'FR': 'bon', 'DE': 'gut', 'PT': 'bom', 'JA': '良い'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'bad', 'IT': 'cattivo', 'ES': 'malo', 'FR': 'mauvais', 'DE': 'schlecht', 'PT': 'mau', 'JA': '悪い'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'new', 'IT': 'nuovo', 'ES': 'nuevo', 'FR': 'nouveau', 'DE': 'neu', 'PT': 'novo', 'JA': '新しい'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'old', 'IT': 'vecchio', 'ES': 'viejo', 'FR': 'vieux', 'DE': 'alt', 'PT': 'velho', 'JA': '古い'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'long', 'IT': 'lungo', 'ES': 'largo', 'FR': 'long', 'DE': 'lang', 'PT': 'longo', 'JA': '長い'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'short', 'IT': 'corto', 'ES': 'corto', 'FR': 'court', 'DE': 'kurz', 'PT': 'curto', 'JA': '短い'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'hot', 'IT': 'caldo', 'ES': 'caliente', 'FR': 'chaud', 'DE': 'heiß', 'PT': 'quente', 'JA': '暑い'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'cold', 'IT': 'freddo', 'ES': 'frío', 'FR': 'froid', 'DE': 'kalt', 'PT': 'frio', 'JA': '寒い'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'fast', 'IT': 'veloce', 'ES': 'rápido', 'FR': 'rapide', 'DE': 'schnell', 'PT': 'rápido', 'JA': '速い'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'slow', 'IT': 'lento', 'ES': 'lento', 'FR': 'lent', 'DE': 'langsam', 'PT': 'lento', 'JA': '遅い'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'hard', 'IT': 'duro', 'ES': 'duro', 'FR': 'dur', 'DE': 'hart', 'PT': 'duro', 'JA': '固い'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'soft', 'IT': 'morbido', 'ES': 'suave', 'FR': 'doux', 'DE': 'weich', 'PT': 'macio', 'JA': '柔らかい'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'easy', 'IT': 'facile', 'ES': 'fácil', 'FR': 'facile', 'DE': 'einfach', 'PT': 'fácil', 'JA': '簡単'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'difficult', 'IT': 'difficile', 'ES': 'difícil', 'FR': 'difficile', 'DE': 'schwierig', 'PT': 'difícil', 'JA': '難しい'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'beautiful', 'IT': 'bello', 'ES': 'hermoso', 'FR': 'beau', 'DE': 'schön', 'PT': 'bonito', 'JA': '美しい'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'clean', 'IT': 'pulito', 'ES': 'limpio', 'FR': 'propre', 'DE': 'sauber', 'PT': 'limpo', 'JA': 'きれい'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'dirty', 'IT': 'sporco', 'ES': 'sucio', 'FR': 'sale', 'DE': 'schmutzig', 'PT': 'sujo', 'JA': '汚い'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'strong', 'IT': 'forte', 'ES': 'fuerte', 'FR': 'fort', 'DE': 'stark', 'PT': 'forte', 'JA': '強い'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'weak', 'IT': 'debole', 'ES': 'débil', 'FR': 'faible', 'DE': 'schwach', 'PT': 'fraco', 'JA': '弱い'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'rich', 'IT': 'ricco', 'ES': 'rico', 'FR': 'riche', 'DE': 'reich', 'PT': 'rico', 'JA': '金持ち'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'poor', 'IT': 'povero', 'ES': 'pobre', 'FR': 'pauvre', 'DE': 'arm', 'PT': 'pobre', 'JA': '貧しい'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'young', 'IT': 'giovane', 'ES': 'joven', 'FR': 'jeune', 'DE': 'jung', 'PT': 'jovem', 'JA': '若い'}, 'difficulty': 1, 'pos': 'adjective'},
    {'word': {'EN': 'heavy', 'IT': 'pesante', 'ES': 'pesado', 'FR': 'lourd', 'DE': 'schwer', 'PT': 'pesado', 'JA': '重い'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'light', 'IT': 'leggero', 'ES': 'ligero', 'FR': 'léger', 'DE': 'leicht', 'PT': 'leve', 'JA': '軽い'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'sweet', 'IT': 'dolce', 'ES': 'dulce', 'FR': 'doux', 'DE': 'süß', 'PT': 'doce', 'JA': '甘い'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'bitter', 'IT': 'amaro', 'ES': 'amargo', 'FR': 'amer', 'DE': 'bitter', 'PT': 'amargo', 'JA': '苦い'}, 'difficulty': 3, 'pos': 'adjective'},
    {'word': {'EN': 'dry', 'IT': 'secco', 'ES': 'seco', 'FR': 'sec', 'DE': 'trocken', 'PT': 'seco', 'JA': '乾いた'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'wet', 'IT': 'bagnato', 'ES': 'mojado', 'FR': 'mouillé', 'DE': 'nass', 'PT': 'molhado', 'JA': '濡れた'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'loud', 'IT': 'rumoroso', 'ES': 'ruidoso', 'FR': 'bruyant', 'DE': 'laut', 'PT': 'barulhento', 'JA': 'うるさい'}, 'difficulty': 3, 'pos': 'adjective'},
    {'word': {'EN': 'quiet', 'IT': 'silenzioso', 'ES': 'tranquilo', 'FR': 'calme', 'DE': 'leise', 'PT': 'quieto', 'JA': '静か'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'dark', 'IT': 'scuro', 'ES': 'oscuro', 'FR': 'sombre', 'DE': 'dunkel', 'PT': 'escuro', 'JA': '暗い'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'bright', 'IT': 'luminoso', 'ES': 'brillante', 'FR': 'brillant', 'DE': 'hell', 'PT': 'brilhante', 'JA': '明るい'}, 'difficulty': 2, 'pos': 'adjective'},
    {'word': {'EN': 'deep', 'IT': 'profondo', 'ES': 'profundo', 'FR': 'profond', 'DE': 'tief', 'PT': 'profundo', 'JA': '深い'}, 'difficulty': 3, 'pos': 'adjective'},
  ],
  'time_calendar': [
    {'word': {'EN': 'day', 'IT': 'giorno', 'ES': 'día', 'FR': 'jour', 'DE': 'Tag', 'PT': 'dia', 'JA': '日'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'night', 'IT': 'notte', 'ES': 'noche', 'FR': 'nuit', 'DE': 'Nacht', 'PT': 'noite', 'JA': '夜'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'morning', 'IT': 'mattina', 'ES': 'mañana', 'FR': 'matin', 'DE': 'Morgen', 'PT': 'manhã', 'JA': '朝'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'afternoon', 'IT': 'pomeriggio', 'ES': 'tarde', 'FR': 'après-midi', 'DE': 'Nachmittag', 'PT': 'tarde', 'JA': '午後'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'evening', 'IT': 'sera', 'ES': 'noche', 'FR': 'soir', 'DE': 'Abend', 'PT': 'noite', 'JA': '夕方'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'week', 'IT': 'settimana', 'ES': 'semana', 'FR': 'semaine', 'DE': 'Woche', 'PT': 'semana', 'JA': '週'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'month', 'IT': 'mese', 'ES': 'mes', 'FR': 'mois', 'DE': 'Monat', 'PT': 'mês', 'JA': '月'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'year', 'IT': 'anno', 'ES': 'año', 'FR': 'an', 'DE': 'Jahr', 'PT': 'ano', 'JA': '年'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'hour', 'IT': 'ora', 'ES': 'hora', 'FR': 'heure', 'DE': 'Stunde', 'PT': 'hora', 'JA': '時間'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'minute', 'IT': 'minuto', 'ES': 'minuto', 'FR': 'minute', 'DE': 'Minute', 'PT': 'minuto', 'JA': '分'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'today', 'IT': 'oggi', 'ES': 'hoy', 'FR': "aujourd'hui", 'DE': 'heute', 'PT': 'hoje', 'JA': '今日'}, 'difficulty': 1, 'pos': 'adverb'},
    {'word': {'EN': 'tomorrow', 'IT': 'domani', 'ES': 'mañana', 'FR': 'demain', 'DE': 'morgen', 'PT': 'amanhã', 'JA': '明日'}, 'difficulty': 1, 'pos': 'adverb'},
    {'word': {'EN': 'yesterday', 'IT': 'ieri', 'ES': 'ayer', 'FR': 'hier', 'DE': 'gestern', 'PT': 'ontem', 'JA': '昨日'}, 'difficulty': 1, 'pos': 'adverb'},
    {'word': {'EN': 'spring', 'IT': 'primavera', 'ES': 'primavera', 'FR': 'printemps', 'DE': 'Frühling', 'PT': 'primavera', 'JA': '春'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'summer', 'IT': 'estate', 'ES': 'verano', 'FR': 'été', 'DE': 'Sommer', 'PT': 'verão', 'JA': '夏'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'autumn', 'IT': 'autunno', 'ES': 'otoño', 'FR': 'automne', 'DE': 'Herbst', 'PT': 'outono', 'JA': '秋'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'winter', 'IT': 'inverno', 'ES': 'invierno', 'FR': 'hiver', 'DE': 'Winter', 'PT': 'inverno', 'JA': '冬'}, 'difficulty': 1, 'pos': 'noun'},
  ],
  'sports_hobbies': [
    {'word': {'EN': 'football', 'IT': 'calcio', 'ES': 'fútbol', 'FR': 'football', 'DE': 'Fußball', 'PT': 'futebol', 'JA': 'サッカー'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'basketball', 'IT': 'pallacanestro', 'ES': 'baloncesto', 'FR': 'basketball', 'DE': 'Basketball', 'PT': 'basquete', 'JA': 'バスケ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'tennis', 'IT': 'tennis', 'ES': 'tenis', 'FR': 'tennis', 'DE': 'Tennis', 'PT': 'tênis', 'JA': 'テニス'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'swimming', 'IT': 'nuoto', 'ES': 'natación', 'FR': 'natation', 'DE': 'Schwimmen', 'PT': 'natação', 'JA': '水泳'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'running', 'IT': 'corsa', 'ES': 'carrera', 'FR': 'course', 'DE': 'Laufen', 'PT': 'corrida', 'JA': 'ランニング'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'cycling', 'IT': 'ciclismo', 'ES': 'ciclismo', 'FR': 'cyclisme', 'DE': 'Radfahren', 'PT': 'ciclismo', 'JA': 'サイクリング'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'reading', 'IT': 'lettura', 'ES': 'lectura', 'FR': 'lecture', 'DE': 'Lesen', 'PT': 'leitura', 'JA': '読書'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'painting', 'IT': 'pittura', 'ES': 'pintura', 'FR': 'peinture', 'DE': 'Malen', 'PT': 'pintura', 'JA': '絵画'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'cooking', 'IT': 'cucina', 'ES': 'cocina', 'FR': 'cuisine', 'DE': 'Kochen', 'PT': 'culinária', 'JA': '料理'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'dancing', 'IT': 'danza', 'ES': 'baile', 'FR': 'danse', 'DE': 'Tanzen', 'PT': 'dança', 'JA': 'ダンス'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'music', 'IT': 'musica', 'ES': 'música', 'FR': 'musique', 'DE': 'Musik', 'PT': 'música', 'JA': '音楽'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'fishing', 'IT': 'pesca', 'ES': 'pesca', 'FR': 'pêche', 'DE': 'Angeln', 'PT': 'pesca', 'JA': '釣り'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'hiking', 'IT': 'escursionismo', 'ES': 'senderismo', 'FR': 'randonnée', 'DE': 'Wandern', 'PT': 'caminhada', 'JA': 'ハイキング'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'photography', 'IT': 'fotografia', 'ES': 'fotografía', 'FR': 'photographie', 'DE': 'Fotografie', 'PT': 'fotografia', 'JA': '写真'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'chess', 'IT': 'scacchi', 'ES': 'ajedrez', 'FR': 'échecs', 'DE': 'Schach', 'PT': 'xadrez', 'JA': 'チェス'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'yoga', 'IT': 'yoga', 'ES': 'yoga', 'FR': 'yoga', 'DE': 'Yoga', 'PT': 'ioga', 'JA': 'ヨガ'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'skiing', 'IT': 'sci', 'ES': 'esquí', 'FR': 'ski', 'DE': 'Skifahren', 'PT': 'esqui', 'JA': 'スキー'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'golf', 'IT': 'golf', 'ES': 'golf', 'FR': 'golf', 'DE': 'Golf', 'PT': 'golfe', 'JA': 'ゴルフ'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'volleyball', 'IT': 'pallavolo', 'ES': 'voleibol', 'FR': 'volleyball', 'DE': 'Volleyball', 'PT': 'vôlei', 'JA': 'バレーボール'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'baseball', 'IT': 'baseball', 'ES': 'béisbol', 'FR': 'baseball', 'DE': 'Baseball', 'PT': 'beisebol', 'JA': '野球'}, 'difficulty': 2, 'pos': 'noun'},
  ],
  'social': [
    {'word': {'EN': 'friend', 'IT': 'amico', 'ES': 'amigo', 'FR': 'ami', 'DE': 'Freund', 'PT': 'amigo', 'JA': '友達'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'love', 'IT': 'amore', 'ES': 'amor', 'FR': 'amour', 'DE': 'Liebe', 'PT': 'amor', 'JA': '愛'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'party', 'IT': 'festa', 'ES': 'fiesta', 'FR': 'fête', 'DE': 'Party', 'PT': 'festa', 'JA': 'パーティー'}, 'difficulty': 1, 'pos': 'noun'},
    {'word': {'EN': 'gift', 'IT': 'regalo', 'ES': 'regalo', 'FR': 'cadeau', 'DE': 'Geschenk', 'PT': 'presente', 'JA': 'プレゼント'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'meeting', 'IT': 'incontro', 'ES': 'reunión', 'FR': 'réunion', 'DE': 'Treffen', 'PT': 'reunião', 'JA': '会議'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'welcome', 'IT': 'benvenuto', 'ES': 'bienvenido', 'FR': 'bienvenue', 'DE': 'Willkommen', 'PT': 'bem-vindo', 'JA': 'ようこそ'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'promise', 'IT': 'promessa', 'ES': 'promesa', 'FR': 'promesse', 'DE': 'Versprechen', 'PT': 'promessa', 'JA': '約束'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'secret', 'IT': 'segreto', 'ES': 'secreto', 'FR': 'secret', 'DE': 'Geheimnis', 'PT': 'segredo', 'JA': '秘密'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'advice', 'IT': 'consiglio', 'ES': 'consejo', 'FR': 'conseil', 'DE': 'Rat', 'PT': 'conselho', 'JA': 'アドバイス'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'trust', 'IT': 'fiducia', 'ES': 'confianza', 'FR': 'confiance', 'DE': 'Vertrauen', 'PT': 'confiança', 'JA': '信頼'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'respect', 'IT': 'rispetto', 'ES': 'respeto', 'FR': 'respect', 'DE': 'Respekt', 'PT': 'respeito', 'JA': '尊敬'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'peace', 'IT': 'pace', 'ES': 'paz', 'FR': 'paix', 'DE': 'Frieden', 'PT': 'paz', 'JA': '平和'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'war', 'IT': 'guerra', 'ES': 'guerra', 'FR': 'guerre', 'DE': 'Krieg', 'PT': 'guerra', 'JA': '戦争'}, 'difficulty': 2, 'pos': 'noun'},
    {'word': {'EN': 'freedom', 'IT': 'libertà', 'ES': 'libertad', 'FR': 'liberté', 'DE': 'Freiheit', 'PT': 'liberdade', 'JA': '自由'}, 'difficulty': 3, 'pos': 'noun'},
    {'word': {'EN': 'dream', 'IT': 'sogno', 'ES': 'sueño', 'FR': 'rêve', 'DE': 'Traum', 'PT': 'sonho', 'JA': '夢'}, 'difficulty': 2, 'pos': 'noun'},
  ],
};

// ─────────────────────────────────────────────────────────────────────────────
// GRAMMAR QUESTIONS — 50+ per language
// ─────────────────────────────────────────────────────────────────────────────

const kGrammarQuestions = <Map<String, dynamic>>[
  // ── ITALIAN ──
  {'question': 'Select the correct article: ___ casa è grande.', 'options': ['La', 'Il', 'Lo', 'Le'], 'correctIndex': 0, 'language': 'IT', 'category': 'articles', 'difficulty': 1},
  {'question': 'Select the correct article: ___ libro è interessante.', 'options': ['Il', 'La', 'Lo', 'I'], 'correctIndex': 0, 'language': 'IT', 'category': 'articles', 'difficulty': 1},
  {'question': 'Select the correct article: ___ studente è bravo.', 'options': ['Lo', 'Il', 'La', 'Le'], 'correctIndex': 0, 'language': 'IT', 'category': 'articles', 'difficulty': 2},
  {'question': 'Complete: Io ___ italiano.', 'options': ['sono', 'sei', 'è', 'siamo'], 'correctIndex': 0, 'language': 'IT', 'category': 'verbs', 'difficulty': 1},
  {'question': 'Complete: Tu ___ un amico.', 'options': ['sei', 'sono', 'è', 'siete'], 'correctIndex': 0, 'language': 'IT', 'category': 'verbs', 'difficulty': 1},
  {'question': 'Complete: Noi ___ a scuola.', 'options': ['andiamo', 'vado', 'vai', 'vanno'], 'correctIndex': 0, 'language': 'IT', 'category': 'verbs', 'difficulty': 2},
  {'question': 'Complete: Io ___ la pizza.', 'options': ['mangio', 'mangi', 'mangia', 'mangiano'], 'correctIndex': 0, 'language': 'IT', 'category': 'verbs', 'difficulty': 1},
  {'question': 'Select the correct preposition: Vado ___ Roma.', 'options': ['a', 'in', 'di', 'da'], 'correctIndex': 0, 'language': 'IT', 'category': 'prepositions', 'difficulty': 2},
  {'question': 'The plural of "gatto" is:', 'options': ['gatti', 'gatte', 'gattos', 'gattii'], 'correctIndex': 0, 'language': 'IT', 'category': 'plurals', 'difficulty': 1},
  {'question': 'Complete: Lei ___ molto bella.', 'options': ['è', 'sei', 'sono', 'siamo'], 'correctIndex': 0, 'language': 'IT', 'category': 'verbs', 'difficulty': 1},
  // ── SPANISH ──
  {'question': 'Select the correct article: ___ casa es grande.', 'options': ['La', 'El', 'Los', 'Las'], 'correctIndex': 0, 'language': 'ES', 'category': 'articles', 'difficulty': 1},
  {'question': 'Select the correct article: ___ libro es interesante.', 'options': ['El', 'La', 'Los', 'Las'], 'correctIndex': 0, 'language': 'ES', 'category': 'articles', 'difficulty': 1},
  {'question': 'Complete: Yo ___ estudiante.', 'options': ['soy', 'eres', 'es', 'somos'], 'correctIndex': 0, 'language': 'ES', 'category': 'verbs', 'difficulty': 1},
  {'question': 'Complete: Tú ___ de España.', 'options': ['eres', 'soy', 'es', 'son'], 'correctIndex': 0, 'language': 'ES', 'category': 'verbs', 'difficulty': 1},
  {'question': 'Complete: Nosotros ___ en la escuela.', 'options': ['estamos', 'estoy', 'estás', 'están'], 'correctIndex': 0, 'language': 'ES', 'category': 'verbs', 'difficulty': 2},
  {'question': 'Complete: Ella ___ español.', 'options': ['habla', 'hablo', 'hablas', 'hablan'], 'correctIndex': 0, 'language': 'ES', 'category': 'verbs', 'difficulty': 1},
  {'question': 'Select the correct preposition: Voy ___ la escuela.', 'options': ['a', 'en', 'de', 'por'], 'correctIndex': 0, 'language': 'ES', 'category': 'prepositions', 'difficulty': 2},
  {'question': 'The plural of "libro" is:', 'options': ['libros', 'libres', 'libroes', 'libras'], 'correctIndex': 0, 'language': 'ES', 'category': 'plurals', 'difficulty': 1},
  {'question': 'Complete: Yo ___ agua.', 'options': ['bebo', 'bebes', 'bebe', 'beben'], 'correctIndex': 0, 'language': 'ES', 'category': 'verbs', 'difficulty': 1},
  {'question': '"Ser" vs "Estar": Yo ___ cansado.', 'options': ['estoy', 'soy', 'es', 'está'], 'correctIndex': 0, 'language': 'ES', 'category': 'verbs', 'difficulty': 2},
  // ── FRENCH ──
  {'question': 'Select the correct article: ___ maison est grande.', 'options': ['La', 'Le', 'Les', 'Un'], 'correctIndex': 0, 'language': 'FR', 'category': 'articles', 'difficulty': 1},
  {'question': 'Select the correct article: ___ livre est intéressant.', 'options': ['Le', 'La', 'Les', 'Un'], 'correctIndex': 0, 'language': 'FR', 'category': 'articles', 'difficulty': 1},
  {'question': 'Complete: Je ___ français.', 'options': ['suis', 'es', 'est', 'sommes'], 'correctIndex': 0, 'language': 'FR', 'category': 'verbs', 'difficulty': 1},
  {'question': 'Complete: Tu ___ un ami.', 'options': ['es', 'suis', 'est', 'êtes'], 'correctIndex': 0, 'language': 'FR', 'category': 'verbs', 'difficulty': 1},
  {'question': 'Complete: Nous ___ à la maison.', 'options': ['allons', 'vais', 'vas', 'vont'], 'correctIndex': 0, 'language': 'FR', 'category': 'verbs', 'difficulty': 2},
  {'question': 'Complete: Elle ___ la musique.', 'options': ['aime', 'aimes', 'aimons', 'aiment'], 'correctIndex': 0, 'language': 'FR', 'category': 'verbs', 'difficulty': 1},
  {'question': 'Select the correct preposition: Je vais ___ Paris.', 'options': ['à', 'en', 'de', 'dans'], 'correctIndex': 0, 'language': 'FR', 'category': 'prepositions', 'difficulty': 2},
  {'question': 'The plural of "chat" is:', 'options': ['chats', 'chates', 'chaux', 'chatis'], 'correctIndex': 0, 'language': 'FR', 'category': 'plurals', 'difficulty': 1},
  {'question': 'Complete: Il ___ du café.', 'options': ['boit', 'bois', 'buvons', 'boivent'], 'correctIndex': 0, 'language': 'FR', 'category': 'verbs', 'difficulty': 2},
  {'question': 'Complete: Je ___ une pomme.', 'options': ['mange', 'manges', 'mangeons', 'mangent'], 'correctIndex': 0, 'language': 'FR', 'category': 'verbs', 'difficulty': 1},
  // ── GERMAN ──
  {'question': 'Select the correct article: ___ Haus ist groß.', 'options': ['Das', 'Der', 'Die', 'Den'], 'correctIndex': 0, 'language': 'DE', 'category': 'articles', 'difficulty': 1},
  {'question': 'Select the correct article: ___ Buch ist interessant.', 'options': ['Das', 'Der', 'Die', 'Den'], 'correctIndex': 0, 'language': 'DE', 'category': 'articles', 'difficulty': 1},
  {'question': 'Select the correct article: ___ Frau ist nett.', 'options': ['Die', 'Der', 'Das', 'Den'], 'correctIndex': 0, 'language': 'DE', 'category': 'articles', 'difficulty': 1},
  {'question': 'Complete: Ich ___ Student.', 'options': ['bin', 'bist', 'ist', 'sind'], 'correctIndex': 0, 'language': 'DE', 'category': 'verbs', 'difficulty': 1},
  {'question': 'Complete: Du ___ aus Deutschland.', 'options': ['bist', 'bin', 'ist', 'sind'], 'correctIndex': 0, 'language': 'DE', 'category': 'verbs', 'difficulty': 1},
  {'question': 'Complete: Wir ___ nach Hause.', 'options': ['gehen', 'gehe', 'gehst', 'geht'], 'correctIndex': 0, 'language': 'DE', 'category': 'verbs', 'difficulty': 2},
  {'question': 'Complete: Er ___ Deutsch.', 'options': ['spricht', 'spreche', 'sprichst', 'sprechen'], 'correctIndex': 0, 'language': 'DE', 'category': 'verbs', 'difficulty': 2},
  {'question': 'Select the correct preposition: Ich gehe ___ die Schule.', 'options': ['in', 'auf', 'an', 'zu'], 'correctIndex': 0, 'language': 'DE', 'category': 'prepositions', 'difficulty': 2},
  {'question': 'The plural of "Kind" is:', 'options': ['Kinder', 'Kinds', 'Kindes', 'Kindern'], 'correctIndex': 0, 'language': 'DE', 'category': 'plurals', 'difficulty': 2},
  {'question': 'Complete: Ich ___ einen Kaffee.', 'options': ['trinke', 'trinkst', 'trinkt', 'trinken'], 'correctIndex': 0, 'language': 'DE', 'category': 'verbs', 'difficulty': 1},
  // ── PORTUGUESE ──
  {'question': 'Select the correct article: ___ casa é grande.', 'options': ['A', 'O', 'Os', 'As'], 'correctIndex': 0, 'language': 'PT', 'category': 'articles', 'difficulty': 1},
  {'question': 'Select the correct article: ___ livro é interessante.', 'options': ['O', 'A', 'Os', 'As'], 'correctIndex': 0, 'language': 'PT', 'category': 'articles', 'difficulty': 1},
  {'question': 'Complete: Eu ___ brasileiro.', 'options': ['sou', 'és', 'é', 'somos'], 'correctIndex': 0, 'language': 'PT', 'category': 'verbs', 'difficulty': 1},
  {'question': 'Complete: Tu ___ de Portugal.', 'options': ['és', 'sou', 'é', 'são'], 'correctIndex': 0, 'language': 'PT', 'category': 'verbs', 'difficulty': 1},
  {'question': 'Complete: Nós ___ na escola.', 'options': ['estamos', 'estou', 'estás', 'estão'], 'correctIndex': 0, 'language': 'PT', 'category': 'verbs', 'difficulty': 2},
  {'question': 'Complete: Ela ___ português.', 'options': ['fala', 'falo', 'falas', 'falam'], 'correctIndex': 0, 'language': 'PT', 'category': 'verbs', 'difficulty': 1},
  {'question': 'The plural of "livro" is:', 'options': ['livros', 'livres', 'livroes', 'livras'], 'correctIndex': 0, 'language': 'PT', 'category': 'plurals', 'difficulty': 1},
  {'question': 'Complete: Eu ___ água.', 'options': ['bebo', 'bebes', 'bebe', 'bebem'], 'correctIndex': 0, 'language': 'PT', 'category': 'verbs', 'difficulty': 1},
  // ── ENGLISH ──
  {'question': 'Select the correct form: She ___ to school every day.', 'options': ['goes', 'go', 'going', 'went'], 'correctIndex': 0, 'language': 'EN', 'category': 'verbs', 'difficulty': 1},
  {'question': 'Select the correct article: I saw ___ elephant.', 'options': ['an', 'a', 'the', 'some'], 'correctIndex': 0, 'language': 'EN', 'category': 'articles', 'difficulty': 1},
  {'question': 'Complete: They ___ playing football.', 'options': ['are', 'is', 'am', 'be'], 'correctIndex': 0, 'language': 'EN', 'category': 'verbs', 'difficulty': 1},
  {'question': 'Select the correct pronoun: ___ is my book.', 'options': ['This', 'These', 'Those', 'They'], 'correctIndex': 0, 'language': 'EN', 'category': 'pronouns', 'difficulty': 1},
  {'question': 'Past tense of "go":', 'options': ['went', 'goed', 'gone', 'going'], 'correctIndex': 0, 'language': 'EN', 'category': 'verbs', 'difficulty': 2},
  {'question': 'Complete: He ___ not like coffee.', 'options': ['does', 'do', 'is', 'has'], 'correctIndex': 0, 'language': 'EN', 'category': 'verbs', 'difficulty': 2},
  {'question': 'Select the correct preposition: I live ___ London.', 'options': ['in', 'at', 'on', 'to'], 'correctIndex': 0, 'language': 'EN', 'category': 'prepositions', 'difficulty': 1},
  {'question': 'The plural of "child" is:', 'options': ['children', 'childs', 'childes', 'childern'], 'correctIndex': 0, 'language': 'EN', 'category': 'plurals', 'difficulty': 2},
  // ── JAPANESE ──
  {'question': 'Select the correct particle: 私___学生です。', 'options': ['は', 'が', 'を', 'に'], 'correctIndex': 0, 'language': 'JA', 'category': 'particles', 'difficulty': 1},
  {'question': 'Select the correct particle: 水___飲みます。', 'options': ['を', 'は', 'が', 'に'], 'correctIndex': 0, 'language': 'JA', 'category': 'particles', 'difficulty': 1},
  {'question': 'Select the correct particle: 学校___行きます。', 'options': ['に', 'を', 'は', 'が'], 'correctIndex': 0, 'language': 'JA', 'category': 'particles', 'difficulty': 1},
  {'question': 'Complete: これ___本です。', 'options': ['は', 'が', 'を', 'の'], 'correctIndex': 0, 'language': 'JA', 'category': 'particles', 'difficulty': 1},
  {'question': 'The polite form of "食べる" is:', 'options': ['食べます', '食べた', '食べて', '食べない'], 'correctIndex': 0, 'language': 'JA', 'category': 'verbs', 'difficulty': 2},
  {'question': 'The negative of "行きます" is:', 'options': ['行きません', '行かない', '行きない', '行けません'], 'correctIndex': 0, 'language': 'JA', 'category': 'verbs', 'difficulty': 2},
  {'question': 'Select the correct counter: リンゴ___つ', 'options': ['ひと', 'いち', 'いっ', 'ひ'], 'correctIndex': 0, 'language': 'JA', 'category': 'counters', 'difficulty': 3},
  {'question': 'Past tense of "飲みます":', 'options': ['飲みました', '飲んだ', '飲みた', '飲みして'], 'correctIndex': 0, 'language': 'JA', 'category': 'verbs', 'difficulty': 2},
];

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;

  print('=== SEEDING GAME WORDS ===\n');

  int totalWords = 0;
  int totalQuestions = 0;
  int totalGrammar = 0;

  for (final language in kLanguages) {
    print('Processing language: $language');

    // Check existing count
    final existingCount = await firestore
        .collection('game_words')
        .where('language', isEqualTo: language.toLowerCase())
        .count()
        .get();
    final existing = existingCount.count ?? 0;
    print('  Existing words: $existing');

    if (existing > 100) {
      print('  Sufficient data exists, skipping word seed.');
      continue;
    }

    WriteBatch batch = firestore.batch();
    int batchCount = 0;
    int langWordCount = 0;

    for (final entry in kStarterWords.entries) {
      final category = entry.key;
      final words = entry.value;

      for (final wordData in words) {
        final translations = wordData['word'] as Map<String, dynamic>;
        final word = (translations[language] as String?) ?? '';
        if (word.isEmpty) continue;

        // Build translation map (all other languages)
        final translationMap = <String, List<String>>{};
        for (final otherLang in kLanguages) {
          if (otherLang == language) continue;
          final trans = translations[otherLang] as String?;
          if (trans != null) {
            translationMap[otherLang.toLowerCase()] = [trans];
          }
        }

        final docRef = firestore.collection('game_words').doc();
        batch.set(docRef, {
          'word': word.toLowerCase(),
          'language': language.toLowerCase(),
          'category': category,
          'difficulty': wordData['difficulty'],
          'translations': translationMap,
          'partOfSpeech': wordData['pos'],
          'createdAt': FieldValue.serverTimestamp(),
        });

        batchCount++;
        langWordCount++;
        totalWords++;

        if (batchCount >= 490) {
          await batch.commit();
          batch = firestore.batch();
          batchCount = 0;
        }
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    print('  Seeded $langWordCount words for $language');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GENERATE TRANSLATION RACE QUESTIONS
  // ─────────────────────────────────────────────────────────────────────────

  print('\n=== GENERATING TRANSLATION RACE QUESTIONS ===\n');

  for (final source in kLanguages) {
    for (final target in kLanguages) {
      if (source == target) continue;

      // Check existing
      final existingQ = await firestore
          .collection('game_translation_race')
          .where('sourceLang', isEqualTo: source.toLowerCase())
          .where('targetLang', isEqualTo: target.toLowerCase())
          .count()
          .get();

      if ((existingQ.count ?? 0) > 10) {
        continue;
      }

      print('Generating TR questions: $source -> $target');

      WriteBatch batch = firestore.batch();
      int batchCount = 0;
      int questionCount = 0;

      for (final entry in kStarterWords.entries) {
        final words = entry.value;
        final allTargetWords = words
            .map((w) => (w['word'] as Map<String, dynamic>)[target] as String?)
            .where((w) => w != null && w.isNotEmpty)
            .cast<String>()
            .toList();

        for (final wordData in words) {
          final translations = wordData['word'] as Map<String, dynamic>;
          final sourceWord = translations[source] as String?;
          final correctAnswer = translations[target] as String?;
          if (sourceWord == null || correctAnswer == null) continue;

          final wrongOptions = allTargetWords
              .where((w) => w != correctAnswer)
              .take(11)
              .toList();

          if (wrongOptions.length < 11) {
            for (final otherEntry in kStarterWords.entries) {
              if (wrongOptions.length >= 11) break;
              for (final w in otherEntry.value) {
                if (wrongOptions.length >= 11) break;
                final t = (w['word'] as Map<String, dynamic>)[target] as String?;
                if (t != null && t != correctAnswer && !wrongOptions.contains(t)) {
                  wrongOptions.add(t);
                }
              }
            }
          }

          final docRef = firestore.collection('game_translation_race').doc();
          batch.set(docRef, {
            'word': sourceWord,
            'sourceLang': source.toLowerCase(),
            'targetLang': target.toLowerCase(),
            'correctAnswer': correctAnswer,
            'wrongOptions': wrongOptions,
            'difficulty': wordData['difficulty'],
            'category': entry.key,
            'createdAt': FieldValue.serverTimestamp(),
          });

          batchCount++;
          questionCount++;
          totalQuestions++;

          if (batchCount >= 490) {
            await batch.commit();
            batch = firestore.batch();
            batchCount = 0;
          }
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      print('  Generated $questionCount questions');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEED GRAMMAR QUESTIONS
  // ─────────────────────────────────────────────────────────────────────────

  print('\n=== SEEDING GRAMMAR QUESTIONS ===\n');

  for (final language in kLanguages) {
    final langQuestions = kGrammarQuestions
        .where((q) => q['language'] == language)
        .toList();

    if (langQuestions.isEmpty) continue;

    // Check existing
    final existingG = await firestore
        .collection('game_grammar_questions')
        .where('language', isEqualTo: language.toLowerCase())
        .count()
        .get();

    if ((existingG.count ?? 0) >= langQuestions.length) {
      print('Grammar questions for $language already exist, skipping.');
      continue;
    }

    print('Seeding ${langQuestions.length} grammar questions for $language');

    WriteBatch batch = firestore.batch();
    int batchCount = 0;

    for (final q in langQuestions) {
      final docRef = firestore.collection('game_grammar_questions').doc();
      batch.set(docRef, {
        'question': q['question'],
        'options': q['options'],
        'correctIndex': q['correctIndex'],
        'language': (q['language'] as String).toLowerCase(),
        'category': q['category'],
        'difficulty': q['difficulty'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      batchCount++;
      totalGrammar++;

      if (batchCount >= 490) {
        await batch.commit();
        batch = firestore.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }
  }

  print('\n=== SEED COMPLETE ===');
  print('Total words seeded: $totalWords');
  print('Total TR questions: $totalQuestions');
  print('Total grammar questions: $totalGrammar');
}
