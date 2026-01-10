import '../../domain/entities/entities.dart';

/// Seed data for language learning feature
/// Contains initial phrases, quizzes, and content for all supported languages
class LanguageSeedData {
  /// Get seed phrases for a specific language
  static List<Map<String, dynamic>> getPhrasesForLanguage(String languageCode) {
    switch (languageCode) {
      case 'es':
        return _spanishPhrases;
      case 'fr':
        return _frenchPhrases;
      case 'de':
        return _germanPhrases;
      case 'it':
        return _italianPhrases;
      case 'pt':
      case 'pt-BR':
        return _portuguesePhrases;
      case 'ja':
        return _japanesePhrases;
      case 'ko':
        return _koreanPhrases;
      case 'zh':
        return _chinesePhrases;
      case 'ar':
        return _arabicPhrases;
      case 'ru':
        return _russianPhrases;
      default:
        return _englishPhrases;
    }
  }

  // Spanish Phrases
  static const List<Map<String, dynamic>> _spanishPhrases = [
    // Greetings - Beginner (Level 1-10)
    {'phrase': 'Hola', 'translation': 'Hello', 'pronunciation': 'OH-lah', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Buenos días', 'translation': 'Good morning', 'pronunciation': 'BWEH-nohs DEE-ahs', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Buenas noches', 'translation': 'Good night', 'pronunciation': 'BWEH-nahs NOH-chehs', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': '¿Cómo estás?', 'translation': 'How are you?', 'pronunciation': 'KOH-moh ehs-TAHS', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 2},
    {'phrase': 'Mucho gusto', 'translation': 'Nice to meet you', 'pronunciation': 'MOO-choh GOOS-toh', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 2},
    {'phrase': 'Adiós', 'translation': 'Goodbye', 'pronunciation': 'ah-DYOHS', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Hasta luego', 'translation': 'See you later', 'pronunciation': 'AHS-tah LWEH-goh', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 3},
    {'phrase': '¿Qué tal?', 'translation': 'What\'s up?', 'pronunciation': 'keh TAHL', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 4},

    // Compliments - Intermediate (Level 11-25)
    {'phrase': 'Eres muy guapa', 'translation': 'You are very beautiful', 'pronunciation': 'EH-rehs mwee GWAH-pah', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 11},
    {'phrase': 'Tienes una sonrisa hermosa', 'translation': 'You have a beautiful smile', 'pronunciation': 'tee-EH-nehs OO-nah sohn-REE-sah ehr-MOH-sah', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 12},
    {'phrase': 'Me encanta tu estilo', 'translation': 'I love your style', 'pronunciation': 'meh ehn-KAHN-tah too ehs-TEE-loh', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 13},
    {'phrase': 'Eres muy interesante', 'translation': 'You are very interesting', 'pronunciation': 'EH-rehs mwee een-teh-reh-SAHN-teh', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 14},

    // Flirty Phrases - Advanced (Level 26-50)
    {'phrase': '¿Tienes un mapa? Me perdí en tus ojos', 'translation': 'Do you have a map? I got lost in your eyes', 'pronunciation': 'tee-EH-nehs oon MAH-pah meh pehr-DEE ehn toos OH-hohs', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 26},
    {'phrase': 'Me gustas mucho', 'translation': 'I like you a lot', 'pronunciation': 'meh GOOS-tahs MOO-choh', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 27},
    {'phrase': '¿Quieres salir conmigo?', 'translation': 'Would you like to go out with me?', 'pronunciation': 'kee-EH-rehs sah-LEER kohn-MEE-goh', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 30},
    {'phrase': 'Eres el amor de mi vida', 'translation': 'You are the love of my life', 'pronunciation': 'EH-rehs ehl ah-MOHR deh mee VEE-dah', 'category': 'romantic', 'difficulty': 'advanced', 'requiredLevel': 35},

    // Conversation Starters
    {'phrase': '¿De dónde eres?', 'translation': 'Where are you from?', 'pronunciation': 'deh DOHN-deh EH-rehs', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 5},
    {'phrase': '¿Qué te gusta hacer?', 'translation': 'What do you like to do?', 'pronunciation': 'keh teh GOOS-tah ah-SEHR', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 15},
    {'phrase': '¿Cuál es tu comida favorita?', 'translation': 'What is your favorite food?', 'pronunciation': 'kwahl ehs too koh-MEE-dah fah-voh-REE-tah', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 16},

    // Date Planning
    {'phrase': '¿Quieres tomar un café?', 'translation': 'Would you like to have coffee?', 'pronunciation': 'kee-EH-rehs toh-MAHR oon kah-FEH', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 18},
    {'phrase': '¿A qué hora nos vemos?', 'translation': 'What time shall we meet?', 'pronunciation': 'ah keh OH-rah nohs VEH-mohs', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 19},

    // Video Call
    {'phrase': '¿Me escuchas bien?', 'translation': 'Can you hear me well?', 'pronunciation': 'meh ehs-KOO-chahs byehn', 'category': 'videoCall', 'difficulty': 'intermediate', 'requiredLevel': 20},
    {'phrase': 'Te veo muy bien', 'translation': 'You look great', 'pronunciation': 'teh VEH-oh mwee byehn', 'category': 'videoCall', 'difficulty': 'intermediate', 'requiredLevel': 21},

    // Romantic - Fluent (Level 51-100)
    {'phrase': 'Te quiero', 'translation': 'I love you', 'pronunciation': 'teh kee-EH-roh', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 51},
    {'phrase': 'Te amo con todo mi corazón', 'translation': 'I love you with all my heart', 'pronunciation': 'teh AH-moh kohn TOH-doh mee koh-rah-SOHN', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 55},

    // Idioms
    {'phrase': 'Estar en las nubes', 'translation': 'To be daydreaming (in the clouds)', 'pronunciation': 'ehs-TAHR ehn lahs NOO-behs', 'category': 'idioms', 'difficulty': 'fluent', 'requiredLevel': 76},
    {'phrase': 'Tirar la casa por la ventana', 'translation': 'To spare no expense (throw house out window)', 'pronunciation': 'tee-RAHR lah KAH-sah pohr lah vehn-TAH-nah', 'category': 'idioms', 'difficulty': 'fluent', 'requiredLevel': 80},
  ];

  // French Phrases
  static const List<Map<String, dynamic>> _frenchPhrases = [
    {'phrase': 'Bonjour', 'translation': 'Hello/Good day', 'pronunciation': 'bohn-ZHOOR', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Bonsoir', 'translation': 'Good evening', 'pronunciation': 'bohn-SWAHR', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Comment allez-vous?', 'translation': 'How are you? (formal)', 'pronunciation': 'koh-mohn tah-lay VOO', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 2},
    {'phrase': 'Enchanté(e)', 'translation': 'Nice to meet you', 'pronunciation': 'ohn-shahn-TAY', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 3},
    {'phrase': 'Au revoir', 'translation': 'Goodbye', 'pronunciation': 'oh ruh-VWAHR', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'À bientôt', 'translation': 'See you soon', 'pronunciation': 'ah byehn-TOH', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 4},

    {'phrase': 'Tu es très belle', 'translation': 'You are very beautiful', 'pronunciation': 'too eh treh BELL', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 11},
    {'phrase': 'Tu as de beaux yeux', 'translation': 'You have beautiful eyes', 'pronunciation': 'too ah duh boh ZYUH', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 12},
    {'phrase': 'J\'aime ton sourire', 'translation': 'I love your smile', 'pronunciation': 'zhehm tohn soo-REER', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 13},

    {'phrase': 'Tu me manques', 'translation': 'I miss you', 'pronunciation': 'too muh MAHNK', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 26},
    {'phrase': 'Je pense à toi', 'translation': 'I\'m thinking of you', 'pronunciation': 'zhuh pahns ah TWAH', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 27},
    {'phrase': 'Veux-tu sortir avec moi?', 'translation': 'Would you like to go out with me?', 'pronunciation': 'vuh-too sohr-TEER ah-vek MWAH', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 30},

    {'phrase': 'Je t\'aime', 'translation': 'I love you', 'pronunciation': 'zhuh TEHM', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 51},
    {'phrase': 'Tu es l\'amour de ma vie', 'translation': 'You are the love of my life', 'pronunciation': 'too eh lah-MOOR duh mah VEE', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 55},

    {'phrase': 'D\'où viens-tu?', 'translation': 'Where are you from?', 'pronunciation': 'doo vyehn-TOO', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 5},
    {'phrase': 'Qu\'est-ce que tu aimes faire?', 'translation': 'What do you like to do?', 'pronunciation': 'kehs-kuh too ehm FEHR', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 15},

    {'phrase': 'Avoir le coup de foudre', 'translation': 'Love at first sight (lightning strike)', 'pronunciation': 'ah-VWAHR luh koo duh FOODR', 'category': 'idioms', 'difficulty': 'fluent', 'requiredLevel': 76},
  ];

  // German Phrases
  static const List<Map<String, dynamic>> _germanPhrases = [
    {'phrase': 'Guten Tag', 'translation': 'Good day', 'pronunciation': 'GOO-ten TAHK', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Guten Morgen', 'translation': 'Good morning', 'pronunciation': 'GOO-ten MOR-gen', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Guten Abend', 'translation': 'Good evening', 'pronunciation': 'GOO-ten AH-bent', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Wie geht es dir?', 'translation': 'How are you?', 'pronunciation': 'vee GAYT es deer', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 2},
    {'phrase': 'Freut mich', 'translation': 'Nice to meet you', 'pronunciation': 'froyt MIKH', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 3},
    {'phrase': 'Auf Wiedersehen', 'translation': 'Goodbye', 'pronunciation': 'owf VEE-der-zay-en', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Tschüss', 'translation': 'Bye (casual)', 'pronunciation': 'CHOOS', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 2},

    {'phrase': 'Du bist wunderschön', 'translation': 'You are beautiful', 'pronunciation': 'doo bist VOON-der-shurn', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 11},
    {'phrase': 'Du hast ein tolles Lächeln', 'translation': 'You have a great smile', 'pronunciation': 'doo hahst ayn TOL-es LEKH-eln', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 12},

    {'phrase': 'Ich mag dich sehr', 'translation': 'I like you a lot', 'pronunciation': 'ikh mahk dikh ZAYR', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 26},
    {'phrase': 'Möchtest du mit mir ausgehen?', 'translation': 'Would you like to go out with me?', 'pronunciation': 'MERKH-test doo mit meer OWS-gay-en', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 30},

    {'phrase': 'Ich liebe dich', 'translation': 'I love you', 'pronunciation': 'ikh LEE-buh dikh', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 51},
    {'phrase': 'Du bist die Liebe meines Lebens', 'translation': 'You are the love of my life', 'pronunciation': 'doo bist dee LEE-buh MY-nes LAY-bens', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 55},

    {'phrase': 'Woher kommst du?', 'translation': 'Where are you from?', 'pronunciation': 'voh-HAYR komst doo', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 5},
  ];

  // Italian Phrases
  static const List<Map<String, dynamic>> _italianPhrases = [
    {'phrase': 'Ciao', 'translation': 'Hello/Goodbye', 'pronunciation': 'CHOW', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Buongiorno', 'translation': 'Good morning/day', 'pronunciation': 'bwohn-JOHR-noh', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Buonasera', 'translation': 'Good evening', 'pronunciation': 'bwoh-nah-SEH-rah', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Come stai?', 'translation': 'How are you?', 'pronunciation': 'KOH-meh STYE', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 2},
    {'phrase': 'Piacere', 'translation': 'Nice to meet you', 'pronunciation': 'pyah-CHEH-reh', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 3},
    {'phrase': 'Arrivederci', 'translation': 'Goodbye', 'pronunciation': 'ah-ree-veh-DEHR-chee', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},

    {'phrase': 'Sei bellissima', 'translation': 'You are very beautiful', 'pronunciation': 'say bel-LEE-see-mah', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 11},
    {'phrase': 'Hai degli occhi bellissimi', 'translation': 'You have beautiful eyes', 'pronunciation': 'eye DEH-lyee OH-kee bel-LEE-see-mee', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 12},

    {'phrase': 'Mi piaci molto', 'translation': 'I like you a lot', 'pronunciation': 'mee PYAH-chee MOHL-toh', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 26},
    {'phrase': 'Vuoi uscire con me?', 'translation': 'Would you like to go out with me?', 'pronunciation': 'VWOY oo-SHEE-reh kon MEH', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 30},

    {'phrase': 'Ti amo', 'translation': 'I love you', 'pronunciation': 'tee AH-moh', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 51},
    {'phrase': 'Sei l\'amore della mia vita', 'translation': 'You are the love of my life', 'pronunciation': 'say lah-MOH-reh DEHL-lah MEE-ah VEE-tah', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 55},

    {'phrase': 'Di dove sei?', 'translation': 'Where are you from?', 'pronunciation': 'dee DOH-veh SAY', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 5},
  ];

  // Portuguese Phrases
  static const List<Map<String, dynamic>> _portuguesePhrases = [
    {'phrase': 'Olá', 'translation': 'Hello', 'pronunciation': 'oh-LAH', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Bom dia', 'translation': 'Good morning', 'pronunciation': 'bom DEE-ah', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Boa noite', 'translation': 'Good night', 'pronunciation': 'BOH-ah NOY-chee', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Tudo bem?', 'translation': 'Everything good?', 'pronunciation': 'TOO-doo beng', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 2},
    {'phrase': 'Prazer', 'translation': 'Nice to meet you', 'pronunciation': 'prah-ZEHR', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 3},
    {'phrase': 'Tchau', 'translation': 'Bye', 'pronunciation': 'chow', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},

    {'phrase': 'Você é muito bonita', 'translation': 'You are very beautiful', 'pronunciation': 'voh-SEH eh MOO-ee-too boh-NEE-tah', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 11},
    {'phrase': 'Você tem um sorriso lindo', 'translation': 'You have a beautiful smile', 'pronunciation': 'voh-SEH tehng oom soh-HEE-zoo LEEN-doo', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 12},

    {'phrase': 'Eu gosto muito de você', 'translation': 'I like you a lot', 'pronunciation': 'eh-oo GOHSH-too MOO-ee-too jee voh-SEH', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 26},

    {'phrase': 'Te amo', 'translation': 'I love you', 'pronunciation': 'tee AH-moo', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 51},
    {'phrase': 'Você é o amor da minha vida', 'translation': 'You are the love of my life', 'pronunciation': 'voh-SEH eh oo ah-MOHR dah MEE-nyah VEE-dah', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 55},

    {'phrase': 'De onde você é?', 'translation': 'Where are you from?', 'pronunciation': 'jee OHN-jee voh-SEH eh', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 5},
  ];

  // Japanese Phrases
  static const List<Map<String, dynamic>> _japanesePhrases = [
    {'phrase': 'こんにちは', 'translation': 'Hello', 'pronunciation': 'kon-nee-chee-wah', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'おはようございます', 'translation': 'Good morning', 'pronunciation': 'oh-hah-yoh goh-zah-ee-mahs', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'こんばんは', 'translation': 'Good evening', 'pronunciation': 'kon-bahn-wah', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'お元気ですか？', 'translation': 'How are you?', 'pronunciation': 'oh-gen-kee dess-kah', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 2},
    {'phrase': 'はじめまして', 'translation': 'Nice to meet you', 'pronunciation': 'hah-jee-meh-mash-teh', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 3},
    {'phrase': 'さようなら', 'translation': 'Goodbye', 'pronunciation': 'sah-yoh-nah-rah', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'またね', 'translation': 'See you', 'pronunciation': 'mah-tah-neh', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 2},

    {'phrase': 'とてもかわいいですね', 'translation': 'You are very cute', 'pronunciation': 'toh-teh-moh kah-wah-ee dess-neh', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 11},
    {'phrase': '笑顔が素敵ですね', 'translation': 'You have a lovely smile', 'pronunciation': 'eh-gah-oh gah soo-teh-kee dess-neh', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 12},

    {'phrase': '好きです', 'translation': 'I like you', 'pronunciation': 'soo-kee dess', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 26},
    {'phrase': 'デートしませんか？', 'translation': 'Would you like to go on a date?', 'pronunciation': 'deh-toh shee-mah-sen-kah', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 30},

    {'phrase': '愛してる', 'translation': 'I love you', 'pronunciation': 'ah-ee-shee-teh-roo', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 51},
    {'phrase': '大好き', 'translation': 'I really like you', 'pronunciation': 'dah-ee-soo-kee', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 45},

    {'phrase': 'どこの出身ですか？', 'translation': 'Where are you from?', 'pronunciation': 'doh-koh noh shoo-shin dess-kah', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 5},
    {'phrase': '趣味は何ですか？', 'translation': 'What are your hobbies?', 'pronunciation': 'shoo-mee wah nahn dess-kah', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 15},
  ];

  // Korean Phrases
  static const List<Map<String, dynamic>> _koreanPhrases = [
    {'phrase': '안녕하세요', 'translation': 'Hello', 'pronunciation': 'ahn-nyeong-hah-seh-yo', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': '좋은 아침이에요', 'translation': 'Good morning', 'pronunciation': 'joh-eun ah-chim-ee-eh-yo', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 2},
    {'phrase': '잘 지내세요?', 'translation': 'How are you?', 'pronunciation': 'jahl jee-neh-seh-yo', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 3},
    {'phrase': '만나서 반갑습니다', 'translation': 'Nice to meet you', 'pronunciation': 'mahn-nah-suh bahn-gahp-soom-nee-dah', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 3},
    {'phrase': '안녕히 가세요', 'translation': 'Goodbye (to someone leaving)', 'pronunciation': 'ahn-nyeong-hee gah-seh-yo', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 2},

    {'phrase': '너무 예뻐요', 'translation': 'You are so pretty', 'pronunciation': 'nuh-moo yeh-ppuh-yo', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 11},
    {'phrase': '미소가 예뻐요', 'translation': 'Your smile is pretty', 'pronunciation': 'mee-soh-gah yeh-ppuh-yo', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 12},

    {'phrase': '좋아해요', 'translation': 'I like you', 'pronunciation': 'joh-ah-heh-yo', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 26},
    {'phrase': '데이트 할래요?', 'translation': 'Would you like to go on a date?', 'pronunciation': 'deh-ee-teu hahl-leh-yo', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 30},

    {'phrase': '사랑해요', 'translation': 'I love you', 'pronunciation': 'sah-rahng-heh-yo', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 51},
    {'phrase': '보고 싶어요', 'translation': 'I miss you', 'pronunciation': 'boh-goh ship-uh-yo', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 45},

    {'phrase': '어디서 왔어요?', 'translation': 'Where are you from?', 'pronunciation': 'uh-dee-suh wah-ssuh-yo', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 5},
  ];

  // Chinese Phrases
  static const List<Map<String, dynamic>> _chinesePhrases = [
    {'phrase': '你好', 'translation': 'Hello', 'pronunciation': 'nee-how', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': '早上好', 'translation': 'Good morning', 'pronunciation': 'zao-shahng-how', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': '晚上好', 'translation': 'Good evening', 'pronunciation': 'wahn-shahng-how', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': '你好吗？', 'translation': 'How are you?', 'pronunciation': 'nee-how-mah', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 2},
    {'phrase': '很高兴认识你', 'translation': 'Nice to meet you', 'pronunciation': 'hen-gow-shing-ren-shih-nee', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 3},
    {'phrase': '再见', 'translation': 'Goodbye', 'pronunciation': 'zai-jee-ehn', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},

    {'phrase': '你很漂亮', 'translation': 'You are very beautiful', 'pronunciation': 'nee-hen-pyow-lyahng', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 11},
    {'phrase': '你的笑容很美', 'translation': 'Your smile is beautiful', 'pronunciation': 'nee-duh-shyow-rohng-hen-may', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 12},

    {'phrase': '我很喜欢你', 'translation': 'I like you a lot', 'pronunciation': 'woh-hen-shee-hwahn-nee', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 26},

    {'phrase': '我爱你', 'translation': 'I love you', 'pronunciation': 'woh-eye-nee', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 51},

    {'phrase': '你是哪里人？', 'translation': 'Where are you from?', 'pronunciation': 'nee-shih-nah-lee-ren', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 5},
  ];

  // Arabic Phrases
  static const List<Map<String, dynamic>> _arabicPhrases = [
    {'phrase': 'مرحبا', 'translation': 'Hello', 'pronunciation': 'mar-ha-ba', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'صباح الخير', 'translation': 'Good morning', 'pronunciation': 'sa-bah al-khayr', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'مساء الخير', 'translation': 'Good evening', 'pronunciation': 'ma-sa al-khayr', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'كيف حالك؟', 'translation': 'How are you?', 'pronunciation': 'kayf ha-lak', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 2},
    {'phrase': 'تشرفت بمعرفتك', 'translation': 'Nice to meet you', 'pronunciation': 'ta-shar-raf-tu bi-ma-ri-fa-tak', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 3},
    {'phrase': 'مع السلامة', 'translation': 'Goodbye', 'pronunciation': 'ma-a sa-la-ma', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},

    {'phrase': 'أنت جميلة جداً', 'translation': 'You are very beautiful', 'pronunciation': 'an-ti ja-mee-la jid-dan', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 11},
    {'phrase': 'ما شاء الله', 'translation': 'God has willed it (expression of admiration)', 'pronunciation': 'ma-sha-al-lah', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 10},

    {'phrase': 'أحبك', 'translation': 'I love you', 'pronunciation': 'u-hib-buk', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 51},

    {'phrase': 'من أين أنت؟', 'translation': 'Where are you from?', 'pronunciation': 'min ay-na an-ta', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 5},
  ];

  // Russian Phrases
  static const List<Map<String, dynamic>> _russianPhrases = [
    {'phrase': 'Привет', 'translation': 'Hello', 'pronunciation': 'pree-VYET', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Доброе утро', 'translation': 'Good morning', 'pronunciation': 'DOB-rah-yeh OO-trah', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Добрый вечер', 'translation': 'Good evening', 'pronunciation': 'DOB-ree VYE-cher', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Как дела?', 'translation': 'How are you?', 'pronunciation': 'kahk dee-LAH', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 2},
    {'phrase': 'Очень приятно', 'translation': 'Nice to meet you', 'pronunciation': 'OH-chen pree-YAHT-nah', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 3},
    {'phrase': 'До свидания', 'translation': 'Goodbye', 'pronunciation': 'dah svee-DAH-nee-yah', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},

    {'phrase': 'Ты очень красивая', 'translation': 'You are very beautiful', 'pronunciation': 'tee OH-chen krah-SEE-vah-yah', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 11},
    {'phrase': 'У тебя красивая улыбка', 'translation': 'You have a beautiful smile', 'pronunciation': 'oo tee-BYAH krah-SEE-vah-yah oo-LEEB-kah', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 12},

    {'phrase': 'Ты мне очень нравишься', 'translation': 'I like you a lot', 'pronunciation': 'tee mnyeh OH-chen NRAH-veesh-syah', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 26},

    {'phrase': 'Я тебя люблю', 'translation': 'I love you', 'pronunciation': 'yah tee-BYAH lyoo-BLYOO', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 51},

    {'phrase': 'Откуда ты?', 'translation': 'Where are you from?', 'pronunciation': 'aht-KOO-dah tee', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 5},
  ];

  // English Phrases (for non-native speakers)
  static const List<Map<String, dynamic>> _englishPhrases = [
    {'phrase': 'Hello', 'translation': 'Hello', 'pronunciation': 'heh-LOH', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'Good morning', 'translation': 'Good morning', 'pronunciation': 'good MOR-ning', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},
    {'phrase': 'How are you?', 'translation': 'How are you?', 'pronunciation': 'how ar YOO', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 2},
    {'phrase': 'Nice to meet you', 'translation': 'Nice to meet you', 'pronunciation': 'nys too meet YOO', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 3},
    {'phrase': 'Goodbye', 'translation': 'Goodbye', 'pronunciation': 'good-BY', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 1},

    {'phrase': 'You look amazing', 'translation': 'You look amazing', 'pronunciation': 'yoo look ah-MAY-zing', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 11},
    {'phrase': 'You have a beautiful smile', 'translation': 'You have a beautiful smile', 'pronunciation': 'yoo hav a BYOO-tiful smyl', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 12},

    {'phrase': 'I really like you', 'translation': 'I really like you', 'pronunciation': 'ai REE-lee lyk yoo', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 26},
    {'phrase': 'Would you like to go out with me?', 'translation': 'Would you like to go out with me?', 'pronunciation': 'wood yoo lyk too goh owt with mee', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 30},

    {'phrase': 'I love you', 'translation': 'I love you', 'pronunciation': 'ai luv yoo', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 51},

    {'phrase': 'Where are you from?', 'translation': 'Where are you from?', 'pronunciation': 'wehr ar yoo from', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 5},

    // Idioms
    {'phrase': 'Break the ice', 'translation': 'To initiate conversation', 'pronunciation': 'breyk thee ais', 'category': 'idioms', 'difficulty': 'fluent', 'requiredLevel': 76},
    {'phrase': 'Hit it off', 'translation': 'To immediately get along well', 'pronunciation': 'hit it off', 'category': 'idioms', 'difficulty': 'fluent', 'requiredLevel': 77},
    {'phrase': 'On cloud nine', 'translation': 'Extremely happy', 'pronunciation': 'on klowd nyn', 'category': 'idioms', 'difficulty': 'fluent', 'requiredLevel': 78},
  ];

  /// Get cultural quizzes for a country
  static List<Map<String, dynamic>> getQuizzesForCountry(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'ES':
        return _spanishQuizzes;
      case 'FR':
        return _frenchQuizzes;
      case 'JP':
        return _japaneseQuizzes;
      case 'KR':
        return _koreanQuizzes;
      default:
        return [];
    }
  }

  static const List<Map<String, dynamic>> _spanishQuizzes = [
    {
      'id': 'es_culture_1',
      'title': 'Spanish Culture Basics',
      'description': 'Test your knowledge of Spanish culture and traditions',
      'languageCode': 'es',
      'countryCode': 'ES',
      'countryName': 'Spain',
      'difficulty': 'easy',
      'questions': [
        {
          'id': 'es_q1',
          'question': 'What is the traditional afternoon nap called in Spain?',
          'options': ['Siesta', 'Fiesta', 'Tapas', 'Paella'],
          'correctOptionIndex': 0,
          'explanation': 'Siesta is a traditional short afternoon rest or nap taken in Spain and other countries with hot climates.',
        },
        {
          'id': 'es_q2',
          'question': 'What time do Spaniards typically eat dinner?',
          'options': ['6 PM', '7 PM', '9-10 PM', '5 PM'],
          'correctOptionIndex': 2,
          'explanation': 'Spaniards typically eat dinner late, usually between 9-10 PM or even later.',
        },
        {
          'id': 'es_q3',
          'question': 'How do Spanish people typically greet friends?',
          'options': ['Handshake', 'Two kisses on cheeks', 'Bow', 'Wave'],
          'correctOptionIndex': 1,
          'explanation': 'In Spain, friends greet each other with two kisses, one on each cheek.',
        },
      ],
    },
  ];

  static const List<Map<String, dynamic>> _frenchQuizzes = [
    {
      'id': 'fr_culture_1',
      'title': 'French Culture Basics',
      'description': 'Test your knowledge of French culture and etiquette',
      'languageCode': 'fr',
      'countryCode': 'FR',
      'countryName': 'France',
      'difficulty': 'easy',
      'questions': [
        {
          'id': 'fr_q1',
          'question': 'What is "la bise" in French culture?',
          'options': ['A bread', 'A kiss greeting', 'A wine', 'A dance'],
          'correctOptionIndex': 1,
          'explanation': 'La bise refers to the French custom of greeting with kisses on the cheeks.',
        },
        {
          'id': 'fr_q2',
          'question': 'What is the most important meal of the day in France?',
          'options': ['Breakfast', 'Lunch', 'Dinner', 'Afternoon tea'],
          'correctOptionIndex': 1,
          'explanation': 'Lunch (le déjeuner) is traditionally the most important meal in France, often lasting 1-2 hours.',
        },
      ],
    },
  ];

  static const List<Map<String, dynamic>> _japaneseQuizzes = [
    {
      'id': 'jp_culture_1',
      'title': 'Japanese Culture Basics',
      'description': 'Test your knowledge of Japanese culture and customs',
      'languageCode': 'ja',
      'countryCode': 'JP',
      'countryName': 'Japan',
      'difficulty': 'easy',
      'questions': [
        {
          'id': 'jp_q1',
          'question': 'What is the proper way to bow when meeting someone in Japan?',
          'options': ['From the waist', 'Just nod', 'Only women bow', 'Bow while shaking hands'],
          'correctOptionIndex': 0,
          'explanation': 'In Japan, bowing from the waist is the traditional greeting, with the depth of the bow indicating respect level.',
        },
        {
          'id': 'jp_q2',
          'question': 'What should you do before entering a Japanese home?',
          'options': ['Knock three times', 'Remove your shoes', 'Bring a gift', 'Call out'],
          'correctOptionIndex': 1,
          'explanation': 'Removing shoes before entering a home is essential in Japanese culture to maintain cleanliness.',
        },
      ],
    },
  ];

  static const List<Map<String, dynamic>> _koreanQuizzes = [
    {
      'id': 'kr_culture_1',
      'title': 'Korean Culture Basics',
      'description': 'Test your knowledge of Korean culture and traditions',
      'languageCode': 'ko',
      'countryCode': 'KR',
      'countryName': 'South Korea',
      'difficulty': 'easy',
      'questions': [
        {
          'id': 'kr_q1',
          'question': 'What is considered respectful when drinking with elders in Korea?',
          'options': ['Drink quickly', 'Turn away while drinking', 'Toast loudly', 'Drink first'],
          'correctOptionIndex': 1,
          'explanation': 'In Korean culture, it\'s respectful to turn your head away from elders while drinking alcohol.',
        },
        {
          'id': 'kr_q2',
          'question': 'What does "skinship" mean in Korean dating culture?',
          'options': ['Online dating', 'Physical affection', 'Meeting parents', 'Exchange gifts'],
          'correctOptionIndex': 1,
          'explanation': 'Skinship refers to physical intimacy and affection between couples, like holding hands or hugging.',
        },
      ],
    },
  ];
}
