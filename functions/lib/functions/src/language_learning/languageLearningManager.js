"use strict";
/**
 * Language Learning Management Cloud Functions
 * Handles lessons, teachers, progress tracking, and analytics
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.getLessonStats = exports.updateLesson = exports.deleteLesson = exports.seedLessons = exports.getAdminLessons = exports.getTeacherAnalytics = exports.getUserProgressReport = exports.getLearningAnalytics = exports.updateLessonProgress = exports.purchaseLesson = exports.publishLesson = exports.createLesson = exports.reviewTeacherApplication = exports.submitTeacherApplication = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
// ============= LESSON SEEDING DATA =============
// Language content translations for 8 major languages
const languageContent = {
    es: {
        greetings: {
            hello_beautiful: "¡Hola guapa/guapo!",
            how_are_you: "¿Cómo estás?",
            nice_to_meet_you: "Encantado/a de conocerte",
            good_morning: "¡Buenos días, cariño!",
            good_night: "¡Buenas noches, mi amor!",
        },
        compliments: {
            beautiful_eyes: "Tienes unos ojos preciosos",
            lovely_smile: "Me encanta tu sonrisa",
            you_look_amazing: "Estás increíble",
            so_funny: "Eres muy gracioso/a",
        },
        flirting: {
            can_i_buy_drink: "¿Te puedo invitar a una copa?",
            you_come_here_often: "¿Vienes aquí a menudo?",
            cant_stop_thinking: "No puedo dejar de pensar en ti",
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
            i_like_you: "Me gustas",
            i_love_you: "Te quiero / Te amo",
            miss_you: "Te echo de menos",
        },
    },
    fr: {
        greetings: {
            hello_beautiful: "Bonjour belle/beau!",
            how_are_you: "Comment vas-tu?",
            nice_to_meet_you: "Enchanté(e) de te rencontrer",
            good_morning: "Bonjour mon cœur!",
            good_night: "Bonne nuit mon amour!",
        },
        compliments: {
            beautiful_eyes: "Tu as de très beaux yeux",
            lovely_smile: "J'adore ton sourire",
            you_look_amazing: "Tu es magnifique",
            so_funny: "Tu es tellement drôle",
        },
        flirting: {
            can_i_buy_drink: "Je peux t'offrir un verre?",
            you_come_here_often: "Tu viens souvent ici?",
            cant_stop_thinking: "Je n'arrête pas de penser à toi",
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
            i_like_you: "Tu me plais",
            i_love_you: "Je t'aime",
            miss_you: "Tu me manques",
        },
    },
    de: {
        greetings: {
            hello_beautiful: "Hallo Schöne/Schöner!",
            how_are_you: "Wie geht es dir?",
            nice_to_meet_you: "Freut mich, dich kennenzulernen",
            good_morning: "Guten Morgen, Schatz!",
            good_night: "Gute Nacht, mein Liebe!",
        },
        compliments: {
            beautiful_eyes: "Du hast wunderschöne Augen",
            lovely_smile: "Ich liebe dein Lächeln",
            you_look_amazing: "Du siehst toll aus",
            so_funny: "Du bist so lustig",
        },
        flirting: {
            can_i_buy_drink: "Darf ich dir einen Drink ausgeben?",
            you_come_here_often: "Kommst du öfter hierher?",
            cant_stop_thinking: "Ich muss ständig an dich denken",
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
            i_like_you: "Ich mag dich",
            i_love_you: "Ich liebe dich",
            miss_you: "Ich vermisse dich",
        },
    },
    it: {
        greetings: {
            hello_beautiful: "Ciao bella/bello!",
            how_are_you: "Come stai?",
            nice_to_meet_you: "Piacere di conoscerti",
            good_morning: "Buongiorno tesoro!",
            good_night: "Buonanotte amore mio!",
        },
        compliments: {
            beautiful_eyes: "Hai degli occhi bellissimi",
            lovely_smile: "Adoro il tuo sorriso",
            you_look_amazing: "Sei fantastica/o",
            so_funny: "Sei molto divertente",
        },
        flirting: {
            can_i_buy_drink: "Posso offrirti qualcosa da bere?",
            you_come_here_often: "Vieni spesso qui?",
            cant_stop_thinking: "Non riesco a smettere di pensare a te",
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
            i_like_you: "Mi piaci",
            i_love_you: "Ti amo",
            miss_you: "Mi manchi",
        },
    },
    pt: {
        greetings: {
            hello_beautiful: "Olá linda/lindo!",
            how_are_you: "Como você está?",
            nice_to_meet_you: "Prazer em te conhecer",
            good_morning: "Bom dia, amor!",
            good_night: "Boa noite, meu amor!",
        },
        compliments: {
            beautiful_eyes: "Você tem olhos lindos",
            lovely_smile: "Adoro seu sorriso",
            you_look_amazing: "Você está incrível",
            so_funny: "Você é muito engraçado/a",
        },
        flirting: {
            can_i_buy_drink: "Posso te pagar uma bebida?",
            you_come_here_often: "Você vem sempre aqui?",
            cant_stop_thinking: "Não consigo parar de pensar em você",
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
            i_like_you: "Eu gosto de você",
            i_love_you: "Eu te amo",
            miss_you: "Sinto sua falta",
        },
    },
    ja: {
        greetings: {
            hello_beautiful: "やあ、かわいいね！(Yaa, kawaii ne!)",
            how_are_you: "元気？(Genki?)",
            nice_to_meet_you: "はじめまして (Hajimemashite)",
            good_morning: "おはよう、大好き！(Ohayou, daisuki!)",
            good_night: "おやすみ、愛してる (Oyasumi, aishiteru)",
        },
        compliments: {
            beautiful_eyes: "目がきれい (Me ga kirei)",
            lovely_smile: "笑顔が素敵 (Egao ga suteki)",
            you_look_amazing: "とてもきれいだね (Totemo kirei da ne)",
            so_funny: "面白いね (Omoshiroi ne)",
        },
        flirting: {
            can_i_buy_drink: "飲み物をおごらせて (Nomimono wo ogorasete)",
            you_come_here_often: "よくここに来るの？(Yoku koko ni kuru no?)",
            cant_stop_thinking: "君のことが頭から離れない",
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
            i_like_you: "好きです (Suki desu)",
            i_love_you: "愛してる (Aishiteru)",
            miss_you: "会いたい (Aitai)",
        },
    },
    ko: {
        greetings: {
            hello_beautiful: "안녕, 예쁜이! (Annyeong, yeppeu-ni!)",
            how_are_you: "어떻게 지내? (Eotteoke jinae?)",
            nice_to_meet_you: "만나서 반가워 (Mannaseo bangawo)",
            good_morning: "좋은 아침, 자기야! (Joeun achim, jagiya!)",
            good_night: "잘 자, 내 사랑 (Jal ja, nae sarang)",
        },
        compliments: {
            beautiful_eyes: "눈이 예뻐요 (Nuni yeppeoyo)",
            lovely_smile: "웃는 모습이 좋아 (Utneun moseubi joa)",
            you_look_amazing: "정말 멋져 (Jeongmal meotjyeo)",
            so_funny: "진짜 웃겨 (Jinjja utgyeo)",
        },
        flirting: {
            can_i_buy_drink: "한 잔 사도 될까요? (Han jan sado doelkkayo?)",
            you_come_here_often: "여기 자주 와요? (Yeogi jaju wayo?)",
            cant_stop_thinking: "자꾸 생각나 (Jakku saenggakna)",
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
            i_like_you: "좋아해요 (Joahaeyo)",
            i_love_you: "사랑해요 (Saranghaeyo)",
            miss_you: "보고 싶어요 (Bogo sipeoyo)",
        },
    },
    zh: {
        greetings: {
            hello_beautiful: "你好，美女/帅哥！(Nǐ hǎo, měinǚ/shuàigē!)",
            how_are_you: "你好吗？(Nǐ hǎo ma?)",
            nice_to_meet_you: "很高兴认识你 (Hěn gāoxìng rènshi nǐ)",
            good_morning: "早上好，亲爱的！(Zǎoshang hǎo, qīn'ài de!)",
            good_night: "晚安，我的爱 (Wǎn'ān, wǒ de ài)",
        },
        compliments: {
            beautiful_eyes: "你的眼睛很美 (Nǐ de yǎnjīng hěn měi)",
            lovely_smile: "我喜欢你的笑容 (Wǒ xǐhuān nǐ de xiàoróng)",
            you_look_amazing: "你真漂亮 (Nǐ zhēn piàoliang)",
            so_funny: "你很幽默 (Nǐ hěn yōumò)",
        },
        flirting: {
            can_i_buy_drink: "我请你喝一杯？(Wǒ qǐng nǐ hē yī bēi?)",
            you_come_here_often: "你常来这里吗？(Nǐ cháng lái zhèlǐ ma?)",
            cant_stop_thinking: "我一直在想你 (Wǒ yīzhí zài xiǎng nǐ)",
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
            i_like_you: "我喜欢你 (Wǒ xǐhuān nǐ)",
            i_love_you: "我爱你 (Wǒ ài nǐ)",
            miss_you: "我想你 (Wǒ xiǎng nǐ)",
        },
    },
};
// Language metadata - Starting with 5 languages
const languageInfo = {
    es: { name: "Spanish", nativeName: "Español", flag: "🇪🇸" },
    en: { name: "English", nativeName: "English", flag: "🇬🇧" },
    pt: { name: "Portuguese", nativeName: "Português", flag: "🇵🇹" },
    "pt-BR": { name: "Brazilian Portuguese", nativeName: "Português Brasileiro", flag: "🇧🇷" },
    it: { name: "Italian", nativeName: "Italiano", flag: "🇮🇹" },
};
// Add English content
languageContent["en"] = {
    greetings: {
        hello_beautiful: "Hello beautiful/handsome!",
        how_are_you: "How are you?",
        nice_to_meet_you: "Nice to meet you",
        good_morning: "Good morning, darling!",
        good_night: "Good night, my love!",
    },
    compliments: {
        beautiful_eyes: "You have beautiful eyes",
        lovely_smile: "I love your smile",
        you_look_amazing: "You look amazing",
        so_funny: "You're so funny",
    },
    flirting: {
        can_i_buy_drink: "Can I buy you a drink?",
        you_come_here_often: "Do you come here often?",
        cant_stop_thinking: "I can't stop thinking about you",
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
        i_like_you: "I like you",
        i_love_you: "I love you",
        miss_you: "I miss you",
    },
};
// Add Brazilian Portuguese content
languageContent["pt-BR"] = {
    greetings: {
        hello_beautiful: "Oi linda/lindo!",
        how_are_you: "Tudo bem?",
        nice_to_meet_you: "Prazer em conhecer você",
        good_morning: "Bom dia, meu amor!",
        good_night: "Boa noite, meu bem!",
    },
    compliments: {
        beautiful_eyes: "Você tem olhos lindos",
        lovely_smile: "Amo seu sorriso",
        you_look_amazing: "Você tá linda/lindo demais",
        so_funny: "Você é muito engraçado/a",
    },
    flirting: {
        can_i_buy_drink: "Posso te pagar uma bebida?",
        you_come_here_often: "Você vem sempre aqui?",
        cant_stop_thinking: "Não consigo parar de pensar em você",
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
        i_like_you: "Eu gosto de você",
        i_love_you: "Eu te amo",
        miss_you: "Tô com saudade de você",
    },
};
// Weekly themes (8 themes that rotate through the year)
const weeklyThemes = [
    {
        theme: "Getting Started with Dating",
        days: [
            { title: "Hello Beautiful! - Basic Greetings", category: "greetings", description: "Learn charming ways to say hello and make a great first impression" },
            { title: "What's Your Name? - Introductions", category: "greetings", description: "Master the art of introducing yourself in a dating context" },
            { title: "You Look Amazing! - Compliments", category: "compliments", description: "Learn sincere compliments that make people smile" },
            { title: "Tell Me About Yourself", category: "greetings", description: "Share interesting things about yourself and ask great questions" },
            { title: "I Really Like... - Expressing Interests", category: "greetings", description: "Talk about your hobbies and find common ground" },
            { title: "Want to Grab Coffee?", category: "asking_out", description: "Learn to suggest a casual first date confidently" },
            { title: "Weekend Review & Practice", category: "greetings", description: "Review everything you learned this week with fun exercises" },
        ],
    },
    {
        theme: "Coffee Date Conversations",
        days: [
            { title: "At the Cafe - Ordering Drinks", category: "restaurant", description: "Navigate the menu and order like a local" },
            { title: "Do You Come Here Often?", category: "flirting", description: "Classic conversation starters that actually work" },
            { title: "What Do You Do? - Jobs & Dreams", category: "greetings", description: "Talk about work and aspirations in an interesting way" },
            { title: "This Is Delicious! - Food Talk", category: "restaurant", description: "Express opinions about food and discover taste preferences" },
            { title: "I Love This Song! - Music Chat", category: "greetings", description: "Bond over music and discover shared tastes" },
            { title: "Let's Do This Again!", category: "asking_out", description: "End dates on a high note and plan the next one" },
            { title: "Coffee Date Mastery", category: "restaurant", description: "Put it all together for the perfect cafe date" },
        ],
    },
    {
        theme: "Flirting Like a Pro",
        days: [
            { title: "You Have Beautiful Eyes", category: "compliments", description: "Romantic compliments that feel genuine" },
            { title: "You Make Me Laugh!", category: "compliments", description: "Appreciate someone's personality and humor" },
            { title: "Playful Teasing 101", category: "flirting", description: "Light-hearted teasing that creates chemistry" },
            { title: "Body Language Phrases", category: "flirting", description: "Words that match flirty body language" },
            { title: "Fun Pickup Lines That Work", category: "flirting", description: "Cheesy but effective ice-breakers" },
            { title: "I Can't Stop Thinking About You", category: "feelings", description: "Express attraction and interest romantically" },
            { title: "Flirting Practice Session", category: "flirting", description: "Practice your new flirting skills with confidence" },
        ],
    },
    {
        theme: "Restaurant Dates",
        days: [
            { title: "Making Reservations", category: "restaurant", description: "Book a table like a pro" },
            { title: "Reading the Menu", category: "restaurant", description: "Navigate any menu with confidence" },
            { title: "What Would You Recommend?", category: "restaurant", description: "Get great recommendations from servers" },
            { title: "Wine and Drinks Selection", category: "restaurant", description: "Order drinks like a sommelier" },
            { title: "This Is Amazing! - Food Reactions", category: "restaurant", description: "Express your culinary delight" },
            { title: "Shall We Split Dessert?", category: "restaurant", description: "The sweet end to a perfect meal" },
            { title: "Getting the Check", category: "restaurant", description: "Handle payment smoothly and gracefully" },
        ],
    },
    {
        theme: "Expressing Your Feelings",
        days: [
            { title: "I Really Like You", category: "feelings", description: "Express your growing feelings" },
            { title: "You Mean So Much to Me", category: "feelings", description: "Deepen emotional expression" },
            { title: "I'm Falling for You", category: "feelings", description: "Romantic declarations" },
            { title: "You Make Me Happy", category: "feelings", description: "Share how they affect your life" },
            { title: "I'm Sorry - Making Up", category: "feelings", description: "Apologize and resolve conflicts" },
            { title: "Let's Talk About Us", category: "feelings", description: "Relationship discussions" },
            { title: "I Love You", category: "feelings", description: "The three magic words" },
        ],
    },
    {
        theme: "Advanced Compliments",
        days: [
            { title: "Beyond Beautiful - Unique Compliments", category: "compliments", description: "Stand out with creative compliments" },
            { title: "Complimenting Intelligence", category: "compliments", description: "Appreciate their mind" },
            { title: "Style and Fashion Praise", category: "compliments", description: "Notice and compliment their style" },
            { title: "Personality Appreciation", category: "compliments", description: "Love who they are inside" },
            { title: "Romantic Comparisons", category: "compliments", description: "Poetic expressions of admiration" },
            { title: "Accepting Compliments Gracefully", category: "compliments", description: "Respond to praise with confidence" },
            { title: "Compliment Mastery", category: "compliments", description: "Perfect your compliment game" },
        ],
    },
    {
        theme: "Planning and Asking Out",
        days: [
            { title: "Casual Date Suggestions", category: "asking_out", description: "Low-pressure first date ideas" },
            { title: "Romantic Date Planning", category: "asking_out", description: "Plan something special" },
            { title: "Adventure Date Proposals", category: "asking_out", description: "Suggest exciting activities" },
            { title: "Setting the Time and Place", category: "asking_out", description: "Nail down the details" },
            { title: "Confirming Plans", category: "asking_out", description: "Follow up without being pushy" },
            { title: "Changing Plans Gracefully", category: "asking_out", description: "Handle schedule changes" },
            { title: "Date Planning Pro", category: "asking_out", description: "Master the art of asking out" },
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
            { title: "Deep Connection", category: "feelings", description: "Meaningful exchanges" },
        ],
    },
];
// ============= TEACHER MANAGEMENT =============
/**
 * Submit teacher application
 */
