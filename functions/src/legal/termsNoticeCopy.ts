/**
 * Advance notice of an important Terms change (Terms 24.2 a): the email copy,
 * per version and per app language.
 *
 * Mirrors the app side (lib/core/constants/legal_versions.dart:
 * kUpcomingTermsVersion / kUpcomingTermsEffectiveDate / kUpcomingTermsUrl and
 * the per-version bullets in the ARB files, legalUpdate530Bullet*). Add the
 * next version here together with the app constants.
 */
import type { AppLocale } from '../shared/i18n/locales';

export interface TermsNotice {
  /** Terms version that takes effect. */
  version: string;
  /** Effective date, YYYY-MM-DD (UTC midnight). */
  effectiveDate: string;
  /**
   * Only accounts created before this date (YYYY-MM-DD, UTC midnight) get the
   * notice: newer accounts accepted the version at sign-up. Omit to notify
   * every account.
   */
  accountsCreatedBefore?: string;
  /** Public page with the new text. */
  url: string;
  /** "What changes", per language. */
  bullets: Record<AppLocale, string[]>;
}

export const TERMS_NOTICES: Record<string, TermsNotice> = {
  // Owner decision of 16 Oct 2026: 5.3.0 applies from that day to accounts
  // created on or after it (they accept it at sign-up); older accounts move to
  // it on 16 Nov 2026 and are the only ones notified.
  '5.3.0': {
    version: '5.3.0',
    effectiveDate: '2026-11-16',
    accountsCreatedBefore: '2026-10-16',
    url: 'https://greengochat.com/terms-of-service/upcoming',
    bullets: {
      en: [
        'Referral rewards described as they work in the app (1 week of Base for the new user, 50 Coins for you, extra rewards at 5, 10 and 20 friends)',
        'Coin gifts arrive instantly and must be between 10 and 1,000 Coins',
        'Where to find Manage subscription and Purchases & withdrawal in the app',
        'How moderation decisions, notices and appeals work, including appeals by the person who reported',
        'Traders selling Experiences to people in the EU must give their trader details',
      ],
      de: [
        'Empfehlungsprämien so beschrieben, wie sie in der App funktionieren (1 Woche Base für die neue Person, 50 Coins für dich, zusätzliche Prämien bei 5, 10 und 20 Freunden)',
        'Coin-Geschenke kommen sofort an und müssen zwischen 10 und 1.000 Coins liegen',
        'Wo du in der App „Abo verwalten“ und „Käufe & Widerruf“ findest',
        'Wie Moderationsentscheidungen, Mitteilungen und Beschwerden funktionieren, auch Beschwerden der meldenden Person',
        'Unternehmer, die Erlebnisse an Personen in der EU verkaufen, müssen ihre Unternehmerangaben machen',
      ],
      es: [
        'Las recompensas por invitación descritas como funcionan en la app (1 semana de Base para la persona nueva, 50 Coins para ti, recompensas extra a los 5, 10 y 20 amigos)',
        'Los regalos de Coins llegan al instante y deben ser de entre 10 y 1.000 Coins',
        'Dónde encontrar Gestionar suscripción y Compras y desistimiento en la app',
        'Cómo funcionan las decisiones de moderación, las notificaciones y los recursos, incluidos los recursos de quien denunció',
        'Los comerciantes que venden Experiencias a personas en la UE deben facilitar sus datos de comerciante',
      ],
      fr: [
        'Les récompenses de parrainage décrites telles qu’elles fonctionnent dans l’app (1 semaine de Base pour la nouvelle personne, 50 Coins pour vous, des récompenses en plus à 5, 10 et 20 amis)',
        'Les cadeaux de Coins arrivent instantanément et doivent être compris entre 10 et 1 000 Coins',
        'Où trouver Gérer l’abonnement et Achats et rétractation dans l’app',
        'Comment fonctionnent les décisions de modération, les notifications et les recours, y compris les recours de la personne qui a signalé',
        'Les professionnels qui vendent des Expériences à des personnes dans l’UE doivent fournir leurs informations de professionnel',
      ],
      it: [
        'I premi per gli inviti descritti come funzionano nell’app (1 settimana di Base per la nuova persona, 50 Coins per te, premi extra a 5, 10 e 20 amici)',
        'I regali di Coins arrivano subito e devono essere tra 10 e 1.000 Coins',
        'Dove trovare Gestisci abbonamento e Acquisti e recesso nell’app',
        'Come funzionano le decisioni di moderazione, le comunicazioni e i ricorsi, compresi i ricorsi di chi ha segnalato',
        'I professionisti che vendono Esperienze a persone nell’UE devono fornire i propri dati di professionista',
      ],
      pt: [
        'As recompensas por convite descritas como funcionam na app (1 semana de Base para a pessoa nova, 50 Coins para si, recompensas extra aos 5, 10 e 20 amigos)',
        'As ofertas de Coins chegam de imediato e têm de ser entre 10 e 1000 Coins',
        'Onde encontrar Gerir subscrição e Compras e livre resolução na app',
        'Como funcionam as decisões de moderação, as notificações e os recursos, incluindo os recursos de quem denunciou',
        'Os profissionais que vendem Experiências a pessoas na UE têm de indicar os seus dados de profissional',
      ],
      pt_BR: [
        'As recompensas por indicação descritas como funcionam no app (1 semana de Base para a pessoa nova, 50 Coins para você, recompensas extras aos 5, 10 e 20 amigos)',
        'Os presentes de Coins chegam na hora e precisam ser de 10 a 1.000 Coins',
        'Onde encontrar Gerenciar assinatura e Compras e arrependimento no app',
        'Como funcionam as decisões de moderação, os avisos e os recursos, inclusive os recursos de quem denunciou',
        'Profissionais que vendem Experiências para pessoas na UE precisam informar seus dados de profissional',
      ],
    },
  },
};

