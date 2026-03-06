import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/entities.dart';
import '../bloc/language_learning_bloc.dart';
import '../widgets/gamified_quiz_widget.dart';

/// Quiz session screen that generates language-specific quiz questions
/// and wraps the GamifiedQuizWidget.
class QuizSessionScreen extends StatelessWidget {
  final String languageCode;
  final String? category;

  const QuizSessionScreen({
    super.key,
    required this.languageCode,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    final language = SupportedLanguage.getByCode(languageCode);
    final languageName = language?.name ?? languageCode;
    final questions = _generateQuestions(languageCode, category);

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            '$languageName Quiz',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.quiz_outlined, color: AppColors.richGold, size: 64),
              SizedBox(height: 16),
              Text(
                'No quiz questions available yet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return GamifiedQuizWidget(
      title: category != null
          ? '$languageName - ${_formatCategory(category!)}'
          : '$languageName Quiz',
      questions: questions,
      xpReward: 30,
      passingScore: 60,
      showTimer: true,
      timerSeconds: 20,
      onResult: (score, total, passed) {
        if (passed) {
          try {
            context.read<LanguageLearningBloc>().add(const FinishQuiz());
          } catch (_) {}
        }
      },
    );
  }

  String _formatCategory(String cat) {
    return cat
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (m) => ' ${m.group(0)}',
        )
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  /// Generate quiz questions based on language code.
  /// These are sample questions — in production, these would come from Firestore
  /// or the seed data based on user progress.
  static List<QuizItem> _generateQuestions(String languageCode, String? category) {
    switch (languageCode) {
      case 'es':
        return _spanishQuestions;
      case 'fr':
        return _frenchQuestions;
      case 'it':
        return _italianQuestions;
      case 'de':
        return _germanQuestions;
      case 'pt':
      case 'pt-BR':
        return _portugueseQuestions;
      case 'en':
        return _englishQuestions;
      default:
        return _spanishQuestions;
    }
  }