exports.submitTeacherApplication = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
    }
    const { fullName, bio, teachingLanguages, nativeLanguages, teachingExperience, yearsExperience, certificationUrls, portfolioUrl, linkedinUrl, videoIntroUrl, motivation, sampleLessonIdea, } = data;
    // Validate required fields
    if (!fullName ||
        !bio ||
        !(teachingLanguages === null || teachingLanguages === void 0 ? void 0 : teachingLanguages.length) ||
        !(nativeLanguages === null || nativeLanguages === void 0 ? void 0 : nativeLanguages.length) ||
        !motivation) {
        throw new functions.https.HttpsError("invalid-argument", "Missing required fields");
    }
    // Check if user already has an application
    const existingApp = await db
        .collection("teacher_applications")
        .where("userId", "==", context.auth.uid)
        .where("status", "in", ["pending", "under_review"])
        .get();
    if (!existingApp.empty) {
        throw new functions.https.HttpsError("already-exists", "You already have a pending application");
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
});
/**
 * Admin: Review teacher application
 */
exports.reviewTeacherApplication = functions.https.onCall(async (data, context) => {
    var _a;
    // Verify admin
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
    }
    const adminDoc = await db
        .collection("profiles")
        .doc(context.auth.uid)
        .get();
    if (!adminDoc.exists || !((_a = adminDoc.data()) === null || _a === void 0 ? void 0 : _a.isAdmin)) {
        throw new functions.https.HttpsError("permission-denied", "Admin access required");
    }
    const { applicationId, approved, reviewNotes, rejectionReason } = data;
    const appRef = db.collection("teacher_applications").doc(applicationId);
    const appDoc = await appRef.get();
    if (!appDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Application not found");
    }
    const appData = appDoc.data();
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
});
// ============= LESSON MANAGEMENT =============
/**
 * Teacher: Create a new lesson
 */
