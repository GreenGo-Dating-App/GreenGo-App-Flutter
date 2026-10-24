/**
 * Owner 2026-10-24: every Buddy topic has a 365-day path, a course intro and a
 * question bank, written once (tools/buddy_content) and stored in Firestore:
 *
 *   buddy_courses/<topic>        {days: [{d, lv, t}] x365, intro: {lang: [b1, b2]}, lessonsReady}
 *   buddy_lessons/<topic>_<ddd>  {d, lv, i18n: {lang: {t, g, p[3], q, c}}, target?: {vocab[6], gram}}
 *   buddy_questions/<topic>      {questions: [{id, lv, i18n: {lang: text}}] x100}
 *
 * Read-only content shared by every user: cached in memory per instance, so a
 * reply costs at most 2 document reads on a cold cache and 0 after.
 *
 * Progress per Buddy (`course` on ai_buddies/{uid}/buddies/{id}):
 *   {day, doneOn: 'yyyymmdd' | null, askedQ: string[]}
 * The Buddy marks today's lesson done (reply field `lessonDone`); the next
 * lesson unlocks on the next UTC day, so the path is one lesson a day.
 */
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { BuddySettings, utcDay } from './model';

export const COURSE_DAYS = 365;
/** Path length for a topic: the contiguous lessons written so far (owner 2026-10-24: 30 for now). */
export const courseDays = (c: Course | null) => Math.min(COURSE_DAYS, Math.max(1, Number(c?.lessonsReady) || COURSE_DAYS));
const TTL_MS = 10 * 60_000;
const ASKED_KEEP = 150;

export interface LessonText { t: string; g: string; p: string[]; q: string; c: string }
export interface Lesson { d: number; lv: string; i18n: Record<string, LessonText>; target?: { vocab: { w: string; ex: string }[]; gram: string } }
export interface Question { id: string; lv: string; i18n: Record<string, string> }
export interface Course { days?: { d: number; lv: string; t: string }[]; intro?: Record<string, string[]>; lessonsReady?: number }
export interface CourseState { day: number; doneOn: string | null; askedQ: string[] }

const cache = new Map<string, { at: number; v: unknown }>();
async function cached<T>(key: string, load: () => Promise<T>): Promise<T> {
  const hit = cache.get(key);
  if (hit && Date.now() - hit.at < TTL_MS) return hit.v as T;
  const v = await load();
  cache.set(key, { at: Date.now(), v });
  return v;
}
/** Test hook. */
export function _clearContentCache() { cache.clear(); }

const db = () => admin.firestore();
const pad = (d: number) => String(d).padStart(3, '0');

export const getCourse = (topic: string) =>
  cached<Course | null>(`c:${topic}`, async () => (await db().doc(`buddy_courses/${topic}`).get()).data() as Course ?? null);
export const getLesson = (topic: string, day: number) =>
  cached<Lesson | null>(`l:${topic}:${day}`, async () => (await db().doc(`buddy_lessons/${topic}_${pad(day)}`).get()).data() as Lesson ?? null);
export const getQuestions = (topic: string) =>
  cached<Question[]>(`q:${topic}`, async () => ((await db().doc(`buddy_questions/${topic}`).get()).data()?.questions ?? []) as Question[]);

/** The stored state, with the next lesson unlocked when yesterday's (or older) was done. */
export function currentCourse(raw: unknown, nowMs = Date.now(), maxDay = COURSE_DAYS): CourseState {
  const c = (raw && typeof raw === 'object' ? raw : {}) as Partial<CourseState>;
  let day = Math.min(maxDay, Math.max(1, Math.floor(Number(c.day) || 1)));
  let doneOn = typeof c.doneOn === 'string' ? c.doneOn : null;
  if (doneOn && doneOn < utcDay(nowMs) && day < maxDay) {
    day += 1;
    doneOn = null;
  }
  return { day, doneOn, askedQ: Array.isArray(c.askedQ) ? c.askedQ.filter((x) => typeof x === 'string').slice(-ASKED_KEEP) : [] };
}

