import 'dart:convert';

import '../domain/entities/attraction.dart';

/// Decoder for the LITE list layout: `attractions_lite/{ISO2}_{n}`, written by
/// `scripts/build_attractions_lite.js` (its header documents the format).
///
/// One doc holds a whole big country (FR: 2,827 attractions, ~0.4 MB instead
/// of 6 index shards / ~1.4 MB). Each attraction is ONE packed row string:
///
///   cols: ['i', 'n', 'c', ...]          column names, in row order
///   sep:  '|'                           field separator (absent from data)
///   dict: {cat: [...], vd: [...], ...}  a column listed here holds an INDEX
///   rows: ['100001|Palace of Versailles|Versailles|...', ...]
///
/// An empty cell means "absent" (or "derived", see [_row]). Columns are
/// looked up by NAME, so a future build adding columns does not break this
/// decoder; a different [format] is ignored (the caller falls back to the
/// full shards).
class AttractionsLiteShard {
  const AttractionsLiteShard({
    required this.iso2,
    required this.shard,
    required this.shards,
    required this.version,
    required this.minScore,
    required this.items,
  });

  /// The only layout this build understands.
  static const int format = 1;

  final String iso2;
  final int shard;
  final int shards;

  /// Content hash shared by every shard of one build.
  final String version;

  /// Lowest GreenGo Score in this shard (rows are best-first).
  final int minScore;

  final List<Attraction> items;

  /// The shard's header (no rows parsed), or null when [d] is not a supported
  /// lite doc. Cheap: used to check a cached query is complete.
  static LiteShardHeader? header(Map<String, dynamic>? d) {
    if (d == null || d['format'] != format) return null;
    final shard = d['shard'], shards = d['shards'], version = d['version'];
    if (shard is! num || shards is! num || version is! String) return null;
    if (shards < 1 || shard < 0 || shard >= shards) return null;
    return LiteShardHeader(
      iso2: (d['iso2'] ?? '').toString().toUpperCase(),
      shard: shard.toInt(),
      shards: shards.toInt(),
      version: version,
      minScore: (d['minScore'] as num?)?.toInt(),
    );
  }

  /// Parses a whole lite doc, or null when it is not a supported one.
  static AttractionsLiteShard? parse(Map<String, dynamic>? d, {String? iso2}) {
    final h = header(d);
    if (h == null) return null;
    final cols = d!['cols'], rows = d['rows'];
    if (cols is! List || rows is! List) return null;
    final sep = d['sep'] is String && (d['sep'] as String).isNotEmpty
        ? d['sep'] as String
        : '|';
    final iso = (iso2 ?? h.iso2).toUpperCase();
    final dict = d['dict'] is Map ? d['dict'] as Map : const {};
    final names = [for (final c in cols) c.toString()];
    final layout = _Layout(
      index: {for (var i = 0; i < names.length; i++) names[i]: i},
      dicts: [
        for (final n in names)
          dict[n] is List
              ? [for (final e in dict[n] as List) e.toString()]
              : null,
      ],
    );
    final items = <Attraction>[];
    int? lowest;
    for (final r in rows) {
      if (r is! String || r.isEmpty) continue;
      final a = _row(layout, r.split(sep), iso);
      if (a == null) continue;
      items.add(a);
      if (lowest == null || a.greengoScore < lowest) lowest = a.greengoScore;
    }
    return AttractionsLiteShard(
      iso2: iso,
      shard: h.shard,
      shards: h.shards,
      version: h.version,
      minScore: h.minScore ?? lowest ?? 0,
      items: items,
    );
  }

