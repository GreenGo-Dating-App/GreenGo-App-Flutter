/// Anti-scam: off-platform contact / payment info in user text.
///
/// 1:1 mirror of `findContactInfo` in functions/src/user_experiences/
/// moderation.ts (the server re-checks every write; this only saves the user a
/// rejected submit). Both are tested against the SAME fixture:
/// functions/__tests__/fixtures/contact_info_cases.json. KEEP BOTH IN SYNC.
///
/// Blocked in experience text (title, description, included / not included,
/// meeting point, availability, cancellation notes) and in review / reply
/// text. The experience's payment link field is exempt.
enum ContactKind { phone, email, pixKey, handle, paymentPhrase }

class ContactInfoDetector {
  const ContactInfoDetector._();

  static final RegExp _email = RegExp(
      r'[a-z0-9._%+-]+@[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z]{2,}',
      caseSensitive: false);

  /// 9+ digits joined only by spaces, dots, dashes or parentheses.
  static final RegExp _phone = RegExp(r'(?:\+\s*)?\d(?:[\s().-]{0,3}\d){8,}');

  /// CNPJ (the slash breaks the phone rule).
  static final RegExp _cnpj = RegExp(r'\b\d{2}\.?\d{3}\.?\d{3}/\d{4}-?\d{2}\b');

  /// PIX random key (UUID shape).
  static final RegExp _uuid = RegExp(
      r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b',
      caseSensitive: false);

  /// @handle, not an e-mail.
  static final RegExp _handle =
      RegExp(r'(?:^|[\s(,;:])@[a-z0-9_][a-z0-9_.]{2,}', caseSensitive: false);

  static const List<String> _phrases = [
    'whatsapp', 'whats app', 'wa.me', 'telegram', 't.me/', 'signal me',
    'pay me', 'paga-me', 'me paga', 'me pague', 'pague-me', 'pagame', 'págame',
    'pagami', 'paie-moi', 'payez-moi', 'bezahl mich', 'zahl mir',
    'paypal.me', '@paypal', 'venmo.com', 'cash.app', 'cashapp', 'zelle',
    'western union', 'chave pix', 'pix key', 'clé pix', 'clave pix', 'iban',
  ];

  /// Kinds found in [text]; empty when clean.
  static Set<ContactKind> find(String? text) {
    final out = <ContactKind>{};
    if (text == null || text.trim().isEmpty) return out;
    final lower = text.toLowerCase();
    if (_email.hasMatch(text)) out.add(ContactKind.email);
    if (_phone.hasMatch(text)) out.add(ContactKind.phone);
    if (_cnpj.hasMatch(text) || _uuid.hasMatch(text)) out.add(ContactKind.pixKey);
    if (_handle.hasMatch(text.replaceAll(_email, ' '))) {
      out.add(ContactKind.handle);
    }
    if (_phrases.any(lower.contains)) out.add(ContactKind.paymentPhrase);
    return out;
  }

  static bool contains(String? text) => find(text).isNotEmpty;

  /// Wire name used by the server / fixture (snake_case).
  static String wireName(ContactKind k) => switch (k) {
        ContactKind.phone => 'phone',
        ContactKind.email => 'email',
        ContactKind.pixKey => 'pix_key',
        ContactKind.handle => 'handle',
        ContactKind.paymentPhrase => 'payment_phrase',
      };
}
