import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/services/age_assurance_service.dart';
import 'age_verification_screen.dart';

/// "Verify your age to use this feature" (P3-1 regional age assurance).
///
/// Shown in place of people discovery, and before a NEW private conversation,
/// for users in a region that requires strong age assurance who have none.
/// Offers what the platform has: the store age signal (Google Play / App
/// Store; not on the web) and the existing ID-document verification. The rest
/// of the app keeps working, and conversations the user already wrote in stay
/// usable. No parental tools: minors are blocked entirely at sign-up.
class AgeAssuranceRequiredPanel extends StatefulWidget {
  const AgeAssuranceRequiredPanel({
    super.key,
    this.onSatisfied,
    this.service,
    this.platform,
  });

  /// Called once assurance is satisfied.
  final VoidCallback? onSatisfied;
  final AgeAssuranceService? service;

  /// Overrides the detected platform (tests).
  final AgeAssurancePlatform? platform;

  @override
  State<AgeAssuranceRequiredPanel> createState() =>
      _AgeAssuranceRequiredPanelState();
}

class _AgeAssuranceRequiredPanelState extends State<AgeAssuranceRequiredPanel> {
  bool _busy = false;
  String? _message;

  AgeAssuranceService get _service =>
      widget.service ?? AgeAssuranceService.instance;
  AgeAssurancePlatform get _platform =>
      widget.platform ?? currentAgeAssurancePlatform();

  Future<void> _afterAttempt() async {
    final s = await _service.status(refresh: true);
    if (!mounted) return;
    if (!s.blocked) widget.onSatisfied?.call();
  }

  Future<void> _storeCheck() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _message = null;
    });
    final outcome = await _service.checkStoreSignal();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = switch (outcome) {
        StoreSignalOutcome.accepted => l10n.ageAssuranceVerified,
        StoreSignalOutcome.underage => l10n.ageVerifyRejectedUnderage,
        _ => l10n.ageAssuranceStoreUnavailable,
      };
    });
    if (outcome == StoreSignalOutcome.accepted) await _afterAttempt();
  }

  Future<void> _idCheck() async {
    await AgeVerificationScreen.push(
      context,
      reason: AgeVerificationReason.regionalAssurance,
    );
    if (!mounted) return;
    _service.invalidate();
    await _afterAttempt();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const status = AgeAssuranceStatus(
      enforced: true,
      required: true,
      satisfied: false,
    );
    final options = status.optionsFor(_platform);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.verified_user_outlined,
                  size: 56, color: AppColors.richGold),
              const SizedBox(height: 20),
              Text(
                l10n.ageAssuranceTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.ageAssuranceBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.ageAssuranceExistingChats,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              if (options.contains(AgeAssuranceMethod.storeSignal)) ...[
                ElevatedButton.icon(
                  key: const Key('ageAssuranceStoreButton'),
                  onPressed: _busy ? null : _storeCheck,
                  icon: const Icon(Icons.storefront_outlined),
                  label: Text(_platform == AgeAssurancePlatform.ios
                      ? l10n.ageAssuranceStoreCheckIos
                      : l10n.ageAssuranceStoreCheckAndroid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.ageAssuranceStoreHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
              ],
              if (options.contains(AgeAssuranceMethod.idVerification))
                OutlinedButton.icon(
                  key: const Key('ageAssuranceIdButton'),
                  onPressed: _busy ? null : _idCheck,
                  icon: const Icon(Icons.badge_outlined),
                  label: Text(l10n.ageAssuranceIdOption),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.richGold,
                    side: const BorderSide(color: AppColors.richGold),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              if (_platform == AgeAssurancePlatform.web) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.ageAssuranceWebNote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
              if (_busy) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen route around [AgeAssuranceRequiredPanel]; pops `true` once
/// assurance is satisfied.
class AgeAssuranceRequiredScreen extends StatelessWidget {
  const AgeAssuranceRequiredScreen({super.key});

  static Future<bool> push(BuildContext context) async {
    final r = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AgeAssuranceRequiredScreen()),
    );
    return r ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: AgeAssuranceRequiredPanel(
          onSatisfied: () => Navigator.of(context).pop(true),
        ),
      ),
    );
  }
}

/// Shows [child] unless discovery is closed for this user, in which case the
/// gate panel is shown in its place. While the status loads the child is shown
/// (fail open; the data layer returns nothing to a gated user anyway).
class AgeAssuranceGateView extends StatefulWidget {
  const AgeAssuranceGateView({super.key, required this.child, this.service});

  final Widget child;
  final AgeAssuranceService? service;

  @override
  State<AgeAssuranceGateView> createState() => _AgeAssuranceGateViewState();
}

class _AgeAssuranceGateViewState extends State<AgeAssuranceGateView> {
  bool _blocked = false;

  AgeAssuranceService get _service =>
      widget.service ?? AgeAssuranceService.instance;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check({bool refresh = false}) async {
    final s = await _service.status(refresh: refresh);
    if (mounted && s.blocked != _blocked) setState(() => _blocked = s.blocked);
  }

  @override
  Widget build(BuildContext context) {
    if (!_blocked) return widget.child;
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: canPop
          ? AppBar(backgroundColor: AppColors.backgroundDark, elevation: 0)
          : null,
      body: SafeArea(
        child: AgeAssuranceRequiredPanel(
          service: _service,
          onSatisfied: () => _check(refresh: true),
        ),
      ),
    );
  }
}

/// Call-site guards for private 1:1 messaging.
class AgeAssuranceGuard {
  const AgeAssuranceGuard._();

  /// Before creating a NEW conversation. Returns true when allowed (possibly
  /// after the user verified on the gate screen).
  static Future<bool> ensureCanStartConversation(BuildContext context,
      {AgeAssuranceService? service}) async {
    final s = service ?? AgeAssuranceService.instance;
    if (!await s.isBlocked()) return true;
    if (!context.mounted) return false;
    return AgeAssuranceRequiredScreen.push(context);
  }

  /// Before sending in an existing conversation: allowed when not gated, or
  /// when the user has already written in it ([alreadyWrote] short-cuts the
  /// lookup when the loaded messages show it).
  static Future<bool> ensureCanSend(
    BuildContext context, {
    required String? conversationId,
    required String userId,
    bool alreadyWrote = false,
    AgeAssuranceService? service,
  }) async {
    final s = service ?? AgeAssuranceService.instance;
    if (!await s.isBlocked()) return true;
    if (alreadyWrote) return true;
    if (conversationId != null &&
        conversationId.isNotEmpty &&
        await s.hasWrittenIn(conversationId, userId)) {
      return true;
    }
    if (!context.mounted) return false;
    return AgeAssuranceRequiredScreen.push(context);
  }
}
