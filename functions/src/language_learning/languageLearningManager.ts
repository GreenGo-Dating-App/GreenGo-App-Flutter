/**
 * Language Learning Management Cloud Functions
 * Handles lessons, teachers, progress tracking, and analytics
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { isAdminCaller, MODERATION_ROLES } from "../shared/adminAuth";
import { monitored } from '../shared/monitoring';

const db = admin.firestore();

// ============= LESSON SEEDING DATA =============

// Language content translations for 8 major languages.
// Category ids (incl. the legacy `flirting` id) are stored on lesson docs and
// are kept unchanged; the phrases are friendship / travel / language-exchange.
const languageContent: Record<string, Record<string, Record<string, string>>> = {
  es: {
    greetings: {
      hello_everyone: "¡Hola a todos!",
      how_are_you: "¿Cómo estás?",
      nice_to_meet_you: "Encantado/a de conocerte",
      good_morning: "¡Buenos días!",
      good_night: "¡Buenas noches!",
    },
    compliments: {
      great_idea: "¡Qué buena idea!",
      you_speak_very_well: "¡Hablas muy bien!",
      your_city_is_beautiful: "Tu ciudad es preciosa",
      so_funny: "Eres muy gracioso/a",
    },
    flirting: {
      where_are_you_from: "¿De dónde eres?",
      what_brings_you_here: "¿Qué te trae por aquí?",
      what_do_you_do_for_fun: "¿Qué te gusta hacer en tu tiempo libre?",
    },
    asking_out: {
      grab_coffee: "¿Tomamos un café?",
      dinner_together: "¿Cenamos juntos?",
      free_this_weekend: "¿Estás libre este fin de semana?",
    },
    restaurant: {
      table_for_two: "Una mesa para dos, por favor",
      menu_please: "¿Nos trae la carta?",
      this_is_delicious: "¡Esto está delicioso!",
      check_please: "La cuenta, por favor",
    },
    feelings: {
      i_had_a_great_time: "¡Lo pasé genial!",
      thank_you_so_much: "¡Muchas gracias!",
      see_you_soon: "¡Hasta pronto!",
    },
  },
  fr: {
    greetings: {
      hello_everyone: "Bonjour à tous !",
      how_are_you: "Comment vas-tu ?",
      nice_to_meet_you: "Enchanté(e) de te rencontrer",
      good_morning: "Bonjour !",
      good_night: "Bonne nuit !",
    },
    compliments: {
      great_idea: "Quelle bonne idée !",
      you_speak_very_well: "Tu parles très bien !",
      your_city_is_beautiful: "Ta ville est magnifique",
      so_funny: "Tu es trop drôle",
    },
    flirting: {
      where_are_you_from: "Tu viens d'où ?",
      what_brings_you_here: "Qu'est-ce qui t'amène ici ?",
      what_do_you_do_for_fun: "Qu'est-ce que tu aimes faire pendant ton temps libre ?",
    },
    asking_out: {
      grab_coffee: "On prend un café?",
      dinner_together: "On dîne ensemble?",
      free_this_weekend: "Tu es libre ce week-end?",
    },
    restaurant: {
      table_for_two: "Une table pour deux, s'il vous plaît",
      menu_please: "Le menu, s'il vous plaît",
      this_is_delicious: "C'est délicieux!",
      check_please: "L'addition, s'il vous plaît",
    },
    feelings: {
      i_had_a_great_time: "J'ai passé un super moment !",
      thank_you_so_much: "Merci beaucoup !",
      see_you_soon: "À bientôt !",
    },
  },
  de: {
    greetings: {
      hello_everyone: "Hallo zusammen!",
      how_are_you: "Wie geht's?",
      nice_to_meet_you: "Freut mich, dich kennenzulernen",
      good_morning: "Guten Morgen!",
      good_night: "Gute Nacht!",
    },
    compliments: {
      great_idea: "Was für eine tolle Idee!",
      you_speak_very_well: "Du sprichst sehr gut!",
      your_city_is_beautiful: "Deine Stadt ist wunderschön",
      so_funny: "Du bist so lustig",
    },
    flirting: {
      where_are_you_from: "Woher kommst du?",
      what_brings_you_here: "Was führt dich hierher?",
      what_do_you_do_for_fun: "Was machst du gern in deiner Freizeit?",
    },
    asking_out: {
      grab_coffee: "Wollen wir einen Kaffee trinken?",
      dinner_together: "Wollen wir zusammen essen?",
      free_this_weekend: "Hast du am Wochenende Zeit?",
    },
    restaurant: {
      table_for_two: "Einen Tisch für zwei, bitte",
      menu_please: "Die Speisekarte, bitte",
      this_is_delicious: "Das ist köstlich!",
      check_please: "Die Rechnung, bitte",
    },
    feelings: {
      i_had_a_great_time: "Ich hatte eine tolle Zeit!",
      thank_you_so_much: "Vielen Dank!",
      see_you_soon: "Bis bald!",
    },
  },
  it: {
    greetings: {
      hello_everyone: "Ciao a tutti!",
      how_are_you: "Come stai?",
      nice_to_meet_you: "Piacere di conoscerti",
      good_morning: "Buongiorno!",
      good_night: "Buonanotte!",
    },
    compliments: {
      great_idea: "Che bella idea!",
      you_speak_very_well: "Parli molto bene!",
      your_city_is_beautiful: "La tua città è bellissima",
      so_funny: "Sei troppo simpatico/a",
    },
    flirting: {
      where_are_you_from: "Di dove sei?",
      what_brings_you_here: "Cosa ti porta qui?",
      what_do_you_do_for_fun: "Cosa ti piace fare nel tempo libero?",
    },
    asking_out: {
      grab_coffee: "Prendiamo un caffè?",
      dinner_together: "Ceniamo insieme?",
      free_this_weekend: "Sei libera/o questo fine settimana?",
    },
    restaurant: {
      table_for_two: "Un tavolo per due, per favore",
      menu_please: "Il menu, per favore",
      this_is_delicious: "È delizioso!",
      check_please: "Il conto, per favore",
    },
    feelings: {
      i_had_a_great_time: "Mi sono divertito/a tantissimo!",
      thank_you_so_much: "Grazie mille!",
      see_you_soon: "A presto!",
    },
  },
  pt: {
    greetings: {
      hello_everyone: "Olá a todos!",
      how_are_you: "Como estás?",
      nice_to_meet_you: "Prazer em conhecer-te",
      good_morning: "Bom dia!",
      good_night: "Boa noite!",
    },
    compliments: {
      great_idea: "Que boa ideia!",
      you_speak_very_well: "Falas muito bem!",
      your_city_is_beautiful: "A tua cidade é linda",
      so_funny: "És muito engraçado/a",
    },
    flirting: {
      where_are_you_from: "De onde és?",
      what_brings_you_here: "O que te traz aqui?",
      what_do_you_do_for_fun: "O que gostas de fazer nos tempos livres?",
    },
    asking_out: {
      grab_coffee: "Vamos tomar um café?",
      dinner_together: "Vamos jantar juntos?",
      free_this_weekend: "Você está livre nesse fim de semana?",
    },
    restaurant: {
      table_for_two: "Uma mesa para dois, por favor",
      menu_please: "O cardápio, por favor",
      this_is_delicious: "Está delicioso!",
      check_please: "A conta, por favor",
    },
    feelings: {
      i_had_a_great_time: "Diverti-me imenso!",
      thank_you_so_much: "Muito obrigado/a!",
      see_you_soon: "Até breve!",
    },
  },
  ja: {
    greetings: {
      hello_everyone: "みんな、こんにちは！(Minna, konnichiwa!)",
      how_are_you: "元気？(Genki?)",
      nice_to_meet_you: "はじめまして (Hajimemashite)",
      good_morning: "おはよう！(Ohayou!)",
      good_night: "おやすみ！(Oyasumi!)",
    },
    compliments: {
      great_idea: "いいアイデアだね！(Ii aidea da ne!)",
      you_speak_very_well: "話すのがとても上手だね！(Hanasu no ga totemo jouzu da ne!)",
      your_city_is_beautiful: "君の街はきれいだね (Kimi no machi wa kirei da ne)",
      so_funny: "面白いね (Omoshiroi ne)",
    },
    flirting: {
      where_are_you_from: "どこの出身？(Doko no shusshin?)",
      what_brings_you_here: "どうしてここに来たの？(Doushite koko ni kita no?)",
      what_do_you_do_for_fun: "暇なときは何をしてるの？(Hima na toki wa nani wo shiteru no?)",
    },
    asking_out: {
      grab_coffee: "コーヒー飲まない？(Koohii nomanai?)",
      dinner_together: "一緒に夕食を食べない？",
      free_this_weekend: "週末暇？(Shuumatsu hima?)",
    },
    restaurant: {
      table_for_two: "二人です (Futari desu)",
      menu_please: "メニューをください (Menyuu wo kudasai)",
      this_is_delicious: "おいしい！(Oishii!)",
      check_please: "お会計お願いします",
    },
    feelings: {
      i_had_a_great_time: "とても楽しかった！(Totemo tanoshikatta!)",
      thank_you_so_much: "本当にありがとう！(Hontou ni arigatou!)",
      see_you_soon: "またね！(Mata ne!)",
    },
  },
  ko: {
    greetings: {
      hello_everyone: "여러분, 안녕! (Yeoreobun, annyeong!)",
      how_are_you: "어떻게 지내? (Eotteoke jinae?)",
      nice_to_meet_you: "만나서 반가워 (Mannaseo bangawo)",
      good_morning: "좋은 아침! (Joeun achim!)",
      good_night: "잘 자! (Jal ja!)",
    },
    compliments: {
      great_idea: "좋은 생각이야! (Joeun saenggagiya!)",
      you_speak_very_well: "말 정말 잘한다! (Mal jeongmal jalhanda!)",
      your_city_is_beautiful: "너희 도시 정말 예쁘다 (Neohui dosi jeongmal yeppeuda)",
      so_funny: "너 정말 재미있다 (Neo jeongmal jaemiitda)",
    },
    flirting: {
      where_are_you_from: "어디에서 왔어? (Eodieseo wasseo?)",
      what_brings_you_here: "여기는 어떻게 왔어? (Yeogineun eotteoke wasseo?)",
      what_do_you_do_for_fun: "쉴 때 뭐 해? (Swil ttae mwo hae?)",
    },
    asking_out: {
      grab_coffee: "커피 마실래요? (Keopi masillaeyo?)",
      dinner_together: "같이 저녁 먹을래요?",
      free_this_weekend: "이번 주말에 시간 있어요?",
    },
    restaurant: {
      table_for_two: "두 명이요 (Du myeong-iyo)",
      menu_please: "메뉴판 주세요 (Menyu-pan juseyo)",
      this_is_delicious: "맛있어요! (Masisseoyo!)",
      check_please: "계산해 주세요 (Gyesanhae juseyo)",
    },
    feelings: {
      i_had_a_great_time: "정말 즐거웠어! (Jeongmal jeulgeowosseo!)",
      thank_you_so_much: "정말 고마워! (Jeongmal gomawo!)",
      see_you_soon: "또 보자! (Tto boja!)",
    },
  },
  zh: {
    greetings: {
      hello_everyone: "大家好！(Dàjiā hǎo!)",
      how_are_you: "你好吗？(Nǐ hǎo ma?)",
      nice_to_meet_you: "很高兴认识你 (Hěn gāoxìng rènshi nǐ)",
      good_morning: "早上好！(Zǎoshang hǎo!)",
      good_night: "晚安！(Wǎn'ān!)",
    },
    compliments: {
      great_idea: "好主意！(Hǎo zhǔyi!)",
      you_speak_very_well: "你说得很好！(Nǐ shuō de hěn hǎo!)",
      your_city_is_beautiful: "你的城市很漂亮 (Nǐ de chéngshì hěn piàoliang)",
      so_funny: "你真有意思 (Nǐ zhēn yǒu yìsi)",
    },
    flirting: {
      where_are_you_from: "你是哪里人？(Nǐ shì nǎlǐ rén?)",
      what_brings_you_here: "你怎么来这里的？(Nǐ zěnme lái zhèlǐ de?)",
      what_do_you_do_for_fun: "你空闲时喜欢做什么？(Nǐ kòngxián shí xǐhuān zuò shénme?)",
    },
    asking_out: {
      grab_coffee: "一起喝咖啡？(Yīqǐ hē kāfēi?)",
      dinner_together: "一起吃晚饭？(Yīqǐ chī wǎnfàn?)",
      free_this_weekend: "这周末有空吗？(Zhè zhōumò yǒu kòng ma?)",
    },
    restaurant: {
      table_for_two: "两位 (Liǎng wèi)",
      menu_please: "请给我菜单 (Qǐng gěi wǒ càidān)",
      this_is_delicious: "很好吃！(Hěn hǎo chī!)",
      check_please: "买单 (Mǎidān)",
    },
    feelings: {
      i_had_a_great_time: "我玩得很开心！(Wǒ wán de hěn kāixīn!)",
      thank_you_so_much: "非常感谢！(Fēicháng gǎnxiè!)",
      see_you_soon: "回头见！(Huítóu jiàn!)",
    },
  },
};

// Language metadata - Starting with 5 languages
const languageInfo: Record<string, { name: string; nativeName: string; flag: string }> = {
  es: { name: "Spanish", nativeName: "Español", flag: "🇪🇸" },
  en: { name: "English", nativeName: "English", flag: "🇬🇧" },
  fr: { name: "French", nativeName: "Français", flag: "🇫🇷" },
  de: { name: "German", nativeName: "Deutsch", flag: "🇩🇪" },
  pt: { name: "Portuguese", nativeName: "Português", flag: "🇵🇹" },
  "pt-BR": { name: "Brazilian Portuguese", nativeName: "Português Brasileiro", flag: "🇧🇷" },
  it: { name: "Italian", nativeName: "Italiano", flag: "🇮🇹" },
};

// Add English content
languageContent["en"] = {
  greetings: {
    hello_everyone: "Hello everyone!",
    how_are_you: "How are you?",
    nice_to_meet_you: "Nice to meet you",
    good_morning: "Good morning!",
    good_night: "Good night!",
  },
  compliments: {
    great_idea: "What a great idea!",
    you_speak_very_well: "You speak very well!",
    your_city_is_beautiful: "Your city is beautiful",
    so_funny: "You're so funny",
  },
  flirting: {
    where_are_you_from: "Where are you from?",
    what_brings_you_here: "What brings you here?",
    what_do_you_do_for_fun: "What do you do for fun?",
  },
  asking_out: {
    grab_coffee: "Want to grab coffee?",
    dinner_together: "Let's have dinner together",
    free_this_weekend: "Are you free this weekend?",
  },
  restaurant: {
    table_for_two: "A table for two, please",
    menu_please: "Can we see the menu?",
    this_is_delicious: "This is delicious!",
    check_please: "Check, please",
  },
  feelings: {
    i_had_a_great_time: "I had a great time!",
    thank_you_so_much: "Thank you so much!",
    see_you_soon: "See you soon!",
  },
};

// Add Brazilian Portuguese content
languageContent["pt-BR"] = {
  greetings: {
    hello_everyone: "Oi, pessoal!",
    how_are_you: "Tudo bem?",
    nice_to_meet_you: "Prazer em conhecer você",
    good_morning: "Bom dia!",
    good_night: "Boa noite!",
  },
  compliments: {
    great_idea: "Que ótima ideia!",
    you_speak_very_well: "Você fala muito bem!",
    your_city_is_beautiful: "Sua cidade é linda",
    so_funny: "Você é muito engraçado/a",
  },
  flirting: {
    where_are_you_from: "De onde você é?",
    what_brings_you_here: "O que te traz aqui?",
    what_do_you_do_for_fun: "O que você gosta de fazer no tempo livre?",
  },
  asking_out: {
    grab_coffee: "Vamos tomar um café?",
    dinner_together: "Vamos jantar juntos?",
    free_this_weekend: "Você tá livre esse fim de semana?",
  },
  restaurant: {
    table_for_two: "Uma mesa para dois, por favor",
    menu_please: "O cardápio, por favor",
    this_is_delicious: "Tá uma delícia!",
    check_please: "A conta, por favor",
  },
  feelings: {
    i_had_a_great_time: "Foi muito legal!",
    thank_you_so_much: "Muito obrigado/a!",
    see_you_soon: "Até logo!",
  },
};

// Weekly themes (8 themes that rotate through the year)
const weeklyThemes = [
  {
    theme: "Getting Started: Meeting New People",
    days: [
      { title: "Hello Everyone! - Basic Greetings", category: "greetings", description: "Learn friendly ways to say hello and make a great first impression" },
      { title: "What's Your Name? - Introductions", category: "greetings", description: "Introduce yourself confidently to new people" },
      { title: "What a Great Idea! - Kind Words", category: "compliments", description: "Learn sincere compliments that make people smile" },
      { title: "Tell Me About Yourself", category: "greetings", description: "Share interesting things about yourself and ask great questions" },
      { title: "I Really Like... - Expressing Interests", category: "greetings", description: "Talk about your hobbies and find common ground" },
      { title: "Want to Grab Coffee?", category: "asking_out", description: "Suggest meeting up with a new friend or exchange partner" },
      { title: "Weekend Review & Practice", category: "greetings", description: "Review everything you learned this week with fun exercises" },
    ],
  },
  {
    theme: "Café Conversations",
    days: [
      { title: "At the Cafe - Ordering Drinks", category: "restaurant", description: "Navigate the menu and order like a local" },
      { title: "Where Are You From?", category: "flirting", description: "Easy small-talk questions to get a conversation going" },
      { title: "What Do You Do? - Jobs & Dreams", category: "greetings", description: "Talk about work and aspirations in an interesting way" },
      { title: "This Is Delicious! - Food Talk", category: "restaurant", description: "Express opinions about food and discover local tastes" },
      { title: "Music Chat", category: "greetings", description: "Bond over music and discover shared tastes" },
      { title: "Let's Do This Again!", category: "asking_out", description: "Wrap up a meetup on a high note and plan the next one" },
      { title: "Café Conversation Mastery", category: "restaurant", description: "Put it all together for a relaxed café chat" },
    ],
  },
  {
    theme: "Small Talk Like a Local",
    days: [
      { title: "You Speak Very Well!", category: "compliments", description: "Encourage your language exchange partner" },
      { title: "You Make Me Laugh!", category: "compliments", description: "Appreciate someone's personality and humor" },
      { title: "What Brings You Here?", category: "flirting", description: "Keep a conversation flowing with curious questions" },
      { title: "Body Language Across Cultures", category: "flirting", description: "Words and gestures that mean different things in different places" },
      { title: "Fun Ice-Breakers", category: "flirting", description: "Light-hearted questions that start great conversations" },
      { title: "I Had a Great Time!", category: "feelings", description: "Tell people you enjoyed their company" },
      { title: "Small Talk Practice Session", category: "flirting", description: "Practice your new small-talk skills with confidence" },
    ],
  },
  {
    theme: "Eating Out with Friends",
    days: [
      { title: "Making Reservations", category: "restaurant", description: "Book a table like a pro" },
      { title: "Reading the Menu", category: "restaurant", description: "Navigate any menu with confidence" },
      { title: "What Would You Recommend?", category: "restaurant", description: "Get great recommendations from servers" },
      { title: "Ordering Drinks", category: "restaurant", description: "Order drinks with confidence" },
      { title: "This Is Amazing! - Food Reactions", category: "restaurant", description: "Express your culinary delight" },
      { title: "Shall We Share Dessert?", category: "restaurant", description: "The sweet end to a great meal" },
      { title: "Getting the Check", category: "restaurant", description: "Handle payment smoothly and gracefully" },
    ],
  },
  {
    theme: "Sharing Thoughts and Feelings",
    days: [
      { title: "Thank You So Much!", category: "feelings", description: "Express gratitude naturally" },
      { title: "That Means a Lot to Me", category: "feelings", description: "Tell people they made a difference" },
      { title: "I'm Excited About...", category: "feelings", description: "Share your enthusiasm" },
      { title: "You Made My Day", category: "feelings", description: "Share how someone made you feel good" },
      { title: "I'm Sorry - Making Up", category: "feelings", description: "Apologize and resolve misunderstandings" },
      { title: "What Do You Think?", category: "feelings", description: "Share and ask for opinions politely" },
      { title: "See You Soon!", category: "feelings", description: "Say goodbye warmly" },
    ],
  },
  {
    theme: "Kind Words and Compliments",
    days: [
      { title: "Beyond 'Nice' - Unique Compliments", category: "compliments", description: "Stand out with creative compliments" },
      { title: "Complimenting Ideas", category: "compliments", description: "Appreciate someone's thinking" },
      { title: "Your City Is Beautiful", category: "compliments", description: "Compliment places, food and culture" },
      { title: "Personality Appreciation", category: "compliments", description: "Appreciate who people are" },
      { title: "Poetic Expressions", category: "compliments", description: "Colorful idioms of admiration" },
      { title: "Accepting Compliments Gracefully", category: "compliments", description: "Respond to praise with confidence" },
      { title: "Compliment Mastery", category: "compliments", description: "Perfect your compliment game" },
    ],
  },
  {
    theme: "Making Plans Together",
    days: [
      { title: "Casual Meetup Suggestions", category: "asking_out", description: "Low-pressure ideas to meet new friends" },
      { title: "Planning a Group Outing", category: "asking_out", description: "Organize something fun together" },
      { title: "Adventure Proposals", category: "asking_out", description: "Suggest exciting activities" },
      { title: "Setting the Time and Place", category: "asking_out", description: "Nail down the details" },
      { title: "Confirming Plans", category: "asking_out", description: "Follow up without being pushy" },
      { title: "Changing Plans Gracefully", category: "asking_out", description: "Handle schedule changes" },
      { title: "Planning Pro", category: "asking_out", description: "Master the art of making plans" },
    ],
  },
  {
    theme: "Fun Conversations",
    days: [
      { title: "Would You Rather...?", category: "flirting", description: "Fun conversation games" },
      { title: "Tell Me Something Interesting", category: "greetings", description: "Deep conversation starters" },
      { title: "Dream Talk", category: "greetings", description: "Discuss hopes and dreams" },
      { title: "Funny Stories", category: "flirting", description: "Share laughs and memories" },
      { title: "Travel Dreams", category: "greetings", description: "Where would you go?" },
      { title: "Food Adventures", category: "restaurant", description: "Culinary conversations" },
      { title: "Meaningful Exchanges", category: "feelings", description: "Conversations that bring people closer" },
    ],
  },
];

// ============= TEACHER MANAGEMENT =============

/**
 * Submit teacher application
 */