exports.createLesson = functions.https.onCall(async (data, context) => {
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
        throw new functions.https.HttpsError("permission-denied", "Must be an approved teacher");
    }
    const teacher = teacherQuery.docs[0].data();
    // Validate language
    if (!teacher.teachingLanguages.includes(data.languageCode)) {
        throw new functions.https.HttpsError("permission-denied", "Not authorized to teach this language");
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
        "stats.lastLessonCreated": admin.firestore.FieldValue.serverTimestamp(),
        [`stats.lessonsByLanguage.${data.languageCode}`]: admin.firestore.FieldValue.increment(1),
    });
    return { success: true, lessonId: lessonRef.id };
});
/**
 * Teacher: Publish a lesson
 */
exports.publishLesson = functions.https.onCall(async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
    }
    const { lessonId } = data;
    const lessonRef = db.collection("lessons").doc(lessonId);
    const lessonDoc = await lessonRef.get();
    if (!lessonDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Lesson not found");
    }
    const lesson = lessonDoc.data();
    // Verify ownership
    const teacherQuery = await db
        .collection("teachers")
        .where("userId", "==", context.auth.uid)
        .where("id", "==", lesson.teacherId)
        .limit(1)
        .get();
    if (teacherQuery.empty) {
        throw new functions.https.HttpsError("permission-denied", "Not authorized to publish this lesson");
    }
    // Validate lesson has content
    if (!((_a = lesson.sections) === null || _a === void 0 ? void 0 : _a.length) || lesson.sections.length < 2) {
        throw new functions.https.HttpsError("failed-precondition", "Lesson must have at least 2 sections");
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
});
// ============= LESSON PURCHASE =============
/**
 * Purchase a lesson with coins
 */
