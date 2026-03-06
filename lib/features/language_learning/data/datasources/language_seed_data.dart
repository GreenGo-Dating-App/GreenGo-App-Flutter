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
    {'phrase': '¿A qué te dedicas?', 'translation': 'What do you do for a living?', 'pronunciation': 'ah keh teh deh-DEE-kahs', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 17},
    {'phrase': '¿Te gusta viajar?', 'translation': 'Do you like to travel?', 'pronunciation': 'teh GOOS-tah vee-ah-HAHR', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 6},
    {'phrase': '¿Qué tipo de música te gusta?', 'translation': 'What kind of music do you like?', 'pronunciation': 'keh TEE-poh deh MOO-see-kah teh GOOS-tah', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 14},

    // Date Planning
    {'phrase': '¿Quieres tomar un café?', 'translation': 'Would you like to have coffee?', 'pronunciation': 'kee-EH-rehs toh-MAHR oon kah-FEH', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 18},
    {'phrase': '¿A qué hora nos vemos?', 'translation': 'What time shall we meet?', 'pronunciation': 'ah keh OH-rah nohs VEH-mohs', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 19},
    {'phrase': '¿Cuándo estás libre?', 'translation': 'When are you free?', 'pronunciation': 'KWAHN-doh ehs-TAHS LEE-breh', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 20},
    {'phrase': 'Nos vemos en el restaurante', 'translation': 'Let\'s meet at the restaurant', 'pronunciation': 'nohs VEH-mohs ehn ehl rehs-tow-RAHN-teh', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 22},
    {'phrase': 'Paso a recogerte', 'translation': 'I\'ll come pick you up', 'pronunciation': 'PAH-soh ah reh-koh-HEHR-teh', 'category': 'datePlanning', 'difficulty': 'advanced', 'requiredLevel': 28},

    // Food & Dining
    {'phrase': 'Me gustaría pedir...', 'translation': 'I would like to order...', 'pronunciation': 'meh goos-tah-REE-ah peh-DEER', 'category': 'foodDining', 'difficulty': 'intermediate', 'requiredLevel': 15},
    {'phrase': 'La cuenta, por favor', 'translation': 'The check, please', 'pronunciation': 'lah KWEHN-tah pohr fah-VOHR', 'category': 'foodDining', 'difficulty': 'beginner', 'requiredLevel': 8},
    {'phrase': '¡Está delicioso!', 'translation': 'This is delicious!', 'pronunciation': 'ehs-TAH deh-lee-SYOH-soh', 'category': 'foodDining', 'difficulty': 'beginner', 'requiredLevel': 7},
    {'phrase': '¿Qué me recomiendas?', 'translation': 'What do you recommend?', 'pronunciation': 'keh meh reh-koh-MYEHN-dahs', 'category': 'foodDining', 'difficulty': 'intermediate', 'requiredLevel': 12},
    {'phrase': 'Una mesa para dos, por favor', 'translation': 'A table for two, please', 'pronunciation': 'OO-nah MEH-sah PAH-rah dohs pohr fah-VOHR', 'category': 'foodDining', 'difficulty': 'beginner', 'requiredLevel': 9},

    // Travel & Culture
    {'phrase': '¿Dónde está...?', 'translation': 'Where is...?', 'pronunciation': 'DOHN-deh ehs-TAH', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 4},
    {'phrase': '¿Cuánto cuesta?', 'translation': 'How much does it cost?', 'pronunciation': 'KWAHN-toh KWEHS-tah', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 5},
    {'phrase': 'Estoy de visita', 'translation': 'I\'m visiting', 'pronunciation': 'ehs-TOY deh vee-SEE-tah', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 6},
    {'phrase': '¿Puedes ayudarme?', 'translation': 'Can you help me?', 'pronunciation': 'PWEH-dehs ah-yoo-DAHR-meh', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 7},

    // Video Call
    {'phrase': '¿Me escuchas bien?', 'translation': 'Can you hear me well?', 'pronunciation': 'meh ehs-KOO-chahs byehn', 'category': 'videoCall', 'difficulty': 'intermediate', 'requiredLevel': 20},
    {'phrase': 'Te veo muy bien', 'translation': 'You look great', 'pronunciation': 'teh VEH-oh mwee byehn', 'category': 'videoCall', 'difficulty': 'intermediate', 'requiredLevel': 21},

    // Romantic - Fluent (Level 51-100)
    {'phrase': 'Te quiero', 'translation': 'I love you', 'pronunciation': 'teh kee-EH-roh', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 51},
    {'phrase': 'Te amo con todo mi corazón', 'translation': 'I love you with all my heart', 'pronunciation': 'teh AH-moh kohn TOH-doh mee koh-rah-SOHN', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 55},
    {'phrase': 'Te echo de menos', 'translation': 'I miss you', 'pronunciation': 'teh EH-choh deh MEH-nohs', 'category': 'romantic', 'difficulty': 'advanced', 'requiredLevel': 40},
    {'phrase': 'Eres todo para mí', 'translation': 'You are everything to me', 'pronunciation': 'EH-rehs TOH-doh PAH-rah mee', 'category': 'romantic', 'difficulty': 'advanced', 'requiredLevel': 42},
    {'phrase': 'Me haces muy feliz', 'translation': 'You make me very happy', 'pronunciation': 'meh AH-sehs mwee feh-LEES', 'category': 'romantic', 'difficulty': 'advanced', 'requiredLevel': 35},

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

    // Conversation Starters
    {'phrase': 'D\'où viens-tu?', 'translation': 'Where are you from?', 'pronunciation': 'doo vyehn-TOO', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 5},
    {'phrase': 'Qu\'est-ce que tu aimes faire?', 'translation': 'What do you like to do?', 'pronunciation': 'kehs-kuh too ehm FEHR', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 15},
    {'phrase': 'Tu fais quoi dans la vie?', 'translation': 'What do you do for a living?', 'pronunciation': 'too feh kwah dahn lah VEE', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 16},
    {'phrase': 'Tu aimes voyager?', 'translation': 'Do you like to travel?', 'pronunciation': 'too ehm vwah-yah-ZHAY', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 6},
    {'phrase': 'Quel est ton film préféré?', 'translation': 'What is your favorite movie?', 'pronunciation': 'kehl eh tohn feelm preh-feh-RAY', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 14},

    // Date Planning
    {'phrase': 'On prend un verre?', 'translation': 'Shall we have a drink?', 'pronunciation': 'ohn prahn uhn VEHR', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 18},
    {'phrase': 'Tu es libre ce soir?', 'translation': 'Are you free tonight?', 'pronunciation': 'too eh LEE-bruh suh SWAHR', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 19},
    {'phrase': 'On se retrouve où?', 'translation': 'Where shall we meet?', 'pronunciation': 'ohn suh ruh-TROOV oo', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 20},
    {'phrase': 'Je passe te chercher', 'translation': 'I\'ll come pick you up', 'pronunciation': 'zhuh pahs tuh shehr-SHAY', 'category': 'datePlanning', 'difficulty': 'advanced', 'requiredLevel': 28},

    // Food & Dining
    {'phrase': 'L\'addition, s\'il vous plaît', 'translation': 'The check, please', 'pronunciation': 'lah-dee-SYOHN seel voo PLEH', 'category': 'foodDining', 'difficulty': 'beginner', 'requiredLevel': 8},
    {'phrase': 'C\'est délicieux!', 'translation': 'This is delicious!', 'pronunciation': 'seh deh-lee-SYUH', 'category': 'foodDining', 'difficulty': 'beginner', 'requiredLevel': 7},
    {'phrase': 'Qu\'est-ce que vous recommandez?', 'translation': 'What do you recommend?', 'pronunciation': 'kehs-kuh voo reh-koh-mahn-DAY', 'category': 'foodDining', 'difficulty': 'intermediate', 'requiredLevel': 12},
    {'phrase': 'Une table pour deux, s\'il vous plaît', 'translation': 'A table for two, please', 'pronunciation': 'oon TAHBL poor duh seel voo PLEH', 'category': 'foodDining', 'difficulty': 'beginner', 'requiredLevel': 9},

    // Travel & Culture
    {'phrase': 'Où est...?', 'translation': 'Where is...?', 'pronunciation': 'oo EH', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 4},
    {'phrase': 'Combien ça coûte?', 'translation': 'How much does it cost?', 'pronunciation': 'kohm-BYEHN sah KOOT', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 5},
    {'phrase': 'Je suis en visite', 'translation': 'I\'m visiting', 'pronunciation': 'zhuh swee ohn vee-ZEET', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 6},
    {'phrase': 'Pouvez-vous m\'aider?', 'translation': 'Can you help me?', 'pronunciation': 'poo-vay-VOO meh-DAY', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 7},

    // Romantic
    {'phrase': 'Tu me manques', 'translation': 'I miss you', 'pronunciation': 'too muh MAHNK', 'category': 'romantic', 'difficulty': 'advanced', 'requiredLevel': 40},
    {'phrase': 'Tu es l\'amour de ma vie', 'translation': 'You are the love of my life', 'pronunciation': 'too eh lah-MOOR duh mah VEE', 'category': 'romantic', 'difficulty': 'fluent', 'requiredLevel': 55},
    {'phrase': 'Tu me rends heureux/heureuse', 'translation': 'You make me happy', 'pronunciation': 'too muh rahn uh-RUH/uh-RUHZ', 'category': 'romantic', 'difficulty': 'advanced', 'requiredLevel': 35},

    // Idioms
    {'phrase': 'Avoir le coup de foudre', 'translation': 'Love at first sight (lightning strike)', 'pronunciation': 'ah-VWAHR luh koo duh FOODR', 'category': 'idioms', 'difficulty': 'fluent', 'requiredLevel': 76},
    {'phrase': 'Avoir le cafard', 'translation': 'To feel down (to have the cockroach)', 'pronunciation': 'ah-VWAHR luh kah-FAHR', 'category': 'idioms', 'difficulty': 'fluent', 'requiredLevel': 78},
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

    // Compliments continued
    {'phrase': 'Du siehst toll aus', 'translation': 'You look great', 'pronunciation': 'doo zeest tohl OWS', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 13},
    {'phrase': 'Dein Stil ist super', 'translation': 'Your style is great', 'pronunciation': 'dyn shteel ist ZOO-per', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 14},

    // Conversation Starters
    {'phrase': 'Woher kommst du?', 'translation': 'Where are you from?', 'pronunciation': 'voh-HAYR komst doo', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 5},
    {'phrase': 'Was machst du beruflich?', 'translation': 'What do you do for work?', 'pronunciation': 'vahs MAHKHST doo beh-ROOF-likh', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 15},
    {'phrase': 'Was machst du gerne in deiner Freizeit?', 'translation': 'What do you like to do in your free time?', 'pronunciation': 'vahs MAHKHST doo GEHR-neh in DYE-nehr FRY-tsyt', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 16},
    {'phrase': 'Reist du gerne?', 'translation': 'Do you like to travel?', 'pronunciation': 'ryst doo GEHR-neh', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 6},
    {'phrase': 'Was für Musik hörst du?', 'translation': 'What music do you listen to?', 'pronunciation': 'vahs foor moo-ZEEK hurst doo', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 14},

    // Date Planning
    {'phrase': 'Hast du Lust auf einen Kaffee?', 'translation': 'Would you like to have coffee?', 'pronunciation': 'hahst doo loost owf AY-nen KAH-feh', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 18},
    {'phrase': 'Wann hast du Zeit?', 'translation': 'When are you free?', 'pronunciation': 'vahn hahst doo TSYT', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 19},
    {'phrase': 'Wo sollen wir uns treffen?', 'translation': 'Where should we meet?', 'pronunciation': 'voh ZOH-len veer oons TREH-fen', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 20},
    {'phrase': 'Ich hole dich ab', 'translation': 'I\'ll pick you up', 'pronunciation': 'ikh HOH-leh dikh AHP', 'category': 'datePlanning', 'difficulty': 'advanced', 'requiredLevel': 28},

    // Food & Dining
    {'phrase': 'Die Rechnung, bitte', 'translation': 'The check, please', 'pronunciation': 'dee REKH-noong BIT-teh', 'category': 'foodDining', 'difficulty': 'beginner', 'requiredLevel': 8},
    {'phrase': 'Das schmeckt wunderbar!', 'translation': 'This tastes wonderful!', 'pronunciation': 'dahs SHMEKT VOON-der-bahr', 'category': 'foodDining', 'difficulty': 'beginner', 'requiredLevel': 7},
    {'phrase': 'Was empfehlen Sie?', 'translation': 'What do you recommend?', 'pronunciation': 'vahs emp-FAY-len zee', 'category': 'foodDining', 'difficulty': 'intermediate', 'requiredLevel': 12},
    {'phrase': 'Einen Tisch für zwei, bitte', 'translation': 'A table for two, please', 'pronunciation': 'AY-nen TISH foor TSVY BIT-teh', 'category': 'foodDining', 'difficulty': 'beginner', 'requiredLevel': 9},

    // Travel & Culture
    {'phrase': 'Wo ist...?', 'translation': 'Where is...?', 'pronunciation': 'voh IST', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 4},
    {'phrase': 'Was kostet das?', 'translation': 'How much does this cost?', 'pronunciation': 'vahs KOS-tet dahs', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 5},
    {'phrase': 'Ich bin zu Besuch hier', 'translation': 'I\'m visiting here', 'pronunciation': 'ikh bin tsoo beh-ZOOKH heer', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 6},
    {'phrase': 'Können Sie mir helfen?', 'translation': 'Can you help me?', 'pronunciation': 'KUR-nen zee meer HEHL-fen', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 7},

    // Romantic continued
    {'phrase': 'Du fehlst mir', 'translation': 'I miss you', 'pronunciation': 'doo fahlst meer', 'category': 'romantic', 'difficulty': 'advanced', 'requiredLevel': 40},
    {'phrase': 'Du machst mich glücklich', 'translation': 'You make me happy', 'pronunciation': 'doo mahkhst mikh GLOOK-likh', 'category': 'romantic', 'difficulty': 'advanced', 'requiredLevel': 35},

    // Idioms
    {'phrase': 'Schmetterlinge im Bauch haben', 'translation': 'To have butterflies in the stomach', 'pronunciation': 'SHMET-ter-ling-eh im BOWKH HAH-ben', 'category': 'idioms', 'difficulty': 'fluent', 'requiredLevel': 76},
    {'phrase': 'Auf Wolke sieben schweben', 'translation': 'To be on cloud nine', 'pronunciation': 'owf VOLK-eh ZEE-ben SHVAY-ben', 'category': 'idioms', 'difficulty': 'fluent', 'requiredLevel': 78},
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

    // Compliments continued
    {'phrase': 'Sei molto affascinante', 'translation': 'You are very charming', 'pronunciation': 'say MOHL-toh ahf-fah-shee-NAHN-teh', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 13},
    {'phrase': 'Mi piace il tuo stile', 'translation': 'I like your style', 'pronunciation': 'mee PYAH-cheh eel TOO-oh STEE-leh', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 14},

    // Conversation Starters
    {'phrase': 'Di dove sei?', 'translation': 'Where are you from?', 'pronunciation': 'dee DOH-veh SAY', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 5},
    {'phrase': 'Che lavoro fai?', 'translation': 'What do you do for work?', 'pronunciation': 'keh lah-VOH-roh FYE', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 15},
    {'phrase': 'Cosa ti piace fare?', 'translation': 'What do you like to do?', 'pronunciation': 'KOH-sah tee PYAH-cheh FAH-reh', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 16},
    {'phrase': 'Ti piace viaggiare?', 'translation': 'Do you like to travel?', 'pronunciation': 'tee PYAH-cheh vyahd-JAH-reh', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 6},
    {'phrase': 'Che musica ascolti?', 'translation': 'What music do you listen to?', 'pronunciation': 'keh MOO-zee-kah ahs-KOHL-tee', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 14},

    // Date Planning
    {'phrase': 'Prendiamo un caffè?', 'translation': 'Shall we have a coffee?', 'pronunciation': 'prehn-DYAH-moh oon kahf-FEH', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 18},
    {'phrase': 'Quando sei libera/o?', 'translation': 'When are you free?', 'pronunciation': 'KWAHN-doh say LEE-beh-rah/oh', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 19},
    {'phrase': 'Dove ci vediamo?', 'translation': 'Where shall we meet?', 'pronunciation': 'DOH-veh chee veh-DYAH-moh', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 20},
    {'phrase': 'Passo a prenderti', 'translation': 'I\'ll come pick you up', 'pronunciation': 'PAHS-soh ah PREHN-dehr-tee', 'category': 'datePlanning', 'difficulty': 'advanced', 'requiredLevel': 28},

    // Food & Dining
    {'phrase': 'Il conto, per favore', 'translation': 'The check, please', 'pronunciation': 'eel KOHN-toh pehr fah-VOH-reh', 'category': 'foodDining', 'difficulty': 'beginner', 'requiredLevel': 8},
    {'phrase': 'È squisito!', 'translation': 'It\'s exquisite!', 'pronunciation': 'eh skwee-ZEE-toh', 'category': 'foodDining', 'difficulty': 'beginner', 'requiredLevel': 7},
    {'phrase': 'Cosa consiglia?', 'translation': 'What do you recommend?', 'pronunciation': 'KOH-sah kohn-SEE-lyah', 'category': 'foodDining', 'difficulty': 'intermediate', 'requiredLevel': 12},
    {'phrase': 'Un tavolo per due, per favore', 'translation': 'A table for two, please', 'pronunciation': 'oon TAH-voh-loh pehr DOO-eh pehr fah-VOH-reh', 'category': 'foodDining', 'difficulty': 'beginner', 'requiredLevel': 9},

    // Travel & Culture
    {'phrase': 'Dove si trova...?', 'translation': 'Where is...?', 'pronunciation': 'DOH-veh see TROH-vah', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 4},
    {'phrase': 'Quanto costa?', 'translation': 'How much does it cost?', 'pronunciation': 'KWAHN-toh KOHS-tah', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 5},
    {'phrase': 'Sono in visita', 'translation': 'I\'m visiting', 'pronunciation': 'SOH-noh een vee-ZEE-tah', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 6},
    {'phrase': 'Mi può aiutare?', 'translation': 'Can you help me?', 'pronunciation': 'mee pwoh ah-yoo-TAH-reh', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 7},

    // Romantic continued
    {'phrase': 'Mi manchi', 'translation': 'I miss you', 'pronunciation': 'mee MAHN-kee', 'category': 'romantic', 'difficulty': 'advanced', 'requiredLevel': 40},
    {'phrase': 'Mi rendi felice', 'translation': 'You make me happy', 'pronunciation': 'mee REHN-dee feh-LEE-cheh', 'category': 'romantic', 'difficulty': 'advanced', 'requiredLevel': 35},

    // Idioms
    {'phrase': 'Avere le farfalle nello stomaco', 'translation': 'To have butterflies in the stomach', 'pronunciation': 'ah-VEH-reh leh fahr-FAHL-leh NEHL-loh STOH-mah-koh', 'category': 'idioms', 'difficulty': 'fluent', 'requiredLevel': 76},
    {'phrase': 'In bocca al lupo!', 'translation': 'Good luck! (In the wolf\'s mouth)', 'pronunciation': 'een BOHK-kah ahl LOO-poh', 'category': 'idioms', 'difficulty': 'fluent', 'requiredLevel': 78},
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

    // Compliments continued
    {'phrase': 'Você é muito charmoso/a', 'translation': 'You are very charming', 'pronunciation': 'voh-SEH eh MOO-ee-too shar-MOH-zoo/ah', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 13},
    {'phrase': 'Adoro seu estilo', 'translation': 'I love your style', 'pronunciation': 'ah-DOH-roo SEH-oo ehs-CHEE-loo', 'category': 'compliments', 'difficulty': 'intermediate', 'requiredLevel': 14},

    // Conversation Starters
    {'phrase': 'De onde você é?', 'translation': 'Where are you from?', 'pronunciation': 'jee OHN-jee voh-SEH eh', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 5},
    {'phrase': 'O que você faz?', 'translation': 'What do you do for a living?', 'pronunciation': 'oo kee voh-SEH FAHZ', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 15},
    {'phrase': 'O que você gosta de fazer?', 'translation': 'What do you like to do?', 'pronunciation': 'oo kee voh-SEH GOHSH-tah jee fah-ZEHR', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 16},
    {'phrase': 'Você gosta de viajar?', 'translation': 'Do you like to travel?', 'pronunciation': 'voh-SEH GOHSH-tah jee vee-ah-ZHAHR', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 6},
    {'phrase': 'Que tipo de música você gosta?', 'translation': 'What kind of music do you like?', 'pronunciation': 'kee CHEE-poo jee MOO-zee-kah voh-SEH GOHSH-tah', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 14},

    // Date Planning
    {'phrase': 'Vamos tomar um café?', 'translation': 'Shall we have a coffee?', 'pronunciation': 'VAH-mohs toh-MAHR oom kah-FEH', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 18},
    {'phrase': 'Quando você está livre?', 'translation': 'When are you free?', 'pronunciation': 'KWAHN-doo voh-SEH ehs-TAH LEE-vree', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 19},
    {'phrase': 'Onde a gente se encontra?', 'translation': 'Where shall we meet?', 'pronunciation': 'OHN-jee ah ZHEHN-chee see ehn-KOHN-trah', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 20},
    {'phrase': 'Eu te busco', 'translation': 'I\'ll pick you up', 'pronunciation': 'eh-oo chee BOOS-koo', 'category': 'datePlanning', 'difficulty': 'advanced', 'requiredLevel': 28},

    // Food & Dining
    {'phrase': 'A conta, por favor', 'translation': 'The check, please', 'pronunciation': 'ah KOHN-tah pohr fah-VOHR', 'category': 'foodDining', 'difficulty': 'beginner', 'requiredLevel': 8},
    {'phrase': 'Está delicioso!', 'translation': 'This is delicious!', 'pronunciation': 'ehs-TAH deh-lee-see-OH-zoo', 'category': 'foodDining', 'difficulty': 'beginner', 'requiredLevel': 7},
    {'phrase': 'O que você recomenda?', 'translation': 'What do you recommend?', 'pronunciation': 'oo kee voh-SEH heh-koh-MEHN-dah', 'category': 'foodDining', 'difficulty': 'intermediate', 'requiredLevel': 12},
    {'phrase': 'Uma mesa para dois, por favor', 'translation': 'A table for two, please', 'pronunciation': 'OO-mah MEH-zah PAH-rah doys pohr fah-VOHR', 'category': 'foodDining', 'difficulty': 'beginner', 'requiredLevel': 9},

    // Travel & Culture
    {'phrase': 'Onde fica...?', 'translation': 'Where is...?', 'pronunciation': 'OHN-jee FEE-kah', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 4},
    {'phrase': 'Quanto custa?', 'translation': 'How much does it cost?', 'pronunciation': 'KWAHN-too KOOS-tah', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 5},
    {'phrase': 'Estou visitando', 'translation': 'I\'m visiting', 'pronunciation': 'ehs-TOH vee-zee-TAHN-doo', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 6},
    {'phrase': 'Pode me ajudar?', 'translation': 'Can you help me?', 'pronunciation': 'POH-jee mee ah-zhoo-DAHR', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 7},

    // Romantic continued
    {'phrase': 'Estou com saudade', 'translation': 'I miss you (longing)', 'pronunciation': 'ehs-TOH kohm sow-DAH-jee', 'category': 'romantic', 'difficulty': 'advanced', 'requiredLevel': 40},
    {'phrase': 'Você me faz feliz', 'translation': 'You make me happy', 'pronunciation': 'voh-SEH mee FAHZ feh-LEEZ', 'category': 'romantic', 'difficulty': 'advanced', 'requiredLevel': 35},

    // Brazilian Portuguese Slang
    {'phrase': 'E aí?', 'translation': 'What\'s up?', 'pronunciation': 'ee ah-EE', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 3},
    {'phrase': 'Beleza', 'translation': 'Cool / Alright', 'pronunciation': 'beh-LEH-zah', 'category': 'greetings', 'difficulty': 'beginner', 'requiredLevel': 4},
    {'phrase': 'Tô a fim de você', 'translation': 'I\'m into you', 'pronunciation': 'toh ah FEEM jee voh-SEH', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 32},
    {'phrase': 'Gata/Gato', 'translation': 'Hottie (cat - slang)', 'pronunciation': 'GAH-tah/GAH-too', 'category': 'flirty', 'difficulty': 'intermediate', 'requiredLevel': 20},
    {'phrase': 'Tá rolando um clima', 'translation': 'There\'s chemistry between us', 'pronunciation': 'tah hoh-LAHN-doo oom KLEE-mah', 'category': 'flirty', 'difficulty': 'advanced', 'requiredLevel': 35},

    // Idioms
    {'phrase': 'Ficar de queixo caído', 'translation': 'To be amazed (jaw dropped)', 'pronunciation': 'fee-KAHR jee KAY-shoo kah-EE-doo', 'category': 'idioms', 'difficulty': 'fluent', 'requiredLevel': 76},
    {'phrase': 'Matar a saudade', 'translation': 'To satisfy a longing', 'pronunciation': 'mah-TAHR ah sow-DAH-jee', 'category': 'idioms', 'difficulty': 'fluent', 'requiredLevel': 78},
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

    // Conversation Starters
    {'phrase': 'Where are you from?', 'translation': 'Where are you from?', 'pronunciation': 'wehr ar yoo from', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 5},
    {'phrase': 'What do you do for a living?', 'translation': 'What do you do for a living?', 'pronunciation': 'wot doo yoo doo for a LIV-ing', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 15},
    {'phrase': 'What are your hobbies?', 'translation': 'What are your hobbies?', 'pronunciation': 'wot ar yor HOB-eez', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 6},
    {'phrase': 'Do you like to travel?', 'translation': 'Do you like to travel?', 'pronunciation': 'doo yoo lyk too TRAV-el', 'category': 'conversationStarters', 'difficulty': 'beginner', 'requiredLevel': 7},
    {'phrase': 'What kind of music do you like?', 'translation': 'What kind of music do you like?', 'pronunciation': 'wot kynd ov MYOO-zik doo yoo lyk', 'category': 'conversationStarters', 'difficulty': 'intermediate', 'requiredLevel': 14},

    // Date Planning
    {'phrase': 'Would you like to grab coffee?', 'translation': 'Would you like to grab coffee?', 'pronunciation': 'wood yoo lyk too grab KOF-ee', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 18},
    {'phrase': 'When are you free?', 'translation': 'When are you free?', 'pronunciation': 'wen ar yoo free', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 19},
    {'phrase': 'Let\'s meet at...', 'translation': 'Let\'s meet at...', 'pronunciation': 'lets meet at', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 20},
    {'phrase': 'I\'ll pick you up', 'translation': 'I\'ll pick you up', 'pronunciation': 'ayl pik yoo up', 'category': 'datePlanning', 'difficulty': 'intermediate', 'requiredLevel': 22},

    // Food & Dining
    {'phrase': 'Can I see the menu, please?', 'translation': 'Can I see the menu, please?', 'pronunciation': 'kan ai see thee MEN-yoo pleez', 'category': 'foodDining', 'difficulty': 'beginner', 'requiredLevel': 8},
    {'phrase': 'This is delicious!', 'translation': 'This is delicious!', 'pronunciation': 'this iz dee-LISH-us', 'category': 'foodDining', 'difficulty': 'beginner', 'requiredLevel': 7},
    {'phrase': 'Check, please', 'translation': 'Check, please', 'pronunciation': 'chek pleez', 'category': 'foodDining', 'difficulty': 'beginner', 'requiredLevel': 8},
    {'phrase': 'What do you recommend?', 'translation': 'What do you recommend?', 'pronunciation': 'wot doo yoo rek-oh-MEND', 'category': 'foodDining', 'difficulty': 'intermediate', 'requiredLevel': 12},

    // Travel & Culture
    {'phrase': 'Where is the nearest...?', 'translation': 'Where is the nearest...?', 'pronunciation': 'wehr iz thee NEER-est', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 4},
    {'phrase': 'How much does this cost?', 'translation': 'How much does this cost?', 'pronunciation': 'how much duz this kost', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 5},
    {'phrase': 'I\'m visiting from...', 'translation': 'I\'m visiting from...', 'pronunciation': 'aym VIZ-it-ing from', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 6},
    {'phrase': 'Could you help me?', 'translation': 'Could you help me?', 'pronunciation': 'kood yoo help mee', 'category': 'travelCulture', 'difficulty': 'beginner', 'requiredLevel': 7},

    // Romantic continued
    {'phrase': 'I miss you', 'translation': 'I miss you', 'pronunciation': 'ai mis yoo', 'category': 'romantic', 'difficulty': 'advanced', 'requiredLevel': 40},
    {'phrase': 'You mean everything to me', 'translation': 'You mean everything to me', 'pronunciation': 'yoo meen EV-ree-thing too mee', 'category': 'romantic', 'difficulty': 'advanced', 'requiredLevel': 42},
    {'phrase': 'You make me so happy', 'translation': 'You make me so happy', 'pronunciation': 'yoo mayk mee soh HAP-ee', 'category': 'romantic', 'difficulty': 'advanced', 'requiredLevel': 35},

    // Idioms
    {'phrase': 'Break the ice', 'translation': 'To initiate conversation', 'pronunciation': 'breyk thee ais', 'category': 'idioms', 'difficulty': 'fluent', 'requiredLevel': 76},
    {'phrase': 'Hit it off', 'translation': 'To immediately get along well', 'pronunciation': 'hit it off', 'category': 'idioms', 'difficulty': 'fluent', 'requiredLevel': 77},
    {'phrase': 'On cloud nine', 'translation': 'Extremely happy', 'pronunciation': 'on klowd nyn', 'category': 'idioms', 'difficulty': 'fluent', 'requiredLevel': 78},
    {'phrase': 'Love is blind', 'translation': 'Love overlooks flaws', 'pronunciation': 'luv iz blynd', 'category': 'idioms', 'difficulty': 'fluent', 'requiredLevel': 79},
  ];

  /// Get cultural quizzes for a country
  static List<Map<String, dynamic>> getQuizzesForCountry(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'ES':
        return _spanishQuizzes;
      case 'FR':
        return _frenchQuizzes;
      case 'DE':
        return _germanQuizzes;
      case 'IT':
        return _italianQuizzes;
      case 'PT':
      case 'BR':
        return _portugueseQuizzes;
      case 'US':
      case 'GB':
        return _englishQuizzes;
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

  static const List<Map<String, dynamic>> _germanQuizzes = [
    {
      'id': 'de_culture_1',
      'title': 'German Culture Basics',
      'description': 'Test your knowledge of German culture and customs',
      'languageCode': 'de',
      'countryCode': 'DE',
      'countryName': 'Germany',
      'difficulty': 'easy',
      'questions': [
        {
          'id': 'de_q1',
          'question': 'What is "Prost" used for in Germany?',
          'options': ['Saying goodbye', 'Toasting with drinks', 'Ordering food', 'Apologizing'],
          'correctOptionIndex': 1,
          'explanation': 'Prost is the German word for cheers, used when clinking glasses. Eye contact during the toast is important.',
        },
        {
          'id': 'de_q2',
          'question': 'What is Oktoberfest traditionally about?',
          'options': ['Wine tasting', 'Beer festival', 'Music festival', 'Film festival'],
          'correctOptionIndex': 1,
          'explanation': 'Oktoberfest in Munich is the world\'s largest beer festival, running for about two weeks in late September to early October.',
        },
      ],
    },
  ];

  static const List<Map<String, dynamic>> _italianQuizzes = [
    {
      'id': 'it_culture_1',
      'title': 'Italian Culture Basics',
      'description': 'Test your knowledge of Italian culture and traditions',
      'languageCode': 'it',
      'countryCode': 'IT',
      'countryName': 'Italy',
      'difficulty': 'easy',
      'questions': [
        {
          'id': 'it_q1',
          'question': 'What is "la passeggiata" in Italian culture?',
          'options': ['A pasta dish', 'An evening stroll', 'A greeting', 'A market'],
          'correctOptionIndex': 1,
          'explanation': 'La passeggiata is the traditional Italian evening stroll through the town center, a social ritual.',
        },
        {
          'id': 'it_q2',
          'question': 'When should you NOT order a cappuccino in Italy?',
          'options': ['Before 9 AM', 'After lunch', 'On weekends', 'In summer'],
          'correctOptionIndex': 1,
          'explanation': 'Italians consider cappuccino a morning drink. Ordering one after a meal is seen as unusual.',
        },
      ],
    },
  ];

  static const List<Map<String, dynamic>> _portugueseQuizzes = [
    {
      'id': 'pt_culture_1',
      'title': 'Portuguese & Brazilian Culture',
      'description': 'Test your knowledge of Lusophone culture',
      'languageCode': 'pt',
      'countryCode': 'PT',
      'countryName': 'Portugal',
      'difficulty': 'easy',
      'questions': [
        {
          'id': 'pt_q1',
          'question': 'What is "saudade" in Portuguese culture?',
          'options': ['A dance', 'A deep longing/nostalgia', 'A greeting', 'A meal'],
          'correctOptionIndex': 1,
          'explanation': 'Saudade is a uniquely Portuguese word describing a deep emotional state of nostalgic longing for something or someone absent.',
        },
        {
          'id': 'pt_q2',
          'question': 'How many kisses are typical in a Brazilian greeting?',
          'options': ['One', 'Two', 'Three', 'None'],
          'correctOptionIndex': 1,
          'explanation': 'Brazilians typically greet with two kisses on alternating cheeks, though it can vary by region.',
        },
      ],
    },
  ];

  static const List<Map<String, dynamic>> _englishQuizzes = [
    {
      'id': 'en_culture_1',
      'title': 'English-Speaking Culture',
      'description': 'Test your knowledge of English-speaking cultures',
      'languageCode': 'en',
      'countryCode': 'US',
      'countryName': 'United States',
      'difficulty': 'easy',
      'questions': [
        {
          'id': 'en_q1',
          'question': 'What does "How do you do?" actually mean in British English?',
          'options': ['Asking about health', 'A formal greeting', 'Asking about work', 'Asking directions'],
          'correctOptionIndex': 1,
          'explanation': '"How do you do?" is a formal greeting in British English, not a genuine question. The expected response is "How do you do?" back.',
        },
        {
          'id': 'en_q2',
          'question': 'What is considered a normal tipping percentage in American restaurants?',
          'options': ['5%', '10%', '15-20%', 'Tips are not expected'],
          'correctOptionIndex': 2,
          'explanation': 'In the United States, tipping 15-20% at restaurants is standard and expected as part of the service culture.',
        },
      ],
    },
  ];
}
