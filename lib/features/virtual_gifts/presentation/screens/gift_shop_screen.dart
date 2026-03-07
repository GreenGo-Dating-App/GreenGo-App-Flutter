import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.giftSendGiftTo(widget.receiverName)),
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
                content: Text(l10n.giftSentTo(widget.receiverName)),
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

          return Center(child: Text(l10n.giftNoGiftsAvailable));
        },
      ),
    );
  }

  Widget _buildGiftGrid(
    BuildContext context,
    List<VirtualGift> gifts,
    GiftCatalogLoaded state,
  ) {
    final l10n = AppLocalizations.of(context)!;
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
              l10n.giftNoGiftsInCategory,
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
    final l10n = AppLocalizations.of(context)!;
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
                            l10n.giftPriceCoins(selectedGift.price),
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
                hintText: l10n.virtualGiftsAddMessageHint,
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
                label: Text(isSending ? l10n.giftSending : l10n.giftSendGift),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.monetization_on, color: Colors.orange),
            const SizedBox(width: 8),
            Text(l10n.giftNotEnoughCoins),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.giftYouNeedCoins(state.required)),
            const SizedBox(height: 8),
            Text(l10n.giftYouHaveCoins(state.available)),
            const SizedBox(height: 8),
            Text(
              l10n.giftYouNeedMoreCoins(state.shortfall),
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
            child: Text(l10n.giftGetCoins),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.giftReceivedGifts),
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
                      l10n.giftNoGiftsYet,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.giftReceivedGiftsEmpty,
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

          return Center(child: Text(l10n.giftNoGiftsAvailable));
        },
      ),
    );
  }

  void _showGiftAnimation(BuildContext context, SentVirtualGift gift) {
    final l10n = AppLocalizations.of(context)!;
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
                l10n.giftFromSender(gift.senderName),
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
