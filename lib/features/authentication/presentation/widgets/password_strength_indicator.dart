import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../generated/app_localizations.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final int strength;

  const PasswordStrengthIndicator({
    super.key,
    required this.strength,
  });

  Color _getStrengthColor() {
    switch (strength) {
      case 0:
      case 1:
        return AppColors.errorRed;
      case 2:
        return AppColors.warningAmber;
      case 3:
      case 4:
        return AppColors.successGreen;
      default:
        return AppColors.textTertiary;
    }
  }

  String _getStrengthLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (strength) {
      case 0:
        return l10n.passwordStrengthVeryWeak;
      case 1:
        return l10n.passwordStrengthWeak;
      case 2:
        return l10n.passwordStrengthFair;
      case 3:
        return l10n.passwordStrengthStrong;
      case 4:
        return l10n.passwordStrengthVeryStrong;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (strength == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength / 4,
                backgroundColor: AppColors.backgroundInput,
                valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor()),
                minHeight: 4,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _getStrengthLabel(context),
              style: TextStyle(
                color: _getStrengthColor(),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.passwordMustContain,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
        const SizedBox(height: 4),
        _buildRequirement(
          context,
          AppLocalizations.of(context)!.atLeast8Characters,
          strength >= 1,
        ),
        _buildRequirement(
          context,
          AppLocalizations.of(context)!.uppercaseLowercase,
          strength >= 2,
        ),
        _buildRequirement(
          context,
          AppLocalizations.of(context)!.atLeastOneNumber,
          strength >= 3,
        ),
        _buildRequirement(
          context,
          AppLocalizations.of(context)!.atLeastOneSpecialChar,
          strength >= 4,
        ),
      ],
    );
  }

  Widget _buildRequirement(BuildContext context, String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: isMet ? AppColors.successGreen : AppColors.textTertiary,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isMet ? AppColors.textPrimary : AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