  static const _spanishQuestions = [
    QuizItem(
      question: 'What does "Hola" mean?',
      options: ['Goodbye', 'Hello', 'Thank you', 'Please'],
      correctIndex: 1,
      explanation: '"Hola" is the most common Spanish greeting, meaning "Hello".',
    ),
    QuizItem(
      question: 'How do you say "Thank you" in Spanish?',
      options: ['De nada', 'Lo siento', 'Gracias', 'Por favor'],
      correctIndex: 2,
      explanation: '"Gracias" means "Thank you". "De nada" means "You\'re welcome".',
    ),
    QuizItem(
      question: 'What is "Te quiero" in English?',
      options: ['I miss you', 'I love you', 'I want you', 'I need you'],
      correctIndex: 1,
      explanation: '"Te quiero" literally means "I want you" but is used to say "I love you".',
    ),
    QuizItem(
      question: 'How do you say "Beautiful" in Spanish?',
      options: ['Bonito', 'Hermoso', 'Guapo', 'All of these'],
      correctIndex: 3,
      explanation: 'All three words can mean "beautiful" in different contexts.',
    ),
    QuizItem(
      question: 'What does "Buenos dias" mean?',
      options: ['Good night', 'Good afternoon', 'Good morning', 'Goodbye'],
      correctIndex: 2,
      explanation: '"Buenos dias" means "Good morning". "Buenas noches" = Good night.',
    ),
    QuizItem(
      question: 'What does "¿Cómo estás?" mean?',
      options: ['Where are you?', 'How are you?', 'What is your name?', 'How old are you?'],
      correctIndex: 1,
      explanation: '"¿Cómo estás?" means "How are you?" in informal Spanish.',
    ),
    QuizItem(
      question: 'Which article goes with "casa" (house)?',
      options: ['El', 'La', 'Los', 'Un'],
      correctIndex: 1,
      explanation: '"Casa" is feminine, so it takes "la": la casa.',
    ),
    QuizItem(
      question: 'What time do Spaniards typically eat dinner?',
      options: ['6 PM', '7 PM', '9-10 PM', '5 PM'],
      correctIndex: 2,
      explanation: 'Spaniards typically eat dinner late, usually between 9-10 PM.',
    ),
    QuizItem(
      question: 'Which phrase would you use to ask for the check?',
      options: ['La carta', 'La cuenta', 'La mesa', 'El menú'],
      correctIndex: 1,
      explanation: '"La cuenta, por favor" means "The check, please".',
    ),
    QuizItem(
      question: 'How do you say "I miss you" in Spanish?',
      options: ['Te amo', 'Te quiero', 'Te echo de menos', 'Te necesito'],
      correctIndex: 2,
      explanation: '"Te echo de menos" means "I miss you" in Spain. In Latin America: "Te extraño".',
    ),
    QuizItem(
      question: 'What is "Mucho gusto"?',
      options: ['Good taste', 'Nice to meet you', 'Thank you much', 'Very well'],
      correctIndex: 1,
      explanation: '"Mucho gusto" literally means "Much pleasure" and is used for "Nice to meet you".',
    ),
    QuizItem(
      question: 'What does "¿Cuánto cuesta?" mean?',
      options: ['How far?', 'How much does it cost?', 'How long?', 'What is it?'],
      correctIndex: 1,
      explanation: '"¿Cuánto cuesta?" means "How much does it cost?".',
    ),
    QuizItem(
      question: 'How do you say "Goodbye" in Spanish?',
      options: ['Buenas', 'Hasta luego', 'Hola', 'Gracias'],
      correctIndex: 1,
      explanation: '"Hasta luego" means "See you later". "Adiós" is another way to say goodbye.',
    ),
    QuizItem(
      question: 'What does "Me gustas mucho" mean?',
      options: ['I eat a lot', 'I like you a lot', 'I sleep a lot', 'I walk a lot'],
      correctIndex: 1,
      explanation: '"Me gustas mucho" means "I like you a lot" — used in romantic contexts.',
    ),
    QuizItem(
      question: 'Which is the correct plural of "amigo"?',
      options: ['Amiges', 'Amigos', 'Amigoes', 'Amigás'],
      correctIndex: 1,
      explanation: 'Words ending in -o form their plural by adding -s: amigo → amigos.',
    ),
    QuizItem(
      question: 'What is "siesta" in Spanish culture?',
      options: ['A party', 'An afternoon nap', 'A dance', 'A meal'],
      correctIndex: 1,
      explanation: 'Siesta is a traditional afternoon rest taken during the hottest part of the day.',
    ),
    QuizItem(
      question: 'How do you say "Where are you from?" in Spanish?',
      options: ['¿Cómo te llamas?', '¿Cuántos años tienes?', '¿De dónde eres?', '¿Qué hora es?'],
      correctIndex: 2,
      explanation: '"¿De dónde eres?" means "Where are you from?".',
    ),
    QuizItem(
      question: 'What does "estar en las nubes" mean?',
      options: ['To be flying', 'To be daydreaming', 'To be in clouds', 'To be sleeping'],
      correctIndex: 1,
      explanation: 'This idiom means "to be daydreaming" — literally "to be in the clouds".',
    ),
    QuizItem(
      question: 'How do Spanish friends greet each other?',
      options: ['Handshake', 'Two kisses on cheeks', 'Bow', 'Fist bump'],
      correctIndex: 1,
      explanation: 'In Spain, friends greet with two kisses, one on each cheek.',
    ),
  ];

