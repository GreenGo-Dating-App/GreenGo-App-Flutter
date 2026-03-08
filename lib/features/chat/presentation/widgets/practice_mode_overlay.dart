import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/chat_learning_service.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../membership/domain/entities/membership.dart';

/// Practice Mode Overlay Widget
///
/// Provides an AI-powered language learning overlay within the chat experience.
/// When enabled, a collapsible bottom panel shows vocabulary suggestions,
/// grammar corrections, and language tips based on the conversation context.
///
/// Gate: Only available for Silver/Gold/Platinum/Test tier members, or a
/// 30-minute free trial for free-tier users.
///
/// Usage:
/// ```dart
/// // Toggle button in app bar:
/// PracticeModeToggle(
///   isActive: _practiceModeActive,
///   onToggle: (active) => setState(() => _practiceModeActive = active),
///   membershipTier: currentUserProfile.membershipTier,
///   userId: currentUserId,
/// )
///
/// // Overlay panel at bottom of chat:
/// PracticeModeOverlay(
///   isActive: _practiceModeActive,
///   partnerLanguages: otherUserProfile.languages,
///   userNativeLanguage: currentUserProfile.nativeLanguage,
///   lastMessages: recentMessages,
///   onClose: () => setState(() => _practiceModeActive = false),
/// )
/// ```
class PracticeModeToggle extends StatelessWidget {
  /// Whether practice mode is currently active
  final bool isActive;

  /// Callback to toggle practice mode on/off
  final ValueChanged<bool> onToggle;

  /// Current user's membership tier (for gating)
  final MembershipTier membershipTier;

  /// Current user's ID
  final String userId;

  const PracticeModeToggle({
    super.key,
    required this.isActive,
    required this.onToggle,
    required this.membershipTier,
    required this.userId,
  });

