import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';

/// Version of the private-content warning text. Bump it (and add it to
/// PRIVATE_CONTENT_WARNING_VERSIONS in
/// functions/src/legal/privateContentWarning.ts) when the wording changes:
/// every user then sees and accepts the warning again.
const String kPrivateContentWarningVersion = 'pcw-1';

/// Where the acceptance is cached on this device (per user and version).
abstract class PrivateContentWarningStore {
  Future<bool> isAccepted(String key);
  Future<void> setAccepted(String key);
}

class SharedPrefsPrivateContentWarningStore
    implements PrivateContentWarningStore {
  @override
  Future<bool> isAccepted(String key) async =>
      (await SharedPreferences.getInstance()).getBool(key) ?? false;

  @override
  Future<void> setAccepted(String key) async =>
      (await SharedPreferences.getInstance()).setBool(key, true);
}

/// Stores the proof server-side (`acknowledgePrivateContentWarning`).
/// Throws on failure: the content must then NOT be opened.
typedef PrivateContentWarningRecorder = Future<void> Function(
    Map<String, Object?> payload);

Future<void> _recordOnServer(Map<String, Object?> payload) async {
  await FirebaseFunctions.instance
      .httpsCallable('acknowledgePrivateContentWarning',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 20)))
      .call<Object?>(payload);
}

/// True when the server holds a proof record for [uid] and [version]
/// (`legal_acknowledgements/{uid}/items`, readable only by its owner).
/// Throws when it cannot be read (offline): the warning is then shown.
typedef PrivateContentWarningServerReader = Future<bool> Function(
    String uid, String version);

Future<bool> _readFromServer(String uid, String version) async {
  final snap = await FirebaseFirestore.instance
      .collection('legal_acknowledgements')
      .doc(uid)
      .collection('items')
      .where('warningVersion', isEqualTo: version)
      .limit(1)
      .get(const GetOptions(source: Source.server))
      .timeout(const Duration(seconds: 8));
  return snap.docs.isNotEmpty;
}

Future<String?> _readAppVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  } catch (_) {
    return null;
  }
}

/// One blocking warning before another user's private content is displayed
/// for the first time (Terms 5.1.0 §16.9(d)): their private photos, private
/// album, and the photos / videos received in 1:1 and group chats. One
/// acceptance covers all of them, once per user per
/// [kPrivateContentWarningVersion] (not once per install: a new device checks
/// the server record first). The content opens only after the server stored
/// the proof.
class PrivateContentWarning {
  PrivateContentWarning({
    PrivateContentWarningStore? store,
    PrivateContentWarningRecorder? recorder,
    PrivateContentWarningServerReader? serverReader,
    String? Function()? currentUid,
    Future<String?> Function()? appVersion,
    this.version = kPrivateContentWarningVersion,
  })  : _store = store ?? SharedPrefsPrivateContentWarningStore(),
        _recorder = recorder ?? _recordOnServer,
        _serverReader = serverReader ?? _readFromServer,
        _currentUid =
            currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid),
        _appVersion = appVersion ?? _readAppVersion;

  static PrivateContentWarning? _instance;
  static PrivateContentWarning get instance =>
      _instance ??= PrivateContentWarning();
  @visibleForTesting
  static set instance(PrivateContentWarning? value) => _instance = value;

  final String version;
  final PrivateContentWarningStore _store;
  final PrivateContentWarningRecorder _recorder;
  final PrivateContentWarningServerReader _serverReader;
  final String? Function() _currentUid;
  final Future<String?> Function() _appVersion;

  /// Users known to have accepted [version] in this session.
  final Set<String> _accepted = <String>{};

  String _key(String uid) => 'private_content_warning_${version}_$uid';

  /// Accepted on this device or on the server. Never throws.
  Future<bool> hasAccepted() async {
    final uid = _currentUid();
    if (uid == null) return false;
    if (_accepted.contains(uid)) return true;
    try {
      if (await _store.isAccepted(_key(uid))) {
        _accepted.add(uid);
        return true;
      }
    } catch (e) {
      debugPrint('[PrivateContentWarning] local read failed: $e');
    }
    try {
      if (await _serverReader(uid, version)) {
        await _remember(uid);
        return true;
      }
    } catch (e) {
      // Offline / unreadable: no proof known, so the warning is shown.
      debugPrint('[PrivateContentWarning] server read failed: $e');
    }
    return false;
  }

  /// Records the acceptance on the server (throws on failure), then caches it.
  Future<void> acknowledge({required String text, required String locale}) async {
    final uid = _currentUid();
    if (uid == null) throw StateError('not signed in');
    await _recorder(<String, Object?>{
      'warningVersion': version,
      'text': text,
      'locale': locale,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase(),
      'appVersion': await _appVersion(),
    });
    await _remember(uid);
  }

  Future<void> _remember(String uid) async {
    _accepted.add(uid);
    try {
      await _store.setAccepted(_key(uid));
    } catch (e) {
      debugPrint('[PrivateContentWarning] local write failed: $e');
    }
  }

  /// True when the content may be shown: already accepted, or the user just
  /// accepted the warning AND the server stored the proof. False on Cancel.
  Future<bool> ensureAccepted(BuildContext context) async {
    if (await hasAccepted()) return true;
    if (!context.mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PrivateContentWarningDialog(service: this),
    );
    return ok ?? false;
  }
}

