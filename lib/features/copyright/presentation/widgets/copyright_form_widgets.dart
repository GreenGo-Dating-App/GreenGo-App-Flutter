import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Shared building blocks of the copyright notice / counter-notice forms.

const TextStyle copyrightBodyStyle = TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.45);
const TextStyle copyrightLabelStyle = TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600);

class CopyrightSectionTitle extends StatelessWidget {
  const CopyrightSectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 8),
        child: Text(text, style: const TextStyle(color: AppColors.richGold, fontSize: 16, fontWeight: FontWeight.w700)),
      );
}

class CopyrightField extends StatelessWidget {
  const CopyrightField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    super.key,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.readOnly = false,
  });

  final String fieldKey;
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool readOnly;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          key: ValueKey(fieldKey),
          controller: controller,
          validator: validator,
          readOnly: readOnly,
          maxLines: maxLines,
          minLines: 1,
          keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
          style: TextStyle(color: readOnly ? AppColors.textSecondary : AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.backgroundInput,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      );
}

class CopyrightStatement extends StatelessWidget {
  const CopyrightStatement({
    required this.fieldKey,
    required this.text,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String fieldKey;
  final String text;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
        key: ValueKey(fieldKey),
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        activeColor: AppColors.richGold,
        title: Text('$text *', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4)),
      );
}

class CopyrightWarning extends StatelessWidget {
  const CopyrightWarning({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warningAmber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warningAmber.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warningAmber),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4))),
          ],
        ),
      );
}

class CopyrightInfoCard extends StatelessWidget {
  const CopyrightInfoCard({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.backgroundCard, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            const Icon(Icons.copyright, color: AppColors.richGold),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))),
          ],
        ),
      );
}