  static Attraction? _row(_Layout l, List<String> cells, String iso) {
    String? v(String col) {
      final i = l.index[col];
      if (i == null || i >= cells.length) return null;
      final raw = cells[i];
      if (raw.isEmpty) return null;
      final dl = l.dicts[i];
      if (dl == null) return raw;
      final j = int.tryParse(raw);
      return (j != null && j >= 0 && j < dl.length) ? dl[j] : null;
    }

    final id = int.tryParse(v('i') ?? '');
    if (id == null) return null;
    final name = v('n') ?? '';
    final city = v('c') ?? '';
    final citySlug = v('cs') ?? liteSlug(city);
    final score = int.tryParse(v('sc') ?? '') ?? 0;
    final flags = int.tryParse(v('f') ?? '') ?? 0;
    final price = double.tryParse(v('tp') ?? '');
    final packed = v('t');
    final tail = v('dt');
    final author = v('aa');
    return Attraction(
      id: id,
      slug: v('s') ?? '${liteSlug(name)}-$citySlug',
      name: name,
      cityName: city,
      citySlug: citySlug,
      countryIso2: iso,
      category: v('cat'),
      categoryIcon: v('ci'),
      importanceKey: v('imp'),
      importanceIcon: v('ii'),
      lat: double.tryParse(v('la') ?? ''),
      lng: double.tryParse(v('ln') ?? ''),
      imgBase: v('b') ?? 'attractions/$iso/$id',
      imgHash: v('h') ?? '',
      imgToken: (packed != null ? unpackUuid(packed) : null) ?? v('tk') ?? '',
      greengoScore: score,
      scoreTier: v('st') ?? tierForScore(score),
      googleRating: double.tryParse(v('r') ?? ''),
      ticketPrice: price,
      currency: price == null ? null : v('cu'),
      freeEntry: flags & 1 != 0,
      unesco: flags & 2 != 0,
      mustVisit: flags & 4 != 0,
      top10Country: flags & 8 != 0,
      descriptionShort: tail != null ? '$name in $city: $tail' : v('d'),
      visitDuration: v('vd'),
      attributionAuthor: author,
      attributionLicense: author == null ? null : v('al'),
    );
  }

  /// The tier the catalogue assigns to [score] (`attraction_config/app`
  /// scoreTiers); the lite rows omit `st` whenever it equals this.
  static String tierForScore(int score) {
    if (score >= 90) return 'iconic';
    if (score >= 80) return 'exceptional';
    if (score >= 70) return 'excellent';
    if (score >= 60) return 'great';
    return 'worth_visit';
  }

  /// A UUID packed as 22-char base64url (16 bytes) back to its canonical
  /// lower-case 8-4-4-4-12 form; null when [b] is not such a value.
  static String? unpackUuid(String b) {
    if (b.length != 22) return null;
    try {
      final bytes = base64Url.decode('$b==');
      if (bytes.length != 16) return null;
      final h = [for (final x in bytes) x.toRadixString(16).padLeft(2, '0')]
          .join();
      return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}'
          '-${h.substring(16, 20)}-${h.substring(20)}';
    } catch (_) {
      return null;
    }
  }

  /// Lite slug - MUST equal `liteSlug` in scripts/build_attractions_lite.js,
  /// which omits a slug / city slug only when this reproduces it exactly:
  /// lower-case, fold the accents of [_fold], drop apostrophes (' and ’),
  /// every other run of non [a-z0-9] -> '-', trim the dashes.
  static String liteSlug(String s) {
    final buf = StringBuffer();
    for (final r in s.toLowerCase().runes) {
      final ch = String.fromCharCode(r);
      if (ch == "'" || ch == '’') continue;
      buf.write(_fold[ch] ?? ch);
    }
    return buf
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static final Map<String, String> _fold = () {
    const groups = {
      'a': 'àáâãäåāăą',
      'c': 'çćĉċč',
      'd': 'ď',
      'e': 'èéêëēĕėęě',
      'g': 'ĝğġģ',
      'h': 'ĥ',
      'i': 'ìíîïĩīĭį',
      'j': 'ĵ',
      'k': 'ķ',
      'l': 'ĺļľ',
      'n': 'ñńņňǹ',
      'o': 'òóôõöōŏő',
      'r': 'ŕŗř',
      's': 'śŝşšș',
      't': 'ţťț',
      'u': 'ùúûüũūŭůűų',
      'w': 'ŵ',
      'y': 'ýÿŷ',
      'z': 'źżž',
    };
    return {
      for (final e in groups.entries)
        for (final ch in e.value.split('')) ch: e.key,
    };
  }();
}

/// The metadata of one lite shard doc.
class LiteShardHeader {
  const LiteShardHeader({
    required this.iso2,
    required this.shard,
    required this.shards,
    required this.version,
    this.minScore,
  });

  final String iso2;
  final int shard;
  final int shards;
  final String version;
  final int? minScore;
}

class _Layout {
  const _Layout({required this.index, required this.dicts});
  final Map<String, int> index;
  final List<List<String>?> dicts;
}
