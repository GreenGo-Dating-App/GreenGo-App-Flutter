import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/services/referral_service.dart';

// TODO(referral-deeplink): auto-redeem a code captured from an install/deep link
// on first run, instead of requiring manual entry below.

/// Glass UI for the referral loop: shows the user's code, a Share action, an
/// invited-count / coins-earned summary, a redemption field and a short
/// "how it works".
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key, this.userId});

  /// Owner user id. Falls back to the signed-in Firebase user when null.
  final String? userId;

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final ReferralService _service = GetIt.instance<ReferralService>();
  final TextEditingController _redeemController = TextEditingController();

  late final String _userId;
  String? _code;
  bool _loadingCode = true;
  bool _redeeming = false;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    _loadCode();
  }

  @override
  void dispose() {
    _redeemController.dispose();
    super.dispose();
  }

  Future<void> _loadCode() async {
    if (_userId.isEmpty) {
      setState(() => _loadingCode = false);
      return;
    }
    try {
      final code = await _service.getOrCreateCode(_userId);
      if (!mounted) return;
      setState(() {
        _code = code;
        _loadingCode = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCode = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.charcoal,
      ),
    );
  }

  Future<void> _shareCode() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _code;
    if (code == null) return;
    // No share_plus dependency — copy an invite message to the clipboard.
    final message = '${l10n.referralShareMessage}\n$code';
    await Clipboard.setData(ClipboardData(text: message));
    _snack(l10n.referralShareCta);
  }

  Future<void> _redeem() async {
    final l10n = AppLocalizations.of(context)!;
    final input = _redeemController.text.trim();
    if (input.isEmpty || _userId.isEmpty || _redeeming) return;

    setState(() => _redeeming = true);
    final success = await _service.redeemCode(
      newUserId: _userId,
      code: input,
    );
    if (!mounted) return;
    setState(() => _redeeming = false);

    if (success) {
      _redeemController.clear();
      _snack(l10n.referralRewardEarned);
    } else {
      _snack(l10n.referralHowItWorks);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.referralTitle),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(l10n),
                const SizedBox(height: 20),
                _buildCodeCard(l10n),
                const SizedBox(height: 16),
                _buildStatsCard(l10n),
                const SizedBox(height: 16),
                _buildRedeemCard(l10n),
                const SizedBox(height: 16),
                _buildHowItWorks(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        const Icon(Icons.card_giftcard, color: AppColors.richGold, size: 48),
        const SizedBox(height: 12),
        Text(
          l10n.referralInviteFriends,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeCard(AppLocalizations l10n) {
    return GlassContainer(
      active: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.referralYourCode,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingCode)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(
                  color: AppColors.richGold,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    _code ?? '------',
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: AppColors.textSecondary),
                  onPressed: _code == null ? null : _shareCode,
                ),
              ],
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _code == null ? null : _shareCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.share),
            label: Text(
              l10n.referralShareCta,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(AppLocalizations l10n) {
    if (_userId.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<ReferralStats>(
      stream: _service.statsStream(_userId),
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final invited = stats?.invitedCount ?? 0;
        final earned = stats?.coinsEarned ?? 0;
        return GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: _statTile(
                  value: '$invited',
                  label: l10n.referralCountLabel,
                  icon: Icons.group,
                ),
              ),
              Container(
                width: 1,
                height: 44,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              Expanded(
                child: _statTile(
                  value: '$earned',
                  label: l10n.referralRewardEarned,
                  icon: Icons.monetization_on,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statTile({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.richGold, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRedeemCard(AppLocalizations l10n) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _redeemController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.referralYourCode,
                    hintStyle: const TextStyle(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _redeeming ? null : _redeem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _redeeming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.deepBlack,
                          ),
                        )
                      : Text(
                          l10n.referralShareCta,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(AppLocalizations l10n) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.richGold, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.referralHowItWorks,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.referralShareMessage,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
