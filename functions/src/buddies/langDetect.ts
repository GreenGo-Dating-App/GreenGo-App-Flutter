/**
 * Tiny stop-word language guesser for the Buddy languages (no AI call, no
 * tokens). Owner 2026-10-24: a Buddy set up in English must answer in English
 * even when the user writes in Spanish, so every reply bubble is checked and
 * a bubble in another language is translated into the Buddy's language.
 *
 * Only distinctive function words are listed (words shared by two languages,
 * like "de", "a", "que", are left out), and a guess is returned only when it
 * is clear: at least 2 hits and twice the runner-up. Otherwise null (unknown,
 * the reply is kept as is).
 */
export type BaseLang = 'en' | 'de' | 'es' | 'fr' | 'it' | 'pt';

const WORDS: Record<BaseLang, string[]> = {
  en: ['the', 'and', 'you', 'your', 'is', 'are', 'what', 'have', 'with', 'this', 'that', 'it', 'do', 'for', 'to', 'of', 'my', 'how', 'was', 'love', 'would', 'there'],
  de: ['und', 'ich', 'du', 'nicht', 'ist', 'das', 'der', 'die', 'mit', 'auch', 'was', 'wie', 'ein', 'eine', 'sehr', 'dich', 'mein', 'hast', 'bist', 'zu'],
  es: ['el', 'los', 'las', 'y', 'es', 'muy', 'pero', 'como', 'qué', 'tu', 'tú', 'yo', 'está', 'estoy', 'hola', 'gracias', 'también', 'mucho', 'del', 'una', 'para', 'por', 'quiero', 'hay'],
  fr: ['le', 'les', 'et', 'est', 'je', 'tu', 'vous', 'pas', 'avec', 'pour', 'une', 'des', 'du', 'mais', 'très', 'c\'est', 'suis', 'bonjour', 'merci', 'aussi', 'ton', 'ça'],
  it: ['il', 'gli', 'e', 'è', 'sono', 'io', 'non', 'che', 'per', 'con', 'una', 'molto', 'anche', 'ciao', 'grazie', 'della', 'del', 'mi', 'ti', 'hai', 'cosa', 'questo'],
  pt: ['o', 'os', 'e', 'é', 'eu', 'você', 'não', 'com', 'uma', 'muito', 'também', 'obrigado', 'obrigada', 'olá', 'do', 'da', 'dos', 'das', 'tem', 'isso', 'está', 'meu'],
};

const INDEX: Map<string, BaseLang[]> = (() => {
  const m = new Map<string, BaseLang[]>();
  for (const [lang, words] of Object.entries(WORDS) as [BaseLang, string[]][]) {
    for (const w of words) m.set(w, [...(m.get(w) ?? []), lang]);
  }
  return m;
})();

export function guessLanguage(text: string): BaseLang | null {
  const tokens = text.toLowerCase().normalize('NFC').match(/[\p{L}']+/gu) ?? [];
  const score: Record<string, number> = {};
  for (const t of tokens) {
    const langs = INDEX.get(t);
    // A word listed for several languages tells nothing.
    if (langs && langs.length === 1) score[langs[0]] = (score[langs[0]] ?? 0) + 1;
  }
  const ranked = Object.entries(score).sort((a, b) => b[1] - a[1]);
  if (!ranked.length) return null;
  const [top, n] = ranked[0];
  const second = ranked[1]?.[1] ?? 0;
  return n >= 2 && n >= second * 2 ? (top as BaseLang) : null;
}
