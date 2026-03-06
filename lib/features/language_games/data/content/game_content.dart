import 'dart:math';

// ============================================================
// DATA CLASSES
// ============================================================

/// Card pair for Language Snaps game
class SnapCard {
  final String english;
  final String translation;
  final int difficulty;

  const SnapCard({
    required this.english,
    required this.translation,
    required this.difficulty,
  });
}

/// Category for Language Tapples game
class TapplesCategory {
  final String name;
  final String icon;
  final Map<String, List<String>> wordsPerLetter;

  const TapplesCategory({
    required this.name,
    required this.icon,
    required this.wordsPerLetter,
  });
}

/// Grammar question data class
class GrammarQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String category;
  final int difficulty;

  const GrammarQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.category,
    this.difficulty = 1,
  });

  String get correctAnswer => options[correctIndex];
}

// ============================================================
// MAIN GAME CONTENT CLASS
// ============================================================

/// Static game content for all mini-games
/// Contains word lists, translation pairs, grammar questions, vocabulary categories,
/// snap cards, and tapples categories for 7 languages across 10 difficulty levels.
///
/// Supported languages: en, es, fr, de, it, pt, pt-BR
class GameContent {
  GameContent._();

  static final _random = Random();

  // ============================================================
  // SUPPORTED LANGUAGES
  // ============================================================

  static const List<String> supportedLanguages = [
    'en', 'es', 'fr', 'de', 'it', 'pt', 'pt-BR',
  ];

