import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/phone_verification_service.dart';
import '../utils/phone_verification_gate.dart';

/// Own-profile banner for accounts without a verified phone (owner rule
/// 2026-10-17): "Add your phone number" for new accounts (required), and an
/// OPTIONAL "Add your phone number (optional) - it helps keep your account
/// safe" for accounts created before 16 Oct 2026 (never required). The only
/// place an old account is ever invited. Dismissible: hidden for [snooze]
/// after "Not now" (per device, per account).
class AddPhoneBanner extends StatefulWidget {
  const AddPhoneBanner({required this.userId, super.key});

  final String userId;
  static const Duration snooze = Duration(days: 14);

  @override
  State<AddPhoneBanner> createState() => _AddPhoneBannerState();
}

class _AddPhoneBannerState extends State<AddPhoneBanner> {
  bool _hidden = true;
  // New account (created on/after 16 Oct 2026) = required; older = optional.
  final bool _required = PhoneVerificationService.phoneRequiredNow();

  String get _key => 'phone_banner_snoozed_until_${widget.userId}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (PhoneVerificationService.currentAccountHasPhone() != false) return;
    var snoozed = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final until = prefs.getInt(_key) ?? 0;
      snoozed = until > DateTime.now().millisecondsSinceEpoch;
    } catch (_) {}
    if (mounted) setState(() => _hidden = snoozed);
  }

  Future<void> _dismiss() async {
    setState(() => _hidden = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _key, DateTime.now().add(AddPhoneBanner.snooze).millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<void> _verify() async {
    final ok = await PhoneVerificationGate.showSheet(context);
    if (ok && mounted) setState(() => _hidden = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const ValueKey('add-phone-banner'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.richGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_android, color: AppColors.richGold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _required
                      ? l10n.phoneVerifyBannerTitle
                      : l10n.phoneVerifyBannerTitleOptional,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(_required ? l10n.phoneVerifyBannerBody : l10n.phoneVerifyBannerBodyOptional,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: const ValueKey('add-phone-banner-dismiss'),
                onPressed: _dismiss,
                child: Text(l10n.phoneVerifyDismiss,
                    style: const TextStyle(color: AppColors.textTertiary)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                key: const ValueKey('add-phone-banner-verify'),
                onPressed: _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: Colors.black,
                ),
                child: Text(l10n.phoneVerifyBannerAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
