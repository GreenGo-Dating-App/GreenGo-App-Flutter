/// Community text guard (Apple 4.3(b), App Review 2026-10-22): GreenGo is
/// for friendship, culture and networking, so dating wording in a
/// community's name, description or rules shows a gentle warning in the
/// create/edit form. Nothing is blocked; the server
/// (functions/src/communities/communityTextGuard.ts) queues the same hits for
/// a low-priority admin review.
///
/// Matching is on normalised WORDS (the community-search tokens: lowercase,
/// accents folded, punctuation splits), never on substrings, so the "date" of
/// an event, "update" or "Partnerschaft" never match. A word ending in "*"
/// matches any word starting with it. MUST stay identical to the server:
/// both are checked against test/fixtures/community_dating_terms.json.
library;

import 'community_search_keywords.dart';

/// Dating phrases (en/pt/es/it/fr/de). KEEP IN SYNC with the server + fixture.
const List<String> kCommunityDatingTerms = [
  'dating*', 'speed dating', 'online dating', 'romance', 'romantic partner*',
  'romantic relationship*', 'romantic date*', 'hookup*', 'hook up', 'hook ups',
  'one night stand*', 'friends with benefits', 'fwb', 'find love',
  'finding love', 'looking for love', 'find true love', 'soulmate*',
  'soul mate*', 'find a boyfriend', 'find a girlfriend',
  'looking for a boyfriend', 'looking for a girlfriend', 'get a girlfriend',
  'get a boyfriend', 'find a wife', 'find a husband', 'looking for a wife',
  'looking for a husband', 'meet singles', 'for singles', 'singles night*',
  'singles party', 'singles event*', 'flirt*', 'sugar daddy', 'sugar daddies',
  'sugar baby', 'sugar babies', 'sugar mommy', 'casual sex',
  'casual encounter*', 'nsfw', 'namor*', 'paquer*', 'encontro romantico',
  'encontros romanticos', 'encontro amoroso', 'encontros amorosos',
  'relacionamento serio', 'alma gemea', 'pegacao', 'sexo casual',
  'encontrar o amor', 'achar o amor', 'encontrar um amor', 'procurando amor',
  'para solteiros', 'encontro de solteiros', 'ficar com gringo*',
  'ficar com gringa*', 'procuro esposa', 'procuro marido', 'citas romanticas',
  'cita romantica', 'app de citas', 'aplicacion de citas', 'pagina de citas',
  'sitio de citas', 'busco pareja', 'buscar pareja', 'encontrar pareja',
  'conocer pareja', 'ligar con', 'ligoteo', 'media naranja',
  'encontrar el amor', 'busco novia', 'busco novio', 'encontrar novia',
  'encontrar novio', 'conseguir novia', 'conseguir novio', 'para solteros',
  'appuntamenti romantici', 'appuntamento romantico', 'incontri romantici',
  'incontri per single', 'incontri single', 'anima gemella', 'trovare l amore',
  'cerco fidanzata', 'cerco fidanzato', 'trovare una fidanzata',
  'trovare un fidanzato', 'rimorchiare', 'rencontre amoureuse',
  'rencontres amoureuses', 'site de rencontre*', 'rencontres coquines',
  'rencontre coquine', 'trouver l amour', 'ame soeur', 'plan cul', 'drague*',
  'pour celibataires', 'rencontre celibataire*', 'rencontres celibataire*',
  'petit ami', 'petite amie', 'partnersuch*', 'partnerborse*',
  'partnervermittlung*', 'singleborse*', 'liebe finden', 'die liebe finden',
  'feste freundin', 'festen freund', 'romantische treffen', 'seitensprung*',
  'sexdate*', 'blind date*',
];

/// Innocent phrases that contain a term; a hit inside one is ignored.
const List<String> kCommunityDatingTermExceptions = [
  'carbon dating', 'radiocarbon dating', 'dating back', 'dating from',
  'dating to', 'romance language*', 'romance studies', 'romance philology',
  'romance novel*', 'romance book*', 'romance literature',
  'romance linguistics',
];

List<List<String>> _compile(List<String> list) => [
      for (final t in list) t.split(' ').where((w) => w.isNotEmpty).toList(),
    ];

final List<List<String>> _terms = _compile(kCommunityDatingTerms);
final List<List<String>> _exceptions = _compile(kCommunityDatingTermExceptions);

bool _word(String pattern, String word) => pattern.endsWith('*')
    ? word.startsWith(pattern.substring(0, pattern.length - 1))
    : word == pattern;

bool _at(List<String> tokens, int i, List<String> p) {
  if (i + p.length > tokens.length) return false;
  for (var k = 0; k < p.length; k++) {
    if (!_word(p[k], tokens[i + k])) return false;
  }
  return true;
}

/// The dating terms (as listed) found in [text]; empty when none.
List<String> findCommunityDatingTerms(String? text) {
  final tokens = communitySearchTokens(text);
  if (tokens.isEmpty) return const [];
  final covered = List<bool>.filled(tokens.length, false);
  for (var i = 0; i < tokens.length; i++) {
    for (final e in _exceptions) {
      if (_at(tokens, i, e)) {
        for (var k = 0; k < e.length; k++) {
          covered[i + k] = true;
        }
      }
    }
  }
  final found = <String>[];
  for (var t = 0; t < _terms.length; t++) {
    final p = _terms[t];
    for (var i = 0; i < tokens.length; i++) {
      if (!_at(tokens, i, p)) continue;
      var allCovered = true;
      for (var k = 0; k < p.length; k++) {
        if (!covered[i + k]) allCovered = false;
      }
      if (allCovered) continue;
      found.add(kCommunityDatingTerms[t]);
      break;
    }
  }
  return found;
}

/// True when any of [texts] contains dating wording.
bool hasCommunityDatingWording(Iterable<String?> texts) =>
    texts.any((t) => findCommunityDatingTerms(t).isNotEmpty);
