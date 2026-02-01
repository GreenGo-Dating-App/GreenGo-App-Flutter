import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Enhancement #18: Message Search Bar
/// Search within conversation messages
class MessageSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback? onClose;
  final int? resultCount;
  final int? currentResultIndex;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const MessageSearchBar({
    super.key,
    required this.onSearch,
    this.onClose,
    this.resultCount,
    this.currentResultIndex,
    this.onPrevious,
    this.onNext,
  });

  @override
  State<MessageSearchBar> createState() => _MessageSearchBarState();
}

class _MessageSearchBarState extends State<MessageSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Close button
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.textSecondary,
            ),
            visualDensity: VisualDensity.compact,
          ),
          // Search input
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onSearch,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search messages...',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _controller.clear();
                          widget.onSearch('');
                        },
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.textTertiary,
                          size: 18,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.backgroundInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
          // Results indicator
          if (widget.resultCount != null && _controller.text.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.backgroundInput,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.resultCount == 0
                    ? 'No results'
                    : '${(widget.currentResultIndex ?? 0) + 1}/${widget.resultCount}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            // Navigation buttons
            if (widget.resultCount! > 0) ...[
              IconButton(
                onPressed: widget.onPrevious,
                icon: const Icon(
                  Icons.keyboard_arrow_up,
                  color: AppColors.textSecondary,
                ),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: widget.onNext,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
