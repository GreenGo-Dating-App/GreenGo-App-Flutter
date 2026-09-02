"use strict";
/**
 * Localized copy for the registration welcome email.
 *
 * The email goes out in whatever language the user had the app set to when
 * they typed their address on the first registration screen — the client sends
 * that as `locale`. Anything unrecognised falls back to English.
 *
 * Only the strings are localized; the HTML shell and CSS are shared.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.welcomeEmailCopy = welcomeEmailCopy;
const EN = {
    subject: 'Welcome to GreenGo!',
    tagline: 'Welcome aboard!',
    intro: "We're thrilled to have you join the <span class=\"highlight\">GreenGo</span> community!",
    profilePrompt: 'Your account has been created successfully. Complete your profile to start connecting with people from every culture.',
    featureProfile: 'Create your unique profile',
    featureDiscover: 'Discover people near you',
    featureConversations: 'Start meaningful conversations',
    featureTravel: 'Travel mode to meet people worldwide',
    callToAction: 'Open the app and complete your profile to get started!',
    rightsReserved: 'All rights reserved.',
};
const COPY = {
    en: EN,
    it: {
        subject: 'Benvenuto su GreenGo!',
        tagline: 'Benvenuto a bordo!',
        intro: 'Siamo felicissimi di averti nella community di <span class="highlight">GreenGo</span>!',
        profilePrompt: 'Il tuo account è stato creato con successo. Completa il profilo per iniziare a connetterti con persone di ogni cultura.',
        featureProfile: 'Crea il tuo profilo unico',
        featureDiscover: 'Scopri persone vicino a te',
        featureConversations: 'Inizia conversazioni autentiche',
        featureTravel: 'Modalità viaggio per conoscere persone in tutto il mondo',
        callToAction: "Apri l'app e completa il profilo per iniziare!",
        rightsReserved: 'Tutti i diritti riservati.',
    },
    es: {
        subject: '¡Bienvenido a GreenGo!',
        tagline: '¡Bienvenido a bordo!',
        intro: '¡Nos encanta que te unas a la comunidad de <span class="highlight">GreenGo</span>!',
        profilePrompt: 'Tu cuenta se ha creado correctamente. Completa tu perfil para empezar a conectar con personas de todas las culturas.',
        featureProfile: 'Crea tu perfil único',
        featureDiscover: 'Descubre personas cerca de ti',
        featureConversations: 'Inicia conversaciones auténticas',
        featureTravel: 'Modo viaje para conocer gente de todo el mundo',
        callToAction: '¡Abre la app y completa tu perfil para empezar!',
        rightsReserved: 'Todos los derechos reservados.',
    },
    pt: {
        subject: 'Bem-vindo ao GreenGo!',
        tagline: 'Bem-vindo a bordo!',
        intro: 'Estamos muito felizes por se juntar à comunidade <span class="highlight">GreenGo</span>!',
        profilePrompt: 'A sua conta foi criada com sucesso. Complete o seu perfil para começar a ligar-se a pessoas de todas as culturas.',
        featureProfile: 'Crie o seu perfil único',
        featureDiscover: 'Descubra pessoas perto de si',
        featureConversations: 'Inicie conversas autênticas',
        featureTravel: 'Modo viagem para conhecer pessoas em todo o mundo',
        callToAction: 'Abra a aplicação e complete o seu perfil para começar!',
        rightsReserved: 'Todos os direitos reservados.',
    },
    pt_BR: {
        subject: 'Bem-vindo ao GreenGo!',
        tagline: 'Boas-vindas!',
        intro: 'Estamos muito felizes em ter você na comunidade <span class="highlight">GreenGo</span>!',
        profilePrompt: 'Sua conta foi criada com sucesso. Complete seu perfil para começar a se conectar com pessoas de todas as culturas.',
        featureProfile: 'Crie seu perfil único',
        featureDiscover: 'Descubra pessoas perto de você',
        featureConversations: 'Comece conversas de verdade',
        featureTravel: 'Modo viagem para conhecer pessoas no mundo todo',
        callToAction: 'Abra o app e complete seu perfil para começar!',
        rightsReserved: 'Todos os direitos reservados.',
    },
    fr: {
        subject: 'Bienvenue sur GreenGo !',
        tagline: 'Bienvenue à bord !',
        intro: 'Nous sommes ravis de vous compter dans la communauté <span class="highlight">GreenGo</span> !',
        profilePrompt: 'Votre compte a bien été créé. Complétez votre profil pour commencer à échanger avec des personnes de toutes les cultures.',
        featureProfile: 'Créez votre profil unique',
        featureDiscover: 'Découvrez des personnes près de chez vous',
        featureConversations: 'Lancez de vraies conversations',
        featureTravel: 'Mode voyage pour rencontrer des gens partout dans le monde',
        callToAction: "Ouvrez l'application et complétez votre profil pour commencer !",
        rightsReserved: 'Tous droits réservés.',
    },
    de: {
        subject: 'Willkommen bei GreenGo!',
        tagline: 'Willkommen an Bord!',
        intro: 'Schön, dass du Teil der <span class="highlight">GreenGo</span>-Community bist!',
        profilePrompt: 'Dein Konto wurde erfolgreich erstellt. Vervollständige dein Profil, um mit Menschen aus allen Kulturen in Kontakt zu kommen.',
        featureProfile: 'Erstelle dein einzigartiges Profil',
        featureDiscover: 'Entdecke Menschen in deiner Nähe',
        featureConversations: 'Beginne echte Gespräche',
        featureTravel: 'Reisemodus, um weltweit Menschen zu treffen',
        callToAction: 'Öffne die App und vervollständige dein Profil, um loszulegen!',
        rightsReserved: 'Alle Rechte vorbehalten.',
    },
};
/**
 * Resolve the copy for a locale code such as `pt_BR`, `pt-BR`, `pt` or `en`.
 * Falls back to the base language, then to English.
 */
function welcomeEmailCopy(locale) {
    var _a;
    if (typeof locale !== 'string' || !locale)
        return EN;
    const normalized = locale.replace('-', '_').trim();
    if (COPY[normalized])
        return COPY[normalized];
    const base = normalized.split('_')[0].toLowerCase();
    return (_a = COPY[base]) !== null && _a !== void 0 ? _a : EN;
}
//# sourceMappingURL=welcomeEmailCopy.js.map