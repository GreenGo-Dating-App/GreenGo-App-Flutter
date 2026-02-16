"use strict";
/**
 * MVP Access Control Functions
 * Functions for managing user approval and access during MVP release
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
exports.getMvpAccessStats = exports.sendNotificationToUser = exports.sendBroadcastNotification = exports.bulkApproveUsers = exports.getPendingUsers = exports.updateUserTier = exports.rejectUser = exports.approveUser = exports.LOCALIZED_MESSAGES = void 0;
const https_1 = require("firebase-functions/v2/https");
const utils_1 = require("../shared/utils");
const admin = __importStar(require("firebase-admin"));
const types_1 = require("../shared/types");
// MVP Release Dates
const PREMIUM_ACCESS_DATE = new Date('2026-03-01T00:00:00Z'); // March 1st, 2026
const BASIC_ACCESS_DATE = new Date('2026-03-15T00:00:00Z'); // March 15th, 2026
// Supported languages for notifications
const SUPPORTED_LANGUAGES = ['en', 'es', 'fr', 'de', 'it', 'pt', 'pt_BR'];
// Localized broadcast messages - Complete set for all notification types
const BROADCAST_MESSAGES = {
    // Welcome message for new registrations
    welcome: {
        en: { title: 'Welcome to GreenGoChat!', body: 'Thank you for registering. We\'re excited to have you join our community!' },
        es: { title: '¡Bienvenido a GreenGoChat!', body: '¡Gracias por registrarte. Estamos emocionados de tenerte en nuestra comunidad!' },
        fr: { title: 'Bienvenue sur GreenGoChat!', body: 'Merci de vous être inscrit. Nous sommes ravis de vous accueillir!' },
        de: { title: 'Willkommen bei GreenGoChat!', body: 'Danke für Ihre Registrierung. Wir freuen uns, Sie in unserer Community zu haben!' },
        it: { title: 'Benvenuto su GreenGoChat!', body: 'Grazie per la registrazione. Siamo entusiasti di averti nella nostra community!' },
        pt: { title: 'Bem-vindo ao GreenGoChat!', body: 'Obrigado por se registar. Estamos entusiasmados por tê-lo na nossa comunidade!' },
        pt_BR: { title: 'Bem-vindo ao GreenGoChat!', body: 'Obrigado por se cadastrar. Estamos animados por ter você em nossa comunidade!' },
    },
    // Account approval notification
    account_approved: {
        en: { title: 'Your Account is Approved!', body: 'Great news! Your GreenGoChat account has been approved. Get ready for launch day!' },
        es: { title: '¡Tu Cuenta Está Aprobada!', body: '¡Buenas noticias! Tu cuenta de GreenGoChat ha sido aprobada. ¡Prepárate para el día del lanzamiento!' },
        fr: { title: 'Votre Compte est Approuvé!', body: 'Bonne nouvelle! Votre compte GreenGoChat a été approuvé. Préparez-vous pour le lancement!' },
        de: { title: 'Ihr Konto ist Genehmigt!', body: 'Gute Nachrichten! Ihr GreenGoChat-Konto wurde genehmigt. Machen Sie sich bereit für den Start!' },
        it: { title: 'Il Tuo Account è Approvato!', body: 'Ottime notizie! Il tuo account GreenGoChat è stato approvato. Preparati per il lancio!' },
        pt: { title: 'A Sua Conta Foi Aprovada!', body: 'Ótimas notícias! A sua conta GreenGoChat foi aprovada. Prepare-se para o lançamento!' },
        pt_BR: { title: 'Sua Conta Foi Aprovada!', body: 'Ótimas notícias! Sua conta GreenGoChat foi aprovada. Prepare-se para o lançamento!' },
    },
    // Backward compatibility alias
    accountApproved: {
        en: { title: 'Your Account is Approved!', body: 'Great news! Your GreenGoChat account has been approved. Get ready for launch day!' },
        es: { title: '¡Tu Cuenta Está Aprobada!', body: '¡Buenas noticias! Tu cuenta de GreenGoChat ha sido aprobada. ¡Prepárate para el día del lanzamiento!' },
        fr: { title: 'Votre Compte est Approuvé!', body: 'Bonne nouvelle! Votre compte GreenGoChat a été approuvé. Préparez-vous pour le lancement!' },
        de: { title: 'Ihr Konto ist Genehmigt!', body: 'Gute Nachrichten! Ihr GreenGoChat-Konto wurde genehmigt. Machen Sie sich bereit für den Start!' },
        it: { title: 'Il Tuo Account è Approvato!', body: 'Ottime notizie! Il tuo account GreenGoChat è stato approvato. Preparati per il lancio!' },
        pt: { title: 'A Sua Conta Foi Aprovada!', body: 'Ótimas notícias! A sua conta GreenGoChat foi aprovada. Prepare-se para o lançamento!' },
        pt_BR: { title: 'Sua Conta Foi Aprovada!', body: 'Ótimas notícias! Sua conta GreenGoChat foi aprovada. Prepare-se para o lançamento!' },
    },
    // Account rejection notification
    account_rejected: {
        en: { title: 'Account Review Update', body: 'We were unable to approve your account at this time. Please contact support for more information.' },
        es: { title: 'Actualización de Revisión de Cuenta', body: 'No pudimos aprobar tu cuenta en este momento. Por favor contacta a soporte para más información.' },
        fr: { title: 'Mise à Jour de Révision du Compte', body: 'Nous n\'avons pas pu approuver votre compte pour le moment. Veuillez contacter le support.' },
        de: { title: 'Kontoüberprüfungs-Update', body: 'Wir konnten Ihr Konto derzeit nicht genehmigen. Bitte kontaktieren Sie den Support.' },
        it: { title: 'Aggiornamento Revisione Account', body: 'Non siamo riusciti ad approvare il tuo account al momento. Contatta il supporto per maggiori informazioni.' },
        pt: { title: 'Atualização da Revisão da Conta', body: 'Não foi possível aprovar a sua conta neste momento. Por favor, contacte o suporte.' },
        pt_BR: { title: 'Atualização da Revisão da Conta', body: 'Não foi possível aprovar sua conta neste momento. Por favor, entre em contato com o suporte.' },
    },
    // Launch reminder (1 week before)
    launch_reminder: {
        en: { title: 'Launch Day is Coming!', body: 'GreenGoChat launches soon! Make sure your notifications are enabled to be the first to know.' },
        es: { title: '¡El Día del Lanzamiento se Acerca!', body: '¡GreenGoChat se lanza pronto! Asegúrate de tener las notificaciones activadas.' },
        fr: { title: 'Le Jour du Lancement Approche!', body: 'GreenGoChat sera bientôt lancé! Assurez-vous d\'avoir les notifications activées.' },
        de: { title: 'Der Launch-Tag Kommt!', body: 'GreenGoChat startet bald! Stellen Sie sicher, dass Ihre Benachrichtigungen aktiviert sind.' },
        it: { title: 'Il Giorno del Lancio si Avvicina!', body: 'GreenGoChat sarà lanciato presto! Assicurati di avere le notifiche attivate.' },
        pt: { title: 'O Dia do Lançamento Aproxima-se!', body: 'O GreenGoChat será lançado em breve! Certifique-se de ter as notificações ativadas.' },
        pt_BR: { title: 'O Dia do Lançamento se Aproxima!', body: 'O GreenGoChat será lançado em breve! Certifique-se de ter as notificações ativadas.' },
    },
    // Backward compatibility alias
    launchReminder: {
        en: { title: 'Launch Day is Coming!', body: 'GreenGoChat launches soon! Make sure your notifications are enabled to be the first to know.' },
        es: { title: '¡El Día del Lanzamiento se Acerca!', body: '¡GreenGoChat se lanza pronto! Asegúrate de tener las notificaciones activadas.' },
        fr: { title: 'Le Jour du Lancement Approche!', body: 'GreenGoChat sera bientôt lancé! Assurez-vous d\'avoir les notifications activées.' },
        de: { title: 'Der Launch-Tag Kommt!', body: 'GreenGoChat startet bald! Stellen Sie sicher, dass Ihre Benachrichtigungen aktiviert sind.' },
        it: { title: 'Il Giorno del Lancio si Avvicina!', body: 'GreenGoChat sarà lanciato presto! Assicurati di avere le notifiche attivate.' },
        pt: { title: 'O Dia do Lançamento Aproxima-se!', body: 'O GreenGoChat será lançado em breve! Certifique-se de ter as notificações ativadas.' },
        pt_BR: { title: 'O Dia do Lançamento se Aproxima!', body: 'O GreenGoChat será lançado em breve! Certifique-se de ter as notificações ativadas.' },
    },
    // Launch day notification
    launch_day: {
        en: { title: 'GreenGoChat is LIVE!', body: 'The wait is over! GreenGoChat is now available. Start connecting today!' },
        es: { title: '¡GreenGoChat está ACTIVO!', body: '¡La espera terminó! GreenGoChat ya está disponible. ¡Comienza a conectar hoy!' },
        fr: { title: 'GreenGoChat est EN LIGNE!', body: 'L\'attente est terminée! GreenGoChat est maintenant disponible. Commencez à vous connecter!' },
        de: { title: 'GreenGoChat ist LIVE!', body: 'Das Warten hat ein Ende! GreenGoChat ist jetzt verfügbar. Starten Sie noch heute!' },
        it: { title: 'GreenGoChat è ATTIVO!', body: 'L\'attesa è finita! GreenGoChat è ora disponibile. Inizia a connetterti oggi!' },
        pt: { title: 'GreenGoChat está ATIVO!', body: 'A espera acabou! O GreenGoChat já está disponível. Comece a conectar-se hoje!' },
        pt_BR: { title: 'GreenGoChat está ATIVO!', body: 'A espera acabou! O GreenGoChat já está disponível. Comece a se conectar hoje!' },
    },
    // Backward compatibility alias
    launchDay: {
        en: { title: 'GreenGoChat is LIVE!', body: 'The wait is over! GreenGoChat is now available. Start connecting today!' },
        es: { title: '¡GreenGoChat está ACTIVO!', body: '¡La espera terminó! GreenGoChat ya está disponible. ¡Comienza a conectar hoy!' },
        fr: { title: 'GreenGoChat est EN LIGNE!', body: 'L\'attente est terminée! GreenGoChat est maintenant disponible. Commencez à vous connecter!' },
        de: { title: 'GreenGoChat ist LIVE!', body: 'Das Warten hat ein Ende! GreenGoChat ist jetzt verfügbar. Starten Sie noch heute!' },
        it: { title: 'GreenGoChat è ATTIVO!', body: 'L\'attesa è finita! GreenGoChat è ora disponibile. Inizia a connetterti oggi!' },
        pt: { title: 'GreenGoChat está ATIVO!', body: 'A espera acabou! O GreenGoChat já está disponível. Comece a conectar-se hoje!' },
        pt_BR: { title: 'GreenGoChat está ATIVO!', body: 'A espera acabou! O GreenGoChat já está disponível. Comece a se conectar hoje!' },
    },
    // Countdown complete / Access granted notification
    countdown_complete: {
        en: { title: 'Your Access is Now Active!', body: 'The countdown is over! You now have full access to GreenGoChat. Start exploring!' },
        es: { title: '¡Tu Acceso Ya Está Activo!', body: '¡La cuenta regresiva terminó! Ahora tienes acceso completo a GreenGoChat. ¡Comienza a explorar!' },
        fr: { title: 'Votre Accès est Maintenant Actif!', body: 'Le compte à rebours est terminé! Vous avez maintenant un accès complet à GreenGoChat. Commencez à explorer!' },
        de: { title: 'Ihr Zugang ist Jetzt Aktiv!', body: 'Der Countdown ist vorbei! Sie haben jetzt vollen Zugang zu GreenGoChat. Beginnen Sie zu erkunden!' },
        it: { title: 'Il Tuo Accesso è Ora Attivo!', body: 'Il conto alla rovescia è finito! Ora hai accesso completo a GreenGoChat. Inizia a esplorare!' },
        pt: { title: 'O Seu Acesso Está Agora Ativo!', body: 'A contagem regressiva terminou! Agora tem acesso completo ao GreenGoChat. Comece a explorar!' },
        pt_BR: { title: 'Seu Acesso Está Agora Ativo!', body: 'A contagem regressiva acabou! Agora você tem acesso completo ao GreenGoChat. Comece a explorar!' },
    },
    // VIP early access notification
    vip_early_access: {
        en: { title: 'VIP Early Access Activated!', body: 'As a VIP member, you now have exclusive early access to GreenGoChat. Enjoy being first!' },
        es: { title: '¡Acceso Anticipado VIP Activado!', body: 'Como miembro VIP, ahora tienes acceso anticipado exclusivo a GreenGoChat. ¡Disfruta de ser el primero!' },
        fr: { title: 'Accès Anticipé VIP Activé!', body: 'En tant que membre VIP, vous avez maintenant un accès anticipé exclusif à GreenGoChat. Profitez d\'être le premier!' },
        de: { title: 'VIP-Frühzugang Aktiviert!', body: 'Als VIP-Mitglied haben Sie jetzt exklusiven Frühzugang zu GreenGoChat. Genießen Sie es, der Erste zu sein!' },
        it: { title: 'Accesso Anticipato VIP Attivato!', body: 'Come membro VIP, ora hai accesso anticipato esclusivo a GreenGoChat. Goditi l\'essere il primo!' },
        pt: { title: 'Acesso Antecipado VIP Ativado!', body: 'Como membro VIP, agora tem acesso antecipado exclusivo ao GreenGoChat. Aproveite ser o primeiro!' },
        pt_BR: { title: 'Acesso Antecipado VIP Ativado!', body: 'Como membro VIP, agora você tem acesso antecipado exclusivo ao GreenGoChat. Aproveite ser o primeiro!' },
    },
    // 24 hours before launch reminder
    launch_24h_reminder: {
        en: { title: 'Only 24 Hours Left!', body: 'GreenGoChat launches tomorrow! Get ready for an amazing experience.' },
        es: { title: '¡Solo Quedan 24 Horas!', body: '¡GreenGoChat se lanza mañana! Prepárate para una experiencia increíble.' },
        fr: { title: 'Plus que 24 Heures!', body: 'GreenGoChat se lance demain! Préparez-vous pour une expérience incroyable.' },
        de: { title: 'Nur noch 24 Stunden!', body: 'GreenGoChat startet morgen! Machen Sie sich bereit für ein fantastisches Erlebnis.' },
        it: { title: 'Solo 24 Ore Rimaste!', body: 'GreenGoChat si lancia domani! Preparati per un\'esperienza fantastica.' },
        pt: { title: 'Apenas 24 Horas Restantes!', body: 'O GreenGoChat lança amanhã! Prepare-se para uma experiência incrível.' },
        pt_BR: { title: 'Apenas 24 Horas Restantes!', body: 'O GreenGoChat lança amanhã! Prepare-se para uma experiência incrível.' },
    },
    // 1 hour before launch reminder
    launch_1h_reminder: {
        en: { title: 'Launch in 1 Hour!', body: 'GreenGoChat goes live in just 1 hour! Get ready to start connecting.' },
        es: { title: '¡Lanzamiento en 1 Hora!', body: '¡GreenGoChat estará activo en solo 1 hora! Prepárate para comenzar a conectar.' },
        fr: { title: 'Lancement dans 1 Heure!', body: 'GreenGoChat sera en ligne dans 1 heure! Préparez-vous à vous connecter.' },
        de: { title: 'Start in 1 Stunde!', body: 'GreenGoChat geht in nur 1 Stunde live! Machen Sie sich bereit.' },
        it: { title: 'Lancio tra 1 Ora!', body: 'GreenGoChat sarà attivo tra solo 1 ora! Preparati a connetterti.' },
        pt: { title: 'Lançamento em 1 Hora!', body: 'O GreenGoChat estará ativo em apenas 1 hora! Prepare-se para se conectar.' },
        pt_BR: { title: 'Lançamento em 1 Hora!', body: 'O GreenGoChat estará ativo em apenas 1 hora! Prepare-se para se conectar.' },
    },
    // Tier upgrade notification
    tier_upgrade: {
        en: { title: 'Membership Upgraded!', body: 'Congratulations! Your membership has been upgraded. Enjoy your new benefits!' },
        es: { title: '¡Membresía Mejorada!', body: '¡Felicidades! Tu membresía ha sido mejorada. ¡Disfruta de tus nuevos beneficios!' },
        fr: { title: 'Adhésion Améliorée!', body: 'Félicitations! Votre adhésion a été améliorée. Profitez de vos nouveaux avantages!' },
        de: { title: 'Mitgliedschaft Aufgewertet!', body: 'Herzlichen Glückwunsch! Ihre Mitgliedschaft wurde aufgewertet. Genießen Sie Ihre neuen Vorteile!' },
        it: { title: 'Abbonamento Aggiornato!', body: 'Congratulazioni! Il tuo abbonamento è stato aggiornato. Goditi i tuoi nuovi vantaggi!' },
        pt: { title: 'Subscrição Melhorada!', body: 'Parabéns! A sua subscrição foi melhorada. Aproveite os seus novos benefícios!' },
        pt_BR: { title: 'Assinatura Melhorada!', body: 'Parabéns! Sua assinatura foi melhorada. Aproveite seus novos benefícios!' },
    },
    // New match notification
    new_match: {
        en: { title: 'New Match!', body: 'You have a new match! Open the app to start chatting.' },
        es: { title: '¡Nuevo Match!', body: '¡Tienes un nuevo match! Abre la app para empezar a chatear.' },
        fr: { title: 'Nouveau Match!', body: 'Vous avez un nouveau match! Ouvrez l\'app pour commencer à discuter.' },
        de: { title: 'Neues Match!', body: 'Sie haben ein neues Match! Öffnen Sie die App, um zu chatten.' },
        it: { title: 'Nuovo Match!', body: 'Hai un nuovo match! Apri l\'app per iniziare a chattare.' },
        pt: { title: 'Novo Match!', body: 'Tens um novo match! Abre a app para começar a conversar.' },
        pt_BR: { title: 'Novo Match!', body: 'Você tem um novo match! Abra o app para começar a conversar.' },
    },
    // New message notification
    new_message: {
        en: { title: 'New Message', body: 'You have a new message waiting for you!' },
        es: { title: 'Nuevo Mensaje', body: '¡Tienes un nuevo mensaje esperándote!' },
        fr: { title: 'Nouveau Message', body: 'Vous avez un nouveau message qui vous attend!' },
        de: { title: 'Neue Nachricht', body: 'Sie haben eine neue Nachricht!' },
        it: { title: 'Nuovo Messaggio', body: 'Hai un nuovo messaggio che ti aspetta!' },
        pt: { title: 'Nova Mensagem', body: 'Tens uma nova mensagem à tua espera!' },
        pt_BR: { title: 'Nova Mensagem', body: 'Você tem uma nova mensagem esperando!' },
    },
    // Profile view notification
    profile_view: {
        en: { title: 'Someone Viewed Your Profile', body: 'Your profile is getting attention! Check out who viewed you.' },
        es: { title: 'Alguien Vio Tu Perfil', body: '¡Tu perfil está recibiendo atención! Mira quién te vio.' },
        fr: { title: 'Quelqu\'un a Vu Votre Profil', body: 'Votre profil attire l\'attention! Découvrez qui vous a vu.' },
        de: { title: 'Jemand Hat Ihr Profil Angesehen', body: 'Ihr Profil bekommt Aufmerksamkeit! Sehen Sie, wer Sie angesehen hat.' },
        it: { title: 'Qualcuno Ha Visto il Tuo Profilo', body: 'Il tuo profilo sta ricevendo attenzione! Scopri chi ti ha visto.' },
        pt: { title: 'Alguém Viu o Teu Perfil', body: 'O teu perfil está a receber atenção! Vê quem te viu.' },
        pt_BR: { title: 'Alguém Viu Seu Perfil', body: 'Seu perfil está recebendo atenção! Veja quem visualizou você.' },
    },
    // Super like notification
    super_like: {
        en: { title: 'You Got a Super Like!', body: 'Someone really likes you! Open the app to see who.' },
        es: { title: '¡Recibiste un Super Like!', body: '¡Alguien realmente te gusta! Abre la app para ver quién.' },
        fr: { title: 'Vous Avez Reçu un Super Like!', body: 'Quelqu\'un vous aime vraiment! Ouvrez l\'app pour voir qui.' },
        de: { title: 'Du Hast ein Super Like!', body: 'Jemand mag dich wirklich! Öffne die App um zu sehen wer.' },
        it: { title: 'Hai Ricevuto un Super Like!', body: 'Qualcuno ti piace davvero! Apri l\'app per vedere chi.' },
        pt: { title: 'Recebeste um Super Like!', body: 'Alguém gosta muito de ti! Abre a app para ver quem.' },
        pt_BR: { title: 'Você Recebeu um Super Like!', body: 'Alguém realmente gosta de você! Abra o app para ver quem.' },
    },
    // Maintenance notification
    maintenance: {
        en: { title: 'Scheduled Maintenance', body: 'GreenGoChat will be undergoing maintenance. We\'ll be back soon!' },
        es: { title: 'Mantenimiento Programado', body: 'GreenGoChat estará en mantenimiento. ¡Volveremos pronto!' },
        fr: { title: 'Maintenance Programmée', body: 'GreenGoChat sera en maintenance. Nous revenons bientôt!' },
        de: { title: 'Geplante Wartung', body: 'GreenGoChat wird gewartet. Wir sind bald zurück!' },
        it: { title: 'Manutenzione Programmata', body: 'GreenGoChat sarà in manutenzione. Torneremo presto!' },
        pt: { title: 'Manutenção Programada', body: 'O GreenGoChat estará em manutenção. Voltamos em breve!' },
        pt_BR: { title: 'Manutenção Programada', body: 'O GreenGoChat estará em manutenção. Voltamos em breve!' },
    },
    // Feature update notification
    feature_update: {
        en: { title: 'New Features Available!', body: 'We\'ve added exciting new features. Update your app to explore!' },
        es: { title: '¡Nuevas Funciones Disponibles!', body: 'Hemos añadido nuevas funciones emocionantes. ¡Actualiza tu app para explorar!' },
        fr: { title: 'Nouvelles Fonctionnalités Disponibles!', body: 'Nous avons ajouté de nouvelles fonctionnalités passionnantes. Mettez à jour pour explorer!' },
        de: { title: 'Neue Funktionen Verfügbar!', body: 'Wir haben aufregende neue Funktionen hinzugefügt. Aktualisieren Sie, um zu erkunden!' },
        it: { title: 'Nuove Funzionalità Disponibili!', body: 'Abbiamo aggiunto nuove funzionalità entusiasmanti. Aggiorna l\'app per esplorare!' },
        pt: { title: 'Novas Funcionalidades Disponíveis!', body: 'Adicionámos novas funcionalidades emocionantes. Atualiza a app para explorar!' },
        pt_BR: { title: 'Novas Funcionalidades Disponíveis!', body: 'Adicionamos novas funcionalidades empolgantes. Atualize o app para explorar!' },
    },
    // Special offer notification
    special_offer: {
        en: { title: 'Special Offer for You!', body: 'Don\'t miss out on this exclusive deal! Limited time only.' },
        es: { title: '¡Oferta Especial Para Ti!', body: '¡No te pierdas esta oferta exclusiva! Por tiempo limitado.' },
        fr: { title: 'Offre Spéciale Pour Vous!', body: 'Ne manquez pas cette offre exclusive! Pour une durée limitée.' },
        de: { title: 'Sonderangebot Für Dich!', body: 'Verpassen Sie dieses exklusive Angebot nicht! Nur für begrenzte Zeit.' },
        it: { title: 'Offerta Speciale Per Te!', body: 'Non perderti questa offerta esclusiva! Solo per un tempo limitato.' },
        pt: { title: 'Oferta Especial Para Ti!', body: 'Não percas esta oferta exclusiva! Por tempo limitado.' },
        pt_BR: { title: 'Oferta Especial Para Você!', body: 'Não perca esta oferta exclusiva! Por tempo limitado.' },
    },
};
// Export messages for admin panel preview
exports.LOCALIZED_MESSAGES = BROADCAST_MESSAGES;
// Helper function to get access date based on tier
function getAccessDateForTier(tier) {
    if (tier === types_1.SubscriptionTier.SILVER || tier === types_1.SubscriptionTier.GOLD || tier === types_1.SubscriptionTier.PLATINUM) {
        return PREMIUM_ACCESS_DATE;
    }
    return BASIC_ACCESS_DATE;
}
// ========== USER APPROVAL FUNCTIONS ==========
// 1. Approve User
exports.approveUser = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a, _b;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { userId, notify = true } = request.data;
        (0, utils_1.logInfo)(`Approving user ${userId}`);
        const userRef = utils_1.db.collection('users').doc(userId);
        const userDoc = await userRef.get();
        if (!userDoc.exists) {
            throw new Error('User not found');
        }
        const userData = userDoc.data();
        const tier = userData.membershipTier || types_1.SubscriptionTier.BASIC;
        const accessDate = getAccessDateForTier(tier);
        await userRef.update({
            approvalStatus: types_1.ApprovalStatus.APPROVED,
            approvedAt: utils_1.FieldValue.serverTimestamp(),
            approvedBy: (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid,
            accessDate: admin.firestore.Timestamp.fromDate(accessDate),
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        // Send notification if requested
        if (notify) {
            const userLang = userData.preferredLanguage || 'en';
            const messages = BROADCAST_MESSAGES.accountApproved;
            const message = messages[userLang] || messages.en;
            await utils_1.db.collection('notifications').add({
                userId,
                type: 'account_approved',
                title: message.title,
                body: message.body,
                read: false,
                sent: false,
                createdAt: utils_1.FieldValue.serverTimestamp(),
            });
            // Send push notification if user has FCM token
            if (userData.fcmToken) {
                await admin.messaging().send({
                    token: userData.fcmToken,
                    notification: {
                        title: message.title,
                        body: message.body,
                    },
                    data: {
                        type: 'account_approved',
                        accessDate: accessDate.toISOString(),
                    },
                });
            }
        }
        // Log audit
        await utils_1.db.collection('audit_logs').add({
            type: 'user_approved',
            userId,
            performedBy: (_b = request.auth) === null || _b === void 0 ? void 0 : _b.uid,
            timestamp: utils_1.FieldValue.serverTimestamp(),
        });
        return { success: true, accessDate: accessDate.toISOString() };
    }
    catch (error) {
        (0, utils_1.logError)('Error approving user:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 2. Reject User
exports.rejectUser = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a, _b;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { userId, reason, notify = true } = request.data;
        (0, utils_1.logInfo)(`Rejecting user ${userId}`);
        const userRef = utils_1.db.collection('users').doc(userId);
        const userDoc = await userRef.get();
        if (!userDoc.exists) {
            throw new Error('User not found');
        }
        await userRef.update({
            approvalStatus: types_1.ApprovalStatus.REJECTED,
            rejectedAt: utils_1.FieldValue.serverTimestamp(),
            rejectedBy: (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid,
            rejectionReason: reason,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        // Send notification if requested
        if (notify) {
            const userData = userDoc.data();
            await utils_1.db.collection('notifications').add({
                userId,
                type: 'account_rejected',
                title: 'Account Not Approved',
                body: `Your account could not be approved. Reason: ${reason}`,
                read: false,
                sent: false,
                createdAt: utils_1.FieldValue.serverTimestamp(),
            });
            if (userData.fcmToken) {
                await admin.messaging().send({
                    token: userData.fcmToken,
                    notification: {
                        title: 'Account Not Approved',
                        body: `Your account could not be approved. Please contact support.`,
                    },
                    data: {
                        type: 'account_rejected',
                    },
                });
            }
        }
        // Log audit
        await utils_1.db.collection('audit_logs').add({
            type: 'user_rejected',
            userId,
            reason,
            performedBy: (_b = request.auth) === null || _b === void 0 ? void 0 : _b.uid,
            timestamp: utils_1.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error rejecting user:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 3. Update User Tier
exports.updateUserTier = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a, _b;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { userId, tier } = request.data;
        (0, utils_1.logInfo)(`Updating user ${userId} to tier ${tier}`);
        const accessDate = getAccessDateForTier(tier);
        await utils_1.db.collection('users').doc(userId).update({
            membershipTier: tier,
            accessDate: admin.firestore.Timestamp.fromDate(accessDate),
            tierUpdatedAt: utils_1.FieldValue.serverTimestamp(),
            tierUpdatedBy: (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        // Log audit
        await utils_1.db.collection('audit_logs').add({
            type: 'tier_updated',
            userId,
            newTier: tier,
            performedBy: (_b = request.auth) === null || _b === void 0 ? void 0 : _b.uid,
            timestamp: utils_1.FieldValue.serverTimestamp(),
        });
        return { success: true, accessDate: accessDate.toISOString() };
    }
    catch (error) {
        (0, utils_1.logError)('Error updating user tier:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 4. Get Pending Users
exports.getPendingUsers = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { limit = 50, startAfter } = request.data;
        (0, utils_1.logInfo)('Fetching pending users');
        let query = utils_1.db
            .collection('users')
            .where('approvalStatus', '==', types_1.ApprovalStatus.PENDING)
            .orderBy('createdAt', 'desc')
            .limit(limit);
        if (startAfter) {
            const startDoc = await utils_1.db.collection('users').doc(startAfter).get();
            if (startDoc.exists) {
                query = query.startAfter(startDoc);
            }
        }
        const snapshot = await query.get();
        const pendingUsers = snapshot.docs.map(doc => {
            var _a;
            return ({
                userId: doc.id,
                email: doc.data().email,
                displayName: doc.data().displayName,
                membershipTier: doc.data().membershipTier || types_1.SubscriptionTier.BASIC,
                createdAt: (_a = doc.data().createdAt) === null || _a === void 0 ? void 0 : _a.toDate().toISOString(),
                photoURL: doc.data().photoURL,
            });
        });
        return {
            success: true,
            users: pendingUsers,
            hasMore: snapshot.size === limit,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching pending users:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 5. Bulk Approve Users
exports.bulkApproveUsers = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 300,
}, async (request) => {
    var _a, _b;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { userIds, notify = true } = request.data;
        (0, utils_1.logInfo)(`Bulk approving ${userIds.length} users`);
        const batch = utils_1.db.batch();
        const approvedUsers = [];
        const errors = [];
        for (const userId of userIds) {
            try {
                const userRef = utils_1.db.collection('users').doc(userId);
                const userDoc = await userRef.get();
                if (!userDoc.exists) {
                    errors.push({ userId, error: 'User not found' });
                    continue;
                }
                const userData = userDoc.data();
                const tier = userData.membershipTier || types_1.SubscriptionTier.BASIC;
                const accessDate = getAccessDateForTier(tier);
                batch.update(userRef, {
                    approvalStatus: types_1.ApprovalStatus.APPROVED,
                    approvedAt: utils_1.FieldValue.serverTimestamp(),
                    approvedBy: (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid,
                    accessDate: admin.firestore.Timestamp.fromDate(accessDate),
                    updatedAt: utils_1.FieldValue.serverTimestamp(),
                });
                approvedUsers.push(userId);
                // Queue notification
                if (notify && userData.fcmToken) {
                    const userLang = userData.preferredLanguage || 'en';
                    const messages = BROADCAST_MESSAGES.accountApproved;
                    const message = messages[userLang] || messages.en;
                    // We'll send notifications after batch commit
                }
            }
            catch (err) {
                errors.push({ userId, error: err.message });
            }
        }
        await batch.commit();
        // Log audit
        await utils_1.db.collection('audit_logs').add({
            type: 'bulk_user_approval',
            userIds: approvedUsers,
            performedBy: (_b = request.auth) === null || _b === void 0 ? void 0 : _b.uid,
            timestamp: utils_1.FieldValue.serverTimestamp(),
        });
        return {
            success: true,
            approved: approvedUsers.length,
            errors,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error bulk approving users:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== BROADCAST NOTIFICATION FUNCTIONS ==========
// 6. Send Broadcast Notification to All Users
exports.sendBroadcastNotification = (0, https_1.onCall)({
    memory: '1GiB',
    timeoutSeconds: 540,
}, async (request) => {
    var _a;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { messageType = 'custom', customTitle, customBody, targetAudience = 'all', targetTiers, } = request.data;
        (0, utils_1.logInfo)(`Sending broadcast notification: ${messageType} to ${targetAudience}`);
        // Build query based on target audience
        let query = utils_1.db.collection('users');
        switch (targetAudience) {
            case 'approved':
                query = query.where('approvalStatus', '==', types_1.ApprovalStatus.APPROVED);
                break;
            case 'premium':
                query = query.where('membershipTier', 'in', [
                    types_1.SubscriptionTier.SILVER,
                    types_1.SubscriptionTier.GOLD,
                    types_1.SubscriptionTier.PLATINUM,
                ]);
                break;
            case 'basic':
                query = query.where('membershipTier', '==', types_1.SubscriptionTier.BASIC);
                break;
            case 'pending':
                query = query.where('approvalStatus', '==', types_1.ApprovalStatus.PENDING);
                break;
            // 'all' - no additional filter
        }
        if (targetTiers && targetTiers.length > 0) {
            query = query.where('membershipTier', 'in', targetTiers);
        }
        // Only target users with notifications enabled and FCM token
        query = query.where('notificationsEnabled', '==', true);
        const snapshot = await query.get();
        (0, utils_1.logInfo)(`Found ${snapshot.size} users to notify`);
        let successCount = 0;
        let failCount = 0;
        const messages = [];
        for (const doc of snapshot.docs) {
            const userData = doc.data();
            const fcmToken = userData.fcmToken;
            if (!fcmToken) {
                failCount++;
                continue;
            }
            const userLang = userData.preferredLanguage || 'en';
            let title;
            let body;
            if (messageType === 'custom') {
                title = (customTitle === null || customTitle === void 0 ? void 0 : customTitle[userLang]) || (customTitle === null || customTitle === void 0 ? void 0 : customTitle.en) || 'GreenGoChat Notification';
                body = (customBody === null || customBody === void 0 ? void 0 : customBody[userLang]) || (customBody === null || customBody === void 0 ? void 0 : customBody.en) || 'You have a new notification';
            }
            else {
                const predefinedMessages = BROADCAST_MESSAGES[messageType];
                const message = (predefinedMessages === null || predefinedMessages === void 0 ? void 0 : predefinedMessages[userLang]) || (predefinedMessages === null || predefinedMessages === void 0 ? void 0 : predefinedMessages.en);
                title = (message === null || message === void 0 ? void 0 : message.title) || 'GreenGoChat';
                body = (message === null || message === void 0 ? void 0 : message.body) || 'You have a new notification';
            }
            messages.push({
                token: fcmToken,
                notification: {
                    title,
                    body,
                },
                data: {
                    type: 'broadcast',
                    messageType,
                    timestamp: new Date().toISOString(),
                },
                android: {
                    priority: 'high',
                    notification: {
                        channelId: 'greengo_broadcasts',
                        sound: 'default',
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: 'default',
                            badge: 1,
                        },
                    },
                },
            });
            // Also create in-app notification
            await utils_1.db.collection('notifications').add({
                userId: doc.id,
                type: 'broadcast',
                title,
                body,
                read: false,
                sent: true,
                sentAt: utils_1.FieldValue.serverTimestamp(),
                createdAt: utils_1.FieldValue.serverTimestamp(),
            });
        }
        // Send in batches of 500 (FCM limit)
        const batchSize = 500;
        for (let i = 0; i < messages.length; i += batchSize) {
            const batch = messages.slice(i, i + batchSize);
            try {
                const response = await admin.messaging().sendEach(batch);
                successCount += response.successCount;
                failCount += response.failureCount;
            }
            catch (err) {
                (0, utils_1.logError)('Error sending batch:', err);
                failCount += batch.length;
            }
        }
        // Log audit
        await utils_1.db.collection('audit_logs').add({
            type: 'broadcast_notification',
            messageType,
            targetAudience,
            totalTargeted: snapshot.size,
            successCount,
            failCount,
            performedBy: (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid,
            timestamp: utils_1.FieldValue.serverTimestamp(),
        });
        return {
            success: true,
            totalTargeted: snapshot.size,
            successCount,
            failCount,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error sending broadcast notification:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 7. Send Notification to Single User
exports.sendNotificationToUser = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { userId, title, body, data } = request.data;
        (0, utils_1.logInfo)(`Sending notification to user ${userId}`);
        const userDoc = await utils_1.db.collection('users').doc(userId).get();
        if (!userDoc.exists) {
            throw new Error('User not found');
        }
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        // Create in-app notification
        await utils_1.db.collection('notifications').add({
            userId,
            type: 'admin_message',
            title,
            body,
            data,
            read: false,
            sent: !!fcmToken,
            sentAt: fcmToken ? utils_1.FieldValue.serverTimestamp() : null,
            createdAt: utils_1.FieldValue.serverTimestamp(),
        });
        // Send push notification if token exists
        if (fcmToken) {
            await admin.messaging().send({
                token: fcmToken,
                notification: {
                    title,
                    body,
                },
                data: Object.assign(Object.assign({}, data), { type: 'admin_message' }),
            });
        }
        return { success: true, pushSent: !!fcmToken };
    }
    catch (error) {
        (0, utils_1.logError)('Error sending notification to user:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 8. Get MVP Access Stats
exports.getMvpAccessStats = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        (0, utils_1.logInfo)('Fetching MVP access stats');
        const [totalUsersSnapshot, pendingSnapshot, approvedSnapshot, rejectedSnapshot, platinumSnapshot, goldSnapshot, silverSnapshot, basicSnapshot, notificationsEnabledSnapshot,] = await Promise.all([
            utils_1.db.collection('users').count().get(),
            utils_1.db.collection('users').where('approvalStatus', '==', types_1.ApprovalStatus.PENDING).count().get(),
            utils_1.db.collection('users').where('approvalStatus', '==', types_1.ApprovalStatus.APPROVED).count().get(),
            utils_1.db.collection('users').where('approvalStatus', '==', types_1.ApprovalStatus.REJECTED).count().get(),
            utils_1.db.collection('users').where('membershipTier', '==', types_1.SubscriptionTier.PLATINUM).count().get(),
            utils_1.db.collection('users').where('membershipTier', '==', types_1.SubscriptionTier.GOLD).count().get(),
            utils_1.db.collection('users').where('membershipTier', '==', types_1.SubscriptionTier.SILVER).count().get(),
            utils_1.db.collection('users').where('membershipTier', '==', types_1.SubscriptionTier.BASIC).count().get(),
            utils_1.db.collection('users').where('notificationsEnabled', '==', true).count().get(),
        ]);
        return {
            success: true,
            stats: {
                totalUsers: totalUsersSnapshot.data().count,
                byApprovalStatus: {
                    pending: pendingSnapshot.data().count,
                    approved: approvedSnapshot.data().count,
                    rejected: rejectedSnapshot.data().count,
                },
                byTier: {
                    platinum: platinumSnapshot.data().count,
                    gold: goldSnapshot.data().count,
                    silver: silverSnapshot.data().count,
                    basic: basicSnapshot.data().count,
                },
                notificationsEnabled: notificationsEnabledSnapshot.data().count,
                launchDates: {
                    premium: PREMIUM_ACCESS_DATE.toISOString(),
                    basic: BASIC_ACCESS_DATE.toISOString(),
                },
            },
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching MVP access stats:', error);
        throw (0, utils_1.handleError)(error);
    }
});
//# sourceMappingURL=mvp_access.js.map