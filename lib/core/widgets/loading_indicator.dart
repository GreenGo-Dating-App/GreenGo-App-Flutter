import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../generated/app_localizations.dart';

/// A loading indicator that shows a CircularProgressIndicator
/// with a random localized message that changes every 3 seconds.
class LoadingIndicator extends StatefulWidget {
  final Color? color;
  final double? strokeWidth;

  const LoadingIndicator({
    super.key,
    this.color,
    this.strokeWidth,
  });

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator> {
  late final Timer _timer;
  int _currentMsgIndex = 0;
  late final List<int> _shuffledIndices;

  List<String> _getLoadingMessages(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return [];
    return [
      l10n.loadingMsg1, l10n.loadingMsg2, l10n.loadingMsg3, l10n.loadingMsg4,
      l10n.loadingMsg5, l10n.loadingMsg6, l10n.loadingMsg7, l10n.loadingMsg8,
      l10n.loadingMsg9, l10n.loadingMsg10, l10n.loadingMsg11, l10n.loadingMsg12,
      l10n.loadingMsg13, l10n.loadingMsg14, l10n.loadingMsg15, l10n.loadingMsg16,
      l10n.loadingMsg17, l10n.loadingMsg18, l10n.loadingMsg19, l10n.loadingMsg20,
      l10n.loadingMsg21, l10n.loadingMsg22, l10n.loadingMsg23, l10n.loadingMsg24,
    ];
  }

  @override
  void initState() {
    super.initState();
    _shuffledIndices = List.generate(24, (i) => i)..shuffle(Random());
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _currentMsgIndex = (_currentMsgIndex + 1) % _shuffledIndices.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _getLoadingMessages(context);
    final color = widget.color ?? Theme.of(context).primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          color: color,
          strokeWidth: widget.strokeWidth ?? 4.0,
        ),
        if (messages.isNotEmpty) ...[
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Padding(
              key: ValueKey<int>(_shuffledIndices[_currentMsgIndex]),
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                messages[_shuffledIndices[_currentMsgIndex] % messages.length],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
