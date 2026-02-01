import 'package:flutter/material.dart';
import '../../domain/entities/conversation_expiry.dart';

/// Widget to display conversation expiry countdown
class ExpiryTimerWidget extends StatelessWidget {
  final ConversationExpiry expiry;
  final VoidCallback? onExtend;
  final bool showExtendButton;
  final bool compact;

  const ExpiryTimerWidget({
    super.key,
    required this.expiry,
    this.onExtend,
    this.showExtendButton = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    final color = _getStatusColor(expiry.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(expiry.status),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            expiry.formattedTimeRemaining,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    final color = _getStatusColor(expiry.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getStatusIcon(expiry.status),
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getStatusTitle(expiry.status),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Text(
                expiry.formattedTimeRemaining,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 1 - expiry.expiryProgress,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          if (expiry.canExtend && showExtendButton) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${expiry.remainingExtensions} extensions left',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onExtend,
                  icon: const Icon(Icons.add_alarm, size: 16),
                  label: Text('Extend (${ExpiryConfig.extensionCost} coins)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.active:
        return Colors.green;
      case ExpiryStatus.warning:
        return Colors.orange;
      case ExpiryStatus.critical:
        return Colors.red;
      case ExpiryStatus.expired:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.active:
        return Icons.timer;
      case ExpiryStatus.warning:
        return Icons.warning_amber;
      case ExpiryStatus.critical:
        return Icons.alarm;
      case ExpiryStatus.expired:
        return Icons.timer_off;
    }
  }

  String _getStatusTitle(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.active:
        return 'Time remaining';
      case ExpiryStatus.warning:
        return 'Expiring soon!';
      case ExpiryStatus.critical:
        return 'Almost expired!';
      case ExpiryStatus.expired:
        return 'Expired';
    }
  }
}

/// Badge showing expiry count for conversations
class ExpiryBadge extends StatelessWidget {
  final int expiringSoonCount;
  final VoidCallback? onTap;

  const ExpiryBadge({
    super.key,
    required this.expiringSoonCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (expiringSoonCount == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timer,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              '$expiringSoonCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List item for expiring conversation
class ExpiringConversationItem extends StatelessWidget {
  final ConversationExpiry expiry;
  final String matchName;
  final String? matchPhoto;
  final VoidCallback? onTap;
  final VoidCallback? onExtend;

  const ExpiringConversationItem({
    super.key,
    required this.expiry,
    required this.matchName,
    this.matchPhoto,
    this.onTap,
    this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(expiry.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundImage:
                    matchPhoto != null ? NetworkImage(matchPhoto!) : null,
                child: matchPhoto == null
                    ? Text(matchName.isNotEmpty ? matchName[0].toUpperCase() : '?')
                    : null,
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      matchName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 14,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          expiry.formattedTimeRemaining,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Extend button
              if (expiry.canExtend && onExtend != null)
                IconButton(
                  onPressed: onExtend,
                  icon: const Icon(Icons.add_alarm),
                  color: color,
                  tooltip: 'Extend',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.active:
        return Colors.green;
      case ExpiryStatus.warning:
        return Colors.orange;
      case ExpiryStatus.critical:
        return Colors.red;
      case ExpiryStatus.expired:
        return Colors.grey;
    }
  }
}