export const submitTeacherApplication = functions.runWith({ memory: '512MB' }).https.onCall(
  monitored("submitTeacherApplication", async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in"
      );
    }

    const {
      fullName,
      bio,
      teachingLanguages,
      nativeLanguages,
      teachingExperience,
      yearsExperience,
      certificationUrls,
      portfolioUrl,
      linkedinUrl,
      videoIntroUrl,
      motivation,
      sampleLessonIdea,
    } = data;

    // Validate required fields
    if (
      !fullName ||
      !bio ||
      !teachingLanguages?.length ||
      !nativeLanguages?.length ||
      !motivation
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields"
      );
    }

    // Check if user already has an application
    const existingApp = await db
      .collection("teacher_applications")
      .where("userId", "==", context.auth.uid)
      .where("status", "in", ["pending", "under_review"])
      .get();

    if (!existingApp.empty) {
      throw new functions.https.HttpsError(
        "already-exists",
        "You already have a pending application"
      );
    }

    const applicationRef = db.collection("teacher_applications").doc();
    await applicationRef.set({
      id: applicationRef.id,
      userId: context.auth.uid,
      email: context.auth.token.email,
      fullName,
      bio,
      teachingLanguages,
      nativeLanguages,
      teachingExperience: teachingExperience || "",
      yearsExperience: yearsExperience || 0,
      certificationUrls: certificationUrls || [],
      portfolioUrl: portfolioUrl || null,
      linkedinUrl: linkedinUrl || null,
      videoIntroUrl: videoIntroUrl || null,
      motivation,
      sampleLessonIdea: sampleLessonIdea || "",
      status: "pending",
      submittedAt: admin.firestore.FieldValue.serverTimestamp(),
      reviewedBy: null,
      reviewedAt: null,
      reviewNotes: null,
      rejectionReason: null,
    });

    return { success: true, applicationId: applicationRef.id };
  })
);

