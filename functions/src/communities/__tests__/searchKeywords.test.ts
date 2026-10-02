/**
 * Node side of the shared keyword algorithm; the Dart side
 * (test/unit/communities/community_search_keywords_test.dart) reads the same
 * vectors, so both produce identical searchKeywords arrays.
 */
import * as fs from 'fs';
import * as path from 'path';
import {
  buildCommunitySearchKeywords,
  normalizeSearchText,
  searchKeywordsStale,
  searchTokens,
} from '../searchKeywords';

const vectors = JSON.parse(
  fs.readFileSync(
    path.join(__dirname, '..', '..', '..', '..', 'test', 'fixtures', 'community_search_keywords_vectors.json'),
    'utf8',
  ),
);

describe('community searchKeywords', () => {
  for (const v of vectors.keywords) {
    it(`keywords for ${JSON.stringify(v.input)}`, () => {
      expect(buildCommunitySearchKeywords(v.input.name, v.input.city, v.input.tags)).toEqual(v.expected);
    });
  }
  for (const v of vectors.normalize) {
    it(`normalise ${JSON.stringify(v.input)}`, () => {
      expect(normalizeSearchText(v.input)).toBe(v.normalized);
      expect(searchTokens(v.input)).toEqual(v.tokens);
    });
  }
  it('stale detection: missing, outdated, correct', () => {
    expect(searchKeywordsStale({ name: 'Cafe' })).toBe(true);
    expect(searchKeywordsStale({ name: 'Cafe', searchKeywords: ['t'] })).toBe(true);
    expect(searchKeywordsStale({ name: 'Cafe', searchKeywords: ['c', 'ca', 'caf', 'cafe'] })).toBe(false);
  });
});