  static const _frenchQuestions = [
    QuizItem(
      question: 'What does "Bonjour" mean?',
      options: ['Good night', 'Hello/Good day', 'Goodbye', 'Please'],
      correctIndex: 1,
      explanation: '"Bonjour" is the standard French greeting meaning "Hello" or "Good day".',
    ),
    QuizItem(
      question: 'How do you say "I love you" in French?',
      options: ['Je t\'aime', 'Je suis', 'Merci', 'S\'il vous plait'],
      correctIndex: 0,
      explanation: '"Je t\'aime" is the French expression for "I love you".',
    ),
    QuizItem(
      question: 'What is "Merci beaucoup"?',
      options: ['You\'re welcome', 'Excuse me', 'Thank you very much', 'See you later'],
      correctIndex: 2,
      explanation: '"Merci beaucoup" means "Thank you very much". "Merci" alone means "Thank you".',
    ),
    QuizItem(
      question: 'How do you say "My name is..." in French?',
      options: ['Je suis...', 'Je m\'appelle...', 'J\'ai...', 'Je veux...'],
      correctIndex: 1,
      explanation: '"Je m\'appelle..." literally means "I call myself..." and is used to introduce yourself.',
    ),
    QuizItem(
      question: 'What does "Au revoir" mean?',
      options: ['Hello', 'Please', 'Goodbye', 'Sorry'],
      correctIndex: 2,
      explanation: '"Au revoir" means "Goodbye". Literally "Until we see each other again".',
    ),
    QuizItem(
      question: 'Which article goes with "maison" (house)?',
      options: ['Le', 'La', 'Les', 'Un'],
      correctIndex: 1,
      explanation: '"Maison" is feminine: la maison.',
    ),
    QuizItem(
      question: 'What is "la bise" in French culture?',
      options: ['A bread', 'A kiss greeting', 'A wine', 'A dance'],
      correctIndex: 1,
      explanation: 'La bise is the French custom of greeting with kisses on the cheeks.',
    ),
    QuizItem(
      question: 'How do you say "I miss you" in French?',
      options: ['Je t\'aime', 'Tu me manques', 'Je suis triste', 'Je te veux'],
      correctIndex: 1,
      explanation: '"Tu me manques" literally means "You are missing from me".',
    ),
    QuizItem(
      question: 'What is "s\'il vous plaît"?',
      options: ['Thank you', 'Excuse me', 'Please', 'Sorry'],
      correctIndex: 2,
      explanation: '"S\'il vous plaît" means "Please" (formal). Informal: "s\'il te plaît".',
    ),
    QuizItem(
      question: 'Which phrase asks "How much does it cost?"',
      options: ['Où est...?', 'Combien ça coûte?', 'Comment dire?', 'Quelle heure est-il?'],
      correctIndex: 1,
      explanation: '"Combien ça coûte?" means "How much does it cost?".',
    ),
    QuizItem(
      question: 'What is the most important meal in France?',
      options: ['Breakfast', 'Lunch', 'Dinner', 'Afternoon tea'],
      correctIndex: 1,
      explanation: 'Lunch (le déjeuner) is traditionally the most important meal, lasting 1-2 hours.',
    ),
    QuizItem(
      question: 'How do you say "beautiful" (feminine) in French?',
      options: ['Beau', 'Belle', 'Bon', 'Bien'],
      correctIndex: 1,
      explanation: '"Belle" is the feminine form. "Beau" is masculine.',
    ),
    QuizItem(
      question: 'What does "avoir le coup de foudre" mean?',
      options: ['To be angry', 'Love at first sight', 'To be scared', 'To have a headache'],
      correctIndex: 1,
      explanation: 'Literally "to have a lightning strike" — means love at first sight.',
    ),
    QuizItem(
      question: 'How do you say "Where is...?" in French?',
      options: ['Quand est...?', 'Comment est...?', 'Où est...?', 'Qui est...?'],
      correctIndex: 2,
      explanation: '"Où est...?" means "Where is...?".',
    ),
    QuizItem(
      question: 'What does "C\'est délicieux!" mean?',
      options: ['It\'s terrible!', 'It\'s delicious!', 'It\'s expensive!', 'It\'s far!'],
      correctIndex: 1,
      explanation: '"C\'est délicieux!" means "This is delicious!".',
    ),
    QuizItem(
      question: 'How do you ask "Do you like to travel?" in French?',
      options: ['Tu manges?', 'Tu aimes voyager?', 'Tu travailles?', 'Tu danses?'],
      correctIndex: 1,
      explanation: '"Tu aimes voyager?" means "Do you like to travel?".',
    ),
    QuizItem(
      question: 'What does "Enchanté(e)" mean?',
      options: ['Enchanted', 'Nice to meet you', 'Thank you', 'Goodbye'],
      correctIndex: 1,
      explanation: '"Enchanté(e)" literally means "Enchanted" and is used for "Nice to meet you".',
    ),
    QuizItem(
      question: 'How do you say "the check, please" in French?',
      options: ['Le menu', 'L\'addition', 'La carte', 'Le plat'],
      correctIndex: 1,
      explanation: '"L\'addition, s\'il vous plaît" means "The check, please".',
    ),
    QuizItem(
      question: 'What does "À bientôt" mean?',
      options: ['Goodbye forever', 'See you soon', 'Good morning', 'Thank you'],
      correctIndex: 1,
      explanation: '"À bientôt" means "See you soon".',
    ),
    QuizItem(
      question: 'How many kisses are typical in a French greeting?',
      options: ['One', 'Two to four', 'Five', 'None'],
      correctIndex: 1,
      explanation: 'The number varies by region (1 to 4), but 2 is most common in Paris.',
    ),
  ];