/**
 * Admin: Review teacher application
 */
export const reviewTeacherApplication = functions.runWith({ memory: '512MB' }).https.onCall(
  monitored("reviewTeacherApplication", async (data, context) => {
    // Verify admin
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in"
      );
    }

    // P1-6: admin_users / adminRole claim (was profiles.isAdmin).
    if (!(await isAdminCaller(context.auth, MODERATION_ROLES))) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Admin access required"
      );
    }

    const { applicationId, approved, reviewNotes, rejectionReason } = data;

    const appRef = db.collection("teacher_applications").doc(applicationId);
    const appDoc = await appRef.get();

    if (!appDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Application not found");
    }

    const appData = appDoc.data()!;
    const batch = db.batch();

    if (approved) {
      // Create teacher profile
      const teacherRef = db.collection("teachers").doc();
      batch.set(teacherRef, {
        id: teacherRef.id,
        userId: appData.userId,
        email: appData.email,
        displayName: appData.fullName,
        profilePhotoUrl: null,
        bio: appData.bio,
        teachingLanguages: appData.teachingLanguages,
        nativeLanguages: appData.nativeLanguages,
        status: "approved",
        tier: "starter",
        certifications: [],
        stats: {
          totalLessons: 0,
          publishedLessons: 0,
          totalStudents: 0,
          activeStudents: 0,
          averageRating: 0,
          totalRatings: 0,
          totalCompletions: 0,
          totalCoinsEarned: 0,
          totalXpAwarded: 0,
          lessonsByLanguage: {},
          ratingsByLanguage: {},
          lastLessonCreated: null,
          lessonsThisMonth: 0,
        },
        paymentInfo: null,
        applicationDate: appData.submittedAt,
        approvalDate: admin.firestore.FieldValue.serverTimestamp(),
        approvedBy: context.auth.uid,
        rejectionReason: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: null,
        isActive: true,
      });

      // Update user profile with teacher role
      batch.update(db.collection("profiles").doc(appData.userId), {
        isTeacher: true,
        teacherId: teacherRef.id,
      });
    }

    // Update application
    batch.update(appRef, {
      status: approved ? "approved" : "rejected",
      reviewedBy: context.auth.uid,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      reviewNotes: reviewNotes || null,
      rejectionReason: approved ? null : rejectionReason,
    });

    await batch.commit();

    // TODO: Send notification to applicant

    return { success: true };
  })
);

