import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Styled text input for game answers
class AnswerInput extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onSubmitted;
  final bool enabled;
  final bool autofocus;
  final TextInputAction textInputAction;

  const AnswerInput({
    super.key,
    this.hintText = 'Type your answer...',
    required this.onSubmitted,
    this.enabled = true,
    this.autofocus = true,
    this.textInputAction = TextInputAction.send,
  });

  @override
  State<AnswerInput> createState() => _AnswerInputState();
}

class _AnswerInputState extends State<AnswerInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmitted(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                textInputAction: widget.textInputAction,
                onSubmitted: (_) => _submit(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundInput,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppColors.richGold,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: widget.enabled ? AppColors.richGold : AppColors.divider,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: widget.enabled ? _submit : null,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.send_rounded,
                    color: AppColors.backgroundDark,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