interface Copy {
  subject: (version: string, date: string) => string;
  hello: string;
  intro: (version: string, date: string) => string;
  whatChanges: string;
  read: string;
  rights: (date: string) => string;
  footer: string;
}

export const NOTICE_COPY: Record<AppLocale, Copy> = {
  en: {
    subject: (v, d) => `Our Terms are changing on ${d} (version ${v})`,
    hello: 'Hello,',
    intro: (v, d) => `We are updating the GreenGo Terms and Conditions. Version ${v} takes effect on ${d}. When it takes effect, we will ask you to accept it in the app.`,
    whatChanges: 'What changes:',
    read: 'Read the new Terms',
    rights: (d) => `If you do not accept the change, you can end your contract free of charge before ${d} by deleting your account (Profile > Delete Account). You will get a refund of the unused part of any prepaid Membership: write to billing@greengochat.com. Until you end it, the previous version keeps applying to you, for up to 60 days.`,
    footer: 'You receive this service email because you have a GreenGo account. It is about your contract with us, so it is sent even if you turned marketing emails off.',
  },
  de: {
    subject: (v, d) => `Unsere AGB ändern sich am ${d} (Version ${v})`,
    hello: 'Hallo,',
    intro: (v, d) => `Wir aktualisieren die Allgemeinen Geschäftsbedingungen von GreenGo. Version ${v} gilt ab dem ${d}. Dann bitten wir dich, sie in der App zu akzeptieren.`,
    whatChanges: 'Was sich ändert:',
    read: 'Die neuen AGB lesen',
    rights: (d) => `Wenn du der Änderung nicht zustimmst, kannst du deinen Vertrag vor dem ${d} kostenlos beenden, indem du dein Konto löschst (Profil > Konto Löschen). Den nicht genutzten Teil einer im Voraus bezahlten Mitgliedschaft erstatten wir dir: schreib an billing@greengochat.com. Bis du kündigst, gilt für dich weiter die bisherige Version, höchstens 60 Tage lang.`,
    footer: 'Du erhältst diese Service-E-Mail, weil du ein GreenGo-Konto hast. Sie betrifft deinen Vertrag mit uns und wird daher auch gesendet, wenn du Marketing-E-Mails abgeschaltet hast.',
  },
  es: {
    subject: (v, d) => `Nuestros Términos cambian el ${d} (versión ${v})`,
    hello: 'Hola:',
    intro: (v, d) => `Estamos actualizando los Términos y Condiciones de GreenGo. La versión ${v} entra en vigor el ${d}. Entonces te pediremos que la aceptes en la app.`,
    whatChanges: 'Qué cambia:',
    read: 'Leer los nuevos Términos',
    rights: (d) => `Si no aceptas el cambio, puedes poner fin a tu contrato sin coste antes del ${d} eliminando tu cuenta (Perfil > Eliminar Cuenta). Te reembolsaremos la parte no usada de una Membresía pagada por adelantado: escribe a billing@greengochat.com. Hasta que lo termines, se te sigue aplicando la versión anterior, durante un máximo de 60 días.`,
    footer: 'Recibes este correo de servicio porque tienes una cuenta de GreenGo. Trata sobre tu contrato con nosotros, por eso se envía aunque hayas desactivado los correos de marketing.',
  },
  fr: {
    subject: (v, d) => `Nos Conditions changent le ${d} (version ${v})`,
    hello: 'Bonjour,',
    intro: (v, d) => `Nous mettons à jour les Conditions générales de GreenGo. La version ${v} s’applique à partir du ${d}. Nous vous demanderons alors de l’accepter dans l’app.`,
    whatChanges: 'Ce qui change :',
    read: 'Lire les nouvelles Conditions',
    rights: (d) => `Si vous n’acceptez pas la modification, vous pouvez mettre fin gratuitement à votre contrat avant le ${d} en supprimant votre compte (Profil > Supprimer le Compte). Nous vous rembourserons la partie non utilisée d’un Abonnement payé d’avance : écrivez à billing@greengochat.com. Tant que vous n’y mettez pas fin, la version précédente continue de s’appliquer à vous, pendant 60 jours au maximum.`,
    footer: 'Vous recevez cet e-mail de service parce que vous avez un compte GreenGo. Il concerne votre contrat avec nous ; il est donc envoyé même si vous avez désactivé les e-mails marketing.',
  },
  it: {
    subject: (v, d) => `I nostri Termini cambiano il ${d} (versione ${v})`,
    hello: 'Ciao,',
    intro: (v, d) => `Stiamo aggiornando i Termini e Condizioni di GreenGo. La versione ${v} si applica dal ${d}. A quel punto ti chiederemo di accettarla nell’app.`,
    whatChanges: 'Cosa cambia:',
    read: 'Leggi i nuovi Termini',
    rights: (d) => `Se non accetti la modifica, puoi chiudere il contratto gratuitamente prima del ${d} eliminando il tuo account (Profilo > Elimina Account). Ti rimborseremo la parte non usata di un Abbonamento pagato in anticipo: scrivi a billing@greengochat.com. Finché non lo chiudi, per te continua a valere la versione precedente, per un massimo di 60 giorni.`,
    footer: 'Ricevi questa email di servizio perché hai un account GreenGo. Riguarda il tuo contratto con noi, quindi viene inviata anche se hai disattivato le email di marketing.',
  },
  pt: {
    subject: (v, d) => `Os nossos Termos mudam a ${d} (versão ${v})`,
    hello: 'Olá,',
    intro: (v, d) => `Estamos a atualizar os Termos e Condições do GreenGo. A versão ${v} aplica-se a partir de ${d}. Nessa altura, pedimos que a aceite na app.`,
    whatChanges: 'O que muda:',
    read: 'Ler os novos Termos',
    rights: (d) => `Se não aceitar a alteração, pode terminar o contrato sem custos antes de ${d}, eliminando a sua conta (Perfil > Eliminar Conta). Reembolsamos a parte não utilizada de uma Assinatura paga antecipadamente: escreva para billing@greengochat.com. Até o terminar, continua a aplicar-se a versão anterior, durante 60 dias no máximo.`,
    footer: 'Recebe este e-mail de serviço porque tem uma conta GreenGo. Diz respeito ao seu contrato connosco, por isso é enviado mesmo que tenha desativado os e-mails de marketing.',
  },
  pt_BR: {
    subject: (v, d) => `Nossos Termos mudam em ${d} (versão ${v})`,
    hello: 'Olá,',
    intro: (v, d) => `Estamos atualizando os Termos e Condições do GreenGo. A versão ${v} vale a partir de ${d}. Nessa data, vamos pedir que você a aceite no app.`,
    whatChanges: 'O que muda:',
    read: 'Ler os novos Termos',
    rights: (d) => `Se você não aceitar a mudança, pode encerrar seu contrato sem custo antes de ${d}, excluindo sua conta (Perfil > Excluir Conta). Você recebe o reembolso da parte não usada de uma Assinatura paga antecipadamente: escreva para billing@greengochat.com. Até você encerrar, continua valendo a versão anterior, por no máximo 60 dias.`,
    footer: 'Você recebe este e-mail de serviço porque tem uma conta GreenGo. Ele trata do seu contrato conosco, por isso é enviado mesmo se você desativou os e-mails de marketing.',
  },
};
