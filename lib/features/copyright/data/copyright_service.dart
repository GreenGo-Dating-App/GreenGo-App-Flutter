import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../../generated/app_localizations.dart';

/// Designated copyright agent shown in the app (policy screen): the company
/// postal address exactly as in Terms section 28 (contact). Keep in sync with
/// functions/src/copyright/model.ts AGENT.postalAddress.
const String kCopyrightAgentPostalAddress =
    'Av. Dona Helena Pereira de Moraes, 290, Sao Paulo - SP, 05707-400, Brazil'; // i18n-ignore: postal address (Terms 28)

/// Content a copyright notice is about, pre-filled from a report entry point.
/// [path] is the Firestore path the server disables on acceptance.
@immutable
class CopyrightContentRef {
  const CopyrightContentRef._(this.type, this.path, [this.photoUrl]);

  /// Chat message or media: 1:1, group, event or community chat.
  factory CopyrightContentRef.message(String parent, String parentId, String messageId) =>
      CopyrightContentRef._('message', '$parent/$parentId/messages/$messageId');
  factory CopyrightContentRef.event(String eventId) =>
      CopyrightContentRef._('event', 'events/$eventId');
  factory CopyrightContentRef.experience(String experienceId) =>
      CopyrightContentRef._('experience', 'user_experiences/$experienceId');
  factory CopyrightContentRef.profilePhoto(String userId, String photoUrl) =>
      CopyrightContentRef._('profilePhoto', 'profiles/$userId', photoUrl);

  final String type;
  final String path;
  final String? photoUrl;

  String label(AppLocalizations l) {
    switch (type) {
      case 'event':
        return l.copyrightContentEvent;
      case 'experience':
        return l.copyrightContentExperience;
      case 'profilePhoto':
        return l.copyrightContentProfilePhoto;
      default:
        return l.copyrightContentMessage;
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'path': path,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };
}

/// Result of a notice / counter-notice submission.
enum CopyrightSubmitOutcome { submitted, rateLimited, invalid, alreadySent, failed }

/// Calls a callable with [data]. Abstracted so widget tests need no Firebase.
typedef CopyrightCallable = Future<void> Function(String name, Map<String, dynamic> data);

Future<void> _callFunction(String name, Map<String, dynamic> data) async {
  await FirebaseFunctions.instance
      .httpsCallable(name, options: HttpsCallableOptions(timeout: const Duration(seconds: 60)))
      .call<dynamic>(data);
}

/// A copyright notice about the signed-in user's content (what the rules let
/// the uploader read once an admin acted on it).
@immutable
class CopyrightNoticeView {
  const CopyrightNoticeView({
    required this.id,
    required this.status,
    required this.complainantName,
    required this.complainantEmail,
    required this.work,
    required this.location,
    this.decisionId,
    this.decisionReason,
    this.decidedAt,
    this.restoreAfter,
  });

  factory CopyrightNoticeView.fromMap(String id, Map<String, dynamic> d) {
    DateTime? ts(Object? v) => v is Timestamp ? v.toDate() : null;
    final complainant = (d['complainant'] as Map?) ?? const {};
    final work = (d['work'] as Map?) ?? const {};
    final content = (d['content'] as Map?) ?? const {};
    final decision = (d['decision'] as Map?) ?? const {};
    return CopyrightNoticeView(
      id: id,
      status: (d['status'] as String?) ?? '',
      complainantName: (complainant['name'] as String?) ?? '',
      complainantEmail: (complainant['email'] as String?) ?? '',
      work: (work['description'] as String?) ?? '',
      location: (content['location'] as String?) ?? '',
      decisionId: d['decisionId'] as String?,
      decisionReason: decision['reason'] as String?,
      decidedAt: ts(decision['decidedAt']),
      restoreAfter: ts(d['restoreAfter']),
    );
  }

  final String id;
  final String status;
  final String complainantName;
  final String complainantEmail;
  final String work;
  final String location;
  final String? decisionId;
  final String? decisionReason;
  final DateTime? decidedAt;
  final DateTime? restoreAfter;
}

/// Client side of the copyright notice-and-takedown process
/// (functions/src/copyright). All writes go through callables; reads are the
/// user's own documents (firestore.rules).
class CopyrightService {
  CopyrightService({CopyrightCallable? callable, FirebaseFirestore? firestore})
      : _call = callable ?? _callFunction,
        _firestore = firestore;

  final CopyrightCallable _call;
  final FirebaseFirestore? _firestore;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Future<CopyrightSubmitOutcome> submitNotice(Map<String, dynamic> data) =>
      _submit('submitCopyrightNotice', data);

  Future<CopyrightSubmitOutcome> submitCounterNotice(Map<String, dynamic> data) =>
      _submit('submitCopyrightCounterNotice', data);

  Future<CopyrightSubmitOutcome> _submit(String name, Map<String, dynamic> data) async {
    try {
      await _call(name, data);
      return CopyrightSubmitOutcome.submitted;
    } on FirebaseFunctionsException catch (e) {
      return outcomeFor(e.code);
    } catch (_) {
      return CopyrightSubmitOutcome.failed;
    }
  }

  /// Maps a callable error code to an outcome. Public for tests.
  static CopyrightSubmitOutcome outcomeFor(String code) {
    switch (code) {
      case 'resource-exhausted':
        return CopyrightSubmitOutcome.rateLimited;
      case 'invalid-argument':
        return CopyrightSubmitOutcome.invalid;
      case 'already-exists':
        return CopyrightSubmitOutcome.alreadySent;
      default:
        return CopyrightSubmitOutcome.failed;
    }
  }

  /// Notices about [uid]'s content, newest decision first.
  Stream<List<CopyrightNoticeView>> watchNoticesAboutMe(String uid) => _db
      .collection('copyright_notices')
      .where('targetUid', isEqualTo: uid)
      .where('uploaderVisible', isEqualTo: true)
      .limit(50)
      .snapshots()
      .map((s) {
        final list = [for (final d in s.docs) CopyrightNoticeView.fromMap(d.id, d.data())];
        list.sort((a, b) => (b.decidedAt ?? DateTime(0)).compareTo(a.decidedAt ?? DateTime(0)));
        return list;
      });

  /// Active (not removed, not expired) strikes of [uid].
  Stream<int> watchActiveStrikes(String uid) => _db
      .collection('copyright_strikes')
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((s) {
        final now = DateTime.now();
        return s.docs.where((d) {
          final x = d.data();
          final exp = x['expiresAt'];
          return x['status'] == 'active' && exp is Timestamp && exp.toDate().isAfter(now);
        }).length;
      });
}

/// "/s/ Jane Doe" -> "jane doe": the typed signature must match the name.
String normalizeCopyrightSignature(String s) => s
    .replaceFirst(RegExp(r'^\s*/s/\s*', caseSensitive: false), '')
    .toLowerCase()
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
bool isValidCopyrightEmail(String s) => _emailRe.hasMatch(s.trim());

/// Same character set the server accepts for a phone number.
final RegExp _phoneRe = RegExp(r'^[0-9+().\-\s/xX]{5,40}$');
bool isValidCopyrightPhone(String s) => _phoneRe.hasMatch(s.trim());
