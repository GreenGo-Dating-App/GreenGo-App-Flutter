import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class AuthTextField extends StatelessWidget {

  const AuthTextField({
    required this.controller, required this.label, super.key,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.fieldKey,
    this.focusNode,
    this.translucent = false,
  });
  /// Calm variant for screens drawn over a background (login): subtle
  /// translucent fill, 1px hairline border, gold only on focus.
  final bool translucent;
  final TextEditingController controller;
  /// Optional: lets a caller react to the field gaining or losing focus (the
  /// registration form uses it to look up the email's entitlement on blur).
  final FocusNode? focusNode;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final TextCapitalization textCapitalization;

  /// Key placed on the inner [TextFormField] rather than on this wrapper, so
  /// `tester.enterText(find.byKey(...))` resolves to the editable itself.
  /// Used by the end-to-end suites; has no effect at runtime.
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    if (translucent) return _buildTranslucent(context);
    return TextFormField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
          ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: enabled ? AppColors.textSecondary : AppColors.textTertiary,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: enabled ? AppColors.richGold : AppColors.textTertiary,
              )
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled ? AppColors.backgroundInput : AppColors.backgroundCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.richGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingM,
        ),
        errorStyle: const TextStyle(
          color: AppColors.errorRed,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTranslucent(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide(color: c, width: w),
        );
    // Gold appears only while focused; otherwise icons/labels stay grey.
    final focusAware = WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.error)) return AppColors.errorRed;
      if (states.contains(WidgetState.focused)) return AppColors.richGold;
      return AppColors.textTertiary;
    });
    return TextFormField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      cursorColor: AppColors.richGold,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textTertiary),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => TextStyle(color: focusAware.resolve(states)),
        ),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        prefixIconColor: focusAware,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: enabled ? 0.05 : 0.03),
        border: border(Colors.white.withValues(alpha: 0.14)),
        enabledBorder: border(Colors.white.withValues(alpha: 0.14)),
        focusedBorder: border(AppColors.richGold, 1.5),
        errorBorder: border(AppColors.errorRed),
        focusedErrorBorder: border(AppColors.errorRed, 1.5),
        disabledBorder: border(Colors.white.withValues(alpha: 0.08)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: 18,
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF8A80), fontSize: 12),
      ),
    );
  }
}