// ============= LESSON MANAGEMENT =============

/**
 * Teacher: Create a new lesson
 */
export const createLesson = functions.runWith({ memory: '512MB' }).https.onCall(monitored("createLesson", async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  // Verify teacher
  const teacherQuery = await db
    .collection("teachers")
    .where("userId", "==", context.auth.uid)
    .where("status", "==", "approved")
    .where("isActive", "==", true)
    .limit(1)
    .get();

  if (teacherQuery.empty) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Must be an approved teacher"
    );
  }

  const teacher = teacherQuery.docs[0].data();

  // Validate language
  if (!teacher.teachingLanguages.includes(data.languageCode)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Not authorized to teach this language"
    );
  }

  const lessonRef = db.collection("lessons").doc();
  const lesson = {
    id: lessonRef.id,
    languageCode: data.languageCode,
    languageName: data.languageName,
    title: data.title,
    description: data.description,
    level: data.level,
    category: data.category,
    lessonNumber: data.lessonNumber || 0,
    weekNumber: data.weekNumber || 0,
    dayNumber: data.dayNumber || 0,
    coinPrice: data.coinPrice || 20,
    isFree: data.isFree || false,
    isPremium: data.isPremium || false,
    estimatedMinutes: data.estimatedMinutes || 15,
    xpReward: data.xpReward || 25,
    bonusCoins: data.bonusCoins || 0,
    sections: data.sections || [],
    objectives: data.objectives || [],
    prerequisites: data.prerequisites || [],
    teacherId: teacherQuery.docs[0].id,
    teacherName: teacher.displayName,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: null,
    isPublished: false,
    averageRating: 0,
    completionCount: 0,
    metadata: data.metadata || null,
  };

  await lessonRef.set(lesson);

  // Update teacher stats
  await db
    .collection("teachers")
    .doc(teacherQuery.docs[0].id)
    .update({
      "stats.totalLessons": admin.firestore.FieldValue.increment(1),
      "stats.lastLessonCreated":
        admin.firestore.FieldValue.serverTimestamp(),
      [`stats.lessonsByLanguage.${data.languageCode}`]:
        admin.firestore.FieldValue.increment(1),
    });

  return { success: true, lessonId: lessonRef.id };
}));