export function levelBand(lv: string): 'beginner' | 'intermediate' | 'advanced' {
  if (lv === 'A1' || lv === 'A2' || lv === 'beginner') return 'beginner';
  if (lv === 'B1' || lv === 'intermediate') return 'intermediate';
  return 'advanced';
}

/** Up to [n] questions not asked yet, for this level (or any), in a stable but varied order. */
export function pickQuestions(all: Question[], lang: string, lv: string, asked: string[], n = 3, seed = 0): { id: string; text: string }[] {
  const band = levelBand(lv);
  const used = new Set(asked);
  let pool = all.filter((q) => !used.has(q.id) && (q.lv === 'any' || q.lv === band) && q.i18n?.[lang]);
  if (pool.length < n) pool = all.filter((q) => !used.has(q.id) && q.i18n?.[lang]);
  if (!pool.length) pool = all.filter((q) => q.i18n?.[lang]); // every question asked once: start over
  const start = pool.length ? Math.abs(seed) % pool.length : 0;
  return [...pool.slice(start), ...pool.slice(0, start)].slice(0, n).map((q) => ({ id: q.id, text: q.i18n[lang] }));
}

/** System-prompt block: today's lesson (in the Buddy's language) + candidate questions. */
export function courseBlock(b: BuddySettings, state: CourseState, lesson: Lesson | null, questions: { id: string; text: string }[], maxDay = COURSE_DAYS): string {
  const parts: string[] = [];
  const lt = lesson?.i18n?.[b.language] ?? lesson?.i18n?.en;
  if (lesson && lt) {
    const finished = !!state.doneOn && lesson.d >= maxDay;
    const note = finished ? ' - the whole path is finished: celebrate it, review earlier lessons or just chat'
      : state.doneOn ? ' - already done today: just chat, review or go deeper, next lesson tomorrow' : '';
    parts.push(
      `TODAY'S LESSON (day ${lesson.d} of ${maxDay}, level ${lesson.lv})${note}:`,
      `Title: ${lt.t}. Goal: ${lt.g}`,
      `Key points: ${lt.p.join(' | ')}`,
      `Practice question: ${lt.q}`,
      `Mini challenge: ${lt.c}`,
    );
    if (lesson.target) {
      parts.push(`Vocabulary: ${lesson.target.vocab.map((v) => `${v.w} (${v.ex})`).join('; ')}`, `Grammar: ${lesson.target.gram}`);
    }
    parts.push('Weave the lesson into the chat naturally, one small step per message (never dump it all). When the user has practised the key points and tried the challenge, set "lessonDone": true.');
  }
  if (questions.length) {
    parts.push(`QUESTIONS YOU MAY ASK (when it fits, ask ONE, reworded naturally if needed; put its id in "q"): ${questions.map((q) => `[${q.id}] ${q.text}`).join(' ')}`);
  }
  return parts.join('\n');
}

/** Reply-format addition for the course fields. */
export const COURSE_FORMAT = 'Also add "lessonDone": true|false and "q": "<question id you asked>" or null.';

/** New state after a reply: lesson marked done today, asked question remembered. */
export function nextCourseState(state: CourseState, lessonDone: boolean, askedId: string | null, candidates: string[], nowMs = Date.now()): CourseState {
  const askedQ = askedId && candidates.includes(askedId) && !state.askedQ.includes(askedId)
    ? [...state.askedQ, askedId].slice(-ASKED_KEEP) : state.askedQ;
  return { day: state.day, doneOn: lessonDone && !state.doneOn ? utcDay(nowMs) : state.doneOn, askedQ };
}

/** The course intro bubbles in [lang] with {name} filled in, or null when not written yet. */
export function introBubbles(course: Course | null, lang: string, name: string): string[] | null {
  const b = course?.intro?.[lang];
  if (!Array.isArray(b) || !b.length) return null;
  return b.map((x) => x.replace(/\{name\}/g, name)).filter((x) => x.trim());
}
