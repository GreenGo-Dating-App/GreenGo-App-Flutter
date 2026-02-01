import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';

/// Chat safety introduction dialog shown on first chat open
/// Provides important safety tips for users before chatting
class ChatSafetyIntroDialog extends StatelessWidget {
  final VoidCallback onDismiss;

  const ChatSafetyIntroDialog({
    super.key,
    required this.onDismiss,
  });

  static const String _prefKey = 'has_seen_chat_safety_intro';

  /// Check if the user has seen the safety intro
  static Future<bool> hasSeenIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  /// Mark the safety intro as seen
  static Future<void> markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  /// Show the safety dialog if not seen before
  static Future<void> showIfNeeded(BuildContext context) async {
    final hasSeen = await hasSeenIntro();
    if (!hasSeen && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ChatSafetyIntroDialog(
          onDismiss: () {
            markAsSeen();
            Navigator.of(context).pop();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.gold.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.gold.withOpacity(0.2),
                    AppColors.gold.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security,
                      color: AppColors.gold,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.chatSafetyTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.chatSafetySubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Safety Tips
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSafetyTip(
                    Icons.lock_outline,
                    l10n.chatSafetyTip1Title,
                    l10n.chatSafetyTip1Description,
                  ),
                  const SizedBox(height: 16),
                  _buildSafetyTip(
                    Icons.money_off,
                    l10n.chatSafetyTip2Title,
                    l10n.chatSafetyTip2Description,
                  ),
                  const SizedBox(height: 16),
                  _buildSafetyTip(
                    Icons.place_outlined,
                    l10n.chatSafetyTip3Title,
                    l10n.chatSafetyTip3Description,
                  ),
                  const SizedBox(height: 16),
                  _buildSafetyTip(
                    Icons.psychology_outlined,
                    l10n.chatSafetyTip4Title,
                    l10n.chatSafetyTip4Description,
                  ),
                  const SizedBox(height: 16),
                  _buildSafetyTip(
                    Icons.flag_outlined,
                    l10n.chatSafetyTip5Title,
                    l10n.chatSafetyTip5Description,
                  ),
                ],
              ),
            ),

            // Got It Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.chatSafetyGotIt,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTip(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.gold,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