/**
 * Teacher: Publish a lesson
 */
export const publishLesson = functions.runWith({ memory: '512MB' }).https.onCall(monitored("publishLesson", async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  const { lessonId } = data;
  const lessonRef = db.collection("lessons").doc(lessonId);
  const lessonDoc = await lessonRef.get();

  if (!lessonDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Lesson not found");
  }

  const lesson = lessonDoc.data()!;

  // Verify ownership
  const teacherQuery = await db
    .collection("teachers")
    .where("userId", "==", context.auth.uid)
    .where("id", "==", lesson.teacherId)
    .limit(1)
    .get();

  if (teacherQuery.empty) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Not authorized to publish this lesson"
    );
  }

  // Validate lesson has content
  if (!lesson.sections?.length || lesson.sections.length < 2) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Lesson must have at least 2 sections"
    );
  }

  await lessonRef.update({
    isPublished: true,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Update teacher stats
  await db
    .collection("teachers")
    .doc(lesson.teacherId)
    .update({
      "stats.publishedLessons": admin.firestore.FieldValue.increment(1),
    });

  return { success: true };
}));

// ============= LESSON PURCHASE =============

/**
 * Purchase a lesson with coins
 */
export const purchaseLesson = functions.runWith({ memory: '512MB' }).https.onCall(monitored("purchaseLesson", async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  const { lessonId } = data;
  const userId = context.auth.uid;

  // Get lesson
  const lessonDoc = await db.collection("lessons").doc(lessonId).get();
  if (!lessonDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Lesson not found");
  }

  const lesson = lessonDoc.data()!;

  if (!lesson.isPublished) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Lesson is not available"
    );
  }

  // Check if already purchased
  const existingAccess = await db
    .collection("user_lesson_access")
    .where("userId", "==", userId)
    .where("lessonId", "==", lessonId)
    .limit(1)
    .get();

  if (!existingAccess.empty) {
    throw new functions.https.HttpsError(
      "already-exists",
      "You already own this lesson"
    );
  }

  // Check if lesson is free
  if (lesson.isFree) {
    const accessRef = db.collection("user_lesson_access").doc();
    await accessRef.set({
      id: accessRef.id,
      userId,
      lessonId,
      purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
      coinsPaid: 0,
      isCompleted: false,
      completedAt: null,
      progressPercent: 0,
      earnedXp: 0,
      sectionProgress: {},
    });

    return { success: true, accessId: accessRef.id, coinsPaid: 0 };
  }

  // Check user coin balance
  const userWallet = await db.collection("coin_wallets").doc(userId).get();
  const balance = userWallet.exists ? userWallet.data()?.balance || 0 : 0;

  if (balance < lesson.coinPrice) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Insufficient coins"
    );
  }

  // Start transaction
  const batch = db.batch();

  // Deduct coins from user
  batch.update(db.collection("coin_wallets").doc(userId), {
    balance: admin.firestore.FieldValue.increment(-lesson.coinPrice),
  });

  // Create transaction record
  const txRef = db.collection("coin_transactions").doc();
  batch.set(txRef, {
    id: txRef.id,
    userId,
    type: "lesson_purchase",
    amount: -lesson.coinPrice,
    balanceAfter: balance - lesson.coinPrice,
    description: `Purchased lesson: ${lesson.title}`,
    metadata: { lessonId, teacherId: lesson.teacherId },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Create lesson access
  const accessRef = db.collection("user_lesson_access").doc();
  batch.set(accessRef, {
    id: accessRef.id,
    userId,
    lessonId,
    purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
    coinsPaid: lesson.coinPrice,
    isCompleted: false,
    completedAt: null,
    progressPercent: 0,
    earnedXp: 0,
    sectionProgress: {},
  });

  // Credit teacher earnings
  const teacherShare = 0.5; // 50% to teacher (starter tier)
  const teacherCoins = Math.floor(lesson.coinPrice * teacherShare);

  const earningRef = db.collection("teacher_earnings").doc();
  batch.set(earningRef, {
    id: earningRef.id,
    teacherId: lesson.teacherId,
    lessonId,
    lessonTitle: lesson.title,
    purchasedByUserId: userId,
    coinAmount: lesson.coinPrice,
    teacherShare,
    teacherCoins,
    usdEquivalent: teacherCoins * 0.01, // Approximate
    earnedAt: admin.firestore.FieldValue.serverTimestamp(),
    isPaidOut: false,
    payoutId: null,
    paidOutAt: null,
  });

  // Update teacher stats
  batch.update(db.collection("teachers").doc(lesson.teacherId), {
    "stats.totalStudents": admin.firestore.FieldValue.increment(1),
    "stats.totalCoinsEarned": admin.firestore.FieldValue.increment(teacherCoins),
  });

  // Update lesson stats
  batch.update(db.collection("lessons").doc(lessonId), {
    purchaseCount: admin.firestore.FieldValue.increment(1),
  });

  await batch.commit();

  return { success: true, accessId: accessRef.id, coinsPaid: lesson.coinPrice };
}));

// ============= PROGRESS TRACKING =============

/**
 * Update lesson progress
 */