  static const _italianQuestions = [
    QuizItem(
      question: 'What does "Ciao" mean?',
      options: ['Only hello', 'Only goodbye', 'Both hello and goodbye', 'Thank you'],
      correctIndex: 2,
      explanation: '"Ciao" is used informally for both "Hello" and "Goodbye" in Italian.',
    ),
    QuizItem(
      question: 'How do you say "I love you" in Italian?',
      options: ['Ti amo', 'Ti voglio', 'Mi piaci', 'Ti adoro'],
      correctIndex: 0,
      explanation: '"Ti amo" is the strongest way to say "I love you" in Italian.',
    ),
    QuizItem(
      question: 'What is "Buongiorno"?',
      options: ['Good night', 'Good morning/day', 'Good evening', 'Goodbye'],
      correctIndex: 1,
      explanation: '"Buongiorno" means "Good morning" or "Good day" in Italian.',
    ),
    QuizItem(
      question: 'How do you say "Thank you" in Italian?',
      options: ['Prego', 'Scusa', 'Grazie', 'Per favore'],
      correctIndex: 2,
      explanation: '"Grazie" means "Thank you". "Prego" means "You\'re welcome".',
    ),
    QuizItem(
      question: 'What does "Bellissimo" mean?',
      options: ['Very ugly', 'Very beautiful', 'Very big', 'Very fast'],
      correctIndex: 1,
      explanation: '"Bellissimo" is the superlative of "bello" (beautiful), meaning "very beautiful".',
    ),
    QuizItem(
      question: 'What is "la passeggiata"?',
      options: ['A pasta dish', 'An evening stroll', 'A greeting', 'A market'],
      correctIndex: 1,
      explanation: 'La passeggiata is the Italian evening stroll — a beloved social tradition.',
    ),
    QuizItem(
      question: 'When should you NOT order cappuccino in Italy?',
      options: ['Before 9 AM', 'After lunch', 'On weekends', 'In summer'],
      correctIndex: 1,
      explanation: 'Italians consider cappuccino a morning drink. Ordering after a meal is unusual.',
    ),
    QuizItem(
      question: 'How do you say "I miss you" in Italian?',
      options: ['Ti amo', 'Mi manchi', 'Mi piaci', 'Ti voglio'],
      correctIndex: 1,
      explanation: '"Mi manchi" literally means "You are missing from me".',
    ),
    QuizItem(
      question: 'What does "Piacere" mean?',
      options: ['Pleasure/Nice to meet you', 'Please', 'Thank you', 'Goodbye'],
      correctIndex: 0,
      explanation: '"Piacere" means "Pleasure" and is used for "Nice to meet you".',
    ),
    QuizItem(
      question: 'How do you ask "How much does it cost?" in Italian?',
      options: ['Dove si trova?', 'Quanto costa?', 'Come stai?', 'Che ore sono?'],
      correctIndex: 1,
      explanation: '"Quanto costa?" means "How much does it cost?".',
    ),
    QuizItem(
      question: 'What does "Arrivederci" mean?',
      options: ['Hello', 'Thank you', 'Goodbye', 'Excuse me'],
      correctIndex: 2,
      explanation: '"Arrivederci" means "Goodbye" — literally "Until we see each other again".',
    ),
    QuizItem(
      question: 'How do you say "A table for two" in Italian?',
      options: ['Un caffè per due', 'Un tavolo per due', 'Un piatto per due', 'Una camera per due'],
      correctIndex: 1,
      explanation: '"Un tavolo per due, per favore" means "A table for two, please".',
    ),
    QuizItem(
      question: 'What does "Mi piaci molto" mean?',
      options: ['I eat a lot', 'I like you a lot', 'I walk a lot', 'I sleep a lot'],
      correctIndex: 1,
      explanation: '"Mi piaci molto" means "I like you a lot" — used romantically.',
    ),
    QuizItem(
      question: 'What is "In bocca al lupo"?',
      options: ['In the wolf mouth (good luck)', 'A recipe', 'A dance', 'A greeting'],
      correctIndex: 0,
      explanation: 'This Italian idiom means "Good luck!" The response is "Crepi il lupo!".',
    ),
    QuizItem(
      question: 'How do you say "Where is...?" in Italian?',
      options: ['Come si dice?', 'Dove si trova?', 'Perché?', 'Chi è?'],
      correctIndex: 1,
      explanation: '"Dove si trova...?" means "Where is...?".',
    ),
    QuizItem(
      question: 'What does "aperitivo" refer to in Italian culture?',
      options: ['Dessert', 'Pre-dinner drinks & snacks', 'Breakfast', 'Lunch'],
      correctIndex: 1,
      explanation: 'Aperitivo is the Italian tradition of pre-dinner drinks with snacks.',
    ),
    QuizItem(
      question: 'How do you say "It\'s delicious!" in Italian?',
      options: ['È brutto!', 'È squisito!', 'È freddo!', 'È grande!'],
      correctIndex: 1,
      explanation: '"È squisito!" means "It\'s exquisite/delicious!".',
    ),
    QuizItem(
      question: 'What does "Come stai?" mean?',
      options: ['Where are you?', 'How are you?', 'What is your name?', 'How old are you?'],
      correctIndex: 1,
      explanation: '"Come stai?" means "How are you?" (informal).',
    ),
    QuizItem(
      question: 'How do you say "I love your style" in Italian?',
      options: ['Ti amo', 'Mi piace il tuo stile', 'Sei bello', 'Grazie mille'],
      correctIndex: 1,
      explanation: '"Mi piace il tuo stile" means "I like your style".',
    ),
    QuizItem(
      question: 'What does "Sei molto affascinante" mean?',
      options: ['You are tired', 'You are very charming', 'You are hungry', 'You are fast'],
      correctIndex: 1,
      explanation: '"Sei molto affascinante" means "You are very charming/fascinating".',
    ),
  ];

