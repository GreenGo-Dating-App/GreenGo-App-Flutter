import 'package:flutter/material.dart';
import '../../domain/entities/video_call.dart';

/// Connection Quality Indicator Widget
class ConnectionQualityIndicator extends StatelessWidget {
  final ConnectionQuality quality;

  const ConnectionQualityIndicator({
    super.key,
    required this.quality,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSignalBars(),
          const SizedBox(width: 6),
          Text(
            _getQualityLabel(),
            style: TextStyle(
              color: _getQualityColor(),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalBars() {
    final activeBars = _getActiveBars();
    final color = _getQualityColor();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        final isActive = index < activeBars;
        final height = 6.0 + (index * 3);
        return Container(
          width: 4,
          height: height,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.white24,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  int _getActiveBars() {
    switch (quality) {
      case ConnectionQuality.excellent:
        return 4;
      case ConnectionQuality.good:
        return 3;
      case ConnectionQuality.fair:
        return 2;
      case ConnectionQuality.poor:
        return 1;
      case ConnectionQuality.veryPoor:
        return 0;
    }
  }

  Color _getQualityColor() {
    switch (quality) {
      case ConnectionQuality.excellent:
        return Colors.green;
      case ConnectionQuality.good:
        return Colors.lightGreen;
      case ConnectionQuality.fair:
        return Colors.orange;
      case ConnectionQuality.poor:
        return Colors.red;
      case ConnectionQuality.veryPoor:
        return Colors.grey;
    }
  }

  String _getQualityLabel() {
    switch (quality) {
      case ConnectionQuality.excellent:
        return 'Excellent';
      case ConnectionQuality.good:
        return 'Good';
      case ConnectionQuality.fair:
        return 'Fair';
      case ConnectionQuality.poor:
        return 'Poor';
      case ConnectionQuality.veryPoor:
        return 'Very Poor';
    }
  }
}