export const updateLessonProgress = functions.runWith({ memory: '512MB' }).https.onCall(
  monitored("updateLessonProgress", async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in"
      );
    }

    const { accessId, sectionId, exerciseResults, timeSpent } = data;
    const userId = context.auth.uid;

    // Get access record
    const accessRef = db.collection("user_lesson_access").doc(accessId);
    const accessDoc = await accessRef.get();

    if (!accessDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Access not found");
    }

    const access = accessDoc.data()!;
    if (access.userId !== userId) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Not your lesson"
      );
    }

    // Get lesson for total sections
    const lessonDoc = await db.collection("lessons").doc(access.lessonId).get();
    const lesson = lessonDoc.data()!;

    // Calculate section progress
    const correctAnswers = exerciseResults?.filter(
      (r: any) => r.isCorrect
    ).length || 0;
    const totalExercises = exerciseResults?.length || 0;

    const sectionProgress = {
      ...access.sectionProgress,
      [sectionId]: {
        sectionId,
        isCompleted: true,
        correctAnswers,
        totalExercises,
        attempts: (access.sectionProgress?.[sectionId]?.attempts || 0) + 1,
        lastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    };

    // Calculate overall progress
    const completedSections = Object.values(sectionProgress).filter(
      (s: any) => s.isCompleted
    ).length;
    const progressPercent = (completedSections / lesson.sections.length) * 100;
    const isCompleted = progressPercent >= 100;

    // Calculate XP earned
    const sectionXp = Math.round(
      (correctAnswers / Math.max(totalExercises, 1)) * 20
    );

    const batch = db.batch();

    // Update access
    const updates: any = {
      sectionProgress,
      progressPercent,
      earnedXp: admin.firestore.FieldValue.increment(sectionXp),
    };

    if (isCompleted && !access.isCompleted) {
      updates.isCompleted = true;
      updates.completedAt = admin.firestore.FieldValue.serverTimestamp();

      // Award completion XP
      const completionXp = lesson.xpReward;
      updates.earnedXp = admin.firestore.FieldValue.increment(
        sectionXp + completionXp
      );

      // Update lesson completion count
      batch.update(db.collection("lessons").doc(access.lessonId), {
        completionCount: admin.firestore.FieldValue.increment(1),
      });

      // Update teacher stats
      batch.update(db.collection("teachers").doc(lesson.teacherId), {
        "stats.totalCompletions": admin.firestore.FieldValue.increment(1),
        "stats.totalXpAwarded": admin.firestore.FieldValue.increment(
          sectionXp + completionXp
        ),
      });
    }

    batch.update(accessRef, updates);

    // Update user learning progress
    const progressRef = db
      .collection("user_learning_progress")
      .doc(`${userId}_${lesson.languageCode}`);
    batch.set(
      progressRef,
      {
        odUserId: userId,
        languageCode: lesson.languageCode,
        languageName: lesson.languageName,
        totalXp: admin.firestore.FieldValue.increment(sectionXp),
        exercisesCompleted: admin.firestore.FieldValue.increment(totalExercises),
        correctAnswers: admin.firestore.FieldValue.increment(correctAnswers),
        totalAnswers: admin.firestore.FieldValue.increment(totalExercises),
        totalMinutesLearned: admin.firestore.FieldValue.increment(timeSpent || 0),
        lastActivityAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    if (isCompleted && !access.isCompleted) {
      batch.update(progressRef, {
        lessonsCompleted: admin.firestore.FieldValue.increment(1),
        completedLessonIds: admin.firestore.FieldValue.arrayUnion(
          access.lessonId
        ),
      });
    }

    await batch.commit();

    return {
      success: true,
      progressPercent,
      isCompleted,
      xpEarned: sectionXp + (isCompleted ? lesson.xpReward : 0),
    };
  })
);

// ============= ANALYTICS =============

/**
 * Admin: Get learning analytics
 */
export const getLearningAnalytics = functions.runWith({ memory: '512MB' }).https.onCall(
  monitored("getLearningAnalytics", async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in"
      );
    }

    // Verify admin
    // P1-6: admin_users / adminRole claim (was profiles.isAdmin).
    if (!(await isAdminCaller(context.auth))) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Admin access required"
      );
    }

    const { startDate, endDate } = data;
    const start = new Date(startDate);
    const end = new Date(endDate);

    // Get active users
    const activeUsersQuery = await db
      .collection("user_learning_progress")
      .where("lastActivityAt", ">=", start)
      .where("lastActivityAt", "<=", end)
      .get();

    // Get lessons completed
    const completionsQuery = await db
      .collection("user_lesson_access")
      .where("isCompleted", "==", true)
      .where("completedAt", ">=", start)
      .where("completedAt", "<=", end)
      .get();

    // Get purchases
    const purchasesQuery = await db
      .collection("user_lesson_access")
      .where("purchasedAt", ">=", start)
      .where("purchasedAt", "<=", end)
      .get();

    // Aggregate by language
    const usersByLanguage: Record<string, number> = {};
    activeUsersQuery.docs.forEach((doc) => {
      const lang = doc.data().languageCode;
      usersByLanguage[lang] = (usersByLanguage[lang] || 0) + 1;
    });

    // Calculate totals
    let totalXpAwarded = 0;
    let totalCoinsSpent = 0;
    activeUsersQuery.docs.forEach((doc) => {
      totalXpAwarded += doc.data().totalXp || 0;
    });
    purchasesQuery.docs.forEach((doc) => {
      totalCoinsSpent += doc.data().coinsPaid || 0;
    });

    // Get top learners
    const topLearnersQuery = await db
      .collection("user_learning_progress")
      .orderBy("totalXp", "desc")
      .limit(10)
      .get();

    const topLearners = await Promise.all(
      topLearnersQuery.docs.map(async (doc, index) => {
        const data = doc.data();
        const profile = await db
          .collection("profiles")
          .doc(data.odUserId)
          .get();
        return {
          odUserId: data.odUserId,
          displayName: profile.data()?.displayName || "Anonymous",
          photoUrl: profile.data()?.photos?.[0] || null,
          xpThisPeriod: data.totalXp,
          lessonsCompleted: data.lessonsCompleted || 0,
          currentStreak: data.currentStreak || 0,
          rank: index + 1,
        };
      })
    );

    // Get popular lessons
    const popularLessonsQuery = await db
      .collection("lessons")
      .where("isPublished", "==", true)
      .orderBy("completionCount", "desc")
      .limit(10)
      .get();

    const popularLessons = popularLessonsQuery.docs.map((doc) => ({
      lessonId: doc.id,
      title: doc.data().title,
      languageCode: doc.data().languageCode,
      completionCount: doc.data().completionCount || 0,
      averageRating: doc.data().averageRating || 0,
      purchaseCount: doc.data().purchaseCount || 0,
    }));

    return {
      generatedAt: new Date().toISOString(),
      dateRange: { start: start.toISOString(), end: end.toISOString() },
      totalActiveUsers: activeUsersQuery.size,
      totalLessonsCompleted: completionsQuery.size,
      totalXpAwarded,
      totalCoinsSpent,
      usersByLanguage,
      topLearners,
      popularLessons,
    };
  })
);

/**
 * Admin: Get user progress report
 */
