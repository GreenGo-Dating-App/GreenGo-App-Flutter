import { COURSE_DAYS, courseBlock, currentCourse, introBubbles, levelBand, nextCourseState, pickQuestions } from '../content';
import { BuddySettings } from '../model';

const b = { name: 'Luna', avatar: 'owl', topic: 'practice_italian', role: 'friend', tone: 'warm', language: 'it', chatLanguage: 'en',
  level: 'beginner', cefr: null, checkInsEnabled: true } as unknown as BuddySettings;
const DAY = 864e5;
const T0 = Date.UTC(2026, 9, 24, 10);

describe('course progress: one lesson a day', () => {
  it('starts at day 1', () => {
    expect(currentCourse(undefined, T0)).toEqual({ day: 1, doneOn: null, askedQ: [] });
  });
  it('done today stays on the same day; the next lesson unlocks tomorrow', () => {
    const s = nextCourseState(currentCourse(undefined, T0), true, null, [], T0);
    expect(s).toMatchObject({ day: 1, doneOn: '20261024' });
    expect(currentCourse(s, T0 + 3600_000)).toMatchObject({ day: 1, doneOn: '20261024' });
    expect(currentCourse(s, T0 + DAY)).toMatchObject({ day: 2, doneOn: null });
  });
  it('not done = the same lesson continues, never skipped', () => {
    expect(currentCourse({ day: 5, doneOn: null }, T0 + 10 * DAY)).toMatchObject({ day: 5 });
  });
  it('stops at day 365', () => {
    expect(currentCourse({ day: COURSE_DAYS, doneOn: '20260101' }, T0)).toMatchObject({ day: COURSE_DAYS });
  });
  it('remembers only questions that were offered', () => {
    const s = nextCourseState(currentCourse(undefined, T0), false, 'x-002', ['x-001', 'x-002'], T0);
    expect(s.askedQ).toEqual(['x-002']);
    expect(nextCourseState(s, false, 'made-up', ['x-003'], T0).askedQ).toEqual(['x-002']);
  });
});

describe('question bank', () => {
  const q = (id: string, lv: string) => ({ id, lv, i18n: { it: `domanda ${id}`, en: `question ${id}` } });
  const bank = [q('a', 'any'), q('b', 'beginner'), q('c', 'advanced'), q('d', 'any'), q('e', 'beginner')];
  it('picks unasked questions for the level (or any), in the Buddy language', () => {
    const p = pickQuestions(bank, 'it', 'A1', ['a'], 3, 0);
    expect(p.map((x) => x.id)).toEqual(['b', 'd', 'e']);
    expect(p[0].text).toBe('domanda b');
  });
  it('starts over when every question was asked', () => {
    expect(pickQuestions(bank, 'it', 'B2', ['a', 'b', 'c', 'd', 'e'], 2, 0)).toHaveLength(2);
  });
  it('maps CEFR to bands', () => {
    expect(levelBand('A2')).toBe('beginner');
    expect(levelBand('B1')).toBe('intermediate');
    expect(levelBand('B2')).toBe('advanced');
  });
});

describe('prompt block and intro', () => {
  const lesson = { d: 3, lv: 'A1', i18n: { it: { t: 'Al bar', g: 'Ordinare un caffè', p: ['un caffè', 'per favore', 'quanto costa?'], q: 'Cosa prendi?', c: 'Ordina in italiano' } },
    target: { vocab: [{ w: 'il caffè', ex: 'Un caffè, per favore.' }], gram: 'Articoli: il, la' } };
  it('puts the lesson in the Buddy language and the question ids', () => {
    const s = courseBlock(b, { day: 3, doneOn: null, askedQ: [] }, lesson as any, [{ id: 'q-1', text: 'Ti piace il caffè?' }]);
    expect(s).toMatch(/day 3 of 365/);
    expect(s).toMatch(/Al bar/);
    expect(s).toMatch(/il caffè \(Un caffè, per favore\.\)/);
    expect(s).toMatch(/\[q-1\] Ti piace il caffè\?/);
    expect(s).toMatch(/"lessonDone": true/);
  });
  it('says when today is already done', () => {
    expect(courseBlock(b, { day: 3, doneOn: '20261024', askedQ: [] }, lesson as any, [])).toMatch(/already done today/);
  });
  it('fills {name} in the stored intro, null when not written', () => {
    const c = { intro: { it: ['Ciao! Sono {name}.', 'Iniziamo?'] } };
    expect(introBubbles(c, 'it', 'Luna')).toEqual(['Ciao! Sono Luna.', 'Iniziamo?']);
    expect(introBubbles(c, 'de', 'Luna')).toBeNull();
    expect(introBubbles(null, 'it', 'Luna')).toBeNull();
  });
});