exports.purchaseLesson = functions.https.onCall(async (data, context) => {
    var _a;
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
    const lesson = lessonDoc.data();
    if (!lesson.isPublished) {
        throw new functions.https.HttpsError("failed-precondition", "Lesson is not available");
    }
    // Check if already purchased
    const existingAccess = await db
        .collection("user_lesson_access")
        .where("userId", "==", userId)
        .where("lessonId", "==", lessonId)
        .limit(1)
        .get();
    if (!existingAccess.empty) {
        throw new functions.https.HttpsError("already-exists", "You already own this lesson");
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
    const balance = userWallet.exists ? ((_a = userWallet.data()) === null || _a === void 0 ? void 0 : _a.balance) || 0 : 0;
    if (balance < lesson.coinPrice) {
        throw new functions.https.HttpsError("failed-precondition", "Insufficient coins");
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
});
// ============= PROGRESS TRACKING =============
/**
 * Update lesson progress
 */
exports.updateLessonProgress = functions.https.onCall(async (data, context) => {
    var _a, _b;
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
    }
    const { accessId, sectionId, exerciseResults, timeSpent } = data;
    const userId = context.auth.uid;
    // Get access record
    const accessRef = db.collection("user_lesson_access").doc(accessId);
    const accessDoc = await accessRef.get();
    if (!accessDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Access not found");
    }
    const access = accessDoc.data();
    if (access.userId !== userId) {
        throw new functions.https.HttpsError("permission-denied", "Not your lesson");
    }
    // Get lesson for total sections
    const lessonDoc = await db.collection("lessons").doc(access.lessonId).get();
    const lesson = lessonDoc.data();
    // Calculate section progress
    const correctAnswers = (exerciseResults === null || exerciseResults === void 0 ? void 0 : exerciseResults.filter((r) => r.isCorrect).length) || 0;
    const totalExercises = (exerciseResults === null || exerciseResults === void 0 ? void 0 : exerciseResults.length) || 0;
    const sectionProgress = Object.assign(Object.assign({}, access.sectionProgress), { [sectionId]: {
            sectionId,
            isCompleted: true,
            correctAnswers,
            totalExercises,
            attempts: (((_b = (_a = access.sectionProgress) === null || _a === void 0 ? void 0 : _a[sectionId]) === null || _b === void 0 ? void 0 : _b.attempts) || 0) + 1,
            lastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
        } });
    // Calculate overall progress
    const completedSections = Object.values(sectionProgress).filter((s) => s.isCompleted).length;
    const progressPercent = (completedSections / lesson.sections.length) * 100;
    const isCompleted = progressPercent >= 100;
    // Calculate XP earned
    const sectionXp = Math.round((correctAnswers / Math.max(totalExercises, 1)) * 20);
    const batch = db.batch();
    // Update access
    const updates = {
        sectionProgress,
        progressPercent,
        earnedXp: admin.firestore.FieldValue.increment(sectionXp),
    };
    if (isCompleted && !access.isCompleted) {
        updates.isCompleted = true;
        updates.completedAt = admin.firestore.FieldValue.serverTimestamp();
        // Award completion XP
        const completionXp = lesson.xpReward;
        updates.earnedXp = admin.firestore.FieldValue.increment(sectionXp + completionXp);
        // Update lesson completion count
        batch.update(db.collection("lessons").doc(access.lessonId), {
            completionCount: admin.firestore.FieldValue.increment(1),
        });
        // Update teacher stats
        batch.update(db.collection("teachers").doc(lesson.teacherId), {
            "stats.totalCompletions": admin.firestore.FieldValue.increment(1),
            "stats.totalXpAwarded": admin.firestore.FieldValue.increment(sectionXp + completionXp),
        });
    }
    batch.update(accessRef, updates);
    // Update user learning progress
    const progressRef = db
        .collection("user_learning_progress")
        .doc(`${userId}_${lesson.languageCode}`);
    batch.set(progressRef, {
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
    }, { merge: true });
    if (isCompleted && !access.isCompleted) {
        batch.update(progressRef, {
            lessonsCompleted: admin.firestore.FieldValue.increment(1),
            completedLessonIds: admin.firestore.FieldValue.arrayUnion(access.lessonId),
        });
    }
    await batch.commit();
    return {
        success: true,
        progressPercent,
        isCompleted,
        xpEarned: sectionXp + (isCompleted ? lesson.xpReward : 0),
    };
});
// ============= ANALYTICS =============
/**
 * Admin: Get learning analytics
 */
exports.getLearningAnalytics = functions.https.onCall(async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
    }
    // Verify admin
    const adminDoc = await db
        .collection("profiles")
        .doc(context.auth.uid)
        .get();
    if (!adminDoc.exists || !((_a = adminDoc.data()) === null || _a === void 0 ? void 0 : _a.isAdmin)) {
        throw new functions.https.HttpsError("permission-denied", "Admin access required");
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
    const usersByLanguage = {};
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
    const topLearners = await Promise.all(topLearnersQuery.docs.map(async (doc, index) => {
        var _a, _b, _c;
        const data = doc.data();
        const profile = await db
            .collection("profiles")
            .doc(data.odUserId)
            .get();
        return {
            odUserId: data.odUserId,
            displayName: ((_a = profile.data()) === null || _a === void 0 ? void 0 : _a.displayName) || "Anonymous",
            photoUrl: ((_c = (_b = profile.data()) === null || _b === void 0 ? void 0 : _b.photos) === null || _c === void 0 ? void 0 : _c[0]) || null,
            xpThisPeriod: data.totalXp,
            lessonsCompleted: data.lessonsCompleted || 0,
            currentStreak: data.currentStreak || 0,
            rank: index + 1,
        };
    }));
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
});
/**
 * Admin: Get user progress report
 */
