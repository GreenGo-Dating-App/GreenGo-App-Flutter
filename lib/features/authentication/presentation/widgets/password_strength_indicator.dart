import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';

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

  String _getStrengthLabel() {
    return Validators.getPasswordStrengthLabel(strength);
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
              _getStrengthLabel(),
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
          'Password must contain:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
        const SizedBox(height: 4),
        _buildRequirement(
          'At least 8 characters',
          strength >= 1,
        ),
        _buildRequirement(
          'Uppercase and lowercase letters',
          strength >= 2,
        ),
        _buildRequirement(
          'At least one number',
          strength >= 3,
        ),
        _buildRequirement(
          'At least one special character',
          strength >= 4,
        ),
      ],
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
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
