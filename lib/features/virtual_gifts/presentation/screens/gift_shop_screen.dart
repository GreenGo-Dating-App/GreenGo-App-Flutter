import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/virtual_gift.dart';
import '../bloc/virtual_gift_bloc.dart';
import '../bloc/virtual_gift_event.dart';
import '../bloc/virtual_gift_state.dart';
import '../widgets/gift_card.dart';

/// Gift Shop Screen
/// Browse and send virtual gifts
class GiftShopScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String receiverId;
  final String receiverName;
  final int? userCoins;

  const GiftShopScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.receiverId,
    required this.receiverName,
    this.userCoins,
  });

  @override
  State<GiftShopScreen> createState() => _GiftShopScreenState();
}

class _GiftShopScreenState extends State<GiftShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedGiftId;
  final _messageController = TextEditingController();

  final List<String> _categories = [
    'All',
    'romantic',
    'fun',
    'luxury',
    'seasonal',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);

    final bloc = context.read<VirtualGiftBloc>();
    if (widget.userCoins != null) {
      bloc.setUserCoins(widget.userCoins!);
    }
    bloc.add(const LoadGiftCatalog());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Send Gift to ${widget.receiverName}'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((cat) {
            return Tab(
              text: cat == 'All'
                  ? 'All'
                  : GiftCategoryExtension.fromString(cat).displayName,
            );
          }).toList(),
        ),
      ),
      body: BlocConsumer<VirtualGiftBloc, VirtualGiftState>(
        listener: (context, state) {
          if (state is VirtualGiftError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
              ),
            );
          } else if (state is GiftSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gift sent to ${widget.receiverName}!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, state.sentGift);
          } else if (state is InsufficientCoins) {
            _showInsufficientCoinsDialog(context, state);
          }
        },
        builder: (context, state) {
          if (state is VirtualGiftLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GiftCatalogLoaded) {
            return Column(
              children: [
                // Gift grid
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _categories.map((category) {
                      List<VirtualGift> gifts;
                      if (category == 'All') {
                        gifts = state.gifts;
                      } else {
                        gifts = state.giftsByCategory[category] ?? [];
                      }
                      return _buildGiftGrid(context, gifts, state);
                    }).toList(),
                  ),
                ),

                // Selected gift panel
                if (_selectedGiftId != null)
                  _buildSelectedGiftPanel(context, state),
              ],
            );
          }

          return const Center(child: Text('No gifts available'));
        },
      ),
    );
  }

  Widget _buildGiftGrid(
    BuildContext context,
    List<VirtualGift> gifts,
    GiftCatalogLoaded state,
  ) {
    if (gifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No gifts in this category',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: gifts.length,
      itemBuilder: (context, index) {
        final gift = gifts[index];
        final isSelected = _selectedGiftId == gift.id;
        final canAfford = state.canAfford(gift.id);

        return GiftCard(
          gift: gift,
          isSelected: isSelected,
          isAffordable: canAfford,
          onTap: () {
            setState(() {
              _selectedGiftId = isSelected ? null : gift.id;
            });
          },
        );
      },
    );
  }

  Widget _buildSelectedGiftPanel(
    BuildContext context,
    GiftCatalogLoaded state,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedGift = state.gifts.firstWhere((g) => g.id == _selectedGiftId);
    final canAfford = state.canAfford(_selectedGiftId!);
    final isSending = context.read<VirtualGiftBloc>().state is GiftSending;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected gift info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    selectedGift.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedGift.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.monetization_on,
                            size: 16,
                            color: canAfford
                                ? colorScheme.secondary
                                : colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${selectedGift.price} coins',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: canAfford
                                  ? colorScheme.secondary
                                  : colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedGiftId = null;
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Message input
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Add a message (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLength: 100,
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Send button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canAfford && !isSending ? _sendGift : null,
                icon: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(isSending ? 'Sending...' : 'Send Gift'),
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
      ),
    );
  }

  void _sendGift() {
    if (_selectedGiftId == null) return;

    context.read<VirtualGiftBloc>().add(
          SendGiftEvent(
            senderId: widget.userId,
            senderName: widget.userName,
            receiverId: widget.receiverId,
            receiverName: widget.receiverName,
            giftId: _selectedGiftId!,
            message: _messageController.text.isNotEmpty
                ? _messageController.text
                : null,
          ),
        );
  }

  void _showInsufficientCoinsDialog(
    BuildContext context,
    InsufficientCoins state,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.monetization_on, color: Colors.orange),
            SizedBox(width: 8),
            Text('Not Enough Coins'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You need ${state.required} coins for this gift.'),
            const SizedBox(height: 8),
            Text('You have ${state.available} coins.'),
            const SizedBox(height: 8),
            Text(
              'You need ${state.shortfall} more coins.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to coin shop
              // Navigator.pushNamed(context, '/shop');
            },
            child: const Text('Get Coins'),
          ),
        ],
      ),
    );
  }
}

/// Received gifts screen
class ReceivedGiftsScreen extends StatefulWidget {
  final String userId;

  const ReceivedGiftsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ReceivedGiftsScreen> createState() => _ReceivedGiftsScreenState();
}

class _ReceivedGiftsScreenState extends State<ReceivedGiftsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<VirtualGiftBloc>().add(
          SubscribeToReceivedGifts(widget.userId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Received Gifts'),
      ),
      body: BlocBuilder<VirtualGiftBloc, VirtualGiftState>(
        builder: (context, state) {
          if (state is VirtualGiftLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ReceivedGiftsLoaded) {
            if (state.gifts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.card_giftcard_outlined,
                      size: 80,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No gifts yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gifts you receive will appear here',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.gifts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final gift = state.gifts[index];
                return ReceivedGiftCard(
                  sentGift: gift,
                  onTap: () {
                    // Mark as viewed if new
                    if (gift.isNew) {
                      context.read<VirtualGiftBloc>().add(
                            MarkGiftViewedEvent(gift.id),
                          );
                    }
                    // Show gift animation dialog
                    _showGiftAnimation(context, gift);
                  },
                  onPlayAnimation: () => _showGiftAnimation(context, gift),
                );
              },
            );
          }

          return const Center(child: Text('No gifts available'));
        },
      ),
    );
  }

  void _showGiftAnimation(BuildContext context, SentVirtualGift gift) {
    // Mark as viewed
    if (gift.isNew) {
      context.read<VirtualGiftBloc>().add(MarkGiftViewedEvent(gift.id));
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                gift.gift?.emoji ?? '🎁',
                style: const TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 16),
              Text(
                gift.gift?.name ?? 'Gift',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'From ${gift.senderName}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (gift.message != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '"${gift.message}"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
