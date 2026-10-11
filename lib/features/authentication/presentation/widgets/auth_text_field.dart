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
  /// "Liquid Gold" glass variant for the login screen: uppercase label above
  /// a translucent dark input, 1px gold hairline, bright-gold focus + halo.
  /// [prefixIcon] is not shown in this variant.
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

  Widget _buildTranslucent(BuildContext context) =>
      _GoldGlassField(field: this);
}

/// "Liquid Gold" login field: small uppercase letter-spaced label above a
/// translucent dark input with a 1px gold hairline; on focus the border warms
/// to bright gold and a soft 4px halo fades in over 300 ms.
class _GoldGlassField extends StatefulWidget {
  const _GoldGlassField({required this.field});

  final AuthTextField field;

  @override
  State<_GoldGlassField> createState() => _GoldGlassFieldState();
}

class _GoldGlassFieldState extends State<_GoldGlassField>
    with SingleTickerProviderStateMixin {
  FocusNode? _ownFocus;
  FocusNode get _focus =>
      widget.field.focusNode ?? (_ownFocus ??= FocusNode());

  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _glowCurve =
      CurvedAnimation(parent: _glow, curve: Curves.easeInOut);

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(_GoldGlassField old) {
    super.didUpdateWidget(old);
    final oldNode = old.field.focusNode ?? _ownFocus;
    if (oldNode != _focus) {
      oldNode?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
  }

  void _onFocus() {
    if (!mounted) return;
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final target = _focus.hasFocus ? 1.0 : 0.0;
    if (reduced) {
      _glow.value = target;
    } else {
      _glow.animateTo(target);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.field;
    const radius = BorderRadius.all(Radius.circular(12));
    final idle = AppColors.liquidGoldLight.withValues(alpha: 0.25);
    final focused = AppColors.liquidGoldBright.withValues(alpha: 0.9);
    const errorColor = Color(0xFFFF8A80);

    // The label sits above the field (as in the mock); MergeSemantics folds
    // it into the text field's node so screen readers still announce it.
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Text(
              f.label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.liquidMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.96, // 0.08em
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _glowCurve,
            builder: (context, _) {
              final t = _glowCurve.value;
              final border = _GoldHaloBorder(
                borderRadius: radius,
                borderSide: BorderSide(color: Color.lerp(idle, focused, t)!),
                halo: t,
              );
              return TextFormField(
                key: f.fieldKey,
                controller: f.controller,
                focusNode: _focus,
                obscureText: f.obscureText,
                keyboardType: f.keyboardType,
                validator: f.validator,
                enabled: f.enabled,
                maxLines: f.maxLines,
                textCapitalization: f.textCapitalization,
                textInputAction: f.textInputAction,
                onChanged: f.onChanged,
                onFieldSubmitted: f.onSubmitted,
                cursorColor: AppColors.liquidGoldBright,
                style: const TextStyle(
                  color: AppColors.liquidText,
                  fontSize: 15,
                  height: 1.3,
                ),
                decoration: InputDecoration(
                  hintText: f.hint,
                  hintStyle: const TextStyle(color: AppColors.liquidHint),
                  suffixIcon: f.suffixIcon,
                  suffixIconColor: AppColors.liquidHint,
                  isDense: true,
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.35),
                  constraints: const BoxConstraints(minHeight: 50),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 15,
                  ),
                  // Same border idle and focused: the 300 ms tween above
                  // drives the change, not InputDecorator's own 167 ms one.
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border,
                  disabledBorder: _GoldHaloBorder(
                    borderRadius: radius,
                    borderSide: BorderSide(
                      color: AppColors.liquidGoldLight.withValues(alpha: 0.12),
                    ),
                  ),
                  errorBorder: const _GoldHaloBorder(
                    borderRadius: radius,
                    borderSide: BorderSide(color: errorColor),
                  ),
                  focusedErrorBorder: const _GoldHaloBorder(
                    borderRadius: radius,
                    borderSide: BorderSide(color: errorColor),
                  ),
                  errorStyle: const TextStyle(color: errorColor, fontSize: 12),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Outline border that can also paint a soft gold halo ring just outside the
/// field ([halo] 0 -> 1), like CSS `box-shadow: 0 0 0 4px`.
class _GoldHaloBorder extends OutlineInputBorder {
  const _GoldHaloBorder({
    super.borderRadius,
    super.borderSide,
    this.halo = 0,
  }) : super(gapPadding: 0);

  final double halo;

  @override
  _GoldHaloBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
    double? halo,
  }) =>
      _GoldHaloBorder(
        borderSide: borderSide ?? this.borderSide,
        borderRadius: borderRadius ?? this.borderRadius,
        halo: halo ?? this.halo,
      );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is _GoldHaloBorder) {
      return _GoldHaloBorder(
        borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        halo: a.halo + (halo - a.halo) * t,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is _GoldHaloBorder) {
      return _GoldHaloBorder(
        borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        halo: halo + (b.halo - halo) * t,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (halo > 0) {
      canvas.drawRRect(
        borderRadius.toRRect(rect).inflate(2.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = AppColors.liquidGoldLight.withValues(alpha: 0.14 * halo),
      );
    }
    super.paint(
      canvas,
      rect,
      gapStart: gapStart,
      gapExtent: gapExtent,
      gapPercentage: gapPercentage,
      textDirection: textDirection,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _GoldHaloBorder && other.halo == halo && super == other;

  @override
  int get hashCode => Object.hash(super.hashCode, halo);
}
