/// Builds a static Pix "Copia e Cola" payload (Banco Central BR Code, EMV
/// MPM format) for a Pix key, entirely on-device — no PSP, no server. The
/// payer pastes it (or scans the QR of it) in their own bank app and types
/// the amount there; the money moves bank-to-bank and never touches GreenGo.
String pixCopiaECola({
  required String pixKey,
  required String receiverName,
  String receiverCity = '',
}) {
  final name = _emvText(receiverName, 25, fallback: 'GREENGO USER');
  final city = _emvText(receiverCity, 15, fallback: 'BRASIL');

  final payload = StringBuffer()
    ..write(_field('00', '01')) // payload format indicator
    ..write(_field(
        '26', _field('00', 'br.gov.bcb.pix') + _field('01', pixKey)))
    ..write(_field('52', '0000')) // merchant category code
    ..write(_field('53', '986')) // BRL
    ..write(_field('58', 'BR'))
    ..write(_field('59', name))
    ..write(_field('60', city))
    ..write(_field('62', _field('05', '***'))) // txid: none (static)
    ..write('6304'); // CRC field id + length; value appended below

  final s = payload.toString();
  return s + _crc16(s);
}

String _field(String id, String value) =>
    '$id${value.length.toString().padLeft(2, '0')}$value';

/// EMV text fields must be plain ASCII; strip accents and anything else,
/// upper-case, and cap to the spec's max length.
String _emvText(String input, int max, {required String fallback}) {
  const from = 'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖòóôõöÙÚÛÜùúûüÇçÑñ';
  const to = 'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCcNn';
  final buf = StringBuffer();
  for (final ch in input.trim().split('')) {
    final i = from.indexOf(ch);
    buf.write(i >= 0 ? to[i] : ch);
  }
  var out = buf
      .toString()
      .replaceAll(RegExp(r'[^A-Za-z0-9 ]'), '')
      .replaceAll(RegExp(r' +'), ' ')
      .trim()
      .toUpperCase();
  if (out.isEmpty) out = fallback;
  return out.length > max ? out.substring(0, max).trim() : out;
}

/// CRC16-CCITT-FALSE (poly 0x1021, init 0xFFFF), 4 upper-case hex digits.
String _crc16(String data) {
  var crc = 0xFFFF;
  for (final byte in data.codeUnits) {
    crc ^= byte << 8;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) : (crc << 1);
      crc &= 0xFFFF;
    }
  }
  return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
}
