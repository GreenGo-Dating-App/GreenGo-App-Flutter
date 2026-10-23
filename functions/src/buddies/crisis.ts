/**
 * Crisis path: self-harm / suicide signals in a user message get a caring
 * fixed reply with helplines in the Buddy's language. No model call, no
 * charge (kind 'safety'). Patterns are deliberately broad: a false positive
 * costs one gentle message, a false negative could cost much more.
 */
import { Language } from './model';

const PATTERNS: RegExp[] = [
  // en
  /\b(kill|hurt|harm)\s+my\s?self\b/i, /\bsuicid/i, /\bend\s+(my|it)\s+(life|all)\b/i, /\bwant\s+to\s+die\b/i,
  /\b(don'?t|do not)\s+want\s+to\s+(live|be alive)\b/i, /\bself[-\s]?harm/i, /\bcut(ting)?\s+my\s?self\b/i,
  /\bno\s+reason\s+to\s+live\b/i, /\bbetter\s+off\s+dead\b/i,
  // it
  /\buccidermi\b/i, /\bsuicid(io|armi)\b/i, /\bvoglio\s+morire\b/i, /\bfarla\s+finita\b/i, /\bfarmi\s+del\s+male\b/i, /\btagliarmi\b/i,
  // es
  /\bmatarme\b/i, /\bsuicidarme\b/i, /\bquiero\s+morir(me)?\b/i, /\bhacerme\s+da[ñn]o\b/i, /\bacabar\s+con\s+mi\s+vida\b/i,
  // fr
  /\bme\s+tuer\b/i, /\bme\s+suicider\b/i, /\bje\s+veux\s+mourir\b/i, /\ben\s+finir\s+avec\s+la\s+vie\b/i, /\bme\s+faire\s+du\s+mal\b/i,
  // de
  /\bmich\s+umbringen\b/i, /\bselbstmord\b/i, /\bsuizid/i, /\bich\s+will\s+sterben\b/i, /\bmir\s+etwas\s+antun\b/i, /\britzen\b/i,
  // pt / pt-BR
  /\bme\s+matar\b/i, /\bmatar-me\b/i, /\bsuic[ií]dio\b/i, /\bquero\s+morrer\b/i, /\bme\s+machucar\b/i, /\bacabar\s+com\s+a\s+minha\s+vida\b/i,
  /\bacabar\s+com\s+tudo\b/i, /\bme\s+cortar\b/i,
];

export function isCrisis(text: string): boolean {
  const t = text.normalize('NFC');
  return PATTERNS.some((re) => re.test(t));
}

/** Fixed safety reply (well-known national helplines; emergency number first). */
export const CRISIS_REPLY: Record<Language, string> = {
  en: "I'm really sorry you're feeling this way. You deserve support right now. If you're in danger, call your local emergency number. In the US call or text 988; in the UK call Samaritans on 116 123. Please reach out to someone you trust.",
  it: 'Mi dispiace tanto che ti senta così. Meriti supporto adesso. Se sei in pericolo chiama il 112. Puoi parlare con Telefono Amico allo 02 2327 2327. Per favore, contatta una persona di cui ti fidi.',
  es: 'Siento mucho que te sientas así. Mereces apoyo ahora mismo. Si estás en peligro, llama al 112. En España puedes llamar al 024 (línea de atención a la conducta suicida). Por favor, habla con alguien de confianza.',
  fr: "Je suis vraiment désolé que tu te sentes comme ça. Tu mérites du soutien maintenant. En cas de danger, appelle le 112. En France, tu peux appeler le 3114, gratuit et 24h/24. Parle aussi à quelqu'un de confiance.",
  de: 'Es tut mir sehr leid, dass es dir so geht. Du verdienst jetzt Unterstützung. Bei Gefahr ruf die 112 an. Die TelefonSeelsorge erreichst du kostenlos unter 0800 111 0 111. Bitte sprich mit einem Menschen, dem du vertraust.',
  pt: 'Lamento muito que te sintas assim. Mereces apoio agora. Se estiveres em perigo, liga 112. Podes falar com a SOS Voz Amiga: 213 544 545. Por favor, fala com alguém em quem confies.',
  pt_BR: 'Sinto muito que você esteja se sentindo assim. Você merece apoio agora. Se estiver em perigo, ligue 192 ou 190. O CVV atende 24h pelo 188, de graça. Por favor, fale com alguém de confiança.',
};

/** Neutral line used when a reply fails the banned-terms check. */
export const FALLBACK_REPLY: Record<Language, string> = {
  en: "Let's talk about something else. What would you like to chat about?",
  it: 'Parliamo di qualcos\'altro. Di cosa ti va di parlare?',
  es: 'Hablemos de otra cosa. ¿De qué te apetece hablar?',
  fr: "Parlons d'autre chose. De quoi as-tu envie de parler ?",
  de: 'Lass uns über etwas anderes reden. Worüber möchtest du sprechen?',
  pt: 'Vamos falar de outra coisa. Sobre o que te apetece conversar?',
  pt_BR: 'Vamos falar de outra coisa. Sobre o que você quer conversar?',
};

/**
 * Output screen for EVERY Buddy reply (owner rule 2026-10-23: always positive;
 * nothing sexual, suicidal or dark). Admin banned terms, self-harm wording
 * and sexual / graphic wording in the 7 languages: the reply is replaced by a
 * friendly fallback line.
 */
// Whole words only (\b): "sexta" (pt Friday), "Essex" or "nuevo" must pass.
const UNSAFE_OUTPUT: RegExp[] = [
  // en
  /\b(sex|sexual(ly)?|sexy|nude|nudes|naked|porn\w*|erotic\w*|orgasm\w*|horny)\b/i,
  // it
  /\b(sesso|sessual[ei]|sessualmente|nud[oaie]|porno\w*|erotic[oaie])\b/i,
  // es / pt / pt-BR
  /\b(sexo|sexual(es)?|desnud[oa]s?|nu[ae]s?|pelad[oa]s?|porn[oô]\w*|er[oó]tic[oa]s?|tes[aã]o)\b/i,
  // fr
  /\b(sexe|sexuel(le)?s?|nue?s?|porno\w*|[ée]rotiques?)\b/i,
  // de
  /\b(sex|sexuell\w*|nackt\w*|porno\w*|erotisch\w*|geil)\b/i,
  // self-harm / graphic violence (the crisis patterns run on replies too)
  /\b(suicide|suicidal|self[- ]?harm|kill (yo)?ur ?self|gore|torture[ds]?|decapitat\w*|massacre)\b/i,
];

export function isUnsafeReply(text: string, banned: string | null): boolean {
  if (banned) return true;
  if (isCrisis(text)) return true;
  return UNSAFE_OUTPUT.some((re) => re.test(text));
}