  static const Map<String, String> languageNames = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'pt-BR': 'Portuguese (Brazilian)',
  };

  // ============================================================
  // DIFFICULTY LABELS
  // ============================================================

  static String getDifficultyLabel(int level) {
    switch (level) {
      case 1: return 'Beginner';
      case 2: return 'Elementary';
      case 3: return 'Pre-Intermediate';
      case 4: return 'Intermediate';
      case 5: return 'Upper-Intermediate';
      case 6: return 'Advanced';
      case 7: return 'Proficient';
      case 8: return 'Expert';
      case 9: return 'Master';
      case 10: return 'Native';
      default: return 'Unknown';
    }
  }

  // ============================================================
  // WORD BOMB - Word lists per language (100+ words each)
  // Levels 1-2: common everyday words
  // Levels 3-4: intermediate vocabulary
  // Levels 5-6: advanced vocabulary
  // Levels 7-10: complex/rare words
  // ============================================================

  static const Map<String, List<String>> wordBombWords = {
    'en': [
      // Common everyday (L1-2)
      'hello', 'house', 'water', 'family', 'friend', 'mother', 'father', 'brother', 'sister', 'school',
      'teacher', 'student', 'morning', 'evening', 'night', 'today', 'tomorrow', 'yesterday', 'always', 'never',
      'happy', 'angry', 'hungry', 'thirsty', 'tired', 'beautiful', 'small', 'large', 'color', 'animal',
      'garden', 'kitchen', 'bedroom', 'window', 'table', 'chair', 'bread', 'butter', 'cheese', 'apple',
      // Intermediate (L3-4)
      'adventure', 'believe', 'celebrate', 'different', 'education', 'favorite', 'generous', 'hospital',
      'imagine', 'journey', 'knowledge', 'language', 'mountain', 'neighbor', 'opinion', 'possible',
      'question', 'remember', 'surprise', 'together', 'umbrella', 'vacation', 'wonderful', 'anxiety',
      // Advanced (L5-6)
      'accomplish', 'bureaucracy', 'comprehensive', 'demonstrate', 'entrepreneur', 'phenomenon',
      'infrastructure', 'jurisdiction', 'philanthropy', 'sustainability', 'revolutionary', 'contemporary',
      'sophisticated', 'preliminary', 'unprecedented', 'circumstance', 'accommodate', 'acknowledge',
      // Complex (L7-10)
      'serendipity', 'quintessential', 'ephemeral', 'ubiquitous', 'juxtaposition', 'onomatopoeia',
      'idiosyncrasy', 'sycophant', 'perspicacious', 'magnanimous', 'obsequious', 'verisimilitude',
      'antediluvian', 'sesquipedalian', 'pulchritudinous', 'defenestration', 'loquacious', 'pusillanimous',
      'supercilious', 'phantasmagoria', 'discombobulate', 'flabbergasted', 'gobbledygook', 'kerfuffle',
    ],
    'es': [
      // Common everyday (L1-2)
      'abandonar', 'abeja', 'abierto', 'abogado', 'abrazar', 'abrir', 'abuelo', 'acabar', 'aceite', 'aceptar',
      'acercar', 'acostumbrar', 'actitud', 'actividad', 'actuar', 'acuerdo', 'adelante', 'adentro', 'adios',
      'admirar', 'adorar', 'aeropuerto', 'afuera', 'agradable', 'agradecer', 'agricultura', 'agua', 'aguantar',
      'ahora', 'aire', 'alegre', 'alejar', 'algo', 'alguien', 'alguno', 'alma', 'almorzar',
      'alto', 'alumno', 'amable', 'amanecer', 'amar', 'amarillo', 'ambiente', 'amigo', 'amor', 'amplio',
      'animal', 'anoche', 'anterior', 'antes', 'antiguo', 'anunciar', 'aparecer', 'apenas', 'aprender',
      'aquel', 'arbol', 'arena', 'arriba', 'arte', 'asegurar', 'asistir', 'atender', 'atras', 'aumentar',
      'aunque', 'avanzar', 'ayer', 'ayudar', 'azul', 'bailar', 'bajar', 'bajo', 'banco', 'barco',
      'bastante', 'beber', 'bello', 'besar', 'bien', 'blanco', 'boca', 'bolsa', 'bonito', 'bosque',
      'brazo', 'bueno', 'buscar', 'caballo', 'cabeza', 'cada', 'caer', 'cafe', 'calidad', 'calle',
      // Intermediate (L3-4)
      'calor', 'cama', 'cambiar', 'caminar', 'camino', 'campo', 'cancion', 'cansado', 'capacidad', 'capital',
      'cara', 'caracter', 'carne', 'carta', 'casa', 'casi', 'causa', 'celebrar', 'centro', 'cerca',
      'cerrar', 'cielo', 'ciencia', 'cierto', 'cinco', 'ciudad', 'claro', 'clase', 'clima', 'cobrar',
      'cocina', 'coger', 'colocar', 'color', 'comer', 'comida', 'compañero', 'completar', 'comprar',
      'comunicar', 'comunidad', 'conciencia', 'conducir', 'conocer', 'conseguir', 'consejo', 'construir',
      // Advanced (L5-6)
      'contar', 'contento', 'contestar', 'continuar', 'contra', 'control', 'copa', 'corazon', 'correr',
      'cortar', 'cosa', 'costar', 'costumbre', 'crear', 'crecer', 'creer', 'cruzar', 'cuerpo',
      'cuidar', 'cultura', 'cumplir', 'debajo', 'deber', 'decidir', 'decir', 'defender', 'dejar',
      'democracia', 'desarrollo', 'desigualdad', 'estrategia', 'infraestructura', 'jurisprudencia',
      // Complex (L7-10)
      'ensimismamiento', 'desapercibimiento', 'inconmensurable', 'imprescindible', 'desafortunadamente',
      'extraordinariamente', 'contemporaneidad', 'bienintencionado', 'circunstancialmente', 'desproporcionado',
    ],
    'fr': [
      // Common everyday (L1-2)
      'abandonner', 'abeille', 'absence', 'accepter', 'accord', 'acheter', 'action', 'adieu', 'admirer', 'adorer',
      'adulte', 'affaire', 'affirmer', 'agir', 'aider', 'aile', 'aimer',
      'air', 'ajouter', 'aller', 'allumer', 'alors', 'ami', 'amour', 'amuser', 'ancien', 'animal',
      'annoncer', 'apercevoir', 'appeler', 'apporter', 'apprendre', 'approcher', 'arbre',
      'argent', 'arme', 'arrêter', 'arriver', 'art', 'assez', 'asseoir', 'assurer', 'attaquer',
      'attendre', 'attention', 'attraper', 'aucun', 'aussi', 'autant', 'automne', 'autoriser', 'autour',
      'autre', 'avancer', 'avant', 'avenir', 'aventure', 'avoir', 'avouer', 'baiser', 'baisser', 'balancer',
      'banque', 'bas', 'bataille', 'battre', 'beau', 'beaucoup', 'besoin', 'bien', 'blanc',
      'blesser', 'bleu', 'boire', 'bois', 'bon', 'bonheur', 'bord', 'bouche', 'bouger', 'bout',
      'bras', 'briller', 'briser', 'bruit', 'bureau', 'but', 'cacher', 'calme', 'campagne',
      // Intermediate (L3-4)
      'capable', 'caractère', 'cause', 'centre', 'certain', 'chaise', 'chambre', 'champ', 'chance',
      'changement', 'changer', 'chanson', 'chanter', 'chaque', 'charger', 'chasser', 'chat', 'chaud', 'chemin',
      'chercher', 'cheval', 'cheveux', 'chez', 'chien', 'chiffre', 'choisir', 'chose', 'ciel', 'cinq',
      'classe', 'coeur', 'coin', 'combat', 'combien', 'commander', 'commencer',
      'comment', 'compagnie', 'complet', 'comprendre', 'compter', 'conduire', 'confiance', 'conseil',
      // Advanced (L5-6)
      'construire', 'contenir', 'content', 'continuer', 'contre', 'convaincre', 'corps', 'coucher',
      'couleur', 'coup', 'couper', 'courage', 'courir', 'cours', 'court', 'couvrir', 'craindre',
      'gouvernement', 'infrastructure', 'jurisprudence', 'philosophie', 'bureaucratie', 'democratie',
      // Complex (L7-10)
      'anticonstitutionnellement', 'invraisemblablement', 'perpendiculairement', 'extraordinairement',
      'contradictoire', 'approfondissement', 'désapprovisionnement', 'incompréhensible', 'incontournable',
      'désenchantement', 'épanouissement', 'rapprochement', 'éblouissement', 'bouleversement',
    ],
    'de': [
      // Common everyday (L1-2)
      'Abend', 'aber', 'allein', 'alles', 'also', 'alt', 'andere', 'anfangen',
      'Angst', 'Antwort', 'Apfel', 'Arbeit', 'arbeiten', 'Arm', 'Art', 'Arzt', 'auch', 'Auge',
      'Augenblick', 'aus', 'Ausgang', 'Auto', 'Bad', 'bald', 'Ball',
      'Bank', 'Baum', 'bedeuten', 'beginnen', 'bei', 'beide', 'Bein', 'Beispiel', 'bekannt',
      'bekommen', 'bemerken', 'benutzen', 'Berg', 'Beruf', 'besonders', 'besser', 'beste', 'bestimmt',
      'Besuch', 'besuchen', 'Bett', 'bevor', 'Bild', 'billig', 'bis', 'bitte', 'Blatt', 'blau',
      'bleiben', 'Blick', 'Blume', 'Blut', 'Boden', 'brauchen', 'breit', 'brennen', 'Brief', 'bringen',
      'Brot', 'Bruder', 'Brust', 'Buch', 'Butter', 'Chef', 'Dach',
      'Dame', 'damit', 'danach', 'Dank', 'dann',
      'dass', 'dauern', 'Decke',
      // Intermediate (L3-4)
      'dein', 'denken', 'denn', 'dennoch', 'deshalb', 'deutsch', 'dicht', 'dick', 'Dienst',
      'dieser', 'Ding', 'doch', 'Dorf', 'dort', 'drehen', 'drei', 'dumm', 'dunkel', 'durch',
      'eben', 'ebenso', 'Ecke', 'Ehre', 'eigen', 'eigentlich', 'einander', 'einfach', 'Eingang', 'einige',
      'einzig', 'Eis', 'Eltern', 'empfangen', 'Ende', 'endlich', 'Erde', 'Erfolg', 'erhalten', 'erkennen',
      'erlauben', 'ernst', 'erreichen', 'erst', 'erwarten', 'essen', 'etwa', 'etwas',
      'fahren', 'Fall', 'fallen', 'falsch', 'Familie', 'fangen', 'Farbe', 'fassen', 'fast',
      // Advanced (L5-6)
      'fehlen', 'Fehler', 'Feld', 'Fenster', 'Ferien', 'fern', 'fest', 'Feuer', 'finden', 'Finger',
      'fliegen', 'Flug', 'Flugzeug', 'Fluss', 'folgen', 'fordern', 'Frage', 'fragen', 'Frau', 'frei',
      'Freiheit', 'fremd', 'Freude', 'freuen', 'Freund', 'Frieden', 'frisch', 'froh',
      'Gesellschaft', 'Wissenschaft', 'Regierung', 'Wirtschaft', 'Philosophie', 'Demokratie',
      // Complex (L7-10)
      'Geschwindigkeitsbegrenzung', 'Unabhängigkeitserklärung', 'Rechtsschutzversicherungsgesellschaften',
      'Streichholzschächtelchen', 'Bezirksschornsteinfegermeister', 'Freundschaftsbeziehung',
      'Nahrungsmittelunverträglichkeit', 'Arbeitsunfähigkeitsbescheinigung', 'Handschuhschneeballwerfer',
      'Rindfleischetikettierungsüberwachungsaufgabenübertragungsgesetz',
    ],
    'it': [
      // Common everyday (L1-2)
      'abbandonare', 'abbastanza', 'abitare', 'abitudine', 'accadere', 'accanto', 'accendere', 'accettare', 'accompagnare', 'accordo',
      'acqua', 'adesso', 'aereo', 'affare', 'affatto', 'aggiungere', 'aiutare', 'aiuto', 'albero', 'allora',
      'almeno', 'alto', 'altro', 'alzare', 'amare', 'amico', 'amore', 'anche', 'ancora', 'andare',
      'anima', 'anno', 'appena', 'aprire', 'aria', 'arrivare', 'arte', 'ascoltare', 'aspettare', 'assai',
      'attaccare', 'attenzione', 'attorno', 'attraverso', 'attuale', 'avanti', 'avere', 'avvenire', 'azione',
      'azzurro', 'baciare', 'bambino', 'basso', 'bastare', 'battere', 'bello', 'bene', 'benissimo', 'bere',
      'bianco', 'bisogno', 'bocca', 'braccio', 'bravo', 'breve', 'buono', 'cadere', 'caldo', 'cambiare',
      'camminare', 'campagna', 'campo', 'cantare', 'capace', 'capello', 'capire', 'capo', 'caro', 'casa',
      'caso', 'cattivo', 'causa', 'centro', 'cercare', 'certo', 'chiamare', 'chiaro', 'chiedere',
      'chiudere', 'cielo', 'cinque', 'classe', 'cogliere', 'colore', 'colpa', 'colpire',
      // Intermediate (L3-4)
      'cominciare', 'compagno', 'compiere', 'comprendere', 'comune', 'condurre', 'conoscere', 'consiglio', 'contare',
      'contento', 'conto', 'contro', 'corpo', 'correre', 'corte', 'cosa', 'costare', 'costruire',
      'credere', 'crescere', 'cuore', 'cura', 'dare', 'davanti', 'davvero', 'dentro', 'desiderare', 'destra',
      'destro', 'detto', 'dieci', 'dietro', 'difficile', 'dimenticare', 'dire', 'diritto', 'discorso',
      'diventare', 'diverso', 'dolce', 'dolore', 'domanda', 'domani', 'donna', 'dopo', 'dormire', 'dove',
      // Advanced (L5-6)
      'dovere', 'due', 'dunque', 'durante', 'duro', 'eccellente', 'ecco', 'entrare', 'errore', 'esattamente',
      'esempio', 'esistere', 'esperienza', 'essere', 'estate', 'europeo', 'evitare', 'faccia', 'facile',
      'famiglia', 'famoso', 'fare', 'fatica', 'fatto', 'favore', 'felice', 'fermare', 'ferro', 'festa',
      'governo', 'democrazia', 'filosofia', 'infrastruttura', 'giurisprudenza', 'economia',
      // Complex (L7-10)
      'precipitevolissimevolmente', 'incontrovertibilmente', 'approfondimento', 'conversazione',
      'contraddistinguere', 'compartecipazione', 'trascendentale', 'sopravvalutazione',
      'familiarizzazione', 'consapevolmente', 'imperturbabilmente', 'sproporzionatamente',
    ],
    'pt': [
      // Common everyday (L1-2)
      'abandonar', 'aberto', 'abraçar', 'abrir', 'acabar', 'aceitar', 'achar', 'acontecer', 'acordar', 'acreditar',
      'agora', 'água', 'ainda', 'ajudar', 'alegre', 'além', 'algo', 'alguém', 'algum', 'alto',
      'aluno', 'amar', 'amigo', 'amor', 'andar', 'animal', 'ano', 'antes', 'aprender', 'apresentar',
      'aquele', 'aqui', 'árvore', 'assim', 'até', 'atender', 'atenção', 'avançar', 'baixo', 'banco',
      'barco', 'bastante', 'beber', 'belo', 'bem', 'bonito', 'bom', 'branco', 'braço', 'buscar',
      'cabeça', 'cada', 'cair', 'calor', 'cama', 'caminho', 'campo', 'canção', 'cansado', 'capaz',
      'cara', 'carne', 'carta', 'casa', 'caso', 'causa', 'centro', 'céu', 'chão', 'chamar',
      'chegar', 'cidade', 'claro', 'coisa', 'colocar', 'começar', 'comer', 'comida',
      'companheiro', 'completar', 'comprar', 'compreender', 'conhecer', 'conseguir', 'conselho', 'contar', 'contente', 'continuar',
      'contra', 'coração', 'corpo', 'correr', 'cortar', 'costa', 'costume', 'criar', 'crescer',
      // Intermediate (L3-4)
      'criança', 'cruzar', 'cuidar', 'cultura', 'curto', 'dar', 'debaixo', 'decidir', 'deixar', 'dentro',
      'depois', 'descansar', 'desculpar', 'desde', 'desejo', 'despertar', 'dever', 'devolver', 'dia', 'diferente',
      'difícil', 'dinheiro', 'direito', 'dizer', 'doce', 'doença', 'doer', 'domingo', 'dormir', 'duro',
      'durante', 'empresa', 'encontrar', 'ensinar', 'entender', 'então', 'entrada', 'entrar', 'entregar', 'enviar',
      'equipa', 'erro', 'escola', 'escrever', 'escutar', 'esforço', 'espaço', 'esperar', 'estado',
      // Advanced (L5-6)
      'estar', 'estrela', 'estudante', 'estudar', 'evitar', 'exemplo', 'exercício', 'existir', 'experiência', 'explicar',
      'falar', 'faltar', 'família', 'favor', 'fazer', 'feliz', 'fechar', 'festa', 'filho', 'fim',
      'governo', 'democracia', 'filosofia', 'infraestrutura', 'jurisprudência', 'economia',
      // Complex (L7-10)
      'inconstitucionalissimamente', 'desproporcionadamente', 'incompreensivelmente', 'extraordinariamente',
      'desconcertantemente', 'imprescindibilidade', 'circunstancialmente', 'contemporaneidade',
      'autocomiseração', 'desapercebidamente', 'incontornavelmente', 'aprofundamento',
    ],
    'pt-BR': [
      // Common everyday (L1-2) — Brazilian Portuguese differences
      'abandonar', 'aberto', 'abraçar', 'abrir', 'acabar', 'aceitar', 'achar', 'acontecer', 'acordar', 'acreditar',
      'agora', 'água', 'ainda', 'ajudar', 'alegre', 'além', 'algo', 'alguém', 'algum', 'alto',
      'aluno', 'amar', 'amigo', 'amor', 'andar', 'animal', 'ano', 'antes', 'aprender', 'apresentar',
      'aquele', 'aqui', 'árvore', 'assim', 'até', 'atender', 'atenção', 'avançar', 'baixo', 'banco',
      'barco', 'bastante', 'beber', 'belo', 'bem', 'bonito', 'bom', 'branco', 'braço', 'buscar',
      'cabeça', 'cada', 'cair', 'calor', 'cama', 'caminho', 'campo', 'canção', 'cansado', 'capaz',
      'cara', 'carne', 'carta', 'casa', 'caso', 'causa', 'centro', 'céu', 'chão', 'chamar',
      'chegar', 'cidade', 'claro', 'coisa', 'colocar', 'começar', 'comer', 'comida',
      'companheiro', 'completar', 'comprar', 'compreender', 'conhecer', 'conseguir', 'conselho', 'contar', 'contente', 'continuar',
      'contra', 'coração', 'corpo', 'correr', 'cortar', 'costa', 'costume', 'criar', 'crescer',
      // Intermediate (L3-4) — BR-specific words
      'criança', 'cruzar', 'cuidar', 'cultura', 'curto', 'dar', 'debaixo', 'decidir', 'deixar', 'dentro',
      'depois', 'descansar', 'desculpar', 'desde', 'desejo', 'despertar', 'dever', 'devolver', 'dia', 'diferente',
      'trem', 'ônibus', 'celular', 'xícara', 'geladeira', 'sorvete', 'banheiro', 'time', 'legal', 'bacana',
      'durante', 'empresa', 'encontrar', 'ensinar', 'entender', 'então', 'entrada', 'entrar', 'entregar', 'enviar',
      // Advanced (L5-6)
      'equipe', 'erro', 'escola', 'escrever', 'escutar', 'esforço', 'espaço', 'esperar', 'estado',
      'estar', 'estrela', 'estudante', 'estudar', 'evitar', 'exemplo', 'exercício', 'existir', 'experiência', 'explicar',
      'governo', 'democracia', 'filosofia', 'infraestrutura', 'jurisprudência', 'economia',
      // Complex (L7-10)
      'inconstitucionalissimamente', 'desproporcionadamente', 'incompreensivelmente', 'extraordinariamente',
      'desconcertantemente', 'imprescindibilidade', 'circunstancialmente', 'contemporaneidade',
      'autocomiseração', 'desapercebidamente', 'incontornavelmente', 'aprofundamento',
    ],
  };

  // ============================================================
  // TRANSLATION RACE - Translation pairs (English -> target)
  // 60+ pairs per language organized by difficulty
  // ============================================================

  static const Map<String, Map<String, String>> translationPairs = {
    'en': {
      // L1-2: Common everyday
      'hello': 'hello', 'goodbye': 'goodbye', 'please': 'please', 'thank you': 'thank you',
      'yes': 'yes', 'no': 'no', 'water': 'water', 'food': 'food', 'house': 'house',
      'friend': 'friend', 'love': 'love', 'family': 'family', 'time': 'time', 'day': 'day',
      'night': 'night', 'sun': 'sun', 'moon': 'moon', 'star': 'star', 'fire': 'fire',
      'earth': 'earth', 'tree': 'tree', 'flower': 'flower', 'dog': 'dog', 'cat': 'cat',
      'bird': 'bird', 'fish': 'fish', 'book': 'book', 'school': 'school', 'teacher': 'teacher',
      // L3-4: Intermediate
      'student': 'student', 'city': 'city', 'country': 'country', 'river': 'river', 'mountain': 'mountain',
      'beach': 'beach', 'sea': 'sea', 'rain': 'rain', 'snow': 'snow', 'wind': 'wind',
      'heart': 'heart', 'hand': 'hand', 'head': 'head', 'eye': 'eye', 'mouth': 'mouth',
      // L5-6: Advanced
      'accomplish': 'accomplish', 'demonstrate': 'demonstrate', 'phenomenon': 'phenomenon',
      'infrastructure': 'infrastructure', 'sustainability': 'sustainability',
      // L7-10: Complex
      'serendipity': 'serendipity', 'ephemeral': 'ephemeral', 'ubiquitous': 'ubiquitous',
      'magnanimous': 'magnanimous', 'quintessential': 'quintessential',
    },
    'es': {
      // L1-2: Common everyday
      'hello': 'hola', 'goodbye': 'adiós', 'please': 'por favor', 'thank you': 'gracias',
      'yes': 'sí', 'no': 'no', 'water': 'agua', 'food': 'comida', 'house': 'casa',
      'friend': 'amigo', 'love': 'amor', 'family': 'familia', 'time': 'tiempo', 'day': 'día',
      'night': 'noche', 'sun': 'sol', 'moon': 'luna', 'star': 'estrella', 'fire': 'fuego',
      'earth': 'tierra', 'tree': 'árbol', 'flower': 'flor', 'dog': 'perro', 'cat': 'gato',
      'bird': 'pájaro', 'fish': 'pez', 'book': 'libro', 'school': 'escuela', 'teacher': 'profesor',
      // L3-4: Intermediate
      'student': 'estudiante', 'city': 'ciudad', 'country': 'país', 'river': 'río', 'mountain': 'montaña',
      'beach': 'playa', 'sea': 'mar', 'rain': 'lluvia', 'snow': 'nieve', 'wind': 'viento',
      'heart': 'corazón', 'hand': 'mano', 'head': 'cabeza', 'eye': 'ojo', 'mouth': 'boca',
      'ear': 'oreja', 'nose': 'nariz', 'hair': 'pelo', 'arm': 'brazo', 'leg': 'pierna',
      'door': 'puerta', 'window': 'ventana', 'table': 'mesa', 'chair': 'silla', 'bed': 'cama',
      'bread': 'pan', 'milk': 'leche', 'meat': 'carne', 'rice': 'arroz', 'egg': 'huevo',
      // L5-6: Advanced
      'red': 'rojo', 'blue': 'azul', 'green': 'verde', 'yellow': 'amarillo', 'white': 'blanco',
      'black': 'negro', 'big': 'grande', 'small': 'pequeño', 'fast': 'rápido', 'slow': 'lento',
      'happy': 'feliz', 'sad': 'triste', 'cold': 'frío', 'hot': 'caliente', 'beautiful': 'hermoso',
      'ugly': 'feo', 'new': 'nuevo', 'old': 'viejo', 'good': 'bueno', 'bad': 'malo',
      // L7-10: Complex
      'man': 'hombre', 'woman': 'mujer', 'boy': 'niño', 'girl': 'niña', 'child': 'hijo',
      'money': 'dinero', 'work': 'trabajo', 'music': 'música', 'game': 'juego', 'king': 'rey',
      'world': 'mundo', 'peace': 'paz', 'war': 'guerra', 'life': 'vida', 'death': 'muerte',
      'dream': 'sueño', 'truth': 'verdad', 'light': 'luz', 'dark': 'oscuro', 'young': 'joven',
      'wisdom': 'sabiduría', 'freedom': 'libertad', 'justice': 'justicia', 'hope': 'esperanza',
      'strength': 'fuerza', 'knowledge': 'conocimiento', 'courage': 'coraje', 'patience': 'paciencia',
    },
    'fr': {
      // L1-2: Common everyday
      'hello': 'bonjour', 'goodbye': 'au revoir', 'please': 's\'il vous plaît', 'thank you': 'merci',
      'yes': 'oui', 'no': 'non', 'water': 'eau', 'food': 'nourriture', 'house': 'maison',
      'friend': 'ami', 'love': 'amour', 'family': 'famille', 'time': 'temps', 'day': 'jour',
      'night': 'nuit', 'sun': 'soleil', 'moon': 'lune', 'star': 'étoile', 'fire': 'feu',
      'earth': 'terre', 'tree': 'arbre', 'flower': 'fleur', 'dog': 'chien', 'cat': 'chat',
      'bird': 'oiseau', 'fish': 'poisson', 'book': 'livre', 'school': 'école', 'teacher': 'professeur',
      // L3-4: Intermediate
      'student': 'étudiant', 'city': 'ville', 'country': 'pays', 'river': 'rivière', 'mountain': 'montagne',
      'beach': 'plage', 'sea': 'mer', 'rain': 'pluie', 'snow': 'neige', 'wind': 'vent',
      'heart': 'coeur', 'hand': 'main', 'head': 'tête', 'eye': 'oeil', 'mouth': 'bouche',
      'ear': 'oreille', 'nose': 'nez', 'hair': 'cheveux', 'arm': 'bras', 'leg': 'jambe',
      'door': 'porte', 'window': 'fenêtre', 'table': 'table', 'chair': 'chaise', 'bed': 'lit',
      'bread': 'pain', 'milk': 'lait', 'meat': 'viande', 'rice': 'riz', 'egg': 'oeuf',
      // L5-6: Advanced
      'red': 'rouge', 'blue': 'bleu', 'green': 'vert', 'yellow': 'jaune', 'white': 'blanc',
      'black': 'noir', 'big': 'grand', 'small': 'petit', 'fast': 'rapide', 'slow': 'lent',
      'happy': 'heureux', 'sad': 'triste', 'cold': 'froid', 'hot': 'chaud', 'beautiful': 'beau',
      'ugly': 'laid', 'new': 'nouveau', 'old': 'vieux', 'good': 'bon', 'bad': 'mauvais',
      // L7-10: Complex
      'man': 'homme', 'woman': 'femme', 'boy': 'garçon', 'girl': 'fille', 'child': 'enfant',
      'money': 'argent', 'work': 'travail', 'music': 'musique', 'game': 'jeu', 'king': 'roi',
      'world': 'monde', 'peace': 'paix', 'war': 'guerre', 'life': 'vie', 'death': 'mort',
      'dream': 'rêve', 'truth': 'vérité', 'light': 'lumière', 'dark': 'sombre', 'young': 'jeune',
      'wisdom': 'sagesse', 'freedom': 'liberté', 'justice': 'justice', 'hope': 'espoir',
      'strength': 'force', 'knowledge': 'connaissance', 'courage': 'courage', 'patience': 'patience',
    },
    'de': {
      // L1-2: Common everyday
      'hello': 'hallo', 'goodbye': 'auf wiedersehen', 'please': 'bitte', 'thank you': 'danke',
      'yes': 'ja', 'no': 'nein', 'water': 'wasser', 'food': 'essen', 'house': 'haus',
      'friend': 'freund', 'love': 'liebe', 'family': 'familie', 'time': 'zeit', 'day': 'tag',
      'night': 'nacht', 'sun': 'sonne', 'moon': 'mond', 'star': 'stern', 'fire': 'feuer',
      'earth': 'erde', 'tree': 'baum', 'flower': 'blume', 'dog': 'hund', 'cat': 'katze',
      'bird': 'vogel', 'fish': 'fisch', 'book': 'buch', 'school': 'schule', 'teacher': 'lehrer',
      // L3-4: Intermediate
      'student': 'schüler', 'city': 'stadt', 'country': 'land', 'river': 'fluss', 'mountain': 'berg',
      'beach': 'strand', 'sea': 'meer', 'rain': 'regen', 'snow': 'schnee', 'wind': 'wind',
      'heart': 'herz', 'hand': 'hand', 'head': 'kopf', 'eye': 'auge', 'mouth': 'mund',
      'door': 'tür', 'window': 'fenster', 'table': 'tisch', 'chair': 'stuhl', 'bed': 'bett',
      'bread': 'brot', 'milk': 'milch', 'meat': 'fleisch', 'rice': 'reis', 'egg': 'ei',
      // L5-6: Advanced
      'red': 'rot', 'blue': 'blau', 'green': 'grün', 'yellow': 'gelb', 'white': 'weiß',
      'black': 'schwarz', 'big': 'groß', 'small': 'klein', 'fast': 'schnell', 'slow': 'langsam',
      'happy': 'glücklich', 'sad': 'traurig', 'cold': 'kalt', 'hot': 'heiß', 'beautiful': 'schön',
      // L7-10: Complex
      'man': 'mann', 'woman': 'frau', 'boy': 'junge', 'girl': 'mädchen', 'child': 'kind',
      'money': 'geld', 'work': 'arbeit', 'music': 'musik', 'game': 'spiel', 'king': 'könig',
      'world': 'welt', 'peace': 'frieden', 'war': 'krieg', 'life': 'leben', 'death': 'tod',
      'dream': 'traum', 'truth': 'wahrheit', 'light': 'licht', 'dark': 'dunkel', 'young': 'jung',
      'wisdom': 'weisheit', 'freedom': 'freiheit', 'justice': 'gerechtigkeit', 'hope': 'hoffnung',
      'strength': 'stärke', 'knowledge': 'wissen', 'courage': 'mut', 'patience': 'geduld',
    },
    'it': {
      // L1-2: Common everyday
      'hello': 'ciao', 'goodbye': 'arrivederci', 'please': 'per favore', 'thank you': 'grazie',
      'yes': 'sì', 'no': 'no', 'water': 'acqua', 'food': 'cibo', 'house': 'casa',
      'friend': 'amico', 'love': 'amore', 'family': 'famiglia', 'time': 'tempo', 'day': 'giorno',
      'night': 'notte', 'sun': 'sole', 'moon': 'luna', 'star': 'stella', 'fire': 'fuoco',
      'earth': 'terra', 'tree': 'albero', 'flower': 'fiore', 'dog': 'cane', 'cat': 'gatto',
      'bird': 'uccello', 'fish': 'pesce', 'book': 'libro', 'school': 'scuola', 'teacher': 'professore',
      // L3-4: Intermediate
      'student': 'studente', 'city': 'città', 'country': 'paese', 'river': 'fiume', 'mountain': 'montagna',
      'beach': 'spiaggia', 'sea': 'mare', 'rain': 'pioggia', 'snow': 'neve', 'wind': 'vento',
      'heart': 'cuore', 'hand': 'mano', 'head': 'testa', 'eye': 'occhio', 'mouth': 'bocca',
      'door': 'porta', 'window': 'finestra', 'table': 'tavolo', 'chair': 'sedia', 'bed': 'letto',
      'bread': 'pane', 'milk': 'latte', 'meat': 'carne', 'rice': 'riso', 'egg': 'uovo',
      // L5-6: Advanced
      'red': 'rosso', 'blue': 'blu', 'green': 'verde', 'yellow': 'giallo', 'white': 'bianco',
      'black': 'nero', 'big': 'grande', 'small': 'piccolo', 'fast': 'veloce', 'slow': 'lento',
      'happy': 'felice', 'sad': 'triste', 'cold': 'freddo', 'hot': 'caldo', 'beautiful': 'bello',
      // L7-10: Complex
      'man': 'uomo', 'woman': 'donna', 'boy': 'ragazzo', 'girl': 'ragazza', 'child': 'bambino',
      'money': 'soldi', 'work': 'lavoro', 'music': 'musica', 'game': 'gioco', 'king': 're',
      'world': 'mondo', 'peace': 'pace', 'war': 'guerra', 'life': 'vita', 'death': 'morte',
      'dream': 'sogno', 'truth': 'verità', 'light': 'luce', 'dark': 'scuro', 'young': 'giovane',
      'wisdom': 'saggezza', 'freedom': 'libertà', 'justice': 'giustizia', 'hope': 'speranza',
      'strength': 'forza', 'knowledge': 'conoscenza', 'courage': 'coraggio', 'patience': 'pazienza',
    },
    'pt': {
      // L1-2: Common everyday
      'hello': 'olá', 'goodbye': 'adeus', 'please': 'por favor', 'thank you': 'obrigado',
      'yes': 'sim', 'no': 'não', 'water': 'água', 'food': 'comida', 'house': 'casa',
      'friend': 'amigo', 'love': 'amor', 'family': 'família', 'time': 'tempo', 'day': 'dia',
      'night': 'noite', 'sun': 'sol', 'moon': 'lua', 'star': 'estrela', 'fire': 'fogo',
      'earth': 'terra', 'tree': 'árvore', 'flower': 'flor', 'dog': 'cão', 'cat': 'gato',
      'bird': 'pássaro', 'fish': 'peixe', 'book': 'livro', 'school': 'escola', 'teacher': 'professor',
      // L3-4: Intermediate
      'student': 'estudante', 'city': 'cidade', 'country': 'país', 'river': 'rio', 'mountain': 'montanha',
      'beach': 'praia', 'sea': 'mar', 'rain': 'chuva', 'snow': 'neve', 'wind': 'vento',
      'heart': 'coração', 'hand': 'mão', 'head': 'cabeça', 'eye': 'olho', 'mouth': 'boca',
      'ear': 'orelha', 'nose': 'nariz', 'hair': 'cabelo', 'arm': 'braço', 'leg': 'perna',
      'door': 'porta', 'window': 'janela', 'table': 'mesa', 'chair': 'cadeira', 'bed': 'cama',
      'bread': 'pão', 'milk': 'leite', 'meat': 'carne', 'rice': 'arroz', 'egg': 'ovo',
      // L5-6: Advanced — PT (European) specific
      'red': 'vermelho', 'blue': 'azul', 'green': 'verde', 'yellow': 'amarelo', 'white': 'branco',
      'black': 'preto', 'big': 'grande', 'small': 'pequeno', 'fast': 'rápido', 'slow': 'devagar',
      'happy': 'feliz', 'sad': 'triste', 'cold': 'frio', 'hot': 'quente', 'beautiful': 'bonito',
      'train': 'comboio', 'bus': 'autocarro', 'phone': 'telemóvel', 'cup': 'chávena', 'fridge': 'frigorífico',
      // L7-10: Complex
      'man': 'homem', 'woman': 'mulher', 'boy': 'rapaz', 'girl': 'rapariga', 'child': 'criança',
      'money': 'dinheiro', 'work': 'trabalho', 'music': 'música', 'game': 'jogo', 'king': 'rei',
      'world': 'mundo', 'peace': 'paz', 'war': 'guerra', 'life': 'vida', 'death': 'morte',
      'dream': 'sonho', 'truth': 'verdade', 'light': 'luz', 'dark': 'escuro', 'young': 'jovem',
      'wisdom': 'sabedoria', 'freedom': 'liberdade', 'justice': 'justiça', 'hope': 'esperança',
      'strength': 'força', 'knowledge': 'conhecimento', 'courage': 'coragem', 'patience': 'paciência',
    },
    'pt-BR': {
      // L1-2: Common everyday
      'hello': 'oi', 'goodbye': 'tchau', 'please': 'por favor', 'thank you': 'obrigado',
      'yes': 'sim', 'no': 'não', 'water': 'água', 'food': 'comida', 'house': 'casa',
      'friend': 'amigo', 'love': 'amor', 'family': 'família', 'time': 'tempo', 'day': 'dia',
      'night': 'noite', 'sun': 'sol', 'moon': 'lua', 'star': 'estrela', 'fire': 'fogo',
      'earth': 'terra', 'tree': 'árvore', 'flower': 'flor', 'dog': 'cachorro', 'cat': 'gato',
      'bird': 'pássaro', 'fish': 'peixe', 'book': 'livro', 'school': 'escola', 'teacher': 'professor',
      // L3-4: Intermediate — BR-specific
      'student': 'estudante', 'city': 'cidade', 'country': 'país', 'river': 'rio', 'mountain': 'montanha',
      'beach': 'praia', 'sea': 'mar', 'rain': 'chuva', 'snow': 'neve', 'wind': 'vento',
      'heart': 'coração', 'hand': 'mão', 'head': 'cabeça', 'eye': 'olho', 'mouth': 'boca',
      'ear': 'orelha', 'nose': 'nariz', 'hair': 'cabelo', 'arm': 'braço', 'leg': 'perna',
      'door': 'porta', 'window': 'janela', 'table': 'mesa', 'chair': 'cadeira', 'bed': 'cama',
      'bread': 'pão', 'milk': 'leite', 'meat': 'carne', 'rice': 'arroz', 'egg': 'ovo',
      // L5-6: Advanced — BR-specific vocabulary
      'red': 'vermelho', 'blue': 'azul', 'green': 'verde', 'yellow': 'amarelo', 'white': 'branco',
      'black': 'preto', 'big': 'grande', 'small': 'pequeno', 'fast': 'rápido', 'slow': 'devagar',
      'happy': 'feliz', 'sad': 'triste', 'cold': 'frio', 'hot': 'quente', 'beautiful': 'bonito',
      'train': 'trem', 'bus': 'ônibus', 'phone': 'celular', 'cup': 'xícara', 'fridge': 'geladeira',
      // L7-10: Complex
      'man': 'homem', 'woman': 'mulher', 'boy': 'menino', 'girl': 'menina', 'child': 'criança',
      'money': 'dinheiro', 'work': 'trabalho', 'music': 'música', 'game': 'jogo', 'king': 'rei',
      'world': 'mundo', 'peace': 'paz', 'war': 'guerra', 'life': 'vida', 'death': 'morte',
      'dream': 'sonho', 'truth': 'verdade', 'light': 'luz', 'dark': 'escuro', 'young': 'jovem',
      'wisdom': 'sabedoria', 'freedom': 'liberdade', 'justice': 'justiça', 'hope': 'esperança',
      'strength': 'força', 'knowledge': 'conhecimento', 'courage': 'coragem', 'patience': 'paciência',
    },
  };

  // ============================================================
  // GRAMMAR DUEL - Grammar questions per language (20+ each)
  // Organized by difficulty
  // ============================================================

  static const Map<String, List<GrammarQuestion>> grammarQuestions = {
    'en': [
      // L1-2: Basic
      GrammarQuestion(question: '"She ___ a student."', options: ['is', 'am', 'are', 'be'], correctIndex: 0, category: 'verb to be', difficulty: 1),
      GrammarQuestion(question: '"They ___ to school every day."', options: ['go', 'goes', 'going', 'gone'], correctIndex: 0, category: 'simple present', difficulty: 1),
      GrammarQuestion(question: '"I ___ breakfast at 8 AM."', options: ['have', 'has', 'having', 'had'], correctIndex: 0, category: 'simple present', difficulty: 1),
      GrammarQuestion(question: '"He ___ English very well."', options: ['speaks', 'speak', 'speaking', 'spoke'], correctIndex: 0, category: 'simple present', difficulty: 2),
      GrammarQuestion(question: '"We ___ watching a movie now."', options: ['are', 'is', 'am', 'be'], correctIndex: 0, category: 'present continuous', difficulty: 2),
      // L3-4: Intermediate
      GrammarQuestion(question: '"She ___ to Paris last summer."', options: ['went', 'go', 'goes', 'going'], correctIndex: 0, category: 'simple past', difficulty: 3),
      GrammarQuestion(question: '"I have ___ this book before."', options: ['read', 'reading', 'reads', 'readed'], correctIndex: 0, category: 'present perfect', difficulty: 3),
      GrammarQuestion(question: '"If it rains, I ___ stay home."', options: ['will', 'would', 'shall', 'should'], correctIndex: 0, category: 'conditionals', difficulty: 4),
      GrammarQuestion(question: '"The book ___ written by Shakespeare."', options: ['was', 'is', 'were', 'been'], correctIndex: 0, category: 'passive voice', difficulty: 4),
      GrammarQuestion(question: '"She asked me ___ I was going."', options: ['where', 'were', 'wear', 'we\'re'], correctIndex: 0, category: 'reported speech', difficulty: 4),
      // L5-6: Advanced
      GrammarQuestion(question: '"Had I known, I ___ have come earlier."', options: ['would', 'will', 'shall', 'should'], correctIndex: 0, category: 'third conditional', difficulty: 5),
      GrammarQuestion(question: '"Not only ___ he smart, but also kind."', options: ['is', 'was', 'does', 'has'], correctIndex: 0, category: 'inversion', difficulty: 6),
      GrammarQuestion(question: '"The project, ___ was delayed, is now complete."', options: ['which', 'who', 'whom', 'whose'], correctIndex: 0, category: 'relative clauses', difficulty: 5),
      GrammarQuestion(question: '"I wish I ___ speak French fluently."', options: ['could', 'can', 'will', 'may'], correctIndex: 0, category: 'subjunctive', difficulty: 6),
      // L7-10: Expert
      GrammarQuestion(question: '"Seldom ___ such brilliance been seen."', options: ['has', 'have', 'is', 'was'], correctIndex: 0, category: 'inversion', difficulty: 7),
      GrammarQuestion(question: '"It is imperative that he ___ on time."', options: ['be', 'is', 'was', 'will be'], correctIndex: 0, category: 'subjunctive', difficulty: 8),
      GrammarQuestion(question: '"Were it not for his help, we ___ have failed."', options: ['would', 'will', 'shall', 'might'], correctIndex: 0, category: 'inversion conditional', difficulty: 9),
      GrammarQuestion(question: '"The data ___ inconclusive, so further research is needed."', options: ['are', 'is', 'was', 'were'], correctIndex: 0, category: 'subject-verb agreement', difficulty: 8),
      GrammarQuestion(question: '"No sooner ___ he arrived than it started raining."', options: ['had', 'has', 'did', 'was'], correctIndex: 0, category: 'correlative conjunctions', difficulty: 9),
      GrammarQuestion(question: '"The committee ___ divided in their opinions."', options: ['were', 'was', 'is', 'has been'], correctIndex: 0, category: 'collective nouns', difficulty: 10),
    ],
    'es': [
      // L1-2: Basic
      GrammarQuestion(question: '"Yo ___ español."', options: ['hablo', 'hablas', 'habla', 'hablan'], correctIndex: 0, category: 'verb conjugation', difficulty: 1),
      GrammarQuestion(question: '"Ella ___ una manzana."', options: ['como', 'comes', 'come', 'comen'], correctIndex: 2, category: 'verb conjugation', difficulty: 1),
      GrammarQuestion(question: '"Nosotros ___ en la escuela."', options: ['estoy', 'estás', 'está', 'estamos'], correctIndex: 3, category: 'verb conjugation', difficulty: 1),
      GrammarQuestion(question: 'Select the correct article: "___ casa es grande."', options: ['El', 'La', 'Los', 'Las'], correctIndex: 1, category: 'articles', difficulty: 1),
      GrammarQuestion(question: '"___ libros son interesantes."', options: ['El', 'La', 'Los', 'Las'], correctIndex: 2, category: 'articles', difficulty: 2),
      // L3-4: Intermediate
      GrammarQuestion(question: '"El gato está ___ la mesa."', options: ['en', 'sobre', 'debajo de', 'encima de'], correctIndex: 1, category: 'prepositions', difficulty: 3),
      GrammarQuestion(question: '"Voy ___ supermercado."', options: ['a', 'al', 'en el', 'del'], correctIndex: 1, category: 'prepositions', difficulty: 3),
      GrammarQuestion(question: '"Ellos ___ mucho ayer."', options: ['trabajan', 'trabajaron', 'trabajaban', 'trabajarán'], correctIndex: 1, category: 'verb conjugation', difficulty: 3),
      GrammarQuestion(question: '"___ agua es fría."', options: ['El', 'La', 'Los', 'Las'], correctIndex: 0, category: 'articles', difficulty: 3),
      GrammarQuestion(question: '"Tú ___ muy inteligente."', options: ['soy', 'eres', 'es', 'somos'], correctIndex: 1, category: 'verb conjugation', difficulty: 4),
      GrammarQuestion(question: 'Which is correct?', options: ['Yo tengo hambre', 'Yo soy hambre', 'Yo estoy hambre', 'Yo hay hambre'], correctIndex: 0, category: 'verb usage', difficulty: 4),
      // L5-6: Advanced
      GrammarQuestion(question: '"Mi hermana es ___ alta ___ yo."', options: ['más...que', 'más...de', 'tan...como', 'tanto...como'], correctIndex: 0, category: 'comparisons', difficulty: 5),
      GrammarQuestion(question: '"¿___ hora es?"', options: ['Que', 'Qué', 'Cuál', 'Cual'], correctIndex: 1, category: 'question words', difficulty: 5),
      GrammarQuestion(question: '"Yo ___ levanto temprano."', options: ['me', 'te', 'se', 'nos'], correctIndex: 0, category: 'reflexive', difficulty: 5),
      GrammarQuestion(question: '"Ayer ___ al cine."', options: ['fui', 'iba', 'iré', 'voy'], correctIndex: 0, category: 'verb conjugation', difficulty: 6),
      // L7-10: Expert
      GrammarQuestion(question: '"Si ___ dinero, compraría un coche."', options: ['tengo', 'tuviera', 'tenga', 'tendré'], correctIndex: 1, category: 'subjunctive', difficulty: 7),
      GrammarQuestion(question: '"___ perros son grandes."', options: ['Esos', 'Esas', 'Ese', 'Esa'], correctIndex: 0, category: 'demonstratives', difficulty: 7),
      GrammarQuestion(question: '"Me gusta ___ música."', options: ['el', 'la', 'los', 'las'], correctIndex: 1, category: 'articles', difficulty: 8),
      GrammarQuestion(question: '"Ella ___ cansada."', options: ['es', 'está', 'ser', 'estar'], correctIndex: 1, category: 'ser vs estar', difficulty: 8),
      GrammarQuestion(question: '"No ___ nada en el refrigerador."', options: ['hay', 'es', 'está', 'tiene'], correctIndex: 0, category: 'verb usage', difficulty: 9),
      GrammarQuestion(question: '"Ojalá que ___ buen tiempo mañana."', options: ['haga', 'hace', 'hará', 'hacía'], correctIndex: 0, category: 'subjunctive', difficulty: 10),
    ],
    'fr': [
      // L1-2: Basic
      GrammarQuestion(question: '"Je ___ français."', options: ['parle', 'parles', 'parlons', 'parlent'], correctIndex: 0, category: 'verb conjugation', difficulty: 1),
      GrammarQuestion(question: '"Elle ___ une pomme."', options: ['mange', 'manges', 'mangeons', 'mangent'], correctIndex: 0, category: 'verb conjugation', difficulty: 1),
      GrammarQuestion(question: '"___ maison est grande."', options: ['Le', 'La', 'Les', 'Un'], correctIndex: 1, category: 'articles', difficulty: 1),
      GrammarQuestion(question: '"Nous ___ à Paris."', options: ['sommes', 'êtes', 'sont', 'suis'], correctIndex: 0, category: 'verb conjugation', difficulty: 2),
      GrammarQuestion(question: '"Il va ___ école."', options: ['à l\'', 'au', 'à la', 'aux'], correctIndex: 0, category: 'prepositions', difficulty: 2),
      // L3-4: Intermediate
      GrammarQuestion(question: '"J\'ai ___ le film hier."', options: ['regardé', 'regarder', 'regarde', 'regardais'], correctIndex: 0, category: 'past tense', difficulty: 3),
      GrammarQuestion(question: '"___ livres sont intéressants."', options: ['Le', 'La', 'Les', 'Des'], correctIndex: 2, category: 'articles', difficulty: 3),
      GrammarQuestion(question: '"Tu ___ beaucoup."', options: ['travaille', 'travailles', 'travaillons', 'travaillent'], correctIndex: 1, category: 'verb conjugation', difficulty: 3),
      GrammarQuestion(question: '"Je ___ faim."', options: ['suis', 'ai', 'fais', 'vais'], correctIndex: 1, category: 'verb usage', difficulty: 4),
      GrammarQuestion(question: '"Elle est ___ intelligente ___ lui."', options: ['plus...que', 'plus...de', 'aussi...que', 'autant...que'], correctIndex: 0, category: 'comparisons', difficulty: 4),
      // L5-6: Advanced
      GrammarQuestion(question: '"___ est ton nom?"', options: ['Que', 'Quel', 'Qui', 'Quoi'], correctIndex: 1, category: 'question words', difficulty: 5),
      GrammarQuestion(question: '"Je ___ lève tôt."', options: ['me', 'te', 'se', 'nous'], correctIndex: 0, category: 'reflexive', difficulty: 5),
      GrammarQuestion(question: '"Hier, je ___ au cinéma."', options: ['suis allé', 'vais aller', 'allais', 'irai'], correctIndex: 0, category: 'past tense', difficulty: 5),
      GrammarQuestion(question: '"Si j\'___ riche, je voyagerais."', options: ['étais', 'suis', 'serai', 'soit'], correctIndex: 0, category: 'conditional', difficulty: 6),
      GrammarQuestion(question: '"Je ne ___ pas de chat."', options: ['ai', 'suis', 'fais', 'vais'], correctIndex: 0, category: 'negation', difficulty: 6),
      // L7-10: Expert
      GrammarQuestion(question: '"Il ___ beau aujourd\'hui."', options: ['fait', 'est', 'a', 'va'], correctIndex: 0, category: 'weather', difficulty: 7),
      GrammarQuestion(question: '"___ chien est noir."', options: ['Ce', 'Cet', 'Cette', 'Ces'], correctIndex: 0, category: 'demonstratives', difficulty: 7),
      GrammarQuestion(question: '"J\'aime ___ musique."', options: ['le', 'la', 'les', 'du'], correctIndex: 1, category: 'articles', difficulty: 8),
      GrammarQuestion(question: '"Nous ___ contents."', options: ['sommes', 'avons', 'faisons', 'allons'], correctIndex: 0, category: 'verb conjugation', difficulty: 8),
      GrammarQuestion(question: '"Il y ___ beaucoup de monde."', options: ['a', 'est', 'sont', 'fait'], correctIndex: 0, category: 'expressions', difficulty: 9),
      GrammarQuestion(question: '"Bien qu\'il ___ fatigué, il continue."', options: ['soit', 'est', 'sera', 'était'], correctIndex: 0, category: 'subjunctive', difficulty: 10),
    ],
    'de': [
      // L1-2: Basic
      GrammarQuestion(question: '"Ich ___ Deutsch."', options: ['spreche', 'sprichst', 'spricht', 'sprechen'], correctIndex: 0, category: 'verb conjugation', difficulty: 1),
      GrammarQuestion(question: '"___ Buch ist interessant."', options: ['Der', 'Die', 'Das', 'Den'], correctIndex: 2, category: 'articles', difficulty: 1),
      GrammarQuestion(question: '"Er ___ einen Apfel."', options: ['esse', 'isst', 'essen', 'esst'], correctIndex: 1, category: 'verb conjugation', difficulty: 1),
      GrammarQuestion(question: '"Wir ___ in Berlin."', options: ['bin', 'bist', 'ist', 'sind'], correctIndex: 3, category: 'verb conjugation', difficulty: 2),
      GrammarQuestion(question: '"Ich gehe ___ Schule."', options: ['zu', 'zur', 'zum', 'nach'], correctIndex: 1, category: 'prepositions', difficulty: 2),
      // L3-4: Intermediate
      GrammarQuestion(question: '"___ Hund ist groß."', options: ['Der', 'Die', 'Das', 'Den'], correctIndex: 0, category: 'articles', difficulty: 3),
      GrammarQuestion(question: '"Du ___ sehr klug."', options: ['bin', 'bist', 'ist', 'sind'], correctIndex: 1, category: 'verb conjugation', difficulty: 3),
      GrammarQuestion(question: '"Ich ___ Hunger."', options: ['bin', 'habe', 'mache', 'gehe'], correctIndex: 1, category: 'verb usage', difficulty: 3),
      GrammarQuestion(question: '"___ Blumen sind schön."', options: ['Der', 'Die', 'Das', 'Den'], correctIndex: 1, category: 'articles', difficulty: 4),
      GrammarQuestion(question: '"Er ___ gestern ins Kino."', options: ['geht', 'ging', 'gehen', 'gehst'], correctIndex: 1, category: 'past tense', difficulty: 4),
      // L5-6: Advanced
      GrammarQuestion(question: '"Ich ___ gern Musik."', options: ['höre', 'hörst', 'hört', 'hören'], correctIndex: 0, category: 'verb conjugation', difficulty: 5),
      GrammarQuestion(question: '"Sie ___ sehr schnell."', options: ['laufe', 'läufst', 'läuft', 'laufen'], correctIndex: 2, category: 'verb conjugation', difficulty: 5),
      GrammarQuestion(question: '"___ Katze schläft."', options: ['Der', 'Die', 'Das', 'Den'], correctIndex: 1, category: 'articles', difficulty: 6),
      GrammarQuestion(question: '"Ich fahre ___ dem Bus."', options: ['mit', 'auf', 'in', 'an'], correctIndex: 0, category: 'prepositions', difficulty: 6),
      GrammarQuestion(question: '"Das Buch ist ___ dem Tisch."', options: ['auf', 'in', 'an', 'über'], correctIndex: 0, category: 'prepositions', difficulty: 6),
      // L7-10: Expert
      GrammarQuestion(question: '"Wenn ich reich ___, würde ich reisen."', options: ['bin', 'wäre', 'sei', 'war'], correctIndex: 1, category: 'subjunctive', difficulty: 7),
      GrammarQuestion(question: '"Ich ___ kein Auto."', options: ['habe', 'bin', 'mache', 'gehe'], correctIndex: 0, category: 'negation', difficulty: 7),
      GrammarQuestion(question: '"Es ___ heute kalt."', options: ['ist', 'hat', 'macht', 'geht'], correctIndex: 0, category: 'weather', difficulty: 8),
      GrammarQuestion(question: '"___ Kind spielt."', options: ['Der', 'Die', 'Das', 'Den'], correctIndex: 2, category: 'articles', difficulty: 8),
      GrammarQuestion(question: '"Ich ___ seit drei Jahren hier."', options: ['wohne', 'wohnst', 'wohnt', 'wohnen'], correctIndex: 0, category: 'verb conjugation', difficulty: 9),
      GrammarQuestion(question: '"Hätte ich das gewusst, ___ ich gekommen."', options: ['wäre', 'bin', 'war', 'sei'], correctIndex: 0, category: 'subjunctive II', difficulty: 10),
    ],
    'it': [
      // L1-2: Basic
      GrammarQuestion(question: '"Io ___ italiano."', options: ['parlo', 'parli', 'parla', 'parliamo'], correctIndex: 0, category: 'verb conjugation', difficulty: 1),
      GrammarQuestion(question: '"___ casa è grande."', options: ['Il', 'La', 'Lo', 'Le'], correctIndex: 1, category: 'articles', difficulty: 1),
      GrammarQuestion(question: '"Lui ___ una mela."', options: ['mangio', 'mangi', 'mangia', 'mangiamo'], correctIndex: 2, category: 'verb conjugation', difficulty: 1),
      GrammarQuestion(question: '"Noi ___ a Roma."', options: ['sono', 'sei', 'è', 'siamo'], correctIndex: 3, category: 'verb conjugation', difficulty: 2),
      GrammarQuestion(question: '"Vado ___ scuola."', options: ['a', 'al', 'alla', 'allo'], correctIndex: 0, category: 'prepositions', difficulty: 2),
      // L3-4: Intermediate
      GrammarQuestion(question: '"___ libro è interessante."', options: ['Il', 'La', 'Lo', 'Le'], correctIndex: 0, category: 'articles', difficulty: 3),
      GrammarQuestion(question: '"Tu ___ molto intelligente."', options: ['sono', 'sei', 'è', 'siamo'], correctIndex: 1, category: 'verb conjugation', difficulty: 3),
      GrammarQuestion(question: '"Ho ___ il film ieri."', options: ['guardato', 'guardare', 'guardo', 'guardavo'], correctIndex: 0, category: 'past tense', difficulty: 3),
      GrammarQuestion(question: '"___ amici sono simpatici."', options: ['I', 'Le', 'Gli', 'Lo'], correctIndex: 2, category: 'articles', difficulty: 4),
      GrammarQuestion(question: '"Io ___ fame."', options: ['sono', 'ho', 'faccio', 'vado'], correctIndex: 1, category: 'verb usage', difficulty: 4),
      // L5-6: Advanced
      GrammarQuestion(question: '"Lei è ___ alta ___ me."', options: ['più...di', 'più...che', 'tanto...quanto', 'così...come'], correctIndex: 0, category: 'comparisons', difficulty: 5),
      GrammarQuestion(question: '"Mi ___ presto."', options: ['alzo', 'alzi', 'alza', 'alziamo'], correctIndex: 0, category: 'reflexive', difficulty: 5),
      GrammarQuestion(question: '"Ieri ___ al cinema."', options: ['sono andato', 'vado', 'andrò', 'andavo'], correctIndex: 0, category: 'past tense', difficulty: 6),
      GrammarQuestion(question: '"Se ___ ricco, viaggerei."', options: ['fossi', 'sono', 'sarò', 'sia'], correctIndex: 0, category: 'subjunctive', difficulty: 6),
      // L7-10: Expert
      GrammarQuestion(question: '"Non ___ nessun gatto."', options: ['ho', 'sono', 'faccio', 'vado'], correctIndex: 0, category: 'negation', difficulty: 7),
      GrammarQuestion(question: '"Oggi ___ bel tempo."', options: ['fa', 'è', 'ha', 'va'], correctIndex: 0, category: 'weather', difficulty: 7),
      GrammarQuestion(question: '"___ gatto è nero."', options: ['Questo', 'Questa', 'Questi', 'Queste'], correctIndex: 0, category: 'demonstratives', difficulty: 8),
      GrammarQuestion(question: '"Mi piace ___ musica."', options: ['il', 'la', 'lo', 'le'], correctIndex: 1, category: 'articles', difficulty: 8),
      GrammarQuestion(question: '"Noi ___ contenti."', options: ['siamo', 'abbiamo', 'facciamo', 'andiamo'], correctIndex: 0, category: 'verb conjugation', difficulty: 9),
      GrammarQuestion(question: '"Ci ___ molta gente."', options: ['è', 'sono', 'ha', 'fa'], correctIndex: 0, category: 'expressions', difficulty: 9),
      GrammarQuestion(question: '"Benché ___ stanco, continua a lavorare."', options: ['sia', 'è', 'sarà', 'era'], correctIndex: 0, category: 'subjunctive', difficulty: 10),
    ],
    'pt': [
      // L1-2: Basic
      GrammarQuestion(question: '"Eu ___ português."', options: ['falo', 'falas', 'fala', 'falamos'], correctIndex: 0, category: 'verb conjugation', difficulty: 1),
      GrammarQuestion(question: '"___ casa é grande."', options: ['O', 'A', 'Os', 'As'], correctIndex: 1, category: 'articles', difficulty: 1),
      GrammarQuestion(question: '"Ele ___ uma maçã."', options: ['como', 'comes', 'come', 'comemos'], correctIndex: 2, category: 'verb conjugation', difficulty: 1),
      GrammarQuestion(question: '"Nós ___ em Lisboa."', options: ['sou', 'és', 'é', 'somos'], correctIndex: 3, category: 'verb conjugation', difficulty: 2),
      GrammarQuestion(question: '"Eu vou ___ escola."', options: ['a', 'à', 'ao', 'no'], correctIndex: 1, category: 'prepositions', difficulty: 2),
      // L3-4: Intermediate
      GrammarQuestion(question: '"___ livro é interessante."', options: ['O', 'A', 'Os', 'As'], correctIndex: 0, category: 'articles', difficulty: 3),
      GrammarQuestion(question: '"Tu ___ muito inteligente."', options: ['sou', 'és', 'é', 'somos'], correctIndex: 1, category: 'verb conjugation', difficulty: 3),
      GrammarQuestion(question: '"Eu ___ fome."', options: ['sou', 'tenho', 'faço', 'vou'], correctIndex: 1, category: 'verb usage', difficulty: 4),
      GrammarQuestion(question: '"Ela é ___ alta ___ eu."', options: ['mais...do que', 'mais...de', 'tão...como', 'tanto...quanto'], correctIndex: 0, category: 'comparisons', difficulty: 4),
      GrammarQuestion(question: '"Eu ___ levanto cedo."', options: ['me', 'te', 'se', 'nos'], correctIndex: 0, category: 'reflexive', difficulty: 4),
      // L5-6: Advanced
      GrammarQuestion(question: '"Ontem ___ ao cinema."', options: ['fui', 'ia', 'irei', 'vou'], correctIndex: 0, category: 'past tense', difficulty: 5),
      GrammarQuestion(question: '"Se ___ rico, viajaria."', options: ['fosse', 'sou', 'serei', 'seja'], correctIndex: 0, category: 'subjunctive', difficulty: 6),
      GrammarQuestion(question: '"___ cão é preto."', options: ['Este', 'Esta', 'Estes', 'Estas'], correctIndex: 0, category: 'demonstratives', difficulty: 5),
      GrammarQuestion(question: '"Eu gosto de ___ música."', options: ['o', 'a', 'os', 'as'], correctIndex: 1, category: 'articles', difficulty: 6),
      // L7-10: Expert
      GrammarQuestion(question: '"Nós ___ contentes."', options: ['estamos', 'temos', 'fazemos', 'vamos'], correctIndex: 0, category: 'verb conjugation', difficulty: 7),
      GrammarQuestion(question: '"Há ___ gente."', options: ['muita', 'muito', 'muitos', 'muitas'], correctIndex: 0, category: 'expressions', difficulty: 7),
      GrammarQuestion(question: '"Eu não ___ nenhum gato."', options: ['tenho', 'sou', 'faço', 'vou'], correctIndex: 0, category: 'negation', difficulty: 8),
      GrammarQuestion(question: '"Hoje ___ bom tempo."', options: ['está', 'é', 'tem', 'faz'], correctIndex: 3, category: 'weather', difficulty: 8),
      GrammarQuestion(question: '"Embora ___ cansado, ele continua."', options: ['esteja', 'está', 'estará', 'estava'], correctIndex: 0, category: 'subjunctive', difficulty: 9),
      GrammarQuestion(question: '"Caso ___ possível, gostaria de ir."', options: ['seja', 'é', 'for', 'será'], correctIndex: 0, category: 'subjunctive future', difficulty: 10),
    ],
    'pt-BR': [
      // L1-2: Basic
      GrammarQuestion(question: '"Eu ___ português."', options: ['falo', 'falas', 'fala', 'falamos'], correctIndex: 0, category: 'verb conjugation', difficulty: 1),
      GrammarQuestion(question: '"___ casa é grande."', options: ['O', 'A', 'Os', 'As'], correctIndex: 1, category: 'articles', difficulty: 1),
      GrammarQuestion(question: '"Ele ___ uma maçã."', options: ['como', 'comes', 'come', 'comemos'], correctIndex: 2, category: 'verb conjugation', difficulty: 1),
      GrammarQuestion(question: '"A gente ___ em São Paulo."', options: ['mora', 'moramos', 'moram', 'moro'], correctIndex: 0, category: 'verb conjugation', difficulty: 2),
      GrammarQuestion(question: '"Eu vou ___ escola."', options: ['pra', 'para a', 'na', 'no'], correctIndex: 1, category: 'prepositions', difficulty: 2),
      // L3-4: Intermediate
      GrammarQuestion(question: '"Você ___ muito inteligente."', options: ['sou', 'é', 'são', 'somos'], correctIndex: 1, category: 'verb conjugation', difficulty: 3),
      GrammarQuestion(question: '"Eu ___ fome."', options: ['sou', 'tenho', 'tô com', 'estou'], correctIndex: 1, category: 'verb usage', difficulty: 3),
      GrammarQuestion(question: '"Ela é ___ alta ___ eu."', options: ['mais...do que', 'mais...de', 'tão...como', 'tanto...quanto'], correctIndex: 0, category: 'comparisons', difficulty: 4),
      GrammarQuestion(question: '"Eu ___ levanto cedo."', options: ['me', 'te', 'se', 'nos'], correctIndex: 0, category: 'reflexive', difficulty: 4),
      GrammarQuestion(question: '"___ livro é interessante."', options: ['O', 'A', 'Os', 'As'], correctIndex: 0, category: 'articles', difficulty: 4),
      // L5-6: Advanced
      GrammarQuestion(question: '"Ontem eu ___ ao cinema."', options: ['fui', 'ia', 'irei', 'vou'], correctIndex: 0, category: 'past tense', difficulty: 5),
      GrammarQuestion(question: '"Se eu ___ rico, viajaria."', options: ['fosse', 'sou', 'serei', 'seja'], correctIndex: 0, category: 'subjunctive', difficulty: 6),
      GrammarQuestion(question: '"___ carro é preto."', options: ['Esse', 'Essa', 'Esses', 'Essas'], correctIndex: 0, category: 'demonstratives', difficulty: 5),
      GrammarQuestion(question: '"Eu gosto ___ música."', options: ['de', 'da', 'do', 'das'], correctIndex: 0, category: 'prepositions', difficulty: 6),
      // L7-10: Expert
      GrammarQuestion(question: '"A gente ___ contente."', options: ['está', 'estamos', 'tá', 'ficou'], correctIndex: 0, category: 'verb conjugation', difficulty: 7),
      GrammarQuestion(question: '"Tem ___ gente aqui."', options: ['muita', 'muito', 'muitos', 'muitas'], correctIndex: 0, category: 'expressions', difficulty: 7),
      GrammarQuestion(question: '"Eu não ___ nenhum gato."', options: ['tenho', 'sou', 'faço', 'vou'], correctIndex: 0, category: 'negation', difficulty: 8),
      GrammarQuestion(question: '"Hoje ___ calor."', options: ['está', 'é', 'tem', 'faz'], correctIndex: 3, category: 'weather', difficulty: 8),
      GrammarQuestion(question: '"Embora ___ cansado, ele continua."', options: ['esteja', 'está', 'estará', 'estava'], correctIndex: 0, category: 'subjunctive', difficulty: 9),
      GrammarQuestion(question: '"Caso ___ possível, eu gostaria de ir."', options: ['seja', 'é', 'for', 'será'], correctIndex: 0, category: 'subjunctive future', difficulty: 10),
    ],
  };

  // ============================================================
  // VOCABULARY CHAIN - Categories with themed words
  // 6 themes x 15+ words per language
  // ============================================================

  static const Map<String, Map<String, List<String>>> vocabularyCategories = {
    'en': {
      'animals': ['eagle', 'whale', 'horse', 'dolphin', 'elephant', 'seal', 'cat', 'ant', 'iguana', 'jaguar', 'koala', 'lion', 'butterfly', 'otter', 'bear', 'duck', 'frog', 'snake', 'turtle', 'cow', 'wolf', 'zebra', 'rabbit', 'deer', 'parrot'],
      'food': ['rice', 'banana', 'cherry', 'peach', 'salad', 'strawberry', 'cookie', 'ice cream', 'ham', 'kiwi', 'lemon', 'mango', 'orange', 'olive', 'bread', 'cheese', 'radish', 'soup', 'tomato', 'grape', 'yogurt', 'carrot', 'apple', 'chicken'],
      'places': ['airport', 'library', 'castle', 'desert', 'station', 'pharmacy', 'gym', 'hospital', 'church', 'garden', 'lake', 'market', 'office', 'park', 'restaurant', 'supermarket', 'theater', 'university', 'museum', 'beach'],
      'colors': ['yellow', 'white', 'sky blue', 'golden', 'scarlet', 'fuchsia', 'gray', 'indigo', 'jade', 'lilac', 'brown', 'orange', 'ochre', 'silver', 'pink', 'turquoise', 'green', 'violet', 'red', 'black'],
      'body': ['arm', 'head', 'finger', 'back', 'forehead', 'throat', 'shoulder', 'intestine', 'lip', 'hand', 'nose', 'eye', 'leg', 'knee', 'ankle', 'nail'],
      'clothing': ['coat', 'blouse', 'shirt', 'tie', 'skirt', 'hat', 'sweater', 'pants', 'sombrero', 'dress', 'shoe', 'scarf', 'jacket', 'glove', 't-shirt'],
    },
    'es': {
      'animals': ['águila', 'ballena', 'caballo', 'delfín', 'elefante', 'foca', 'gato', 'hormiga', 'iguana', 'jaguar', 'koala', 'león', 'mariposa', 'nutria', 'oso', 'pato', 'quetzal', 'rana', 'serpiente', 'tortuga', 'vaca', 'lobo', 'zorro', 'conejo', 'ciervo'],
      'food': ['arroz', 'banana', 'cereza', 'durazno', 'ensalada', 'fresa', 'galleta', 'helado', 'jamón', 'kiwi', 'limón', 'mango', 'naranja', 'oliva', 'pan', 'queso', 'rábano', 'sopa', 'tomate', 'uva', 'vinagre', 'yogur', 'zanahoria', 'pollo', 'manzana'],
      'places': ['aeropuerto', 'biblioteca', 'castillo', 'desierto', 'estación', 'farmacia', 'gimnasio', 'hospital', 'iglesia', 'jardín', 'kiosco', 'lago', 'mercado', 'norte', 'oficina', 'parque', 'restaurante', 'supermercado', 'teatro', 'universidad'],
      'colors': ['amarillo', 'blanco', 'celeste', 'dorado', 'escarlata', 'fucsia', 'gris', 'índigo', 'jade', 'lila', 'marrón', 'naranja', 'ocre', 'plateado', 'rosado', 'turquesa', 'verde', 'violeta'],
      'body': ['brazo', 'cabeza', 'dedo', 'espalda', 'frente', 'garganta', 'hombro', 'intestino', 'labio', 'mano', 'nariz', 'ojo', 'pierna', 'rodilla', 'tobillo', 'uña'],
      'clothing': ['abrigo', 'blusa', 'camisa', 'corbata', 'falda', 'gorro', 'jersey', 'pantalón', 'sombrero', 'vestido', 'zapato', 'bufanda', 'chaqueta', 'guante', 'camiseta'],
    },
    'fr': {
      'animals': ['aigle', 'baleine', 'chat', 'dauphin', 'éléphant', 'fourmi', 'grenouille', 'hamster', 'iguane', 'jaguar', 'koala', 'lion', 'mouton', 'narval', 'ours', 'perroquet', 'rat', 'serpent', 'tortue', 'vache', 'zèbre', 'loup', 'lapin', 'cerf', 'cheval'],
      'food': ['ananas', 'banane', 'cerise', 'datte', 'fraise', 'gâteau', 'haricot', 'jambon', 'kiwi', 'lait', 'mangue', 'noisette', 'olive', 'pain', 'raisin', 'soupe', 'tomate', 'vanille', 'yaourt', 'poulet', 'pomme', 'fromage', 'riz', 'beurre'],
      'places': ['aéroport', 'bibliothèque', 'cathédrale', 'désert', 'école', 'forêt', 'gare', 'hôpital', 'île', 'jardin', 'lac', 'musée', 'nord', 'océan', 'parc', 'restaurant', 'stade', 'théâtre', 'université', 'plage'],
      'colors': ['argent', 'blanc', 'brun', 'doré', 'gris', 'indigo', 'jaune', 'marron', 'noir', 'orange', 'rose', 'rouge', 'turquoise', 'vert', 'violet'],
      'body': ['bras', 'cerveau', 'doigt', 'épaule', 'front', 'genou', 'jambe', 'lèvre', 'main', 'nez', 'oeil', 'pied', 'tête', 'ventre', 'dos', 'cheville'],
      'clothing': ['blouson', 'bonnet', 'chaussette', 'chapeau', 'chemise', 'cravate', 'écharpe', 'gant', 'jupe', 'manteau', 'pantalon', 'pull', 'robe', 'veste', 'chaussure'],
    },
    'de': {
      'animals': ['Adler', 'Bär', 'Delfin', 'Elefant', 'Frosch', 'Giraffe', 'Hund', 'Igel', 'Jaguar', 'Katze', 'Löwe', 'Maus', 'Nashorn', 'Otter', 'Papagei', 'Rabe', 'Schlange', 'Tiger', 'Uhu', 'Vogel', 'Wolf', 'Zebra', 'Kaninchen', 'Hirsch', 'Pferd'],
      'food': ['Apfel', 'Banane', 'Ei', 'Fisch', 'Gurke', 'Honig', 'Joghurt', 'Kartoffel', 'Limone', 'Milch', 'Nudel', 'Orange', 'Pizza', 'Reis', 'Salat', 'Tomate', 'Wurst', 'Zucker', 'Brot', 'Käse', 'Huhn', 'Butter', 'Kirsche', 'Erdbeere'],
      'places': ['Apotheke', 'Bibliothek', 'Dom', 'Fabrik', 'Garten', 'Hafen', 'Insel', 'Kirche', 'Laden', 'Museum', 'Park', 'Restaurant', 'Schule', 'Theater', 'Universität', 'Strand', 'Flughafen', 'Krankenhaus', 'Markt', 'Büro'],
      'colors': ['Blau', 'Braun', 'Gelb', 'Gold', 'Grau', 'Grün', 'Lila', 'Orange', 'Rosa', 'Rot', 'Schwarz', 'Silber', 'Türkis', 'Weiß'],
      'body': ['Arm', 'Auge', 'Bauch', 'Bein', 'Finger', 'Fuß', 'Haar', 'Hand', 'Knie', 'Kopf', 'Lippe', 'Mund', 'Nase', 'Ohr', 'Rücken', 'Schulter', 'Zahn'],
      'clothing': ['Anzug', 'Bluse', 'Gürtel', 'Handschuh', 'Hemd', 'Hose', 'Hut', 'Jacke', 'Kleid', 'Mantel', 'Mütze', 'Rock', 'Schal', 'Schuh', 'Socke'],
    },
    'it': {
      'animals': ['aquila', 'balena', 'cavallo', 'delfino', 'elefante', 'farfalla', 'gatto', 'iguana', 'leone', 'mucca', 'orso', 'pappagallo', 'rana', 'serpente', 'tartaruga', 'volpe', 'zebra', 'lupo', 'coniglio', 'cervo', 'cane', 'topo', 'uccello', 'formica', 'scimmia'],
      'food': ['arancia', 'banana', 'ciliegia', 'dolce', 'fragola', 'gelato', 'insalata', 'limone', 'mango', 'noce', 'oliva', 'pane', 'riso', 'spaghetti', 'torta', 'uva', 'yogurt', 'pollo', 'mela', 'formaggio', 'latte', 'burro', 'pomodoro', 'uovo'],
      'places': ['aeroporto', 'biblioteca', 'castello', 'chiesa', 'cinema', 'deserto', 'farmacia', 'giardino', 'lago', 'museo', 'ospedale', 'parco', 'ristorante', 'scuola', 'teatro', 'università', 'spiaggia', 'mercato', 'ufficio', 'stazione'],
      'colors': ['arancione', 'azzurro', 'bianco', 'blu', 'dorato', 'giallo', 'grigio', 'marrone', 'nero', 'oro', 'rosa', 'rosso', 'verde', 'viola'],
      'body': ['bocca', 'braccio', 'caviglia', 'dito', 'gamba', 'ginocchio', 'gomito', 'labbro', 'mano', 'naso', 'occhio', 'orecchio', 'piede', 'schiena', 'spalla', 'testa'],
      'clothing': ['berretto', 'borsa', 'camicia', 'cappello', 'cintura', 'giacca', 'gonna', 'guanto', 'maglietta', 'maglione', 'pantaloni', 'scarpa', 'sciarpa', 'vestito', 'calzino'],
    },
    'pt': {
      'animals': ['águia', 'baleia', 'cavalo', 'golfinho', 'elefante', 'foca', 'gato', 'formiga', 'iguana', 'jaguar', 'koala', 'leão', 'borboleta', 'lontra', 'urso', 'pato', 'rã', 'serpente', 'tartaruga', 'vaca', 'lobo', 'zebra', 'coelho', 'veado', 'cão'],
      'food': ['arroz', 'banana', 'cereja', 'pêssego', 'salada', 'morango', 'bolacha', 'gelado', 'fiambre', 'kiwi', 'limão', 'manga', 'laranja', 'azeitona', 'pão', 'queijo', 'rabanete', 'sopa', 'tomate', 'uva', 'iogurte', 'cenoura', 'maçã', 'frango'],
      'places': ['aeroporto', 'biblioteca', 'castelo', 'deserto', 'estação', 'farmácia', 'ginásio', 'hospital', 'igreja', 'jardim', 'lago', 'mercado', 'escritório', 'parque', 'restaurante', 'supermercado', 'teatro', 'universidade', 'museu', 'praia'],
      'colors': ['amarelo', 'branco', 'azul celeste', 'dourado', 'escarlate', 'fúcsia', 'cinzento', 'índigo', 'jade', 'lilás', 'castanho', 'laranja', 'ocre', 'prateado', 'rosa', 'turquesa', 'verde', 'violeta'],
      'body': ['braço', 'cabeça', 'dedo', 'costas', 'testa', 'garganta', 'ombro', 'intestino', 'lábio', 'mão', 'nariz', 'olho', 'perna', 'joelho', 'tornozelo', 'unha'],
      'clothing': ['casaco', 'blusa', 'camisa', 'gravata', 'saia', 'gorro', 'camisola', 'calças', 'chapéu', 'vestido', 'sapato', 'cachecol', 'casaco', 'luva', 'camiseta'],
    },
    'pt-BR': {
      'animals': ['águia', 'baleia', 'cavalo', 'golfinho', 'elefante', 'foca', 'gato', 'formiga', 'iguana', 'onça', 'coala', 'leão', 'borboleta', 'lontra', 'urso', 'pato', 'sapo', 'cobra', 'tartaruga', 'vaca', 'lobo', 'zebra', 'coelho', 'veado', 'cachorro'],
      'food': ['arroz', 'banana', 'cereja', 'pêssego', 'salada', 'morango', 'biscoito', 'sorvete', 'presunto', 'kiwi', 'limão', 'manga', 'laranja', 'azeitona', 'pão', 'queijo', 'rabanete', 'sopa', 'tomate', 'uva', 'iogurte', 'cenoura', 'maçã', 'frango'],
      'places': ['aeroporto', 'biblioteca', 'castelo', 'deserto', 'estação', 'farmácia', 'academia', 'hospital', 'igreja', 'jardim', 'lago', 'mercado', 'escritório', 'parque', 'restaurante', 'supermercado', 'teatro', 'universidade', 'museu', 'praia'],
      'colors': ['amarelo', 'branco', 'azul celeste', 'dourado', 'escarlate', 'fúcsia', 'cinza', 'índigo', 'jade', 'lilás', 'marrom', 'laranja', 'ocre', 'prateado', 'rosa', 'turquesa', 'verde', 'violeta'],
      'body': ['braço', 'cabeça', 'dedo', 'costas', 'testa', 'garganta', 'ombro', 'intestino', 'lábio', 'mão', 'nariz', 'olho', 'perna', 'joelho', 'tornozelo', 'unha'],
      'clothing': ['casaco', 'blusa', 'camisa', 'gravata', 'saia', 'gorro', 'suéter', 'calça', 'chapéu', 'vestido', 'sapato', 'cachecol', 'jaqueta', 'luva', 'camiseta'],
    },
  };

  // ============================================================
  // VOCABULARY CHAIN - Theme labels
  // ============================================================

  static const Map<String, String> themeLabels = {
    'animals': 'Animals',
    'food': 'Food & Drink',
    'places': 'Places',
    'colors': 'Colors',
    'body': 'Body Parts',
    'clothing': 'Clothing',
  };

  static final List<String> themeKeys = themeLabels.keys.toList();

  // ============================================================
  // LANGUAGE SNAPS - Card matching pairs (English <-> translation)
  // 50+ pairs per language organized by difficulty
  // Map<language, Map<difficulty, List<SnapCard>>>
  // ============================================================

  static const Map<String, Map<int, List<SnapCard>>> snapCards = {
    'es': {
      1: [
        SnapCard(english: 'hello', translation: 'hola', difficulty: 1),
        SnapCard(english: 'goodbye', translation: 'adiós', difficulty: 1),
        SnapCard(english: 'water', translation: 'agua', difficulty: 1),
        SnapCard(english: 'house', translation: 'casa', difficulty: 1),
        SnapCard(english: 'dog', translation: 'perro', difficulty: 1),
        SnapCard(english: 'cat', translation: 'gato', difficulty: 1),
        SnapCard(english: 'sun', translation: 'sol', difficulty: 1),
        SnapCard(english: 'moon', translation: 'luna', difficulty: 1),
        SnapCard(english: 'yes', translation: 'sí', difficulty: 1),
        SnapCard(english: 'no', translation: 'no', difficulty: 1),
      ],
      2: [
        SnapCard(english: 'mother', translation: 'madre', difficulty: 2),
        SnapCard(english: 'father', translation: 'padre', difficulty: 2),
        SnapCard(english: 'brother', translation: 'hermano', difficulty: 2),
        SnapCard(english: 'sister', translation: 'hermana', difficulty: 2),
        SnapCard(english: 'friend', translation: 'amigo', difficulty: 2),
        SnapCard(english: 'food', translation: 'comida', difficulty: 2),
        SnapCard(english: 'book', translation: 'libro', difficulty: 2),
        SnapCard(english: 'school', translation: 'escuela', difficulty: 2),
        SnapCard(english: 'happy', translation: 'feliz', difficulty: 2),
        SnapCard(english: 'sad', translation: 'triste', difficulty: 2),
      ],
      3: [
        SnapCard(english: 'beach', translation: 'playa', difficulty: 3),
        SnapCard(english: 'mountain', translation: 'montaña', difficulty: 3),
        SnapCard(english: 'river', translation: 'río', difficulty: 3),
        SnapCard(english: 'city', translation: 'ciudad', difficulty: 3),
        SnapCard(english: 'rain', translation: 'lluvia', difficulty: 3),
        SnapCard(english: 'snow', translation: 'nieve', difficulty: 3),
        SnapCard(english: 'wind', translation: 'viento', difficulty: 3),
        SnapCard(english: 'garden', translation: 'jardín', difficulty: 3),
        SnapCard(english: 'teacher', translation: 'profesor', difficulty: 3),
        SnapCard(english: 'student', translation: 'estudiante', difficulty: 3),
      ],
      4: [
        SnapCard(english: 'shoulder', translation: 'hombro', difficulty: 4),
        SnapCard(english: 'knee', translation: 'rodilla', difficulty: 4),
        SnapCard(english: 'dream', translation: 'sueño', difficulty: 4),
        SnapCard(english: 'truth', translation: 'verdad', difficulty: 4),
        SnapCard(english: 'heart', translation: 'corazón', difficulty: 4),
        SnapCard(english: 'airplane', translation: 'avión', difficulty: 4),
        SnapCard(english: 'bridge', translation: 'puente', difficulty: 4),
        SnapCard(english: 'church', translation: 'iglesia', difficulty: 4),
        SnapCard(english: 'library', translation: 'biblioteca', difficulty: 4),
        SnapCard(english: 'hospital', translation: 'hospital', difficulty: 4),
      ],
      5: [
        SnapCard(english: 'knowledge', translation: 'conocimiento', difficulty: 5),
        SnapCard(english: 'freedom', translation: 'libertad', difficulty: 5),
        SnapCard(english: 'justice', translation: 'justicia', difficulty: 5),
        SnapCard(english: 'strength', translation: 'fuerza', difficulty: 5),
        SnapCard(english: 'environment', translation: 'medio ambiente', difficulty: 5),
        SnapCard(english: 'development', translation: 'desarrollo', difficulty: 5),
        SnapCard(english: 'success', translation: 'éxito', difficulty: 5),
        SnapCard(english: 'failure', translation: 'fracaso', difficulty: 5),
      ],
      6: [
        SnapCard(english: 'government', translation: 'gobierno', difficulty: 6),
        SnapCard(english: 'economy', translation: 'economía', difficulty: 6),
        SnapCard(english: 'research', translation: 'investigación', difficulty: 6),
        SnapCard(english: 'achievement', translation: 'logro', difficulty: 6),
        SnapCard(english: 'challenge', translation: 'desafío', difficulty: 6),
        SnapCard(english: 'opportunity', translation: 'oportunidad', difficulty: 6),
      ],
      7: [
        SnapCard(english: 'resilience', translation: 'resiliencia', difficulty: 7),
        SnapCard(english: 'perseverance', translation: 'perseverancia', difficulty: 7),
        SnapCard(english: 'accountability', translation: 'responsabilidad', difficulty: 7),
        SnapCard(english: 'bureaucracy', translation: 'burocracia', difficulty: 7),
        SnapCard(english: 'contradiction', translation: 'contradicción', difficulty: 7),
      ],
      8: [
        SnapCard(english: 'homesickness', translation: 'nostalgia', difficulty: 8),
        SnapCard(english: 'stubbornness', translation: 'terquedad', difficulty: 8),
        SnapCard(english: 'bewilderment', translation: 'desconcierto', difficulty: 8),
        SnapCard(english: 'overwhelm', translation: 'abrumar', difficulty: 8),
      ],
      9: [
        SnapCard(english: 'serendipity', translation: 'serendipia', difficulty: 9),
        SnapCard(english: 'wanderlust', translation: 'pasión por viajar', difficulty: 9),
        SnapCard(english: 'melancholy', translation: 'melancolía', difficulty: 9),
      ],
      10: [
        SnapCard(english: 'zeitgeist', translation: 'espíritu del tiempo', difficulty: 10),
        SnapCard(english: 'schadenfreude', translation: 'regodeo', difficulty: 10),
        SnapCard(english: 'epiphany', translation: 'epifanía', difficulty: 10),
      ],
    },
    'fr': {
      1: [
        SnapCard(english: 'hello', translation: 'bonjour', difficulty: 1),
        SnapCard(english: 'goodbye', translation: 'au revoir', difficulty: 1),
        SnapCard(english: 'water', translation: 'eau', difficulty: 1),
        SnapCard(english: 'house', translation: 'maison', difficulty: 1),
        SnapCard(english: 'dog', translation: 'chien', difficulty: 1),
        SnapCard(english: 'cat', translation: 'chat', difficulty: 1),
        SnapCard(english: 'sun', translation: 'soleil', difficulty: 1),
        SnapCard(english: 'moon', translation: 'lune', difficulty: 1),
        SnapCard(english: 'yes', translation: 'oui', difficulty: 1),
        SnapCard(english: 'no', translation: 'non', difficulty: 1),
      ],
      2: [
        SnapCard(english: 'mother', translation: 'mère', difficulty: 2),
        SnapCard(english: 'father', translation: 'père', difficulty: 2),
        SnapCard(english: 'brother', translation: 'frère', difficulty: 2),
        SnapCard(english: 'sister', translation: 'soeur', difficulty: 2),
        SnapCard(english: 'friend', translation: 'ami', difficulty: 2),
        SnapCard(english: 'food', translation: 'nourriture', difficulty: 2),
        SnapCard(english: 'book', translation: 'livre', difficulty: 2),
        SnapCard(english: 'school', translation: 'école', difficulty: 2),
        SnapCard(english: 'happy', translation: 'heureux', difficulty: 2),
        SnapCard(english: 'sad', translation: 'triste', difficulty: 2),
      ],
      3: [
        SnapCard(english: 'beach', translation: 'plage', difficulty: 3),
        SnapCard(english: 'mountain', translation: 'montagne', difficulty: 3),
        SnapCard(english: 'river', translation: 'rivière', difficulty: 3),
        SnapCard(english: 'city', translation: 'ville', difficulty: 3),
        SnapCard(english: 'rain', translation: 'pluie', difficulty: 3),
        SnapCard(english: 'snow', translation: 'neige', difficulty: 3),
        SnapCard(english: 'garden', translation: 'jardin', difficulty: 3),
        SnapCard(english: 'teacher', translation: 'professeur', difficulty: 3),
        SnapCard(english: 'student', translation: 'étudiant', difficulty: 3),
        SnapCard(english: 'window', translation: 'fenêtre', difficulty: 3),
      ],
      4: [
        SnapCard(english: 'shoulder', translation: 'épaule', difficulty: 4),
        SnapCard(english: 'knee', translation: 'genou', difficulty: 4),
        SnapCard(english: 'dream', translation: 'rêve', difficulty: 4),
        SnapCard(english: 'truth', translation: 'vérité', difficulty: 4),
        SnapCard(english: 'heart', translation: 'coeur', difficulty: 4),
        SnapCard(english: 'airplane', translation: 'avion', difficulty: 4),
        SnapCard(english: 'bridge', translation: 'pont', difficulty: 4),
        SnapCard(english: 'church', translation: 'église', difficulty: 4),
        SnapCard(english: 'library', translation: 'bibliothèque', difficulty: 4),
        SnapCard(english: 'hospital', translation: 'hôpital', difficulty: 4),
      ],
      5: [
        SnapCard(english: 'knowledge', translation: 'connaissance', difficulty: 5),
        SnapCard(english: 'freedom', translation: 'liberté', difficulty: 5),
        SnapCard(english: 'justice', translation: 'justice', difficulty: 5),
        SnapCard(english: 'strength', translation: 'force', difficulty: 5),
        SnapCard(english: 'environment', translation: 'environnement', difficulty: 5),
        SnapCard(english: 'development', translation: 'développement', difficulty: 5),
        SnapCard(english: 'success', translation: 'succès', difficulty: 5),
        SnapCard(english: 'failure', translation: 'échec', difficulty: 5),
      ],
      6: [
        SnapCard(english: 'government', translation: 'gouvernement', difficulty: 6),
        SnapCard(english: 'economy', translation: 'économie', difficulty: 6),
        SnapCard(english: 'research', translation: 'recherche', difficulty: 6),
        SnapCard(english: 'achievement', translation: 'réalisation', difficulty: 6),
        SnapCard(english: 'challenge', translation: 'défi', difficulty: 6),
        SnapCard(english: 'opportunity', translation: 'opportunité', difficulty: 6),
      ],
      7: [
        SnapCard(english: 'resilience', translation: 'résilience', difficulty: 7),
        SnapCard(english: 'perseverance', translation: 'persévérance', difficulty: 7),
        SnapCard(english: 'accountability', translation: 'responsabilité', difficulty: 7),
        SnapCard(english: 'bureaucracy', translation: 'bureaucratie', difficulty: 7),
        SnapCard(english: 'contradiction', translation: 'contradiction', difficulty: 7),
      ],
      8: [
        SnapCard(english: 'homesickness', translation: 'mal du pays', difficulty: 8),
        SnapCard(english: 'stubbornness', translation: 'entêtement', difficulty: 8),
        SnapCard(english: 'bewilderment', translation: 'perplexité', difficulty: 8),
        SnapCard(english: 'overwhelm', translation: 'accabler', difficulty: 8),
      ],
      9: [
        SnapCard(english: 'serendipity', translation: 'sérendipité', difficulty: 9),
        SnapCard(english: 'wanderlust', translation: 'envie de voyager', difficulty: 9),
        SnapCard(english: 'melancholy', translation: 'mélancolie', difficulty: 9),
      ],
      10: [
        SnapCard(english: 'zeitgeist', translation: 'esprit du temps', difficulty: 10),
        SnapCard(english: 'schadenfreude', translation: 'joie maligne', difficulty: 10),
        SnapCard(english: 'epiphany', translation: 'épiphanie', difficulty: 10),
      ],
    },
    'de': {
      1: [
        SnapCard(english: 'hello', translation: 'hallo', difficulty: 1),
        SnapCard(english: 'goodbye', translation: 'auf wiedersehen', difficulty: 1),
        SnapCard(english: 'water', translation: 'Wasser', difficulty: 1),
        SnapCard(english: 'house', translation: 'Haus', difficulty: 1),
        SnapCard(english: 'dog', translation: 'Hund', difficulty: 1),
        SnapCard(english: 'cat', translation: 'Katze', difficulty: 1),
        SnapCard(english: 'sun', translation: 'Sonne', difficulty: 1),
        SnapCard(english: 'moon', translation: 'Mond', difficulty: 1),
        SnapCard(english: 'yes', translation: 'ja', difficulty: 1),
        SnapCard(english: 'no', translation: 'nein', difficulty: 1),
      ],
      2: [
        SnapCard(english: 'mother', translation: 'Mutter', difficulty: 2),
        SnapCard(english: 'father', translation: 'Vater', difficulty: 2),
        SnapCard(english: 'brother', translation: 'Bruder', difficulty: 2),
        SnapCard(english: 'sister', translation: 'Schwester', difficulty: 2),
        SnapCard(english: 'friend', translation: 'Freund', difficulty: 2),
        SnapCard(english: 'food', translation: 'Essen', difficulty: 2),
        SnapCard(english: 'book', translation: 'Buch', difficulty: 2),
        SnapCard(english: 'school', translation: 'Schule', difficulty: 2),
        SnapCard(english: 'happy', translation: 'glücklich', difficulty: 2),
        SnapCard(english: 'sad', translation: 'traurig', difficulty: 2),
      ],
      3: [
        SnapCard(english: 'beach', translation: 'Strand', difficulty: 3),
        SnapCard(english: 'mountain', translation: 'Berg', difficulty: 3),
        SnapCard(english: 'river', translation: 'Fluss', difficulty: 3),
        SnapCard(english: 'city', translation: 'Stadt', difficulty: 3),
        SnapCard(english: 'rain', translation: 'Regen', difficulty: 3),
        SnapCard(english: 'snow', translation: 'Schnee', difficulty: 3),
        SnapCard(english: 'garden', translation: 'Garten', difficulty: 3),
        SnapCard(english: 'teacher', translation: 'Lehrer', difficulty: 3),
        SnapCard(english: 'student', translation: 'Schüler', difficulty: 3),
        SnapCard(english: 'window', translation: 'Fenster', difficulty: 3),
      ],
      4: [
        SnapCard(english: 'shoulder', translation: 'Schulter', difficulty: 4),
        SnapCard(english: 'knee', translation: 'Knie', difficulty: 4),
        SnapCard(english: 'dream', translation: 'Traum', difficulty: 4),
        SnapCard(english: 'truth', translation: 'Wahrheit', difficulty: 4),
        SnapCard(english: 'heart', translation: 'Herz', difficulty: 4),
        SnapCard(english: 'airplane', translation: 'Flugzeug', difficulty: 4),
        SnapCard(english: 'bridge', translation: 'Brücke', difficulty: 4),
        SnapCard(english: 'church', translation: 'Kirche', difficulty: 4),
        SnapCard(english: 'library', translation: 'Bibliothek', difficulty: 4),
        SnapCard(english: 'hospital', translation: 'Krankenhaus', difficulty: 4),
      ],
      5: [
        SnapCard(english: 'knowledge', translation: 'Wissen', difficulty: 5),
        SnapCard(english: 'freedom', translation: 'Freiheit', difficulty: 5),
        SnapCard(english: 'justice', translation: 'Gerechtigkeit', difficulty: 5),
        SnapCard(english: 'strength', translation: 'Stärke', difficulty: 5),
        SnapCard(english: 'environment', translation: 'Umwelt', difficulty: 5),
        SnapCard(english: 'development', translation: 'Entwicklung', difficulty: 5),
        SnapCard(english: 'success', translation: 'Erfolg', difficulty: 5),
        SnapCard(english: 'failure', translation: 'Misserfolg', difficulty: 5),
      ],
      6: [
        SnapCard(english: 'government', translation: 'Regierung', difficulty: 6),
        SnapCard(english: 'economy', translation: 'Wirtschaft', difficulty: 6),
        SnapCard(english: 'research', translation: 'Forschung', difficulty: 6),
        SnapCard(english: 'achievement', translation: 'Leistung', difficulty: 6),
        SnapCard(english: 'challenge', translation: 'Herausforderung', difficulty: 6),
        SnapCard(english: 'opportunity', translation: 'Gelegenheit', difficulty: 6),
      ],
      7: [
        SnapCard(english: 'resilience', translation: 'Belastbarkeit', difficulty: 7),
        SnapCard(english: 'perseverance', translation: 'Ausdauer', difficulty: 7),
        SnapCard(english: 'accountability', translation: 'Verantwortlichkeit', difficulty: 7),
        SnapCard(english: 'bureaucracy', translation: 'Bürokratie', difficulty: 7),
        SnapCard(english: 'contradiction', translation: 'Widerspruch', difficulty: 7),
      ],
      8: [
        SnapCard(english: 'homesickness', translation: 'Heimweh', difficulty: 8),
        SnapCard(english: 'stubbornness', translation: 'Sturheit', difficulty: 8),
        SnapCard(english: 'bewilderment', translation: 'Verwirrung', difficulty: 8),
        SnapCard(english: 'overwhelm', translation: 'überwältigen', difficulty: 8),
      ],
      9: [
        SnapCard(english: 'serendipity', translation: 'Zufallsfund', difficulty: 9),
        SnapCard(english: 'wanderlust', translation: 'Fernweh', difficulty: 9),
        SnapCard(english: 'melancholy', translation: 'Schwermut', difficulty: 9),
      ],
      10: [
        SnapCard(english: 'zeitgeist', translation: 'Zeitgeist', difficulty: 10),
        SnapCard(english: 'schadenfreude', translation: 'Schadenfreude', difficulty: 10),
        SnapCard(english: 'epiphany', translation: 'Erleuchtung', difficulty: 10),
      ],
    },
    'it': {
      1: [
        SnapCard(english: 'hello', translation: 'ciao', difficulty: 1),
        SnapCard(english: 'goodbye', translation: 'arrivederci', difficulty: 1),
        SnapCard(english: 'water', translation: 'acqua', difficulty: 1),
        SnapCard(english: 'house', translation: 'casa', difficulty: 1),
        SnapCard(english: 'dog', translation: 'cane', difficulty: 1),
        SnapCard(english: 'cat', translation: 'gatto', difficulty: 1),
        SnapCard(english: 'sun', translation: 'sole', difficulty: 1),
        SnapCard(english: 'moon', translation: 'luna', difficulty: 1),
        SnapCard(english: 'yes', translation: 'sì', difficulty: 1),
        SnapCard(english: 'no', translation: 'no', difficulty: 1),
      ],
      2: [
        SnapCard(english: 'mother', translation: 'madre', difficulty: 2),
        SnapCard(english: 'father', translation: 'padre', difficulty: 2),
        SnapCard(english: 'brother', translation: 'fratello', difficulty: 2),
        SnapCard(english: 'sister', translation: 'sorella', difficulty: 2),
        SnapCard(english: 'friend', translation: 'amico', difficulty: 2),
        SnapCard(english: 'food', translation: 'cibo', difficulty: 2),
        SnapCard(english: 'book', translation: 'libro', difficulty: 2),
        SnapCard(english: 'school', translation: 'scuola', difficulty: 2),
        SnapCard(english: 'happy', translation: 'felice', difficulty: 2),
        SnapCard(english: 'sad', translation: 'triste', difficulty: 2),
      ],
      3: [
        SnapCard(english: 'beach', translation: 'spiaggia', difficulty: 3),
        SnapCard(english: 'mountain', translation: 'montagna', difficulty: 3),
        SnapCard(english: 'river', translation: 'fiume', difficulty: 3),
        SnapCard(english: 'city', translation: 'città', difficulty: 3),
        SnapCard(english: 'rain', translation: 'pioggia', difficulty: 3),
        SnapCard(english: 'snow', translation: 'neve', difficulty: 3),
        SnapCard(english: 'garden', translation: 'giardino', difficulty: 3),
        SnapCard(english: 'teacher', translation: 'professore', difficulty: 3),
        SnapCard(english: 'student', translation: 'studente', difficulty: 3),
        SnapCard(english: 'window', translation: 'finestra', difficulty: 3),
      ],
      4: [
        SnapCard(english: 'shoulder', translation: 'spalla', difficulty: 4),
        SnapCard(english: 'knee', translation: 'ginocchio', difficulty: 4),
        SnapCard(english: 'dream', translation: 'sogno', difficulty: 4),
        SnapCard(english: 'truth', translation: 'verità', difficulty: 4),
        SnapCard(english: 'heart', translation: 'cuore', difficulty: 4),
        SnapCard(english: 'airplane', translation: 'aereo', difficulty: 4),
        SnapCard(english: 'bridge', translation: 'ponte', difficulty: 4),
        SnapCard(english: 'church', translation: 'chiesa', difficulty: 4),
        SnapCard(english: 'library', translation: 'biblioteca', difficulty: 4),
        SnapCard(english: 'hospital', translation: 'ospedale', difficulty: 4),
      ],
      5: [
        SnapCard(english: 'knowledge', translation: 'conoscenza', difficulty: 5),
        SnapCard(english: 'freedom', translation: 'libertà', difficulty: 5),
        SnapCard(english: 'justice', translation: 'giustizia', difficulty: 5),
        SnapCard(english: 'strength', translation: 'forza', difficulty: 5),
        SnapCard(english: 'environment', translation: 'ambiente', difficulty: 5),
        SnapCard(english: 'development', translation: 'sviluppo', difficulty: 5),
        SnapCard(english: 'success', translation: 'successo', difficulty: 5),
        SnapCard(english: 'failure', translation: 'fallimento', difficulty: 5),
      ],
      6: [
        SnapCard(english: 'government', translation: 'governo', difficulty: 6),
        SnapCard(english: 'economy', translation: 'economia', difficulty: 6),
        SnapCard(english: 'research', translation: 'ricerca', difficulty: 6),
        SnapCard(english: 'achievement', translation: 'traguardo', difficulty: 6),
        SnapCard(english: 'challenge', translation: 'sfida', difficulty: 6),
        SnapCard(english: 'opportunity', translation: 'opportunità', difficulty: 6),
      ],
      7: [
        SnapCard(english: 'resilience', translation: 'resilienza', difficulty: 7),
        SnapCard(english: 'perseverance', translation: 'perseveranza', difficulty: 7),
        SnapCard(english: 'accountability', translation: 'responsabilità', difficulty: 7),
        SnapCard(english: 'bureaucracy', translation: 'burocrazia', difficulty: 7),
        SnapCard(english: 'contradiction', translation: 'contraddizione', difficulty: 7),
      ],
      8: [
        SnapCard(english: 'homesickness', translation: 'nostalgia di casa', difficulty: 8),
        SnapCard(english: 'stubbornness', translation: 'testardaggine', difficulty: 8),
        SnapCard(english: 'bewilderment', translation: 'sconcerto', difficulty: 8),
        SnapCard(english: 'overwhelm', translation: 'sopraffare', difficulty: 8),
      ],
      9: [
        SnapCard(english: 'serendipity', translation: 'serendipità', difficulty: 9),
        SnapCard(english: 'wanderlust', translation: 'voglia di viaggiare', difficulty: 9),
        SnapCard(english: 'melancholy', translation: 'malinconia', difficulty: 9),
      ],
      10: [
        SnapCard(english: 'zeitgeist', translation: 'spirito del tempo', difficulty: 10),
        SnapCard(english: 'schadenfreude', translation: 'gioia per le disgrazie altrui', difficulty: 10),
        SnapCard(english: 'epiphany', translation: 'epifania', difficulty: 10),
      ],
    },
    'pt': {
      1: [
        SnapCard(english: 'hello', translation: 'olá', difficulty: 1),
        SnapCard(english: 'goodbye', translation: 'adeus', difficulty: 1),
        SnapCard(english: 'water', translation: 'água', difficulty: 1),
        SnapCard(english: 'house', translation: 'casa', difficulty: 1),
        SnapCard(english: 'dog', translation: 'cão', difficulty: 1),
        SnapCard(english: 'cat', translation: 'gato', difficulty: 1),
        SnapCard(english: 'sun', translation: 'sol', difficulty: 1),
        SnapCard(english: 'moon', translation: 'lua', difficulty: 1),
        SnapCard(english: 'yes', translation: 'sim', difficulty: 1),
        SnapCard(english: 'no', translation: 'não', difficulty: 1),
      ],
      2: [
        SnapCard(english: 'mother', translation: 'mãe', difficulty: 2),
        SnapCard(english: 'father', translation: 'pai', difficulty: 2),
        SnapCard(english: 'brother', translation: 'irmão', difficulty: 2),
        SnapCard(english: 'sister', translation: 'irmã', difficulty: 2),
        SnapCard(english: 'friend', translation: 'amigo', difficulty: 2),
        SnapCard(english: 'food', translation: 'comida', difficulty: 2),
        SnapCard(english: 'book', translation: 'livro', difficulty: 2),
        SnapCard(english: 'school', translation: 'escola', difficulty: 2),
        SnapCard(english: 'happy', translation: 'feliz', difficulty: 2),
        SnapCard(english: 'sad', translation: 'triste', difficulty: 2),
      ],
      3: [
        SnapCard(english: 'beach', translation: 'praia', difficulty: 3),
        SnapCard(english: 'mountain', translation: 'montanha', difficulty: 3),
        SnapCard(english: 'river', translation: 'rio', difficulty: 3),
        SnapCard(english: 'city', translation: 'cidade', difficulty: 3),
        SnapCard(english: 'rain', translation: 'chuva', difficulty: 3),
        SnapCard(english: 'train', translation: 'comboio', difficulty: 3),
        SnapCard(english: 'bus', translation: 'autocarro', difficulty: 3),
        SnapCard(english: 'phone', translation: 'telemóvel', difficulty: 3),
        SnapCard(english: 'teacher', translation: 'professor', difficulty: 3),
        SnapCard(english: 'student', translation: 'estudante', difficulty: 3),
      ],
      4: [
        SnapCard(english: 'shoulder', translation: 'ombro', difficulty: 4),
        SnapCard(english: 'knee', translation: 'joelho', difficulty: 4),
        SnapCard(english: 'dream', translation: 'sonho', difficulty: 4),
        SnapCard(english: 'truth', translation: 'verdade', difficulty: 4),
        SnapCard(english: 'heart', translation: 'coração', difficulty: 4),
        SnapCard(english: 'airplane', translation: 'avião', difficulty: 4),
        SnapCard(english: 'bridge', translation: 'ponte', difficulty: 4),
        SnapCard(english: 'church', translation: 'igreja', difficulty: 4),
        SnapCard(english: 'library', translation: 'biblioteca', difficulty: 4),
        SnapCard(english: 'hospital', translation: 'hospital', difficulty: 4),
      ],
      5: [
        SnapCard(english: 'knowledge', translation: 'conhecimento', difficulty: 5),
        SnapCard(english: 'freedom', translation: 'liberdade', difficulty: 5),
        SnapCard(english: 'justice', translation: 'justiça', difficulty: 5),
        SnapCard(english: 'strength', translation: 'força', difficulty: 5),
        SnapCard(english: 'success', translation: 'sucesso', difficulty: 5),
        SnapCard(english: 'failure', translation: 'fracasso', difficulty: 5),
      ],
      6: [
        SnapCard(english: 'government', translation: 'governo', difficulty: 6),
        SnapCard(english: 'economy', translation: 'economia', difficulty: 6),
        SnapCard(english: 'research', translation: 'investigação', difficulty: 6),
        SnapCard(english: 'challenge', translation: 'desafio', difficulty: 6),
        SnapCard(english: 'opportunity', translation: 'oportunidade', difficulty: 6),
      ],
      7: [
        SnapCard(english: 'resilience', translation: 'resiliência', difficulty: 7),
        SnapCard(english: 'perseverance', translation: 'perseverança', difficulty: 7),
        SnapCard(english: 'bureaucracy', translation: 'burocracia', difficulty: 7),
        SnapCard(english: 'contradiction', translation: 'contradição', difficulty: 7),
      ],
      8: [
        SnapCard(english: 'homesickness', translation: 'saudade', difficulty: 8),
        SnapCard(english: 'stubbornness', translation: 'teimosia', difficulty: 8),
        SnapCard(english: 'bewilderment', translation: 'perplexidade', difficulty: 8),
      ],
      9: [
        SnapCard(english: 'serendipity', translation: 'serendipidade', difficulty: 9),
        SnapCard(english: 'melancholy', translation: 'melancolia', difficulty: 9),
      ],
      10: [
        SnapCard(english: 'zeitgeist', translation: 'espírito da época', difficulty: 10),
        SnapCard(english: 'epiphany', translation: 'epifania', difficulty: 10),
      ],
    },
    'pt-BR': {
      1: [
        SnapCard(english: 'hello', translation: 'oi', difficulty: 1),
        SnapCard(english: 'goodbye', translation: 'tchau', difficulty: 1),
        SnapCard(english: 'water', translation: 'água', difficulty: 1),
        SnapCard(english: 'house', translation: 'casa', difficulty: 1),
        SnapCard(english: 'dog', translation: 'cachorro', difficulty: 1),
        SnapCard(english: 'cat', translation: 'gato', difficulty: 1),
        SnapCard(english: 'sun', translation: 'sol', difficulty: 1),
        SnapCard(english: 'moon', translation: 'lua', difficulty: 1),
        SnapCard(english: 'yes', translation: 'sim', difficulty: 1),
        SnapCard(english: 'no', translation: 'não', difficulty: 1),
      ],
      2: [
        SnapCard(english: 'mother', translation: 'mãe', difficulty: 2),
        SnapCard(english: 'father', translation: 'pai', difficulty: 2),
        SnapCard(english: 'brother', translation: 'irmão', difficulty: 2),
        SnapCard(english: 'sister', translation: 'irmã', difficulty: 2),
        SnapCard(english: 'friend', translation: 'amigo', difficulty: 2),
        SnapCard(english: 'food', translation: 'comida', difficulty: 2),
        SnapCard(english: 'book', translation: 'livro', difficulty: 2),
        SnapCard(english: 'school', translation: 'escola', difficulty: 2),
        SnapCard(english: 'happy', translation: 'feliz', difficulty: 2),
        SnapCard(english: 'sad', translation: 'triste', difficulty: 2),
      ],
      3: [
        SnapCard(english: 'beach', translation: 'praia', difficulty: 3),
        SnapCard(english: 'mountain', translation: 'montanha', difficulty: 3),
        SnapCard(english: 'river', translation: 'rio', difficulty: 3),
        SnapCard(english: 'city', translation: 'cidade', difficulty: 3),
        SnapCard(english: 'rain', translation: 'chuva', difficulty: 3),
        SnapCard(english: 'train', translation: 'trem', difficulty: 3),
        SnapCard(english: 'bus', translation: 'ônibus', difficulty: 3),
        SnapCard(english: 'phone', translation: 'celular', difficulty: 3),
        SnapCard(english: 'teacher', translation: 'professor', difficulty: 3),
        SnapCard(english: 'student', translation: 'estudante', difficulty: 3),
      ],
      4: [
        SnapCard(english: 'shoulder', translation: 'ombro', difficulty: 4),
        SnapCard(english: 'knee', translation: 'joelho', difficulty: 4),
        SnapCard(english: 'dream', translation: 'sonho', difficulty: 4),
        SnapCard(english: 'truth', translation: 'verdade', difficulty: 4),
        SnapCard(english: 'heart', translation: 'coração', difficulty: 4),
        SnapCard(english: 'airplane', translation: 'avião', difficulty: 4),
        SnapCard(english: 'bridge', translation: 'ponte', difficulty: 4),
        SnapCard(english: 'church', translation: 'igreja', difficulty: 4),
        SnapCard(english: 'library', translation: 'biblioteca', difficulty: 4),
        SnapCard(english: 'hospital', translation: 'hospital', difficulty: 4),
      ],
      5: [
        SnapCard(english: 'knowledge', translation: 'conhecimento', difficulty: 5),
        SnapCard(english: 'freedom', translation: 'liberdade', difficulty: 5),
        SnapCard(english: 'justice', translation: 'justiça', difficulty: 5),
        SnapCard(english: 'strength', translation: 'força', difficulty: 5),
        SnapCard(english: 'success', translation: 'sucesso', difficulty: 5),
        SnapCard(english: 'failure', translation: 'fracasso', difficulty: 5),
      ],
      6: [
        SnapCard(english: 'government', translation: 'governo', difficulty: 6),
        SnapCard(english: 'economy', translation: 'economia', difficulty: 6),
        SnapCard(english: 'research', translation: 'pesquisa', difficulty: 6),
        SnapCard(english: 'challenge', translation: 'desafio', difficulty: 6),
        SnapCard(english: 'opportunity', translation: 'oportunidade', difficulty: 6),
      ],
      7: [
        SnapCard(english: 'resilience', translation: 'resiliência', difficulty: 7),
        SnapCard(english: 'perseverance', translation: 'perseverança', difficulty: 7),
        SnapCard(english: 'bureaucracy', translation: 'burocracia', difficulty: 7),
        SnapCard(english: 'contradiction', translation: 'contradição', difficulty: 7),
      ],
      8: [
        SnapCard(english: 'homesickness', translation: 'saudade', difficulty: 8),
        SnapCard(english: 'stubbornness', translation: 'teimosia', difficulty: 8),
        SnapCard(english: 'bewilderment', translation: 'perplexidade', difficulty: 8),
      ],
      9: [
        SnapCard(english: 'serendipity', translation: 'serendipidade', difficulty: 9),
        SnapCard(english: 'melancholy', translation: 'melancolia', difficulty: 9),
      ],
      10: [
        SnapCard(english: 'zeitgeist', translation: 'espírito da época', difficulty: 10),
        SnapCard(english: 'epiphany', translation: 'epifania', difficulty: 10),
      ],
    },
    'en': {
      1: [
        SnapCard(english: 'hello', translation: 'hello', difficulty: 1),
        SnapCard(english: 'goodbye', translation: 'goodbye', difficulty: 1),
        SnapCard(english: 'water', translation: 'water', difficulty: 1),
        SnapCard(english: 'house', translation: 'house', difficulty: 1),
        SnapCard(english: 'dog', translation: 'dog', difficulty: 1),
        SnapCard(english: 'cat', translation: 'cat', difficulty: 1),
        SnapCard(english: 'sun', translation: 'sun', difficulty: 1),
        SnapCard(english: 'moon', translation: 'moon', difficulty: 1),
        SnapCard(english: 'yes', translation: 'yes', difficulty: 1),
        SnapCard(english: 'no', translation: 'no', difficulty: 1),
      ],
      2: [
        SnapCard(english: 'mother', translation: 'mother', difficulty: 2),
        SnapCard(english: 'father', translation: 'father', difficulty: 2),
        SnapCard(english: 'friend', translation: 'friend', difficulty: 2),
        SnapCard(english: 'happy', translation: 'happy', difficulty: 2),
        SnapCard(english: 'sad', translation: 'sad', difficulty: 2),
      ],
      3: [SnapCard(english: 'adventure', translation: 'adventure', difficulty: 3)],
      4: [SnapCard(english: 'imagination', translation: 'imagination', difficulty: 4)],
      5: [SnapCard(english: 'accomplishment', translation: 'accomplishment', difficulty: 5)],
      6: [SnapCard(english: 'infrastructure', translation: 'infrastructure', difficulty: 6)],
      7: [SnapCard(english: 'quintessential', translation: 'quintessential', difficulty: 7)],
      8: [SnapCard(english: 'ephemeral', translation: 'ephemeral', difficulty: 8)],
      9: [SnapCard(english: 'sesquipedalian', translation: 'sesquipedalian', difficulty: 9)],
      10: [SnapCard(english: 'antediluvian', translation: 'antediluvian', difficulty: 10)],
    },
  };

  // ============================================================
  // LANGUAGE TAPPLES - Category-based word naming with letter constraints
  // Map<language, Map<category, Map<letter, List<words>>>>
  // 10 categories, words for letters A-Z per language
  // ============================================================

  static const Map<String, Map<String, Map<String, List<String>>>> tapplesWords = {
    'es': {
      'Animals': {
        'A': ['águila', 'araña', 'abeja', 'armadillo'], 'B': ['ballena', 'burro', 'búfalo'], 'C': ['caballo', 'conejo', 'ciervo', 'cocodrilo'],
        'D': ['delfín', 'dinosaurio'], 'E': ['elefante', 'escorpión'], 'F': ['foca', 'flamenco'], 'G': ['gato', 'gorila', 'gallina'],
        'H': ['hormiga', 'halcón', 'hipopótamo'], 'I': ['iguana', 'insecto'], 'J': ['jaguar', 'jabalí'], 'K': ['koala'],
        'L': ['león', 'lobo', 'lagarto', 'liebre'], 'M': ['mono', 'mariposa', 'murciélago'], 'N': ['nutria', 'narval'],
        'O': ['oso', 'oveja', 'orangután'], 'P': ['perro', 'pato', 'pantera', 'pulpo'], 'Q': ['quetzal'],
        'R': ['rana', 'ratón', 'rinoceronte'], 'S': ['serpiente', 'salamandra'], 'T': ['tortuga', 'tigre', 'tiburón'],
        'U': ['unicornio', 'urraca'], 'V': ['vaca', 'víbora'], 'Z': ['zorro', 'zebra'],
      },
      'Food': {
        'A': ['arroz', 'aguacate', 'almendra'], 'B': ['banana', 'burrito', 'brócoli'], 'C': ['cereza', 'chocolate', 'carne'],
        'D': ['durazno', 'dátil'], 'E': ['ensalada', 'espinaca'], 'F': ['fresa', 'frijol'], 'G': ['galleta', 'guisante'],
        'H': ['helado', 'huevo'], 'J': ['jamón', 'jalea'], 'K': ['kiwi'], 'L': ['limón', 'lechuga', 'lentejas'],
        'M': ['mango', 'manzana', 'maíz'], 'N': ['naranja', 'nuez'], 'O': ['oliva', 'ostras'], 'P': ['pan', 'papa', 'pollo'],
        'Q': ['queso', 'quinoa'], 'R': ['rábano', 'remolacha'], 'S': ['sopa', 'sandía'], 'T': ['tomate', 'tortilla'],
        'U': ['uva'], 'V': ['vainilla', 'vinagre'], 'Y': ['yogur'], 'Z': ['zanahoria', 'zapallo'],
      },
      'Colors': {
        'A': ['amarillo', 'azul', 'ámbar'], 'B': ['blanco', 'beige'], 'C': ['celeste', 'carmesí', 'coral'],
        'D': ['dorado'], 'E': ['escarlata', 'esmeralda'], 'F': ['fucsia'], 'G': ['gris', 'granate'],
        'I': ['índigo'], 'J': ['jade'], 'L': ['lila', 'lavanda'], 'M': ['marrón', 'magenta', 'mostaza'],
        'N': ['naranja', 'negro'], 'O': ['ocre', 'oliva'], 'P': ['plateado', 'púrpura'], 'R': ['rojo', 'rosado'],
        'S': ['salmón'], 'T': ['turquesa'], 'V': ['verde', 'violeta'],
      },
      'Countries': {
        'A': ['Argentina', 'Alemania', 'Australia'], 'B': ['Brasil', 'Bolivia', 'Bélgica'], 'C': ['Colombia', 'Chile', 'Cuba', 'Canadá'],
        'D': ['Dinamarca'], 'E': ['España', 'Ecuador', 'Egipto'], 'F': ['Francia', 'Finlandia'], 'G': ['Guatemala', 'Grecia'],
        'H': ['Honduras', 'Hungría'], 'I': ['Italia', 'Irlanda', 'India'], 'J': ['Japón', 'Jamaica'], 'K': ['Kenia'],
        'L': ['Luxemburgo'], 'M': ['México', 'Marruecos'], 'N': ['Nicaragua', 'Noruega', 'Nigeria'], 'P': ['Perú', 'Portugal', 'Panamá'],
        'R': ['Rusia', 'Rumania'], 'S': ['Suecia', 'Suiza'], 'T': ['Turquía', 'Tailandia'], 'U': ['Uruguay'],
        'V': ['Venezuela', 'Vietnam'],
      },
      'Jobs': {
        'A': ['abogado', 'arquitecto', 'actor'], 'B': ['bombero', 'biólogo'], 'C': ['cocinero', 'carpintero', 'cantante'],
        'D': ['dentista', 'diseñador', 'director'], 'E': ['enfermero', 'electricista', 'escritor'], 'F': ['fotógrafo', 'farmacéutico'],
        'G': ['gerente', 'granjero'], 'I': ['ingeniero', 'instructor'], 'J': ['jardinero', 'juez'], 'M': ['maestro', 'mecánico', 'médico'],
        'N': ['nutricionista'], 'P': ['piloto', 'policía', 'profesor', 'periodista'], 'S': ['soldado', 'secretario'],
        'T': ['taxista', 'técnico'], 'V': ['veterinario', 'vendedor'],
      },
      'Sports': {
        'A': ['atletismo', 'ajedrez'], 'B': ['baloncesto', 'boxeo', 'béisbol'], 'C': ['ciclismo', 'cricket'],
        'E': ['esgrima', 'escalada'], 'F': ['fútbol'], 'G': ['golf', 'gimnasia'], 'H': ['hockey'],
        'J': ['judo'], 'K': ['karate'], 'N': ['natación'], 'P': ['polo', 'patinaje'],
        'R': ['rugby', 'remo'], 'S': ['surf', 'squash'], 'T': ['tenis', 'taekwondo'], 'V': ['voleibol', 'vela'],
      },
      'Clothes': {
        'A': ['abrigo'], 'B': ['blusa', 'bufanda', 'botas'], 'C': ['camisa', 'corbata', 'cinturón', 'camiseta', 'chaqueta'],
        'F': ['falda'], 'G': ['gorro', 'guante'], 'J': ['jersey', 'jeans'], 'M': ['medias'],
        'P': ['pantalón', 'pijama'], 'R': ['ropa interior'], 'S': ['sombrero', 'suéter', 'sandalias'],
        'T': ['traje'], 'V': ['vestido'], 'Z': ['zapato', 'zapatillas'],
      },
      'Nature': {
        'A': ['arroyo', 'arbusto', 'arena'], 'B': ['bosque', 'bahía'], 'C': ['cascada', 'colina', 'cueva'],
        'D': ['desierto', 'dunas'], 'E': ['estrella'], 'F': ['flor', 'fuente'], 'H': ['hoja', 'hierba'],
        'I': ['isla'], 'J': ['jungla'], 'L': ['lago', 'lluvia', 'luna'], 'M': ['montaña', 'mar', 'musgo'],
        'N': ['nube', 'nieve'], 'O': ['océano', 'ola'], 'P': ['playa', 'pradera', 'piedra'], 'R': ['río', 'roca', 'raíz'],
        'S': ['selva', 'sol'], 'T': ['trueno', 'tormenta'], 'V': ['volcán', 'valle', 'viento'],
      },
      'Family': {
        'A': ['abuelo', 'abuela'], 'B': ['bisabuelo'], 'C': ['cuñado', 'cuñada', 'compadre'],
        'E': ['esposo', 'esposa'], 'H': ['hermano', 'hermana', 'hijo', 'hija'], 'M': ['madre', 'madrina', 'marido'],
        'N': ['nieto', 'nieta', 'novio', 'novia', 'nuera'], 'P': ['padre', 'padrino', 'primo', 'prima'],
        'S': ['sobrino', 'sobrina', 'suegro', 'suegra'], 'T': ['tío', 'tía'], 'Y': ['yerno'],
      },
      'Music': {
        'A': ['arpa', 'acordeón'], 'B': ['batería', 'bajo', 'bandoneón'], 'C': ['clarinete', 'contrabajo', 'cello'],
        'F': ['flauta'], 'G': ['guitarra', 'gaita'], 'M': ['maracas', 'mandolina'], 'O': ['oboe', 'órgano'],
        'P': ['piano', 'percusión'], 'S': ['saxofón', 'sintetizador'], 'T': ['trompeta', 'trombón', 'tambor', 'tuba'],
        'U': ['ukelele'], 'V': ['violín', 'viola', 'violonchelo'], 'X': ['xilófono'],
      },
    },
    'fr': {
      'Animals': {
        'A': ['aigle', 'araignée', 'abeille'], 'B': ['baleine', 'bison'], 'C': ['chat', 'cheval', 'cerf', 'crocodile'],
        'D': ['dauphin', 'dindon'], 'E': ['éléphant', 'escargot'], 'F': ['fourmi', 'faucon'], 'G': ['grenouille', 'gorille'],
        'H': ['hamster', 'hippopotame'], 'I': ['iguane', 'insecte'], 'J': ['jaguar'], 'K': ['koala'],
        'L': ['lion', 'loup', 'lézard'], 'M': ['mouton', 'moustique'], 'N': ['narval'],
        'O': ['ours', 'oie'], 'P': ['perroquet', 'papillon', 'poisson'], 'R': ['rat', 'renard'],
        'S': ['serpent', 'singe'], 'T': ['tortue', 'tigre'], 'V': ['vache', 'vipère'], 'Z': ['zèbre'],
      },
      'Food': {
        'A': ['ananas', 'abricot', 'amande'], 'B': ['banane', 'beurre', 'brocoli'], 'C': ['cerise', 'chocolat', 'carotte'],
        'D': ['datte'], 'E': ['épinard'], 'F': ['fraise', 'fromage', 'figue'], 'G': ['gâteau'],
        'H': ['haricot'], 'J': ['jambon'], 'K': ['kiwi'], 'L': ['lait', 'laitue', 'lentilles'],
        'M': ['mangue', 'melon', 'maïs'], 'N': ['noisette', 'noix'], 'O': ['olive', 'orange'], 'P': ['pain', 'pomme', 'poulet'],
        'R': ['raisin', 'riz'], 'S': ['soupe', 'salade'], 'T': ['tomate', 'tarte'],
        'V': ['vanille', 'vinaigre'], 'Y': ['yaourt'],
      },
      'Colors': {
        'A': ['argent', 'azur'], 'B': ['blanc', 'bleu', 'beige', 'brun'], 'C': ['corail', 'crème'],
        'D': ['doré'], 'E': ['émeraude', 'écarlate'], 'F': ['fuchsia'], 'G': ['gris', 'grenat'],
        'I': ['indigo', 'ivoire'], 'J': ['jaune', 'jade'], 'L': ['lavande', 'lilas'], 'M': ['magenta', 'marron', 'moutarde'],
        'N': ['noir'], 'O': ['orange', 'ocre', 'or'], 'P': ['pourpre'], 'R': ['rouge', 'rose'],
        'S': ['saumon'], 'T': ['turquoise'], 'V': ['vert', 'violet', 'vermillon'],
      },
      'Countries': {
        'A': ['Argentine', 'Allemagne', 'Australie', 'Algérie'], 'B': ['Brésil', 'Belgique', 'Bolivie'],
        'C': ['Canada', 'Chili', 'Chine', 'Colombie', 'Cuba'], 'D': ['Danemark'], 'E': ['Espagne', 'Équateur', 'Égypte'],
        'F': ['France', 'Finlande'], 'G': ['Grèce', 'Guatemala'], 'H': ['Hongrie', 'Honduras'], 'I': ['Italie', 'Inde', 'Irlande'],
        'J': ['Japon', 'Jamaïque'], 'K': ['Kenya'], 'L': ['Luxembourg'], 'M': ['Mexique', 'Maroc'],
        'N': ['Norvège', 'Nigeria'], 'P': ['Portugal', 'Pérou', 'Panama'], 'R': ['Russie', 'Roumanie'],
        'S': ['Suède', 'Suisse'], 'T': ['Turquie', 'Thaïlande'], 'U': ['Uruguay'], 'V': ['Venezuela', 'Vietnam'],
      },
      'Jobs': {
        'A': ['avocat', 'architecte', 'acteur'], 'B': ['boulanger', 'biologiste'], 'C': ['cuisinier', 'chanteur', 'coiffeur'],
        'D': ['dentiste', 'directeur'], 'E': ['enseignant', 'électricien', 'écrivain'], 'F': ['photographe', 'fermier'],
        'I': ['ingénieur', 'infirmier'], 'J': ['jardinier', 'juge'], 'M': ['médecin', 'mécanicien'],
        'P': ['pilote', 'policier', 'professeur'], 'S': ['soldat', 'secrétaire'], 'V': ['vétérinaire', 'vendeur'],
      },
      'Sports': {
        'A': ['athlétisme'], 'B': ['basket', 'boxe', 'baseball'], 'C': ['cyclisme', 'cricket'],
        'E': ['escrime', 'escalade'], 'F': ['football'], 'G': ['golf', 'gymnastique'], 'H': ['hockey'],
        'J': ['judo'], 'K': ['karaté'], 'N': ['natation'], 'P': ['polo', 'patinage'],
        'R': ['rugby'], 'S': ['surf', 'squash'], 'T': ['tennis', 'taekwondo'], 'V': ['volleyball', 'voile'],
      },
      'Clothes': {
        'B': ['blouson', 'bonnet', 'bottes'], 'C': ['chemise', 'chapeau', 'cravate', 'chaussette', 'casquette'],
        'E': ['écharpe'], 'G': ['gant'], 'J': ['jupe', 'jean'], 'M': ['manteau', 'maillot'],
        'P': ['pantalon', 'pull', 'pyjama'], 'R': ['robe'], 'S': ['sandales'], 'T': ['t-shirt'],
        'V': ['veste'], 'Z': ['zip'],
      },
      'Nature': {
        'A': ['arbre', 'arc-en-ciel'], 'B': ['baie', 'bois'], 'C': ['cascade', 'colline', 'caverne'],
        'D': ['désert', 'dune'], 'E': ['étoile'], 'F': ['fleur', 'forêt', 'feuille'], 'H': ['herbe'],
        'I': ['île'], 'J': ['jungle'], 'L': ['lac', 'lune'], 'M': ['montagne', 'mer', 'mousse'],
        'N': ['nuage', 'neige'], 'O': ['océan'], 'P': ['plage', 'prairie', 'pierre'], 'R': ['rivière', 'rocher'],
        'S': ['soleil'], 'T': ['tonnerre', 'tempête'], 'V': ['volcan', 'vallée', 'vent'],
      },
      'Family': {
        'B': ['beau-père', 'belle-mère'], 'C': ['cousin', 'cousine'], 'E': ['époux', 'épouse'],
        'F': ['frère', 'fille', 'fils'], 'G': ['grand-père', 'grand-mère'], 'M': ['mère', 'mari'],
        'N': ['neveu', 'nièce'], 'O': ['oncle'], 'P': ['père'], 'S': ['soeur'],
        'T': ['tante'],
      },
      'Music': {
        'A': ['accordéon'], 'B': ['batterie', 'basse', 'banjo'], 'C': ['clarinette', 'contrebasse'],
        'F': ['flûte'], 'G': ['guitare'], 'H': ['harmonica', 'harpe'], 'M': ['mandoline'],
        'O': ['orgue', 'hautbois'], 'P': ['piano', 'percussion'], 'S': ['saxophone', 'synthétiseur'],
        'T': ['trompette', 'trombone', 'tambour', 'tuba'], 'V': ['violon', 'violoncelle'], 'X': ['xylophone'],
      },
    },
    'de': {
      'Animals': {
        'A': ['Adler', 'Ameise', 'Affe'], 'B': ['Bär', 'Biene', 'Büffel'], 'D': ['Delfin', 'Dachs'],
        'E': ['Elefant', 'Eichhörnchen', 'Ente'], 'F': ['Frosch', 'Fuchs', 'Flamingo'], 'G': ['Giraffe', 'Gorilla'],
        'H': ['Hund', 'Hase', 'Hirsch'], 'I': ['Igel'], 'J': ['Jaguar'], 'K': ['Katze', 'Kaninchen', 'Krokodil'],
        'L': ['Löwe', 'Leopard'], 'M': ['Maus', 'Murmeltier'], 'N': ['Nashorn'],
        'O': ['Otter'], 'P': ['Papagei', 'Pferd', 'Pinguin'], 'R': ['Rabe'],
        'S': ['Schlange', 'Schmetterling', 'Spinne'], 'T': ['Tiger'], 'U': ['Uhu'],
        'V': ['Vogel'], 'W': ['Wolf', 'Wal'], 'Z': ['Zebra'],
      },
      'Food': {
        'A': ['Apfel', 'Ananas'], 'B': ['Banane', 'Brot', 'Butter', 'Birne'], 'E': ['Ei', 'Erdbeere'],
        'F': ['Fisch'], 'G': ['Gurke'], 'H': ['Honig', 'Hähnchen'], 'J': ['Joghurt'],
        'K': ['Kartoffel', 'Käse', 'Kirsche', 'Kiwi'], 'L': ['Limone'], 'M': ['Milch', 'Mandel', 'Mais'],
        'N': ['Nudel', 'Nuss'], 'O': ['Orange', 'Olive'], 'P': ['Pizza', 'Pfirsich'],
        'R': ['Reis', 'Rosine'], 'S': ['Salat', 'Suppe', 'Schokolade'], 'T': ['Tomate', 'Torte'],
        'W': ['Wurst', 'Wassermelone'], 'Z': ['Zucker', 'Zitrone', 'Zwiebel'],
      },
      'Colors': {
        'B': ['Blau', 'Braun', 'Beige'], 'G': ['Gelb', 'Gold', 'Grau', 'Grün'],
        'I': ['Indigo'], 'K': ['Koralle', 'Kupfer'], 'L': ['Lila', 'Lavendel'],
        'M': ['Magenta'], 'O': ['Orange'], 'R': ['Rot', 'Rosa'],
        'S': ['Schwarz', 'Silber', 'Smaragd'], 'T': ['Türkis'], 'W': ['Weiß'],
      },
      'Countries': {
        'A': ['Argentinien', 'Australien', 'Ägypten'], 'B': ['Brasilien', 'Belgien', 'Bolivien'],
        'C': ['Chile', 'China'], 'D': ['Deutschland', 'Dänemark'], 'E': ['Ecuador'],
        'F': ['Frankreich', 'Finnland'], 'G': ['Griechenland', 'Guatemala'], 'I': ['Italien', 'Indien', 'Irland'],
        'J': ['Japan', 'Jamaika'], 'K': ['Kanada', 'Kenia', 'Kolumbien', 'Kuba'], 'L': ['Luxemburg'],
        'M': ['Mexiko', 'Marokko'], 'N': ['Norwegen', 'Nigeria'], 'P': ['Portugal', 'Peru', 'Panama', 'Polen'],
        'R': ['Russland', 'Rumänien'], 'S': ['Schweden', 'Schweiz', 'Spanien'], 'T': ['Türkei', 'Thailand'],
        'U': ['Uruguay', 'Ungarn'], 'V': ['Venezuela', 'Vietnam'], 'Ö': ['Österreich'],
      },
      'Jobs': {
        'A': ['Anwalt', 'Architekt', 'Arzt'], 'B': ['Bäcker', 'Biologe'], 'D': ['Direktor', 'Designer'],
        'E': ['Elektriker'], 'F': ['Feuerwehrmann', 'Fotograf'], 'I': ['Ingenieur'],
        'K': ['Koch', 'Krankenschwester'], 'L': ['Lehrer'], 'M': ['Mechaniker', 'Musiker'],
        'P': ['Pilot', 'Polizist', 'Professor'], 'R': ['Richter'], 'S': ['Soldat', 'Sekretär'],
        'T': ['Taxifahrer', 'Tierarzt'],
      },
      'Sports': {
        'B': ['Basketball', 'Boxen', 'Baseball'], 'E': ['Eishockey'],
        'F': ['Fußball', 'Fechten'], 'G': ['Golf', 'Gymnastik'], 'H': ['Handball', 'Hockey'],
        'J': ['Judo'], 'K': ['Karate', 'Klettern'], 'L': ['Leichtathletik'],
        'R': ['Radfahren', 'Rugby', 'Rudern'], 'S': ['Schwimmen', 'Surfen', 'Squash', 'Segeln', 'Skifahren'],
        'T': ['Tennis', 'Taekwondo', 'Tischtennis'], 'V': ['Volleyball'],
      },
      'Clothes': {
        'A': ['Anzug'], 'B': ['Bluse'], 'G': ['Gürtel'], 'H': ['Handschuh', 'Hemd', 'Hose', 'Hut'],
        'J': ['Jacke', 'Jeans'], 'K': ['Kleid', 'Krawatte'], 'M': ['Mantel', 'Mütze'],
        'P': ['Pullover', 'Pyjama'], 'R': ['Rock'], 'S': ['Schal', 'Schuh', 'Socke', 'Stiefel', 'Sandalen'],
        'T': ['T-Shirt'],
      },
      'Nature': {
        'B': ['Bach', 'Berg', 'Busch', 'Bucht'], 'D': ['Düne'], 'E': ['Erde'],
        'F': ['Fluss', 'Feld', 'Fels'], 'G': ['Gras'], 'H': ['Hügel', 'Höhle'],
        'I': ['Insel'], 'L': ['See', 'Lichtung'], 'M': ['Meer', 'Mond', 'Moos'],
        'O': ['Ozean'], 'R': ['Regen'], 'S': ['Sonne', 'Sand', 'Schnee', 'Stern', 'Strand', 'Sturm'],
        'T': ['Tal'], 'V': ['Vulkan'], 'W': ['Wald', 'Welle', 'Wind', 'Wolke', 'Wasserfall'],
      },
      'Family': {
        'B': ['Bruder'], 'E': ['Ehemann', 'Ehefrau', 'Eltern', 'Enkel', 'Enkelin'],
        'G': ['Großvater', 'Großmutter'], 'K': ['Kind', 'Kusine', 'Cousin'],
        'M': ['Mutter'], 'N': ['Neffe', 'Nichte'], 'O': ['Onkel', 'Oma', 'Opa'],
        'S': ['Schwester', 'Schwager', 'Schwägerin', 'Sohn', 'Schwiegermutter', 'Schwiegervater'],
        'T': ['Tante', 'Tochter'], 'V': ['Vater'],
      },
      'Music': {
        'A': ['Akkordeon'], 'B': ['Bass'], 'C': ['Cello'],
        'F': ['Flöte'], 'G': ['Gitarre', 'Geige'], 'H': ['Harfe', 'Harmonika'],
        'K': ['Klavier', 'Klarinette', 'Kontrabass'], 'M': ['Mandoline'],
        'O': ['Orgel', 'Oboe'], 'P': ['Pauke'],
        'S': ['Saxophon', 'Schlagzeug', 'Synthesizer'], 'T': ['Trompete', 'Trommel', 'Tuba'],
        'V': ['Violine'], 'X': ['Xylophon'],
      },
    },
    'it': {
      'Animals': {
        'A': ['aquila', 'ape', 'asino'], 'B': ['balena', 'bisonte'], 'C': ['cavallo', 'coniglio', 'cervo', 'coccodrillo', 'cane'],
        'D': ['delfino'], 'E': ['elefante'], 'F': ['farfalla', 'formica', 'fenicottero'], 'G': ['gatto', 'gorilla', 'gallina'],
        'I': ['iguana'], 'J': ['jaguar'], 'K': ['koala'],
        'L': ['leone', 'lupo', 'lucertola', 'lepre'], 'M': ['mucca', 'maiale', 'mosca'], 'O': ['orso', 'oca'],
        'P': ['pappagallo', 'pinguino', 'polpo'], 'R': ['rana', 'rinoceronte'],
        'S': ['serpente', 'scimmia', 'squalo'], 'T': ['tartaruga', 'tigre', 'topo'],
        'U': ['uccello', 'usignolo'], 'V': ['volpe', 'vipera'], 'Z': ['zebra', 'zanzara'],
      },
      'Food': {
        'A': ['arancia', 'aglio', 'ananas'], 'B': ['banana', 'burro', 'biscotto'], 'C': ['ciliegia', 'cioccolato', 'carne', 'carota'],
        'F': ['fragola', 'formaggio', 'fico'], 'G': ['gelato'], 'I': ['insalata'],
        'K': ['kiwi'], 'L': ['limone', 'latte', 'lattuga'], 'M': ['mango', 'mela', 'mais'],
        'N': ['noce'], 'O': ['oliva'], 'P': ['pane', 'pasta', 'pollo', 'pesca', 'pizza'],
        'R': ['riso', 'ravanello'], 'S': ['spaghetti', 'sugo', 'spinaci'], 'T': ['tomate', 'torta'],
        'U': ['uva', 'uovo'], 'V': ['vaniglia', 'vino'], 'Y': ['yogurt'], 'Z': ['zucchero', 'zucchina'],
      },
      'Colors': {
        'A': ['arancione', 'azzurro', 'ambra'], 'B': ['bianco', 'blu', 'beige'],
        'C': ['corallo', 'crema'], 'D': ['dorato'], 'G': ['giallo', 'grigio'],
        'I': ['indaco'], 'L': ['lilla', 'lavanda'], 'M': ['marrone', 'magenta'],
        'N': ['nero'], 'O': ['oro', 'ocra'], 'R': ['rosso', 'rosa'],
        'S': ['smeraldo'], 'T': ['turchese'], 'V': ['verde', 'viola', 'vermiglio'],
      },
      'Countries': {
        'A': ['Argentina', 'Australia', 'Austria'], 'B': ['Brasile', 'Belgio', 'Bolivia'],
        'C': ['Canada', 'Cile', 'Cina', 'Colombia', 'Cuba'], 'D': ['Danimarca'],
        'E': ['Egitto', 'Ecuador'], 'F': ['Francia', 'Finlandia'], 'G': ['Germania', 'Grecia', 'Giappone', 'Guatemala'],
        'I': ['Italia', 'India', 'Irlanda'], 'K': ['Kenya'],
        'L': ['Lussemburgo'], 'M': ['Messico', 'Marocco'], 'N': ['Norvegia', 'Nigeria'],
        'P': ['Portogallo', 'Perù', 'Panama', 'Polonia'], 'R': ['Russia', 'Romania'],
        'S': ['Spagna', 'Svezia', 'Svizzera'], 'T': ['Turchia', 'Thailandia'],
        'U': ['Ungheria', 'Uruguay'], 'V': ['Venezuela', 'Vietnam'],
      },
      'Jobs': {
        'A': ['avvocato', 'architetto', 'attore'], 'B': ['biologo'], 'C': ['cuoco', 'cantante'],
        'D': ['dentista', 'direttore'], 'E': ['elettricista'], 'F': ['fotografo', 'farmacista'],
        'G': ['giardiniere', 'giudice'], 'I': ['ingegnere', 'infermiere', 'insegnante'],
        'M': ['medico', 'meccanico', 'musicista'], 'P': ['pilota', 'poliziotto', 'professore'],
        'S': ['soldato', 'segretario', 'scrittore'], 'V': ['veterinario', 'venditore'],
      },
      'Sports': {
        'A': ['atletica'], 'B': ['basket', 'boxe', 'baseball'], 'C': ['ciclismo', 'calcio', 'cricket'],
        'G': ['golf', 'ginnastica'], 'H': ['hockey'], 'J': ['judo'],
        'K': ['karate'], 'N': ['nuoto'], 'P': ['pallavolo', 'pattinaggio', 'polo'],
        'R': ['rugby'], 'S': ['scherma', 'surf', 'sci'], 'T': ['tennis', 'taekwondo'],
        'V': ['vela'],
      },
      'Clothes': {
        'B': ['berretto', 'borsa'], 'C': ['camicia', 'cappello', 'cintura', 'calzino', 'cravatta'],
        'G': ['giacca', 'gonna', 'guanto'], 'J': ['jeans'],
        'M': ['maglietta', 'maglione', 'manteau'], 'P': ['pantaloni', 'pigiama'],
        'S': ['scarpa', 'sciarpa', 'sandali', 'stivali'], 'V': ['vestito'],
      },
      'Nature': {
        'A': ['albero', 'arcobaleno'], 'B': ['bosco', 'baia'], 'C': ['cascata', 'collina', 'caverna'],
        'D': ['deserto', 'duna'], 'F': ['fiore', 'foglia', 'fonte'], 'G': ['giungla'],
        'I': ['isola'], 'L': ['lago', 'luna'], 'M': ['montagna', 'mare', 'muschio'],
        'N': ['nuvola', 'neve'], 'O': ['oceano', 'onda'], 'P': ['pianura', 'pietra', 'prato', 'pioggia'],
        'R': ['ruscello', 'roccia'], 'S': ['sole', 'stella', 'sabbia'],
        'T': ['tuono', 'tempesta'], 'V': ['vulcano', 'valle', 'vento'],
      },
      'Family': {
        'C': ['cugino', 'cugina', 'cognato', 'cognata'], 'F': ['fratello', 'figlio', 'figlia'],
        'G': ['genero'], 'M': ['madre', 'marito', 'moglie'], 'N': ['nonno', 'nonna', 'nipote', 'nuora'],
        'P': ['padre'], 'S': ['sorella', 'suocero', 'suocera'], 'Z': ['zia', 'zio'],
      },
      'Music': {
        'A': ['arpa', 'armonica', 'fisarmonica'], 'B': ['basso', 'batteria'],
        'C': ['clarinetto', 'contrabbasso', 'chitarra'], 'F': ['flauto'],
        'M': ['mandolino'], 'O': ['oboe', 'organo'], 'P': ['pianoforte', 'percussione'],
        'S': ['sassofono', 'sintetizzatore'], 'T': ['tromba', 'trombone', 'tamburo', 'tuba'],
        'U': ['ukulele'], 'V': ['violino', 'viola', 'violoncello'], 'X': ['xilofono'],
      },
    },
    'pt': {
      'Animals': {
        'A': ['águia', 'abelha', 'aranha'], 'B': ['baleia', 'búfalo'], 'C': ['cavalo', 'coelho', 'cão', 'crocodilo'],
        'D': ['golfinho'], 'E': ['elefante', 'escorpião'], 'F': ['foca', 'formiga', 'flamingo'],
        'G': ['gato', 'gorila', 'galinha'], 'H': ['hipopótamo'], 'I': ['iguana'], 'J': ['jaguar'],
        'K': ['koala'], 'L': ['leão', 'lobo', 'lagarto'], 'M': ['macaco', 'mosca'],
        'O': ['ovelha', 'urso'], 'P': ['papagaio', 'pato', 'pinguim'], 'R': ['rato', 'raposa'],
        'S': ['serpente'], 'T': ['tartaruga', 'tigre', 'tubarão'],
        'V': ['vaca', 'víbora'], 'Z': ['zebra'],
      },
      'Food': {
        'A': ['arroz', 'abacate', 'amêndoa', 'alho'], 'B': ['banana', 'batata'], 'C': ['cereja', 'cenoura', 'carne', 'chocolate'],
        'F': ['morango', 'figo'], 'G': ['gelado'], 'K': ['kiwi'],
        'L': ['limão', 'leite', 'lentilha'], 'M': ['manga', 'maçã', 'milho'],
        'N': ['noz'], 'O': ['azeitona', 'laranja'], 'P': ['pão', 'pêssego', 'frango'],
        'Q': ['queijo'], 'R': ['rabanete'], 'S': ['sopa', 'salada'],
        'T': ['tomate'], 'U': ['uva'], 'V': ['vinho', 'vinagre'], 'Y': ['iogurte'],
      },
      'Colors': {
        'A': ['amarelo', 'azul', 'âmbar'], 'B': ['branco', 'bege'], 'C': ['castanho', 'coral', 'creme', 'cinzento'],
        'D': ['dourado'], 'E': ['escarlate', 'esmeralda'], 'F': ['fúcsia'],
        'I': ['índigo'], 'J': ['jade'], 'L': ['lilás', 'lavanda'],
        'M': ['magenta'], 'N': ['negro'], 'P': ['prateado', 'preto', 'púrpura'],
        'R': ['rosa', 'roxo', 'vermelho'], 'T': ['turquesa'], 'V': ['verde', 'violeta'],
      },
      'Countries': {
        'A': ['Argentina', 'Alemanha', 'Austrália', 'Angola'], 'B': ['Brasil', 'Bélgica', 'Bolívia'],
        'C': ['Canadá', 'Chile', 'China', 'Colômbia', 'Cuba'], 'D': ['Dinamarca'],
        'E': ['Espanha', 'Equador', 'Egito'], 'F': ['França', 'Finlândia'], 'G': ['Grécia', 'Guatemala'],
        'I': ['Itália', 'Índia', 'Irlanda'], 'J': ['Japão', 'Jamaica'], 'K': ['Quénia'],
        'L': ['Luxemburgo'], 'M': ['México', 'Marrocos', 'Moçambique'], 'N': ['Noruega', 'Nigéria'],
        'P': ['Portugal', 'Peru', 'Panamá', 'Polónia'], 'R': ['Rússia', 'Roménia'],
        'S': ['Suécia', 'Suíça'], 'T': ['Turquia', 'Tailândia', 'Timor-Leste'], 'U': ['Uruguai'],
        'V': ['Venezuela', 'Vietname'],
      },
      'Jobs': {
        'A': ['advogado', 'arquiteto', 'ator'], 'B': ['biólogo', 'bombeiro'], 'C': ['cozinheiro', 'cantor'],
        'D': ['dentista', 'diretor'], 'E': ['enfermeiro', 'eletricista', 'escritor'], 'F': ['fotógrafo', 'farmacêutico'],
        'I': ['engenheiro'], 'J': ['jardineiro', 'juiz'], 'M': ['médico', 'mecânico'],
        'P': ['piloto', 'polícia', 'professor'], 'S': ['soldado', 'secretário'],
        'V': ['veterinário', 'vendedor'],
      },
      'Sports': {
        'A': ['atletismo'], 'B': ['basquetebol', 'boxe'], 'C': ['ciclismo', 'críquete'],
        'E': ['esgrima', 'escalada'], 'F': ['futebol'], 'G': ['golfe', 'ginástica'], 'H': ['hóquei'],
        'J': ['judo'], 'K': ['karaté'], 'N': ['natação'],
        'R': ['râguebi', 'remo'], 'S': ['surf', 'squash'], 'T': ['ténis', 'taekwondo'], 'V': ['voleibol', 'vela'],
      },
      'Clothes': {
        'B': ['blusa', 'botas'], 'C': ['camisa', 'cachecol', 'casaco', 'camisola', 'calças'],
        'G': ['gorro', 'gravata', 'luva'], 'J': ['jeans'], 'M': ['meias'],
        'P': ['pijama'], 'S': ['saia', 'sapato', 'sandálias'],
        'V': ['vestido'],
      },
      'Nature': {
        'A': ['árvore', 'arco-íris', 'areia'], 'B': ['bosque', 'baía'], 'C': ['cascata', 'colina', 'caverna'],
        'D': ['deserto', 'duna'], 'E': ['estrela'], 'F': ['flor', 'floresta', 'folha'],
        'I': ['ilha'], 'L': ['lago', 'lua'], 'M': ['montanha', 'mar', 'musgo'],
        'N': ['nuvem', 'neve'], 'O': ['oceano', 'onda'], 'P': ['praia', 'pradaria', 'pedra'],
        'R': ['rio', 'rocha'], 'S': ['sol'], 'T': ['trovão', 'tempestade'], 'V': ['vulcão', 'vale', 'vento'],
      },
      'Family': {
        'A': ['avô', 'avó'], 'C': ['cunhado', 'cunhada'], 'E': ['esposo', 'esposa'],
        'F': ['filho', 'filha'], 'I': ['irmão', 'irmã'], 'M': ['mãe', 'marido'],
        'N': ['neto', 'neta', 'nora'], 'P': ['pai', 'primo', 'prima'],
        'S': ['sobrinho', 'sobrinha', 'sogro', 'sogra'], 'T': ['tio', 'tia'],
      },
      'Music': {
        'A': ['acordeão'], 'B': ['bateria', 'baixo'], 'C': ['clarinete', 'contrabaixo'],
        'F': ['flauta'], 'G': ['guitarra'], 'H': ['harpa', 'harmónica'],
        'O': ['oboé', 'órgão'], 'P': ['piano', 'percussão'],
        'S': ['saxofone', 'sintetizador'], 'T': ['trompete', 'trombone', 'tambor', 'tuba'],
        'V': ['violino', 'viola', 'violoncelo'], 'X': ['xilofone'],
      },
    },
    'pt-BR': {
      'Animals': {
        'A': ['águia', 'abelha', 'aranha'], 'B': ['baleia', 'búfalo'], 'C': ['cavalo', 'coelho', 'cachorro', 'jacaré'],
        'D': ['golfinho'], 'E': ['elefante', 'escorpião'], 'F': ['foca', 'formiga', 'flamingo'],
        'G': ['gato', 'gorila', 'galinha'], 'H': ['hipopótamo'], 'I': ['iguana'], 'J': ['jaguar', 'jaguatirica'],
        'K': ['coala'], 'L': ['leão', 'lobo', 'lagarto'], 'M': ['macaco', 'mosca', 'mico'],
        'O': ['ovelha', 'onça'], 'P': ['papagaio', 'pato', 'pinguim', 'periquito'], 'R': ['rato', 'raposa'],
        'S': ['cobra', 'sapo'], 'T': ['tartaruga', 'tigre', 'tubarão', 'tucano'],
        'V': ['vaca'], 'Z': ['zebra'],
      },
      'Food': {
        'A': ['arroz', 'abacate', 'abacaxi', 'açaí', 'amendoim'], 'B': ['banana', 'batata', 'brigadeiro', 'biscoito'],
        'C': ['cereja', 'cenoura', 'carne', 'chocolate', 'coxinha'], 'F': ['morango', 'feijão', 'farinha'],
        'G': ['goiaba'], 'K': ['kiwi'], 'L': ['limão', 'leite', 'laranja'],
        'M': ['manga', 'maçã', 'milho', 'mandioca'], 'N': ['noz'],
        'P': ['pão', 'pêssego', 'frango', 'paçoca', 'pão de queijo'], 'Q': ['queijo', 'quiabo'],
        'R': ['rabanete'], 'S': ['sopa', 'salada', 'sorvete'], 'T': ['tomate', 'tapioca'],
        'U': ['uva'], 'V': ['vinagre'], 'Y': ['iogurte'],
      },
      'Colors': {
        'A': ['amarelo', 'azul', 'âmbar'], 'B': ['branco', 'bege'], 'C': ['cinza', 'coral', 'creme'],
        'D': ['dourado'], 'E': ['escarlate', 'esmeralda'], 'F': ['fúcsia'],
        'I': ['índigo'], 'J': ['jade'], 'L': ['lilás', 'lavanda'],
        'M': ['magenta', 'marrom'], 'N': ['negro'], 'P': ['prateado', 'preto', 'púrpura'],
        'R': ['rosa', 'roxo', 'vermelho'], 'T': ['turquesa'], 'V': ['verde', 'violeta'],
      },
      'Countries': {
        'A': ['Argentina', 'Alemanha', 'Austrália', 'Angola'], 'B': ['Brasil', 'Bélgica', 'Bolívia'],
        'C': ['Canadá', 'Chile', 'China', 'Colômbia', 'Cuba'], 'D': ['Dinamarca'],
        'E': ['Espanha', 'Equador', 'Egito'], 'F': ['França', 'Finlândia'], 'G': ['Grécia', 'Guatemala'],
        'I': ['Itália', 'Índia', 'Irlanda'], 'J': ['Japão', 'Jamaica'], 'K': ['Quênia'],
        'L': ['Luxemburgo'], 'M': ['México', 'Marrocos', 'Moçambique'], 'N': ['Noruega', 'Nigéria'],
        'P': ['Portugal', 'Peru', 'Panamá', 'Polônia'], 'R': ['Rússia', 'Romênia'],
        'S': ['Suécia', 'Suíça'], 'T': ['Turquia', 'Tailândia'], 'U': ['Uruguai'],
        'V': ['Venezuela', 'Vietnã'],
      },
      'Jobs': {
        'A': ['advogado', 'arquiteto', 'ator'], 'B': ['biólogo', 'bombeiro'], 'C': ['cozinheiro', 'cantor'],
        'D': ['dentista', 'diretor'], 'E': ['enfermeiro', 'eletricista', 'escritor'], 'F': ['fotógrafo', 'farmacêutico'],
        'I': ['engenheiro'], 'J': ['jardineiro', 'juiz'], 'M': ['médico', 'mecânico'],
        'P': ['piloto', 'policial', 'professor'], 'S': ['soldado', 'secretário'],
        'V': ['veterinário', 'vendedor'],
      },
      'Sports': {
        'A': ['atletismo'], 'B': ['basquete', 'boxe'], 'C': ['ciclismo', 'críquete'],
        'E': ['esgrima', 'escalada'], 'F': ['futebol'], 'G': ['golfe', 'ginástica'], 'H': ['hóquei'],
        'J': ['judô'], 'K': ['caratê'], 'N': ['natação'],
        'R': ['rúgbi', 'remo'], 'S': ['surfe', 'squash'], 'T': ['tênis', 'taekwondo'], 'V': ['vôlei', 'vela'],
      },
      'Clothes': {
        'B': ['blusa', 'botas', 'bermuda'], 'C': ['camisa', 'cachecol', 'casaco', 'calça', 'camiseta'],
        'G': ['gorro', 'gravata'], 'J': ['jaqueta', 'jeans'], 'L': ['luva'],
        'M': ['meia'], 'P': ['pijama'], 'S': ['saia', 'sapato', 'sandália', 'suéter', 'shorts'],
        'V': ['vestido'],
      },
      'Nature': {
        'A': ['árvore', 'arco-íris', 'areia'], 'B': ['bosque', 'baía'], 'C': ['cachoeira', 'colina', 'caverna'],
        'D': ['deserto', 'duna'], 'E': ['estrela'], 'F': ['flor', 'floresta', 'folha'],
        'I': ['ilha'], 'L': ['lago', 'lua'], 'M': ['montanha', 'mar', 'musgo'],
        'N': ['nuvem', 'neve'], 'O': ['oceano', 'onda'], 'P': ['praia', 'pedra'],
        'R': ['rio', 'rocha'], 'S': ['sol'], 'T': ['trovão', 'tempestade'], 'V': ['vulcão', 'vale', 'vento'],
      },
      'Family': {
        'A': ['avô', 'avó'], 'C': ['cunhado', 'cunhada'], 'E': ['esposo', 'esposa'],
        'F': ['filho', 'filha'], 'I': ['irmão', 'irmã'], 'M': ['mãe', 'marido'],
        'N': ['neto', 'neta', 'nora'], 'P': ['pai', 'primo', 'prima'],
        'S': ['sobrinho', 'sobrinha', 'sogro', 'sogra'], 'T': ['tio', 'tia'],
      },
      'Music': {
        'A': ['acordeão'], 'B': ['bateria', 'baixo'], 'C': ['clarinete', 'contrabaixo', 'cavaquinho'],
        'F': ['flauta'], 'G': ['guitarra'], 'H': ['harpa'],
        'O': ['oboé'], 'P': ['piano', 'pandeiro', 'percussão'],
        'S': ['saxofone', 'sintetizador'], 'T': ['trompete', 'trombone', 'tambor', 'tuba'],
        'U': ['ukulele'], 'V': ['violino', 'viola', 'violoncelo', 'violão'], 'X': ['xilofone'],
      },
    },
    'en': {
      'Animals': {
        'A': ['alligator', 'ant', 'antelope'], 'B': ['bear', 'bee', 'buffalo', 'butterfly'], 'C': ['cat', 'cow', 'crocodile'],
        'D': ['deer', 'dolphin', 'duck', 'dog'], 'E': ['eagle', 'elephant', 'eel'], 'F': ['fox', 'frog', 'flamingo'],
        'G': ['gorilla', 'goat', 'giraffe'], 'H': ['horse', 'hamster', 'hawk'], 'I': ['iguana', 'ibis'],
        'J': ['jaguar', 'jellyfish'], 'K': ['kangaroo', 'koala'], 'L': ['lion', 'leopard', 'lobster'],
        'M': ['monkey', 'mouse', 'moose'], 'N': ['narwhal', 'newt'], 'O': ['octopus', 'otter', 'owl'],
        'P': ['parrot', 'penguin', 'pig'], 'Q': ['quail'], 'R': ['rabbit', 'raccoon', 'rhinoceros'],
        'S': ['snake', 'shark', 'squirrel'], 'T': ['tiger', 'turtle', 'toucan'],
        'U': ['unicorn'], 'V': ['vulture', 'viper'], 'W': ['wolf', 'whale', 'walrus'],
        'X': ['x-ray fish'], 'Y': ['yak'], 'Z': ['zebra'],
      },
      'Food': {
        'A': ['apple', 'avocado', 'almond'], 'B': ['banana', 'bread', 'butter', 'broccoli'], 'C': ['cherry', 'chocolate', 'carrot', 'cheese'],
        'D': ['donut', 'date'], 'E': ['egg', 'eggplant'], 'F': ['fig', 'fish'], 'G': ['grape', 'garlic'],
        'H': ['honey', 'ham'], 'I': ['ice cream'], 'J': ['jam', 'juice'], 'K': ['kiwi', 'kale'],
        'L': ['lemon', 'lettuce', 'lentil'], 'M': ['mango', 'melon', 'milk', 'mushroom'], 'N': ['nut', 'noodle'],
        'O': ['olive', 'orange', 'oat'], 'P': ['pizza', 'peach', 'potato', 'pasta'], 'Q': ['quiche', 'quinoa'],
        'R': ['rice', 'radish', 'raisin'], 'S': ['soup', 'salad', 'strawberry'], 'T': ['tomato', 'toast'],
        'U': ['udon'], 'V': ['vanilla', 'vinegar'], 'W': ['watermelon', 'waffle'], 'Y': ['yogurt'], 'Z': ['zucchini'],
      },
      'Colors': {
        'A': ['amber', 'aqua'], 'B': ['blue', 'brown', 'beige', 'black'], 'C': ['crimson', 'coral', 'cream', 'cyan'],
        'E': ['emerald', 'ebony'], 'F': ['fuchsia'], 'G': ['green', 'gold', 'gray'],
        'I': ['indigo', 'ivory'], 'J': ['jade'], 'K': ['khaki'], 'L': ['lavender', 'lime', 'lilac'],
        'M': ['magenta', 'maroon', 'mustard'], 'N': ['navy'], 'O': ['orange', 'olive', 'ochre'],
        'P': ['pink', 'purple', 'peach'], 'R': ['red', 'rose', 'ruby'],
        'S': ['silver', 'scarlet', 'salmon'], 'T': ['turquoise', 'teal', 'tan'],
        'V': ['violet', 'vermillion'], 'W': ['white'], 'Y': ['yellow'],
      },
      'Countries': {
        'A': ['Argentina', 'Australia', 'Austria'], 'B': ['Brazil', 'Belgium', 'Bolivia'],
        'C': ['Canada', 'Chile', 'China', 'Colombia', 'Cuba'], 'D': ['Denmark'],
        'E': ['Egypt', 'Ecuador', 'England'], 'F': ['France', 'Finland'], 'G': ['Germany', 'Greece', 'Guatemala'],
        'H': ['Honduras', 'Hungary'], 'I': ['Italy', 'India', 'Ireland', 'Iceland'], 'J': ['Japan', 'Jamaica'],
        'K': ['Kenya', 'Kuwait'], 'L': ['Luxembourg'], 'M': ['Mexico', 'Morocco'],
        'N': ['Norway', 'Nigeria', 'Nepal'], 'P': ['Portugal', 'Peru', 'Panama', 'Poland'],
        'R': ['Russia', 'Romania'], 'S': ['Sweden', 'Switzerland', 'Spain'],
        'T': ['Turkey', 'Thailand', 'Tunisia'], 'U': ['Uruguay', 'Uganda'],
        'V': ['Venezuela', 'Vietnam'],
      },
      'Jobs': {
        'A': ['accountant', 'architect', 'actor'], 'B': ['baker', 'biologist'], 'C': ['chef', 'carpenter', 'captain'],
        'D': ['dentist', 'designer', 'director'], 'E': ['engineer', 'electrician'], 'F': ['firefighter', 'farmer'],
        'G': ['gardener'], 'J': ['journalist', 'judge'], 'L': ['lawyer', 'librarian'],
        'M': ['mechanic', 'musician', 'manager'], 'N': ['nurse', 'nutritionist'],
        'P': ['pilot', 'police officer', 'professor'], 'S': ['soldier', 'scientist', 'surgeon'],
        'T': ['teacher', 'technician'], 'V': ['vet', 'vendor'], 'W': ['writer'],
      },
      'Sports': {
        'A': ['archery', 'athletics'], 'B': ['basketball', 'boxing', 'baseball', 'badminton'],
        'C': ['cricket', 'cycling', 'climbing'], 'F': ['football', 'fencing'],
        'G': ['golf', 'gymnastics'], 'H': ['hockey', 'handball'],
        'J': ['judo'], 'K': ['karate', 'kayaking'], 'L': ['lacrosse'],
        'N': ['netball'], 'P': ['polo'], 'R': ['rugby', 'rowing', 'running'],
        'S': ['soccer', 'swimming', 'surfing', 'squash', 'skiing', 'sailing'],
        'T': ['tennis', 'taekwondo', 'triathlon'], 'V': ['volleyball'],
        'W': ['wrestling', 'weightlifting'],
      },
      'Clothes': {
        'B': ['blouse', 'boots', 'belt', 'blazer'], 'C': ['coat', 'cap'],
        'D': ['dress'], 'G': ['gloves', 'gown'], 'H': ['hat', 'hoodie'],
        'J': ['jacket', 'jeans', 'jumpsuit'], 'L': ['leggings'],
        'P': ['pants', 'pajamas', 'polo'], 'R': ['raincoat'],
        'S': ['shirt', 'skirt', 'socks', 'sweater', 'sandals', 'scarf', 'shorts', 'suit'],
        'T': ['t-shirt', 'tie', 'trousers', 'tank top'], 'V': ['vest'],
      },
      'Nature': {
        'B': ['beach', 'bay', 'brook', 'bush'], 'C': ['cave', 'cliff', 'cloud'], 'D': ['desert', 'dune'],
        'F': ['flower', 'forest', 'field'], 'G': ['grass', 'glacier'],
        'H': ['hill'], 'I': ['island', 'iceberg'], 'J': ['jungle'],
        'L': ['lake', 'leaf'], 'M': ['mountain', 'meadow', 'moon', 'moss'],
        'O': ['ocean'], 'P': ['pond', 'prairie'], 'R': ['river', 'rock', 'rain', 'rainbow'],
        'S': ['sea', 'sand', 'snow', 'star', 'storm', 'sun', 'stream'],
        'T': ['tree', 'thunder'], 'V': ['volcano', 'valley'],
        'W': ['waterfall', 'wave', 'wind', 'woods'],
      },
      'Family': {
        'A': ['aunt'], 'B': ['brother'], 'C': ['cousin'],
        'D': ['daughter'], 'F': ['father'], 'G': ['grandfather', 'grandmother', 'grandchild'],
        'H': ['husband'], 'M': ['mother'], 'N': ['nephew', 'niece'],
        'P': ['parent'], 'S': ['sister', 'son', 'stepfather', 'stepmother'],
        'U': ['uncle'], 'W': ['wife'],
      },
      'Music': {
        'A': ['accordion'], 'B': ['bass', 'banjo'], 'C': ['cello', 'clarinet'],
        'D': ['drums'], 'F': ['flute', 'fiddle'], 'G': ['guitar'],
        'H': ['harp', 'harmonica'], 'K': ['keyboard'],
        'M': ['mandolin'], 'O': ['oboe', 'organ'],
        'P': ['piano', 'percussion'], 'S': ['saxophone', 'synthesizer'],
        'T': ['trumpet', 'trombone', 'tambourine', 'tuba'],
        'U': ['ukulele'], 'V': ['violin', 'viola'], 'X': ['xylophone'],
      },
    },
  };

  // ============================================================
  // TAPPLES CATEGORY METADATA
  // ============================================================

  static const List<TapplesCategory> tapplesCategories = [
    TapplesCategory(name: 'Animals', icon: '🐾', wordsPerLetter: {}),
    TapplesCategory(name: 'Food', icon: '🍕', wordsPerLetter: {}),
    TapplesCategory(name: 'Colors', icon: '🎨', wordsPerLetter: {}),
    TapplesCategory(name: 'Countries', icon: '🌍', wordsPerLetter: {}),
    TapplesCategory(name: 'Jobs', icon: '💼', wordsPerLetter: {}),
    TapplesCategory(name: 'Sports', icon: '⚽', wordsPerLetter: {}),
    TapplesCategory(name: 'Clothes', icon: '👕', wordsPerLetter: {}),
    TapplesCategory(name: 'Nature', icon: '🌿', wordsPerLetter: {}),
    TapplesCategory(name: 'Family', icon: '👨‍👩‍👧‍👦', wordsPerLetter: {}),
    TapplesCategory(name: 'Music', icon: '🎵', wordsPerLetter: {}),
  ];

  static const List<String> tapplesCategoryNames = [
    'Animals', 'Food', 'Colors', 'Countries', 'Jobs',
    'Sports', 'Clothes', 'Nature', 'Family', 'Music',
  ];

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Get a random starting letter/syllable for Word Bomb
  static String getRandomWordBombPrompt(String language) {
    final words = wordBombWords[language] ?? wordBombWords['es']!;
    final word = words[_random.nextInt(words.length)];
    // Return first 1-2 characters as the prompt
    final length = _random.nextBool() ? 1 : 2;
    return word.substring(0, length.clamp(1, word.length));
  }

  /// Check if a word is valid for Word Bomb
  static bool isValidWordBombWord(String word, String prompt, String language) {
    final normalizedWord = word.toLowerCase().trim();
    final normalizedPrompt = prompt.toLowerCase().trim();
    if (!normalizedWord.startsWith(normalizedPrompt)) return false;
    final words = wordBombWords[language] ?? wordBombWords['es']!;
    return words.any((w) => w.toLowerCase() == normalizedWord);
  }

  /// Get a random translation pair for Translation Race
  static MapEntry<String, String> getRandomTranslationPair(String language) {
    final pairs = translationPairs[language] ?? translationPairs['es']!;
    final keys = pairs.keys.toList();
    final key = keys[_random.nextInt(keys.length)];
    return MapEntry(key, pairs[key]!);
  }

  /// Check translation answer with fuzzy matching (Levenshtein distance)
  static ({bool isExact, bool isClose}) checkTranslation(
    String answer,
    String correctAnswer,
  ) {
    final normalizedAnswer = answer.toLowerCase().trim();
    final normalizedCorrect = correctAnswer.toLowerCase().trim();

    if (normalizedAnswer == normalizedCorrect) {
      return (isExact: true, isClose: true);
    }

    final distance = _levenshteinDistance(normalizedAnswer, normalizedCorrect);
    return (isExact: false, isClose: distance < 2);
  }

  /// Get random grammar question
  static GrammarQuestion getRandomGrammarQuestion(
    String language, {
    String? category,
    List<int> excludeIndices = const [],
    int? maxDifficulty,
  }) {
    final questions = grammarQuestions[language] ?? grammarQuestions['es']!;
    var filtered = questions.toList();

    if (category != null) {
      filtered = filtered.where((q) => q.category == category).toList();
    }

    if (maxDifficulty != null) {
      filtered = filtered.where((q) => q.difficulty <= maxDifficulty).toList();
    }

    if (excludeIndices.isNotEmpty) {
      filtered = filtered
          .where((q) => !excludeIndices.contains(questions.indexOf(q)))
          .toList();
    }

    if (filtered.isEmpty) filtered = questions;
    return filtered[_random.nextInt(filtered.length)];
  }

  /// Get vocabulary words for a theme in a language
  static List<String> getVocabularyForTheme(String language, String theme) {
    final langCategories = vocabularyCategories[language];
    if (langCategories == null) return [];
    return langCategories[theme] ?? [];
  }

  /// Get a random vocabulary theme
  static String getRandomTheme() {
    return themeKeys[_random.nextInt(themeKeys.length)];
  }

  /// Check if a word is valid for vocabulary chain
  static bool isValidChainWord(
    String word,
    String lastLetter,
    String language,
    String theme,
    List<String> usedWords,
  ) {
    final normalizedWord = word.toLowerCase().trim();
    if (usedWords.contains(normalizedWord)) return false;
    if (normalizedWord.isEmpty) return false;
    if (lastLetter.isNotEmpty &&
        !normalizedWord.startsWith(lastLetter.toLowerCase())) {
      return false;
    }

    final validWords = getVocabularyForTheme(language, theme);
    if (validWords.isEmpty) return true; // If no list, accept any word
    return validWords.any((w) => w.toLowerCase() == normalizedWord);
  }

  /// Get the last letter of a word
  static String getLastLetter(String word) {
    if (word.isEmpty) return '';
    return word[word.length - 1].toLowerCase();
  }

  /// Get language display name
  static String getLanguageName(String code) {
    return languageNames[code] ?? code.toUpperCase();
  }

  // ============================================================
  // LANGUAGE SNAPS HELPERS
  // ============================================================

  /// Get snap cards for a specific language and difficulty, shuffled
  static List<SnapCard> getSnapCards(String language, int difficulty) {
    final langCards = snapCards[language];
    if (langCards == null) return [];

    // Collect cards at the requested difficulty and below (up to 2 levels below)
    final cards = <SnapCard>[];
    for (var d = (difficulty - 2).clamp(1, 10); d <= difficulty; d++) {
      final levelCards = langCards[d];
      if (levelCards != null) {
        cards.addAll(levelCards);
      }
    }

    // Shuffle and return
    final shuffled = List<SnapCard>.from(cards);
    shuffled.shuffle(_random);
    return shuffled;
  }

  // ============================================================
  // LANGUAGE TAPPLES HELPERS
  // ============================================================

  /// Get a random tapples category name for a language
  static String getTapplesCategory(String language) {
    final langWords = tapplesWords[language];
    if (langWords == null) return 'Animals';
    final categories = langWords.keys.toList();
    return categories[_random.nextInt(categories.length)];
  }

  /// Validate a Tapples word: does this word exist for the given language, category, and starting letter?
  static bool isValidTapplesWord(String word, String language, String category, String letter) {
    final normalizedWord = word.toLowerCase().trim();
    final normalizedLetter = letter.toUpperCase().trim();

    final langWords = tapplesWords[language];
    if (langWords == null) return false;

    final categoryWords = langWords[category];
    if (categoryWords == null) return false;

    final letterWords = categoryWords[normalizedLetter];
    if (letterWords == null) return false;

    return letterWords.any((w) => w.toLowerCase() == normalizedWord);
  }

  /// Get the icon for a tapples category
  static String getTapplesCategoryIcon(String categoryName) {
    for (final cat in tapplesCategories) {
      if (cat.name == categoryName) return cat.icon;
    }
    return '❓';
  }

  // ============================================================
  // DIFFICULTY-BASED CONTENT FILTERING
  // ============================================================

  /// Get words filtered by difficulty for any game type
  /// For Word Bomb: returns words appropriate for the difficulty level
  /// For other games: returns filtered content
  static List<String> getWordsForDifficulty(String language, String gameType, int difficulty) {
    final words = wordBombWords[language] ?? wordBombWords['es']!;
    final totalWords = words.length;

    // Divide words into difficulty segments (words are ordered by difficulty in the lists)
    final segmentSize = (totalWords / 10).ceil();
    final startIndex = ((difficulty - 1) * segmentSize).clamp(0, totalWords - 1);
    final endIndex = (difficulty * segmentSize).clamp(0, totalWords);

    // Include some words from easier levels for continuity
    final easyStart = (startIndex - segmentSize).clamp(0, totalWords);
    return words.sublist(easyStart, endIndex);
  }

  /// Get grammar questions filtered by difficulty
  static List<GrammarQuestion> getGrammarQuestionsForDifficulty(String language, int difficulty) {
    final questions = grammarQuestions[language] ?? grammarQuestions['es']!;
    // Return questions at or below the specified difficulty
    return questions.where((q) => q.difficulty <= difficulty).toList();
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  /// Levenshtein distance for fuzzy matching
  static int _levenshteinDistance(String s, String t) {
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final matrix = List.generate(
      s.length + 1,
      (i) => List.filled(t.length + 1, 0),
    );

    for (var i = 0; i <= s.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= t.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= s.length; i++) {
      for (var j = 1; j <= t.length; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s.length][t.length];
  }
}