export const getUserProgressReport = functions.runWith({ memory: '512MB' }).https.onCall(
  monitored("getUserProgressReport", async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in"
      );
    }

    const { userId } = data;

    // Allow user to get their own report or admin to get any
    if (userId !== context.auth.uid) {
      // P1-6: admin_users / adminRole claim (was profiles.isAdmin).
    if (!(await isAdminCaller(context.auth))) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Not authorized"
        );
      }
    }

    // Get all language progress
    const progressQuery = await db
      .collection("user_learning_progress")
      .where("odUserId", "==", userId)
      .get();

    // Get lesson access
    const accessQuery = await db
      .collection("user_lesson_access")
      .where("userId", "==", userId)
      .orderBy("purchasedAt", "desc")
      .get();

    // Get user profile
    const profileDoc = await db.collection("profiles").doc(userId).get();

    const languageProgress = progressQuery.docs.map((doc) => doc.data());
    const lessonHistory = accessQuery.docs.map((doc) => doc.data());

    // Calculate summary stats
    const totalXp = languageProgress.reduce((sum, p) => sum + (p.totalXp || 0), 0);
    const totalLessons = languageProgress.reduce(
      (sum, p) => sum + (p.lessonsCompleted || 0),
      0
    );
    const totalMinutes = languageProgress.reduce(
      (sum, p) => sum + (p.totalMinutesLearned || 0),
      0
    );
    const averageAccuracy =
      languageProgress.length > 0
        ? languageProgress.reduce((sum, p) => {
            const acc =
              p.totalAnswers > 0 ? p.correctAnswers / p.totalAnswers : 0;
            return sum + acc;
          }, 0) / languageProgress.length
        : 0;

    return {
      userId,
      displayName: profileDoc.data()?.displayName || "User",
      summary: {
        totalXp,
        totalLessons,
        totalMinutes,
        languagesLearning: languageProgress.length,
        averageAccuracy: Math.round(averageAccuracy * 100),
      },
      languageProgress,
      recentLessons: lessonHistory.slice(0, 20),
    };
  })
);

/**
 * Admin: Get teacher analytics
 */
export const getTeacherAnalytics = functions.runWith({ memory: '512MB' }).https.onCall(
  monitored("getTeacherAnalytics", async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in"
      );
    }

    // Verify admin or teacher accessing own data
    const { teacherId } = data;
    const teacherDoc = await db.collection("teachers").doc(teacherId).get();

    if (!teacherDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Teacher not found");
    }

    const teacher = teacherDoc.data()!;
    const isOwnData = teacher.userId === context.auth.uid;

    if (!isOwnData) {
      // P1-6: admin_users / adminRole claim (was profiles.isAdmin).
    if (!(await isAdminCaller(context.auth))) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Not authorized"
        );
      }
    }

    // Get earnings
    const earningsQuery = await db
      .collection("teacher_earnings")
      .where("teacherId", "==", teacherId)
      .orderBy("earnedAt", "desc")
      .limit(100)
      .get();

    const earnings = earningsQuery.docs.map((doc) => doc.data());
    const totalEarnings = earnings.reduce(
      (sum, e) => sum + (e.teacherCoins || 0),
      0
    );
    const pendingPayout = earnings
      .filter((e) => !e.isPaidOut)
      .reduce((sum, e) => sum + (e.teacherCoins || 0), 0);

    // Get lessons
    const lessonsQuery = await db
      .collection("lessons")
      .where("teacherId", "==", teacherId)
      .get();

    const lessons = lessonsQuery.docs.map((doc) => ({
      id: doc.id,
      ...(doc.data() as { isPublished?: boolean; [key: string]: any }),
    }));

    // Get ratings
    const ratingsQuery = await db
      .collection("lesson_ratings")
      .where(
        "lessonId",
        "in",
        lessons.map((l) => l.id).slice(0, 10)
      ) // Firestore limit
      .orderBy("createdAt", "desc")
      .limit(50)
      .get();

    const ratings = ratingsQuery.docs.map((doc) => doc.data());

    return {
      teacher: {
        id: teacherDoc.id,
        displayName: teacher.displayName,
        tier: teacher.tier,
        stats: teacher.stats,
      },
      earnings: {
        total: totalEarnings,
        pending: pendingPayout,
        history: earnings.slice(0, 20),
      },
      lessons: {
        total: lessons.length,
        published: lessons.filter((l) => l.isPublished).length,
        list: lessons,
      },
      ratings: {
        average: teacher.stats?.averageRating || 0,
        count: teacher.stats?.totalRatings || 0,
        recent: ratings.slice(0, 10),
      },
    };
  })
);

// ============= ADMIN LESSON API =============

/**
 * Admin: Get all lessons with filtering
 */
export const getAdminLessons = functions.runWith({ memory: '512MB' }).https.onCall(
  monitored("getAdminLessons", async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in"
      );
    }

    // Verify admin
    // P1-6: admin_users / adminRole claim (was profiles.isAdmin).
    if (!(await isAdminCaller(context.auth))) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Admin access required"
      );
    }

    const { languageCode, level, category, isPublished, limit: queryLimit } = data;

    let query: admin.firestore.Query = db.collection("lessons");

    if (languageCode) {
      query = query.where("languageCode", "==", languageCode);
    }
    if (level) {
      query = query.where("level", "==", level);
    }
    if (category) {
      query = query.where("category", "==", category);
    }
    if (typeof isPublished === "boolean") {
      query = query.where("isPublished", "==", isPublished);
    }

    query = query.orderBy("weekNumber").orderBy("dayNumber");

    if (queryLimit) {
      query = query.limit(queryLimit);
    }

    const snapshot = await query.get();

    const lessons = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    // Get stats
    const totalLessons = await db.collection("lessons").count().get();
    const publishedLessons = await db
      .collection("lessons")
      .where("isPublished", "==", true)
      .count()
      .get();

    // Group by language
    const lessonsByLanguage: Record<string, number> = {};
    lessons.forEach((lesson: any) => {
      const lang = lesson.languageCode;
      lessonsByLanguage[lang] = (lessonsByLanguage[lang] || 0) + 1;
    });

    return {
      lessons,
      stats: {
        total: totalLessons.data().count,
        published: publishedLessons.data().count,
        byLanguage: lessonsByLanguage,
      },
    };
  })
);

/**
 * Admin: Seed lessons for supported languages (es, en, pt, pt-BR, it)
 * Creates 52 weeks (1 year) of lessons for each language
 */
