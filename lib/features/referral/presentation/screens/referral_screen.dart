import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/services/referral_service.dart';

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

  late final String _userId;
  String? _code;
  bool _loadingCode = true;
  bool _codeFailed = false;

  /// Created once so a rebuild never re-subscribes (and never flashes back
  /// to an empty state).
  Stream<ReferralStats>? _statsStream;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    if (_userId.isNotEmpty) {
      _statsStream = _service.statsStream(_userId);
    }
    _loadCode();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCode() async {
    if (_userId.isEmpty) {
      setState(() => _loadingCode = false);
      return;
    }
    if (!_loadingCode || _codeFailed) {
      setState(() {
        _loadingCode = true;
        _codeFailed = false;
      });
    }
    try {
      // Bounded: a stalled connection must end in a retry, never a spinner.
      final code = await _service
          .getOrCreateCode(_userId)
          .timeout(ReferralService.requestTimeout);
      if (!mounted) return;
      setState(() {
        _code = code;
        _loadingCode = false;
      });
    } catch (e) {
      debugPrint('ReferralScreen: could not load referral code: $e');
      if (!mounted) return;
      setState(() {
        _loadingCode = false;
        _codeFailed = true;
      });
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
    _snack(l10n.inviteCodeCopied);
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
          else if (_code == null && _codeFailed)
            Column(
              children: [
                Text(
                  l10n.loadErrorCheckConnection,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                TextButton.icon(
                  onPressed: _loadCode,
                  icon: const Icon(Icons.refresh, color: AppColors.richGold),
                  label: Text(
                    l10n.retry,
                    style: const TextStyle(color: AppColors.richGold),
                  ),
                ),
              ],
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
    final statsStream = _statsStream;
    if (statsStream == null) return const SizedBox.shrink();
    return StreamBuilder<ReferralStats>(
      stream: statsStream,
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
              // Short heading; Expanded so a long translation wraps instead
              // of overflowing the row.
              Expanded(
                child: Text(
                  l10n.referralHowItWorksTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Full rules, always wrapped (no maxLines / ellipsis). Numbers come
          // from the server-mirrored constants in ReferralService.
          Text(
            l10n.referralHowItWorks(
              ReferralService.referrerCoinReward,
              ReferralService.referrerMonthlyCap,
            ),
            softWrap: true,
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
