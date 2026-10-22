import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/community_text_guard.dart';

/// Gentle note under the community create/edit fields when the typed text
/// contains dating wording (Apple 4.3(b)). It never blocks saving; the
/// server queues such text for a low-priority admin review.
class CommunityTextWarning extends StatefulWidget {
  const CommunityTextWarning({required this.controllers, super.key});

  /// The fields to watch (name, description, rules...).
  final List<TextEditingController> controllers;

  @override
  State<CommunityTextWarning> createState() => _CommunityTextWarningState();
}

class _CommunityTextWarningState extends State<CommunityTextWarning> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    for (final c in widget.controllers) {
      c.addListener(_check);
    }
    _show = _matches();
  }

  @override
  void didUpdateWidget(CommunityTextWarning old) {
    super.didUpdateWidget(old);
    for (final c in old.controllers) {
      c.removeListener(_check);
    }
    for (final c in widget.controllers) {
      c.addListener(_check);
    }
    _show = _matches();
  }

  @override
  void dispose() {
    for (final c in widget.controllers) {
      c.removeListener(_check);
    }
    super.dispose();
  }

  bool _matches() =>
      hasCommunityDatingWording(widget.controllers.map((c) => c.text));

  void _check() {
    final next = _matches();
    if (next != _show && mounted) setState(() => _show = next);
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    return Container(
      key: const ValueKey('community-text-dating-warning'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.richGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.richGold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.communitiesDatingWordingWarning,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