  static const _germanQuestions = [
    QuizItem(
      question: 'What does "Guten Tag" mean?',
      options: ['Good night', 'Good morning', 'Good day/Hello', 'Goodbye'],
      correctIndex: 2,
      explanation: '"Guten Tag" literally means "Good day" and is a standard German greeting.',
    ),
    QuizItem(
      question: 'How do you say "I love you" in German?',
      options: ['Ich liebe dich', 'Ich mag dich', 'Ich brauche dich', 'Ich will dich'],
      correctIndex: 0,
      explanation: '"Ich liebe dich" is the German expression for "I love you".',
    ),
    QuizItem(
      question: 'What is "Danke schon"?',
      options: ['Excuse me', 'I\'m sorry', 'Thank you very much', 'You\'re welcome'],
      correctIndex: 2,
      explanation: '"Danke schon" means "Thank you very much". "Danke" alone means "Thank you".',
    ),
    QuizItem(
      question: 'How do you say "Goodbye" in German?',
      options: ['Hallo', 'Bitte', 'Entschuldigung', 'Auf Wiedersehen'],
      correctIndex: 3,
      explanation: '"Auf Wiedersehen" literally means "Until we see again" and is formal goodbye.',
    ),
    QuizItem(
      question: 'What does "Schon" mean?',
      options: ['Ugly', 'Beautiful', 'Fast', 'Old'],
      correctIndex: 1,
      explanation: '"Schön" means "beautiful" or "nice" in German.',
    ),
    QuizItem(
      question: 'What does "Wie geht es dir?" mean?',
      options: ['Where are you?', 'How are you?', 'What is your name?', 'How old are you?'],
      correctIndex: 1,
      explanation: '"Wie geht es dir?" means "How are you?" (informal).',
    ),
    QuizItem(
      question: 'What is "Prost" used for in Germany?',
      options: ['Saying goodbye', 'Toasting with drinks', 'Ordering food', 'Apologizing'],
      correctIndex: 1,
      explanation: '"Prost" means "Cheers!" — eye contact during the toast is important.',
    ),
    QuizItem(
      question: 'How do you say "I miss you" in German?',
      options: ['Ich liebe dich', 'Du fehlst mir', 'Ich mag dich', 'Ich brauche dich'],
      correctIndex: 1,
      explanation: '"Du fehlst mir" literally means "You are missing from me".',
    ),
    QuizItem(
      question: 'What does "Was kostet das?" mean?',
      options: ['What is that?', 'How much does this cost?', 'Where is that?', 'When is it?'],
      correctIndex: 1,
      explanation: '"Was kostet das?" means "How much does this cost?".',
    ),
    QuizItem(
      question: 'How do you say "The check, please" in German?',
      options: ['Die Karte', 'Die Rechnung, bitte', 'Das Menü', 'Der Tisch'],
      correctIndex: 1,
      explanation: '"Die Rechnung, bitte" means "The check, please".',
    ),
    QuizItem(
      question: 'What does "Schmetterlinge im Bauch haben" mean?',
      options: ['To be sick', 'To have butterflies in the stomach', 'To be hungry', 'To be tired'],
      correctIndex: 1,
      explanation: 'This German idiom means having butterflies — being in love or nervous.',
    ),
    QuizItem(
      question: 'How do you say "Where are you from?" in German?',
      options: ['Wie heißt du?', 'Woher kommst du?', 'Was machst du?', 'Wie alt bist du?'],
      correctIndex: 1,
      explanation: '"Woher kommst du?" means "Where are you from?".',
    ),
    QuizItem(
      question: 'What does "Freut mich" mean?',
      options: ['I\'m happy', 'Nice to meet you', 'Thank you', 'Goodbye'],
      correctIndex: 1,
      explanation: '"Freut mich" literally means "Pleases me" — used for "Nice to meet you".',
    ),
    QuizItem(
      question: 'How do you say "Do you like to travel?" in German?',
      options: ['Magst du essen?', 'Reist du gerne?', 'Arbeitest du?', 'Tanzt du?'],
      correctIndex: 1,
      explanation: '"Reist du gerne?" means "Do you like to travel?".',
    ),
    QuizItem(
      question: 'What does "Tschüss" mean?',
      options: ['Hello', 'Thank you', 'Bye (casual)', 'Please'],
      correctIndex: 2,
      explanation: '"Tschüss" is an informal way to say goodbye in German.',
    ),
    QuizItem(
      question: 'What is Oktoberfest?',
      options: ['Wine festival', 'Beer festival', 'Music festival', 'Film festival'],
      correctIndex: 1,
      explanation: 'Oktoberfest in Munich is the world\'s largest beer festival.',
    ),
    QuizItem(
      question: 'How do you say "This tastes wonderful!" in German?',
      options: ['Das schmeckt wunderbar!', 'Das ist groß!', 'Das ist teuer!', 'Das ist kalt!'],
      correctIndex: 0,
      explanation: '"Das schmeckt wunderbar!" means "This tastes wonderful!".',
    ),
    QuizItem(
      question: 'What does "Du bist wunderschön" mean?',
      options: ['You are smart', 'You are beautiful', 'You are funny', 'You are tall'],
      correctIndex: 1,
      explanation: '"Du bist wunderschön" means "You are beautiful".',
    ),
    QuizItem(
      question: 'How do you say "Can you help me?" in German?',
      options: ['Können Sie mir helfen?', 'Was ist das?', 'Wo bin ich?', 'Wie spät ist es?'],
      correctIndex: 0,
      explanation: '"Können Sie mir helfen?" means "Can you help me?" (formal).',
    ),
    QuizItem(
      question: 'What does "Ich hole dich ab" mean?',
      options: ['I\'ll call you', 'I\'ll pick you up', 'I\'ll text you', 'I\'ll wait for you'],
      correctIndex: 1,
      explanation: '"Ich hole dich ab" means "I\'ll pick you up".',
    ),
  ];