  /// Check if the user can access practice mode
  bool get _hasAccess {
    return membershipTier == MembershipTier.silver ||
        membershipTier == MembershipTier.gold ||
        membershipTier == MembershipTier.platinum ||
        membershipTier == MembershipTier.test;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleToggle(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.richGold.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: isActive
                ? AppColors.richGold.withValues(alpha: 0.5)
                : AppColors.divider,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.school : Icons.school_outlined,
              size: 16,
              color: isActive ? AppColors.richGold : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context)!.chatPractice,
              style: TextStyle(
                color:
                    isActive ? AppColors.richGold : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleToggle(BuildContext context) async {
    HapticFeedback.selectionClick();

    if (isActive) {
      // Turning off is always allowed
      onToggle(false);
      return;
    }

    // Check membership access
    if (_hasAccess) {
      onToggle(true);
      return;
    }

    // Free tier: check if trial is available or active
    final trialStatus = await _checkTrialStatus();

    if (!context.mounted) return;

    switch (trialStatus) {
      case _TrialStatus.available:
        // Start the trial
        await _startTrial();
        if (context.mounted) {
          onToggle(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.chatPracticeTrialStarted,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              backgroundColor: AppColors.backgroundCard,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        break;

      case _TrialStatus.active:
        onToggle(true);
        break;

      case _TrialStatus.expired:
        _showUpgradeDialog(context);
        break;
    }
  }

  Future<_TrialStatus> _checkTrialStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('features')
          .doc('practice_mode_trial')
          .get();

      if (!doc.exists) return _TrialStatus.available;

      final data = doc.data()!;
      final startedAt = (data['startedAt'] as Timestamp?)?.toDate();
      if (startedAt == null) return _TrialStatus.available;

      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed.inMinutes < 30) {
        return _TrialStatus.active;
      } else {
        return _TrialStatus.expired;
      }
    } catch (e) {
      // On error, be permissive and allow access
      return _TrialStatus.available;
    }
  }

  Future<void> _startTrial() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('features')
          .doc('practice_mode_trial')
          .set({
        'startedAt': FieldValue.serverTimestamp(),
        'tier': membershipTier.value,
      });
    } catch (e) {
      // Silently fail - trial tracking is best-effort
    }
  }

  void _showUpgradeDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        title: Row(
          children: [
            const Icon(Icons.school, color: AppColors.richGold, size: 24),
            const SizedBox(width: 8),
            Text(
              l10n.chatPracticeMode,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.chatTrialExpired,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.chatUpgradePracticeMode,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _FeatureRow(icon: Icons.auto_awesome, text: l10n.chatFeatureVocabulary),
            const SizedBox(height: 6),
            _FeatureRow(icon: Icons.spellcheck, text: l10n.chatFeatureGrammar),
            const SizedBox(height: 6),
            _FeatureRow(icon: Icons.lightbulb_outline, text: l10n.chatFeatureCulturalTips),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n.chatMaybeLater,
              style: const TextStyle(color: AppColors.textTertiary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Navigate to membership screen — consumer decides how
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
            ),
            child: Text(
              l10n.chatUpgrade,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature row used in upgrade dialog
class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.richGold),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// Trial status for free-tier users
enum _TrialStatus { available, active, expired }

/// Practice Mode Overlay Panel
///
/// The collapsible bottom panel that shows AI language tips during chat.
/// Slides up from the bottom and can be collapsed to a minimal bar.
class PracticeModeOverlay extends StatefulWidget {
  /// Whether practice mode is currently active
  final bool isActive;

  /// The partner's spoken languages
  final List<String> partnerLanguages;

  /// The user's native language
  final String? userNativeLanguage;

  /// Recent messages for context (last 5-10 messages)
  final List<String> lastMessages;

  /// Callback to close practice mode
  final VoidCallback onClose;

  /// Current user's membership tier (for trial countdown)
  final MembershipTier membershipTier;

  /// Current user's ID (for trial status check)
  final String userId;

  const PracticeModeOverlay({
    super.key,
    required this.isActive,
    this.partnerLanguages = const [],
    this.userNativeLanguage,
    this.lastMessages = const [],
    required this.onClose,
    this.membershipTier = MembershipTier.free,
    this.userId = '',
  });

  @override
  State<PracticeModeOverlay> createState() => _PracticeModeOverlayState();
}

class _PracticeModeOverlayState extends State<PracticeModeOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final ChatLearningService _learningService = ChatLearningService();

  bool _isCollapsed = false;
  List<_LanguageTip> _tips = [];
  bool _isLoadingTips = false;
  Timer? _trialTimer;
  Duration _trialRemaining = Duration.zero;
  bool _isTrialUser = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    if (widget.isActive) {
      _slideController.forward();
      _loadTips();
      _checkTrialStatus();
    }
  }

  @override
  void didUpdateWidget(PracticeModeOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _slideController.forward();
      _loadTips();
      _checkTrialStatus();
    } else if (!widget.isActive && oldWidget.isActive) {
      _slideController.reverse();
      _trialTimer?.cancel();
    }
    // Reload tips when messages change
    if (widget.isActive &&
        widget.lastMessages.length != oldWidget.lastMessages.length) {
      _loadTips();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _trialTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkTrialStatus() async {
    final isFree = widget.membershipTier == MembershipTier.free;
    if (!isFree) {
      setState(() => _isTrialUser = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('features')
          .doc('practice_mode_trial')
          .get();

      if (!doc.exists || !mounted) return;

      final data = doc.data()!;
      final startedAt = (data['startedAt'] as Timestamp?)?.toDate();
      if (startedAt == null) return;

      final elapsed = DateTime.now().difference(startedAt);
      final remaining = const Duration(minutes: 30) - elapsed;

      if (remaining.isNegative) {
        // Trial expired — close practice mode
        widget.onClose();
        return;
      }

      setState(() {
        _isTrialUser = true;
        _trialRemaining = remaining;
      });

      // Start countdown timer
      _trialTimer?.cancel();
      _trialTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _trialRemaining -= const Duration(seconds: 1);
          if (_trialRemaining.isNegative) {
            timer.cancel();
            widget.onClose();
          }
        });
      });
    } catch (e) {
      // Silently fail
    }
  }

  /// Load AI language tips based on conversation context
  Future<void> _loadTips() async {
    if (_isLoadingTips) return;
    setState(() => _isLoadingTips = true);

    try {
      final tips = <_LanguageTip>[];
      final partnerLang = widget.partnerLanguages.isNotEmpty
          ? widget.partnerLanguages.first
          : 'en';

      // Try to generate AI-powered tips from conversation context
      if (widget.lastMessages.isNotEmpty) {
        final lastMsg = widget.lastMessages.last;

        // Vocabulary tip from word breakdown
        try {
          final breakdown = await _learningService.getWordBreakdown(lastMsg, partnerLang, 'en');
          if (breakdown.isNotEmpty) {
            final words = breakdown.take(3).map((w) => '${w['word']} = ${w['translation']}').join(', ');
            tips.add(_LanguageTip(
              type: _TipType.vocabulary,
              title: 'Words from chat',
              content: words,
              icon: Icons.auto_awesome,
            ));
          }
        } catch (_) {}

        // Difficulty assessment
        try {
          final difficulty = await _learningService.getMessageDifficulty(lastMsg, partnerLang);
          tips.add(_LanguageTip(
            type: _TipType.vocabulary,
            title: 'Message level',
            content: 'Last message is CEFR level $difficulty. Keep chatting to improve!',
            icon: Icons.trending_up,
          ));
        } catch (_) {}

        // Grammar tip
        try {
          final grammar = await _learningService.checkGrammar(lastMsg, partnerLang);
          if (grammar != null && grammar['hasErrors'] == true) {
            tips.add(_LanguageTip(
              type: _TipType.grammar,
              title: 'Grammar note',
              content: '${grammar['explanation']}',
              icon: Icons.spellcheck,
            ));
          }
        } catch (_) {}

        // Cultural context
        try {
          final cultural = await _learningService.getCulturalTooltip(lastMsg, partnerLang);
          if (cultural != null) {
            tips.add(_LanguageTip(
              type: _TipType.cultural,
              title: 'Cultural insight',
              content: cultural,
              icon: Icons.lightbulb_outline,
            ));
          }
        } catch (_) {}
      }

      // Fallback to generic tips if no AI tips generated
      if (tips.isEmpty) {
        final partnerLangName = widget.partnerLanguages.isNotEmpty
            ? widget.partnerLanguages.first
            : 'their language';
        tips.add(_LanguageTip(
          type: _TipType.vocabulary,
          title: 'Useful phrases',
          content: 'Try saying "Nice to meet you" in $partnerLangName to make a great first impression.',
          icon: Icons.auto_awesome,
        ));
        tips.add(_LanguageTip(
          type: _TipType.grammar,
          title: 'Grammar tip',
          content: 'When chatting in $partnerLangName, remember to match adjective gender with the noun.',
          icon: Icons.spellcheck,
        ));
        tips.add(_LanguageTip(
          type: _TipType.cultural,
          title: 'Cultural context',
          content: "In many cultures, asking about someone's day is a warm way to start a conversation.",
          icon: Icons.lightbulb_outline,
        ));
      }

      if (mounted) {
        setState(() {
          _tips = tips;
          _isLoadingTips = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTips = false);
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusL),
          ),
          border: Border(
            top: BorderSide(
              color: AppColors.richGold.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar and header
            _buildHeader(),

            // Collapsible content
            if (!_isCollapsed) _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _isCollapsed = !_isCollapsed);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.school,
                  size: 18,
                  color: AppColors.richGold,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.chatPracticeMode,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // Trial countdown for free users
                if (_isTrialUser) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _trialRemaining.inMinutes < 5
                          ? AppColors.errorRed.withValues(alpha: 0.15)
                          : AppColors.warningAmber.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: _trialRemaining.inMinutes < 5
                              ? AppColors.errorRed
                              : AppColors.warningAmber,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatDuration(_trialRemaining),
                          style: TextStyle(
                            color: _trialRemaining.inMinutes < 5
                                ? AppColors.errorRed
                                : AppColors.warningAmber,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Collapse/expand indicator
                Icon(
                  _isCollapsed
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.textTertiary,
                ),

                const SizedBox(width: 4),

                // Close button
                GestureDetector(
                  onTap: widget.onClose,
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoadingTips) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.richGold,
            ),
          ),
        ),
      );
    }

    if (_tips.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          AppLocalizations.of(context)!.chatSendMessagesForTips,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 180),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        itemCount: _tips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final tip = _tips[index];
          return _TipCard(tip: tip);
        },
      ),
    );
  }
}

/// Individual tip card
class _TipCard extends StatelessWidget {
  final _LanguageTip tip;

  const _TipCard({required this.tip});

  Color get _accentColor {
    switch (tip.type) {
      case _TipType.vocabulary:
        return AppColors.richGold;
      case _TipType.grammar:
        return AppColors.infoBlue;
      case _TipType.cultural:
        return AppColors.successGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border(
          left: BorderSide(color: _accentColor, width: 2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(tip.icon, size: 16, color: _accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tip.content,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tip type enum
enum _TipType { vocabulary, grammar, cultural }

/// Language tip data model
class _LanguageTip {
  final _TipType type;
  final String title;
  final String content;
  final IconData icon;

  _LanguageTip({
    required this.type,
    required this.title,
    required this.content,
    required this.icon,
  });
}
