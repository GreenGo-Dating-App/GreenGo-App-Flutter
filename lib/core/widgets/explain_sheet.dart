import 'dart:ui';

import 'package:flutter/material.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../theme/app_glass.dart';

/// Shared frosted-glass bottom-sheet frame used by the in-app explanation
/// widgets ([InfoButton], [LockedReasonSheet], [ConsequenceConfirmSheet]).
///
/// Shows an icon, a title, a short body (plain text and/or bullet lines) and
/// the [actions] row at the bottom. Kept deliberately small: these sheets
/// answer one question ("what is this?", "why can't I?", "what happens if?").
class ExplainSheetFrame extends StatelessWidget {
  const ExplainSheetFrame({
    required this.title,
    required this.actions,
    super.key,
    this.message,
    this.bullets = const <String>[],
    this.icon = Icons.info_outline,
    this.iconColor = AppColors.richGold,
  });

  final String title;
  final String? message;
  final List<String> bullets;
  final IconData icon;
  final Color iconColor;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(
      top: Radius.circular(AppGlass.radiusSheet),
    );
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlass.blurSigma,
          sigmaY: AppGlass.blurSigma,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundCard.withValues(alpha: 0.92),
            borderRadius: radius,
            border: Border.all(color: AppGlass.border),
          ),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textTertiary.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: iconColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (message != null && message!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        message!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                    ],
                    for (final b in bullets) ...[
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 8, right: 10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: iconColor.withValues(alpha: 0.7),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              b,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 22),
                    ...actions,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gold filled primary button used by the explanation sheets.
class ExplainPrimaryButton extends StatelessWidget {
  const ExplainPrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              destructive ? AppColors.errorRed : AppColors.richGold,
          foregroundColor:
              destructive ? AppColors.textPrimary : AppColors.deepBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

/// Secondary text button used by the explanation sheets.
class ExplainSecondaryButton extends StatelessWidget {
  const ExplainSecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(foregroundColor: AppColors.textTertiary),
        child: Text(label),
      ),
    );
  }
}

/// Opens an [ExplainSheetFrame] as a modal bottom sheet.
Future<T?> showExplainSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: builder,
  );
}

/// Localized "Got it" label of the explanation sheets.
String explainGotIt(BuildContext context) =>
    AppLocalizations.of(context)!.xplGotIt;