exports.getUserProgressReport = functions.https.onCall(async (data, context) => {
    var _a, _b;
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
    }
    const { userId } = data;
    // Allow user to get their own report or admin to get any
    if (userId !== context.auth.uid) {
        const adminDoc = await db
            .collection("profiles")
            .doc(context.auth.uid)
            .get();
        if (!adminDoc.exists || !((_a = adminDoc.data()) === null || _a === void 0 ? void 0 : _a.isAdmin)) {
            throw new functions.https.HttpsError("permission-denied", "Not authorized");
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
    const totalLessons = languageProgress.reduce((sum, p) => sum + (p.lessonsCompleted || 0), 0);
    const totalMinutes = languageProgress.reduce((sum, p) => sum + (p.totalMinutesLearned || 0), 0);
    const averageAccuracy = languageProgress.length > 0
        ? languageProgress.reduce((sum, p) => {
            const acc = p.totalAnswers > 0 ? p.correctAnswers / p.totalAnswers : 0;
            return sum + acc;
        }, 0) / languageProgress.length
        : 0;
    return {
        userId,
        displayName: ((_b = profileDoc.data()) === null || _b === void 0 ? void 0 : _b.displayName) || "User",
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
});
/**
 * Admin: Get teacher analytics
 */
exports.getTeacherAnalytics = functions.https.onCall(async (data, context) => {
    var _a, _b, _c;
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
    }
    // Verify admin or teacher accessing own data
    const { teacherId } = data;
    const teacherDoc = await db.collection("teachers").doc(teacherId).get();
    if (!teacherDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Teacher not found");
    }
    const teacher = teacherDoc.data();
    const isOwnData = teacher.userId === context.auth.uid;
    if (!isOwnData) {
        const adminDoc = await db
            .collection("profiles")
            .doc(context.auth.uid)
            .get();
        if (!adminDoc.exists || !((_a = adminDoc.data()) === null || _a === void 0 ? void 0 : _a.isAdmin)) {
            throw new functions.https.HttpsError("permission-denied", "Not authorized");
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
    const totalEarnings = earnings.reduce((sum, e) => sum + (e.teacherCoins || 0), 0);
    const pendingPayout = earnings
        .filter((e) => !e.isPaidOut)
        .reduce((sum, e) => sum + (e.teacherCoins || 0), 0);
    // Get lessons
    const lessonsQuery = await db
        .collection("lessons")
        .where("teacherId", "==", teacherId)
        .get();
    const lessons = lessonsQuery.docs.map((doc) => (Object.assign({ id: doc.id }, doc.data())));
    // Get ratings
    const ratingsQuery = await db
        .collection("lesson_ratings")
        .where("lessonId", "in", lessons.map((l) => l.id).slice(0, 10)) // Firestore limit
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
            average: ((_b = teacher.stats) === null || _b === void 0 ? void 0 : _b.averageRating) || 0,
            count: ((_c = teacher.stats) === null || _c === void 0 ? void 0 : _c.totalRatings) || 0,
            recent: ratings.slice(0, 10),
        },
    };
});
// ============= ADMIN LESSON API =============
/**
 * Admin: Get all lessons with filtering
 */
exports.getAdminLessons = functions.https.onCall(async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
    }
    // Verify admin
    const adminDoc = await db
        .collection("profiles")
        .doc(context.auth.uid)
        .get();
    if (!adminDoc.exists || !((_a = adminDoc.data()) === null || _a === void 0 ? void 0 : _a.isAdmin)) {
        throw new functions.https.HttpsError("permission-denied", "Admin access required");
    }
    const { languageCode, level, category, isPublished, limit: queryLimit } = data;
    let query = db.collection("lessons");
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
    const lessons = snapshot.docs.map((doc) => (Object.assign({ id: doc.id }, doc.data())));
    // Get stats
    const totalLessons = await db.collection("lessons").count().get();
    const publishedLessons = await db
        .collection("lessons")
        .where("isPublished", "==", true)
        .count()
        .get();
    // Group by language
    const lessonsByLanguage = {};
    lessons.forEach((lesson) => {
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
});
/**
 * Admin: Seed lessons for supported languages (es, en, pt, pt-BR, it)
 * Creates 52 weeks (1 year) of lessons for each language
 */
exports.seedLessons = functions.https.onCall(async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
    }
    // Verify admin
    const adminDoc = await db
        .collection("profiles")
        .doc(context.auth.uid)
        .get();
    if (!adminDoc.exists || !((_a = adminDoc.data()) === null || _a === void 0 ? void 0 : _a.isAdmin)) {
        throw new functions.https.HttpsError("permission-denied", "Admin access required");
    }
    const { languageCodes, clearExisting } = data;
    // Use specified languages or default to all supported
    const targetLanguages = (languageCodes === null || languageCodes === void 0 ? void 0 : languageCodes.length)
        ? languageCodes
        : Object.keys(languageInfo);
    const results = {};
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
            const deletePromises = existingLessons.docs.map((doc) => doc.ref.delete());
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
                if (week > 4)
                    level = "beginner";
                if (week > 10)
                    level = "elementary";
                if (week > 18)
                    level = "pre_intermediate";
                if (week > 26)
                    level = "intermediate";
                if (week > 36)
                    level = "upper_intermediate";
                if (week > 44)
                    level = "advanced";
                if (week > 50)
                    level = "fluent";
                // Determine price
                let coinPrice = 0;
                if (week > 1)
                    coinPrice = 10;
                if (week > 4)
                    coinPrice = 15;
                if (week > 10)
                    coinPrice = 20;
                if (week > 18)
                    coinPrice = 25;
                if (week > 26)
                    coinPrice = 30;
                if (week > 36)
                    coinPrice = 40;
                if (week > 44)
                    coinPrice = 50;
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
                }
                catch (e) {
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
});
/**
 * Admin: Delete lesson
 */