  static const _portugueseQuestions = [
    QuizItem(
      question: 'What does "Ola" mean in Portuguese?',
      options: ['Goodbye', 'Hello', 'Thank you', 'Please'],
      correctIndex: 1,
      explanation: '"Ola" is the Portuguese greeting for "Hello".',
    ),
    QuizItem(
      question: 'How do you say "I love you" in Portuguese?',
      options: ['Eu te amo', 'Eu gosto', 'Eu preciso', 'Eu quero'],
      correctIndex: 0,
      explanation: '"Eu te amo" means "I love you" in Portuguese.',
    ),
    QuizItem(
      question: 'What is "Obrigado/Obrigada"?',
      options: ['Sorry', 'Please', 'Thank you', 'Goodbye'],
      correctIndex: 2,
      explanation: '"Obrigado" (male) / "Obrigada" (female) means "Thank you".',
    ),
    QuizItem(
      question: 'What does "Bom dia" mean?',
      options: ['Good night', 'Good afternoon', 'Good morning', 'Goodbye'],
      correctIndex: 2,
      explanation: '"Bom dia" means "Good morning". "Boa noite" = Good night.',
    ),
    QuizItem(
      question: 'How do you say "Beautiful" in Portuguese?',
      options: ['Feio', 'Bonito/Bonita', 'Grande', 'Pequeno'],
      correctIndex: 1,
      explanation: '"Bonito" (masculine) or "Bonita" (feminine) means "Beautiful".',
    ),
    QuizItem(
      question: 'What does "Tudo bem?" mean?',
      options: ['All bad?', 'Everything good?', 'What time?', 'Where is it?'],
      correctIndex: 1,
      explanation: '"Tudo bem?" means "Everything good?" — a casual Brazilian greeting.',
    ),
    QuizItem(
      question: 'What is "saudade" in Portuguese culture?',
      options: ['A dance', 'A deep longing/nostalgia', 'A greeting', 'A meal'],
      correctIndex: 1,
      explanation: 'Saudade is a uniquely Portuguese word for deep nostalgic longing.',
    ),
    QuizItem(
      question: 'How do you say "I miss you" in Portuguese?',
      options: ['Te amo', 'Estou com saudade', 'Boa noite', 'Tchau'],
      correctIndex: 1,
      explanation: '"Estou com saudade" expresses longing/missing someone.',
    ),
    QuizItem(
      question: 'What does "Quanto custa?" mean?',
      options: ['What is it?', 'How much does it cost?', 'Where is it?', 'When is it?'],
      correctIndex: 1,
      explanation: '"Quanto custa?" means "How much does it cost?".',
    ),
    QuizItem(
      question: 'How do you say "The check, please" in Portuguese?',
      options: ['O menu', 'A conta, por favor', 'A mesa', 'O prato'],
      correctIndex: 1,
      explanation: '"A conta, por favor" means "The check, please".',
    ),
    QuizItem(
      question: 'How many kisses are typical in a Brazilian greeting?',
      options: ['One', 'Two', 'Three', 'None'],
      correctIndex: 1,
      explanation: 'Brazilians typically greet with two kisses on alternating cheeks.',
    ),
    QuizItem(
      question: 'What does "Tchau" mean?',
      options: ['Hello', 'Please', 'Bye', 'Thank you'],
      correctIndex: 2,
      explanation: '"Tchau" is the informal Portuguese word for "Bye", borrowed from Italian "ciao".',
    ),
    QuizItem(
      question: 'How do you say "Where is...?" in Portuguese?',
      options: ['Como é?', 'Onde fica...?', 'Quando é?', 'Por quê?'],
      correctIndex: 1,
      explanation: '"Onde fica...?" means "Where is...?".',
    ),
    QuizItem(
      question: 'What does "E aí?" mean in Brazilian slang?',
      options: ['Goodbye', 'What\'s up?', 'Thank you', 'Excuse me'],
      correctIndex: 1,
      explanation: '"E aí?" is a very casual Brazilian greeting meaning "What\'s up?".',
    ),
    QuizItem(
      question: 'How do you say "You make me happy" in Portuguese?',
      options: ['Você me faz feliz', 'Você é bonita', 'Você é legal', 'Você tem razão'],
      correctIndex: 0,
      explanation: '"Você me faz feliz" means "You make me happy".',
    ),
    QuizItem(
      question: 'What does "Prazer" mean?',
      options: ['Please', 'Nice to meet you', 'Party', 'Food'],
      correctIndex: 1,
      explanation: '"Prazer" means "Pleasure" and is used for "Nice to meet you".',
    ),
    QuizItem(
      question: 'How do you say "Do you like to travel?" in Portuguese?',
      options: ['Você gosta de comer?', 'Você gosta de viajar?', 'Você gosta de dormir?', 'Você gosta de ler?'],
      correctIndex: 1,
      explanation: '"Você gosta de viajar?" means "Do you like to travel?".',
    ),
    QuizItem(
      question: 'What does "Gata/Gato" mean in Brazilian slang?',
      options: ['Cat (literally)', 'Hottie', 'Friend', 'Boss'],
      correctIndex: 1,
      explanation: 'While literally meaning "cat", Gata/Gato is Brazilian slang for an attractive person.',
    ),
    QuizItem(
      question: 'What does "Beleza" mean as a response?',
      options: ['Beautiful', 'Cool/Alright', 'Goodbye', 'Thank you'],
      correctIndex: 1,
      explanation: '"Beleza" literally means "beauty" but is used as slang for "Cool" or "Alright".',
    ),
    QuizItem(
      question: 'How do you say "This is delicious!" in Portuguese?',
      options: ['Está frio!', 'Está delicioso!', 'Está longe!', 'Está caro!'],
      correctIndex: 1,
      explanation: '"Está delicioso!" means "This is delicious!".',
    ),
  ];