export const seedLessons = functions.runWith({ memory: '512MB' }).https.onCall(
  monitored("seedLessons", async (data, context) => {
    // Check if running in emulator mode - allow bypass for local development
    const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";

    if (!isEmulator) {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "Must be logged in"
        );
      }

      // Verify admin
      // P1-6: admin_users / adminRole claim (was profiles.isAdmin).
    if (!(await isAdminCaller(context.auth, MODERATION_ROLES))) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Admin access required"
        );
      }
    }

    const { languageCodes, clearExisting } = data;

    // Use specified languages or default to all supported
    const targetLanguages = languageCodes?.length
      ? languageCodes
      : Object.keys(languageInfo);

    const results: Record<string, { created: number; errors: number }> = {};

    for (const langCode of targetLanguages) {
      const langInfo = languageInfo[langCode];
      const langContent = languageContent[langCode] || languageContent["en"];

      if (!langInfo) {
        results[langCode] = { created: 0, errors: 1 };
        continue;
      }

      // Clear existing lessons for this language if requested
      if (clearExisting) {
        const existingLessons = await db
          .collection("lessons")
          .where("languageCode", "==", langCode)
          .get();

        const deletePromises = existingLessons.docs.map((doc) =>
          doc.ref.delete()
        );
        await Promise.all(deletePromises);
      }

      let created = 0;
      let errors = 0;

      // Generate 52 weeks of lessons
      for (let week = 1; week <= 52; week++) {
        const themeIndex = (week - 1) % weeklyThemes.length;
        const theme = weeklyThemes[themeIndex];

        for (let day = 1; day <= 7; day++) {
          const dayPlan = theme.days[day - 1];
          const lessonNumber = (week - 1) * 7 + day;

          // Get content for this category
          const categoryContent = langContent[dayPlan.category] || langContent["greetings"];
          const phrases = Object.entries(categoryContent).slice(0, 5);

          // Build sections
          const sections = [
            {
              id: `${langCode}_${lessonNumber}_vocab`,
              title: "Key Vocabulary",
              type: "vocabulary",
              orderIndex: 0,
              introduction: "Learn these essential words and phrases",
              contents: phrases.map(([key, phrase], i) => ({
                id: `${langCode}_${lessonNumber}_vocab_${i}`,
                type: "phrase",
                text: phrase,
                translation: key.replace(/_/g, " "),
                pronunciation: phrase,
              })),
              exercises: phrases.map(([key, phrase], i) => ({
                id: `${langCode}_${lessonNumber}_vocab_ex_${i}`,
                type: "multiple_choice",
                question: `What does "${key.replace(/_/g, " ")}" mean?`,
                options: [phrase, "Wrong answer 1", "Wrong answer 2", "Wrong answer 3"],
                correctAnswer: phrase,
                explanation: `"${key.replace(/_/g, " ")}" translates to "${phrase}"`,
                xpReward: 5,
                orderIndex: i,
              })),
              xpReward: 15,
            },
            {
              id: `${langCode}_${lessonNumber}_practice`,
              title: "Practice Time",
              type: "practice",
              orderIndex: 1,
              introduction: "Test what you learned",
              contents: [],
              exercises: phrases.map(([key, phrase], i) => ({
                id: `${langCode}_${lessonNumber}_practice_ex_${i}`,
                type: "fill_in_blank",
                question: `Complete: ${phrase.substring(0, Math.floor(phrase.length / 2))}___`,
                options: [],
                correctAnswer: phrase,
                hint: key.replace(/_/g, " "),
                xpReward: 10,
                orderIndex: i,
              })),
              xpReward: 25,
            },
          ];

          // Determine level based on week
          let level = "absolute_beginner";
          if (week > 4) level = "beginner";
          if (week > 10) level = "elementary";
          if (week > 18) level = "pre_intermediate";
          if (week > 26) level = "intermediate";
          if (week > 36) level = "upper_intermediate";
          if (week > 44) level = "advanced";
          if (week > 50) level = "fluent";

          // Determine price
          let coinPrice = 0;
          if (week > 1) coinPrice = 10;
          if (week > 4) coinPrice = 15;
          if (week > 10) coinPrice = 20;
          if (week > 18) coinPrice = 25;
          if (week > 26) coinPrice = 30;
          if (week > 36) coinPrice = 40;
          if (week > 44) coinPrice = 50;

          try {
            const lessonRef = db.collection("lessons").doc(`${langCode}_lesson_${lessonNumber}`);
            await lessonRef.set({
              id: lessonRef.id,
              languageCode: langCode,
              languageName: langInfo.name,
              languageNativeName: langInfo.nativeName,
              languageFlag: langInfo.flag,
              title: dayPlan.title,
              description: dayPlan.description,
              category: dayPlan.category,
              level,
              lessonNumber,
              weekNumber: week,
              dayNumber: day,
              weekTheme: theme.theme,
              coinPrice,
              isFree: week === 1, // First week is free
              isPremium: week > 40,
              estimatedMinutes: 10 + Math.floor(Math.random() * 10),
              xpReward: 15 + (week * 2),
              bonusCoins: day === 7 ? 10 : 0,
              sections,
              objectives: [
                `Learn key ${dayPlan.category} phrases`,
                "Practice pronunciation",
                "Complete all exercises",
              ],
              prerequisites: lessonNumber > 1 ? [`${langCode}_lesson_${lessonNumber - 1}`] : [],
              teacherId: "system",
              teacherName: "GreenGo Language Team",
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: null,
              isPublished: true,
              status: "published",
              averageRating: 4.5 + Math.random() * 0.5,
              totalRatings: Math.floor(Math.random() * 100),
              completionCount: Math.floor(Math.random() * 500),
              purchaseCount: Math.floor(Math.random() * 1000),
            });
            created++;
          } catch (e) {
            console.error(`Error creating lesson ${langCode}_${lessonNumber}:`, e);
            errors++;
          }
        }
      }

      results[langCode] = { created, errors };
    }

    return {
      success: true,
      message: `Seeded lessons for ${targetLanguages.length} languages`,
      results,
    };
  })
);

/**
 * Admin: Delete lesson
 */
export const deleteLesson = functions.runWith({ memory: '512MB' }).https.onCall(
  monitored("deleteLesson", async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in"
      );
    }

    // Verify admin
    // P1-6: admin_users / adminRole claim (was profiles.isAdmin).
    if (!(await isAdminCaller(context.auth, MODERATION_ROLES))) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Admin access required"
      );
    }

    const { lessonId } = data;

    await db.collection("lessons").doc(lessonId).delete();

    return { success: true, deletedId: lessonId };
  })
);

/**
 * Admin: Update lesson
 */
export const updateLesson = functions.runWith({ memory: '512MB' }).https.onCall(
  monitored("updateLesson", async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in"
      );
    }

    // Verify admin
    // P1-6: admin_users / adminRole claim (was profiles.isAdmin).
    if (!(await isAdminCaller(context.auth, MODERATION_ROLES))) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Admin access required"
      );
    }

    const { lessonId, updates } = data;

    // Remove sensitive fields
    delete updates.id;
    delete updates.createdAt;

    updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    await db.collection("lessons").doc(lessonId).update(updates);

    return { success: true, updatedId: lessonId };
  })
);

/**
 * Admin: Get lesson stats by language
 */
export const getLessonStats = functions.runWith({ memory: '512MB' }).https.onCall(
  monitored("getLessonStats", async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in"
      );
    }

    // Verify admin
    // P1-6: admin_users / adminRole claim (was profiles.isAdmin).
    if (!(await isAdminCaller(context.auth))) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Admin access required"
      );
    }

    const stats: Record<string, any> = {};

    for (const [langCode, langInfo] of Object.entries(languageInfo)) {
      const totalQuery = await db
        .collection("lessons")
        .where("languageCode", "==", langCode)
        .count()
        .get();

      const publishedQuery = await db
        .collection("lessons")
        .where("languageCode", "==", langCode)
        .where("isPublished", "==", true)
        .count()
        .get();

      const freeQuery = await db
        .collection("lessons")
        .where("languageCode", "==", langCode)
        .where("isFree", "==", true)
        .count()
        .get();

      stats[langCode] = {
        ...langInfo,
        totalLessons: totalQuery.data().count,
        publishedLessons: publishedQuery.data().count,
        freeLessons: freeQuery.data().count,
        paidLessons: totalQuery.data().count - freeQuery.data().count,
      };
    }

    return {
      supportedLanguages: Object.keys(languageInfo),
      languageStats: stats,
      totalLessonsAllLanguages: Object.values(stats).reduce(
        (sum: number, s: any) => sum + s.totalLessons,
        0
      ),
    };
  })
);