exports.deleteLesson = functions.https.onCall(async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
    }
    // Verify admin
    const adminDoc = await db
        .collection("profiles")
        .doc(context.auth.uid)
        .get();
    if (!adminDoc.exists || !((_a = adminDoc.data()) === null || _a === void 0 ? void 0 : _a.isAdmin)) {
        throw new functions.https.HttpsError("permission-denied", "Admin access required");
    }
    const { lessonId } = data;
    await db.collection("lessons").doc(lessonId).delete();
    return { success: true, deletedId: lessonId };
});
/**
 * Admin: Update lesson
 */
exports.updateLesson = functions.https.onCall(async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
    }
    // Verify admin
    const adminDoc = await db
        .collection("profiles")
        .doc(context.auth.uid)
        .get();
    if (!adminDoc.exists || !((_a = adminDoc.data()) === null || _a === void 0 ? void 0 : _a.isAdmin)) {
        throw new functions.https.HttpsError("permission-denied", "Admin access required");
    }
    const { lessonId, updates } = data;
    // Remove sensitive fields
    delete updates.id;
    delete updates.createdAt;
    updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    await db.collection("lessons").doc(lessonId).update(updates);
    return { success: true, updatedId: lessonId };
});
/**
 * Admin: Get lesson stats by language
 */
exports.getLessonStats = functions.https.onCall(async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
    }
    // Verify admin
    const adminDoc = await db
        .collection("profiles")
        .doc(context.auth.uid)
        .get();
    if (!adminDoc.exists || !((_a = adminDoc.data()) === null || _a === void 0 ? void 0 : _a.isAdmin)) {
        throw new functions.https.HttpsError("permission-denied", "Admin access required");
    }
    const stats = {};
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
        stats[langCode] = Object.assign(Object.assign({}, langInfo), { totalLessons: totalQuery.data().count, publishedLessons: publishedQuery.data().count, freeLessons: freeQuery.data().count, paidLessons: totalQuery.data().count - freeQuery.data().count });
    }
    return {
        supportedLanguages: Object.keys(languageInfo),
        languageStats: stats,
        totalLessonsAllLanguages: Object.values(stats).reduce((sum, s) => sum + s.totalLessons, 0),
    };
});
//# sourceMappingURL=languageLearningManager.js.map