  static const _englishQuestions = [
    QuizItem(
      question: 'What is the past tense of "go"?',
      options: ['Goed', 'Went', 'Gone', 'Goes'],
      correctIndex: 1,
      explanation: '"Go" is an irregular verb. Past simple: "went". Past participle: "gone".',
    ),
    QuizItem(
      question: 'Which is correct?',
      options: ['He don\'t like it', 'He doesn\'t like it', 'He not like it', 'He no like it'],
      correctIndex: 1,
      explanation: 'Third person singular uses "doesn\'t" (does not) for negation.',
    ),
    QuizItem(
      question: 'What does "break the ice" mean?',
      options: ['Destroy ice', 'Start a conversation', 'Feel cold', 'Break something'],
      correctIndex: 1,
      explanation: '"Break the ice" is an idiom meaning to initiate conversation in a social setting.',
    ),
    QuizItem(
      question: 'Choose the correct spelling:',
      options: ['Recieve', 'Receive', 'Receeve', 'Receve'],
      correctIndex: 1,
      explanation: 'The correct spelling is "receive". Remember: "i before e, except after c".',
    ),
    QuizItem(
      question: 'What is a synonym for "beautiful"?',
      options: ['Ugly', 'Gorgeous', 'Terrible', 'Boring'],
      correctIndex: 1,
      explanation: '"Gorgeous" is a synonym meaning very beautiful or attractive.',
    ),
    QuizItem(
      question: 'What does "I\'m over the moon" mean?',
      options: ['I\'m confused', 'I\'m extremely happy', 'I\'m tired', 'I\'m traveling'],
      correctIndex: 1,
      explanation: '"Over the moon" is an idiom meaning extremely happy or delighted.',
    ),
    QuizItem(
      question: 'Which sentence uses the present perfect correctly?',
      options: ['I have went there', 'I have gone there', 'I have go there', 'I have going there'],
      correctIndex: 1,
      explanation: 'Present perfect uses "have/has" + past participle. "Gone" is the past participle of "go".',
    ),
    QuizItem(
      question: 'What is the plural of "child"?',
      options: ['Childs', 'Childen', 'Children', 'Childrens'],
      correctIndex: 2,
      explanation: '"Child" has an irregular plural: "children". It does not follow the standard -s rule.',
    ),
    QuizItem(
      question: 'Which phrase would you use to ask someone on a date?',
      options: ['Do you want to hang out?', 'Would you like to go out sometime?', 'Where are you going?', 'What time is it?'],
      correctIndex: 1,
      explanation: '"Would you like to go out sometime?" is a polite and clear way to ask someone on a date.',
    ),
    QuizItem(
      question: 'What does "to ghost someone" mean in modern English?',
      options: ['To scare someone', 'To stop responding without explanation', 'To follow someone', 'To compliment someone'],
      correctIndex: 1,
      explanation: '"Ghosting" means suddenly cutting off all communication with someone without explanation.',
    ),
    QuizItem(
      question: 'Which is the correct conditional sentence?',
      options: ['If I will go, I tell you', 'If I go, I will tell you', 'If I go, I telling you', 'If I going, I tell you'],
      correctIndex: 1,
      explanation: 'First conditional: "If + present simple, will + base verb". Used for real/possible future situations.',
    ),
    QuizItem(
      question: 'What does "RSVP" stand for?',
      options: ['Reply soon very please', 'Répondez s\'il vous plaît', 'Return stamp very promptly', 'Read silently very politely'],
      correctIndex: 1,
      explanation: 'RSVP comes from French "Répondez s\'il vous plaît" meaning "Please respond".',
    ),
    QuizItem(
      question: 'Which word means "a strong feeling of affection"?',
      options: ['Anger', 'Love', 'Fear', 'Boredom'],
      correctIndex: 1,
      explanation: '"Love" means a deep, strong feeling of affection toward someone.',
    ),
    QuizItem(
      question: 'What is the difference between "your" and "you\'re"?',
      options: ['They mean the same', '"Your" is possessive, "you\'re" means "you are"', '"You\'re" is possessive', 'There is no difference'],
      correctIndex: 1,
      explanation: '"Your" shows possession (your book). "You\'re" is a contraction of "you are".',
    ),
    QuizItem(
      question: 'Which tipping custom is standard in the United States?',
      options: ['No tipping expected', '5% of the bill', '15-20% of the bill', '50% of the bill'],
      correctIndex: 2,
      explanation: 'In the US, tipping 15-20% at restaurants is standard and expected.',
    ),
    QuizItem(
      question: 'What does "to have butterflies in your stomach" mean?',
      options: ['To feel sick', 'To feel nervous or excited', 'To be hungry', 'To have eaten too much'],
      correctIndex: 1,
      explanation: '"Butterflies in your stomach" describes the nervous, fluttery feeling you get when excited or anxious, especially about romance.',
    ),
    QuizItem(
      question: 'Which is correct: "less" or "fewer"?',
      options: ['Less people came', 'Fewer people came', 'Both are correct', 'Neither is correct'],
      correctIndex: 1,
      explanation: '"Fewer" is used with countable nouns (people, items). "Less" is for uncountable nouns (water, time).',
    ),
    QuizItem(
      question: 'How do you spell the number 40?',
      options: ['Fourty', 'Forty', 'Forthy', 'Fourthy'],
      correctIndex: 1,
      explanation: 'The correct spelling is "forty" — note there is no "u", unlike "four".',
    ),
    QuizItem(
      question: 'What does "it\'s raining cats and dogs" mean?',
      options: ['Animals are falling', 'It\'s raining very heavily', 'The weather is nice', 'Pets are outside'],
      correctIndex: 1,
      explanation: '"Raining cats and dogs" is an idiom meaning it is raining very heavily.',
    ),
  ];
}
