import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../domain/entities/virtual_gift.dart';

/// Gift card widget for displaying a single gift
class GiftCard extends StatelessWidget {
  final VirtualGift gift;
  final bool isSelected;
  final bool isAffordable;
  final VoidCallback? onTap;

  const GiftCard({
    super.key,
    required this.gift,
    this.isSelected = false,
    this.isAffordable = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gift icon/animation preview
            SizedBox(
              height: 60,
              width: 60,
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      gift.emoji,
                      style: TextStyle(
                        fontSize: 40,
                        color: !isAffordable ? Colors.grey : null,
                      ),
                    ),
                  ),
                  if (gift.isPremium)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber.shade600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Gift name
            Text(
              gift.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: !isAffordable
                    ? colorScheme.onSurface.withOpacity(0.5)
                    : null,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Price
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on,
                  size: 14,
                  color: !isAffordable
                      ? colorScheme.error
                      : colorScheme.secondary,
                ),
                const SizedBox(width: 2),
                Text(
                  '${gift.price}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: !isAffordable
                        ? colorScheme.error
                        : colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Large gift card for gift detail/preview
class GiftDetailCard extends StatelessWidget {
  final VirtualGift gift;
  final VoidCallback? onSend;
  final bool isLoading;
  final int? userCoins;

  const GiftDetailCard({
    super.key,
    required this.gift,
    this.onSend,
    this.isLoading = false,
    this.userCoins,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canAfford = userCoins == null || gift.isAffordable(userCoins!);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gift animation or emoji
          SizedBox(
            height: 120,
            width: 120,
            child: gift.animationUrl.isNotEmpty
                ? Lottie.network(
                    gift.animationUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          gift.emoji,
                          style: const TextStyle(fontSize: 80),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      gift.emoji,
                      style: const TextStyle(fontSize: 80),
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // Gift name
          Text(
            gift.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (gift.description != null) ...[
            const SizedBox(height: 8),
            Text(
              gift.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),

          // Price info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: canAfford
                  ? colorScheme.primaryContainer
                  : colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on,
                  color: canAfford
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  '${gift.price} coins',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: canAfford
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),

          if (!canAfford && userCoins != null) ...[
            const SizedBox(height: 8),
            Text(
              'You need ${gift.price - userCoins!} more coins',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Send button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canAfford && !isLoading ? onSend : null,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.card_giftcard),
              label: Text(isLoading ? 'Sending...' : 'Send Gift'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Received gift card with animation
class ReceivedGiftCard extends StatelessWidget {
  final SentVirtualGift sentGift;
  final VoidCallback? onTap;
  final VoidCallback? onPlayAnimation;

  const ReceivedGiftCard({
    super.key,
    required this.sentGift,
    this.onTap,
    this.onPlayAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gift = sentGift.gift;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sentGift.isNew
              ? colorScheme.primaryContainer.withOpacity(0.3)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sentGift.isNew
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            // Gift icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: gift != null
                    ? Text(gift.emoji, style: const TextStyle(fontSize: 32))
                    : const Icon(Icons.card_giftcard, size: 32),
              ),
            ),
            const SizedBox(width: 12),

            // Gift info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (sentGift.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NEW',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          gift?.name ?? 'Gift',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'From ${sentGift.senderName}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  if (sentGift.message != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '"${sentGift.message}"',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Play animation button
            if (gift?.animationUrl != null && gift!.animationUrl.isNotEmpty)
              IconButton(
                onPressed: onPlayAnimation,
                icon: const Icon(Icons.play_circle_filled),
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