/// Shorthand for [PrivateContentWarning.ensureAccepted] on the shared
/// instance: `if (!await ensurePrivateContentWarningAccepted(context)) return;`
Future<bool> ensurePrivateContentWarningAccepted(BuildContext context) =>
    PrivateContentWarning.instance.ensureAccepted(context);

/// The warning. Pops true only after [PrivateContentWarning.acknowledge]
/// succeeded; Cancel pops false. A failed save keeps the dialog open with an
/// error so the user can retry.
class PrivateContentWarningDialog extends StatefulWidget {
  const PrivateContentWarningDialog({super.key, required this.service});
  final PrivateContentWarning service;

  /// The exact text shown, hashed into the server proof.
  static String displayedText(AppLocalizations l10n) => [
        l10n.pcwTitle,
        l10n.pcwIntro,
        l10n.pcwForbidden,
        l10n.pcwConsequences,
        l10n.pcwRecorded,
        l10n.pcwCheckbox,
      ].join('\n\n');

  @override
  State<PrivateContentWarningDialog> createState() =>
      _PrivateContentWarningDialogState();
}

class _PrivateContentWarningDialogState
    extends State<PrivateContentWarningDialog> {
  bool _checked = false;
  bool _saving = false;
  bool _failed = false;

  Future<void> _accept() async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.service.acknowledge(
        text: PrivateContentWarningDialog.displayedText(l10n),
        locale: locale,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('[PrivateContentWarning] acknowledge failed: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const body = TextStyle(
        color: AppColors.textSecondary, fontSize: 14, height: 1.45);
    Widget point(IconData icon, String text, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color ?? AppColors.richGold),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: body)),
            ],
          ),
        );
    return PopScope(
      canPop: !_saving,
      child: Dialog(
        backgroundColor: AppColors.backgroundCard,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: AppColors.richGold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(l10n.pcwTitle,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    key: const ValueKey('pcw-scroll'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        point(Icons.lock_outline, l10n.pcwIntro),
                        point(Icons.no_photography_outlined,
                            l10n.pcwForbidden,
                            color: AppColors.errorRed),
                        point(Icons.gavel_outlined, l10n.pcwConsequences,
                            color: AppColors.errorRed),
                        point(Icons.verified_user_outlined, l10n.pcwRecorded),
                      ],
                    ),
                  ),
                ),
                CheckboxListTile(
                  key: const ValueKey('pcw-checkbox'),
                  value: _checked,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _checked = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.richGold,
                  checkColor: AppColors.deepBlack,
                  title: Text(l10n.pcwCheckbox,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
                if (_failed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(l10n.pcwSaveFailed,
                        key: const ValueKey('pcw-error'),
                        style: const TextStyle(
                            color: AppColors.errorRed, fontSize: 13)),
                  ),
                const SizedBox(height: 4),
                // Wraps the buttons onto two lines when a translation is long.
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  overflowAlignment: OverflowBarAlignment.end,
                  spacing: 8,
                  overflowSpacing: 4,
                  children: [
                    TextButton(
                      key: const ValueKey('pcw-cancel'),
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: Text(l10n.cancel,
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                    ),
                    ElevatedButton(
                      key: const ValueKey('pcw-accept'),
                      onPressed: _checked && !_saving ? _accept : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: AppColors.deepBlack,
                        disabledBackgroundColor:
                            AppColors.richGold.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.deepBlack),
                            )
                          : Text(l10n.pcwUnderstand,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
