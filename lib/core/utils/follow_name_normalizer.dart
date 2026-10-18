/// Normalizes a person's name for the follow-list PREFIX search, exactly like
/// the server's `normalizeFollowName` (functions/src/social/followNames.ts),
/// which writes `followerNameLower` / `followeeNameLower` on follow edges.
///
/// Server: NFD → drop U+0300–U+036F → NFC → lowercase → collapse whitespace →
/// trim → cap 80. Dart has no Unicode normalization, so [_from]/[_to] is that
/// same NFD fold PRE-COMPUTED (by Node) for every precomposed letter in
/// Latin-1 Supplement, Latin Extended-A/B and Latin Extended Additional
/// (Vietnamese); already-decomposed input has its combining marks dropped.
/// Characters outside those blocks pass through unchanged on both sides.
String normalizeFollowName(String raw) {
  final b = StringBuffer();
  for (final r in raw.runes) {
    if (r >= 0x300 && r <= 0x36F) continue; // combining diacritical marks
    final ch = String.fromCharCode(r);
    final i = r <= 0xFFFF ? _from.indexOf(ch) : -1;
    b.write(i >= 0 ? _to[i] : ch);
  }
  final s = b.toString().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  final runes = s.runes.toList();
  if (runes.length <= _maxLen) return s;
  return String.fromCharCodes(runes.take(_maxLen)).trim();
}

const int _maxLen = 80;

// Generated from Node: ch.normalize('NFD').replace(/[U+0300-U+036F]/g, '')
//   .normalize('NFC') for U+00C0–U+024F and U+1E00–U+1EFF (where it differs).
const String _from =
      'ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝàáâãäåçèéêëìíîïñòóôõöùúûüýÿĀāĂăĄąĆ'
      'ćĈĉĊċČčĎďĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĨĩĪīĬĭĮįİĴĵĶķĹĺĻļĽľŃńŅņŇňŌōŎŏŐő'
      'ŔŕŖŗŘřŚśŜŝŞşŠšŢţŤťŨũŪūŬŭŮůŰűŲųŴŵŶŷŸŹźŻżŽžƠơƯưǍǎǏǐǑǒǓǔǕǖǗǘǙǚǛ'
      'ǜǞǟǠǡǢǣǦǧǨǩǪǫǬǭǮǯǰǴǵǸǹǺǻǼǽǾǿȀȁȂȃȄȅȆȇȈȉȊȋȌȍȎȏȐȑȒȓȔȕȖȗȘșȚțȞȟȦȧ'
      'ȨȩȪȫȬȭȮȯȰȱȲȳḀḁḂḃḄḅḆḇḈḉḊḋḌḍḎḏḐḑḒḓḔḕḖḗḘḙḚḛḜḝḞḟḠḡḢḣḤḥḦḧḨḩḪḫḬḭḮḯ'
      'ḰḱḲḳḴḵḶḷḸḹḺḻḼḽḾḿṀṁṂṃṄṅṆṇṈṉṊṋṌṍṎṏṐṑṒṓṔṕṖṗṘṙṚṛṜṝṞṟṠṡṢṣṤṥṦṧṨṩṪṫ'
      'ṬṭṮṯṰṱṲṳṴṵṶṷṸṹṺṻṼṽṾṿẀẁẂẃẄẅẆẇẈẉẊẋẌẍẎẏẐẑẒẓẔẕẖẗẘẙẛẠạẢảẤấẦầẨẩẪẫẬ'
      'ậẮắẰằẲẳẴẵẶặẸẹẺẻẼẽẾếỀềỂểỄễỆệỈỉỊịỌọỎỏỐốỒồỔổỖỗỘộỚớỜờỞởỠỡỢợỤụỦủỨ'
      'ứỪừỬửỮữỰựỲỳỴỵỶỷỸỹ';
const String _to =
      'AAAAAACEEEEIIIINOOOOOUUUUYaaaaaaceeeeiiiinooooouuuuyyAaAaAaC'
      'cCcCcCcDdEeEeEeEeEeGgGgGgGgHhIiIiIiIiIJjKkLlLlLlNnNnNnOoOoOo'
      'RrRrRrSsSsSsSsTtTtUuUuUuUuUuUuWwYyYZzZzZzOoUuAaIiOoUuUuUuUuU'
      'uAaAaÆæGgKkOoOoƷʒjGgNnAaÆæØøAaAaEeEeIiIiOoOoRrRrUuUuSsTtHhAa'
      'EeOoOoOoOoYyAaBbBbBbCcDdDdDdDdDdEeEeEeEeEeFfGgHhHhHhHhHhIiIi'
      'KkKkKkLlLlLlLlMmMmMmNnNnNnNnOoOoOoOoPpPpRrRrRrRrSsSsSsSsSsTt'
      'TtTtTtUuUuUuUuUuVvVvWwWwWwWwWwXxXxYyZzZzZzhtwyſAaAaAaAaAaAaA'
      'aAaAaAaAaAaEeEeEeEeEeEeEeEeIiIiOoOoOoOoOoOoOoOoOoOoOoOoUuUuU'
      'uUuUuUuUuYyYyYyYy';
