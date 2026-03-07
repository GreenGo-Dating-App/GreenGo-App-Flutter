import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/coin_transaction.dart';
import '../bloc/coin_bloc.dart';
import '../bloc/coin_event.dart';
import '../bloc/coin_state.dart';

/// Transaction History Screen
/// Point 159: Transaction history showing earnings and spending
class TransactionHistoryScreen extends StatefulWidget {
  final String userId;

  const TransactionHistoryScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final DateFormat _dateFormat = DateFormat('MMM d, y');
  final DateFormat _timeFormat = DateFormat('h:mm a');
  AppLocalizations? _l10n;

  @override
  void initState() {
    super.initState();
    context.read<CoinBloc>().add(
          LoadTransactionHistory(userId: widget.userId, limit: 100),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _l10n = l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(l10n.coinsTransactionHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: BlocBuilder<CoinBloc, CoinState>(
        builder: (context, state) {
          if (state is CoinLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TransactionHistoryLoaded) {
            return _buildTransactionList(state.transactions);
          }

          if (state is CoinError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CoinBloc>().add(
                            LoadTransactionHistory(
                              userId: widget.userId,
                              limit: 100,
                            ),
                          );
                    },
                    child: Text(l10n.coinsRetry),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Text(
              l10n.coinsNoTransactionsYet,
              style: const TextStyle(color: Colors.grey),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionList(List<CoinTransaction> transactions) {
    final l10n = AppLocalizations.of(context)!;
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              l10n.coinsNoTransactionsYet,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.coinsTransactionsAppearHere,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Group transactions by date
    final groupedTransactions = _groupTransactionsByDate(transactions);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final entry = groupedTransactions.entries.elementAt(index);
        final date = entry.key;
        final dayTransactions = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _getDateLabel(date),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                ),
              ),
            ),

            // Transactions for this date
            ...dayTransactions.map((transaction) =>
                _buildTransactionCard(transaction)),
          ],
        );
      },
    );
  }

  Widget _buildTransactionCard(CoinTransaction transaction) {
    final l10n = AppLocalizations.of(context)!;
    final isCredit = transaction.type == CoinTransactionType.credit;
    final color = isCredit ? const Color(0xFF4CAF50) : const Color(0xFFFF5252);
    final icon = _getIconForReason(transaction.reason, isCredit);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),

          // Description and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.reason.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeFormat.format(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.displayAmount,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                l10n.coinsBalance(transaction.balanceAfter),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<CoinTransaction>> _groupTransactionsByDate(
    List<CoinTransaction> transactions,
  ) {
    final Map<DateTime, List<CoinTransaction>> grouped = {};

    for (final transaction in transactions) {
      final date = DateTime(
        transaction.createdAt.year,
        transaction.createdAt.month,
        transaction.createdAt.day,
      );

      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(transaction);
    }

    return grouped;
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return _l10n?.coinsToday ?? 'Today';
    } else if (date == yesterday) {
      return _l10n?.coinsYesterday ?? 'Yesterday';
    } else {
      return _dateFormat.format(date);
    }
  }

  IconData _getIconForReason(CoinTransactionReason reason, bool isCredit) {
    if (isCredit) {
      switch (reason) {
        case CoinTransactionReason.coinPurchase:
          return Icons.shopping_cart;
        case CoinTransactionReason.firstMatchReward:
          return Icons.favorite;
        case CoinTransactionReason.completeProfileReward:
          return Icons.account_circle;
        case CoinTransactionReason.dailyLoginStreakReward:
          return Icons.calendar_today;
        case CoinTransactionReason.achievementReward:
          return Icons.emoji_events;
        case CoinTransactionReason.monthlyAllowance:
          return Icons.card_giftcard;
        case CoinTransactionReason.giftReceived:
          return Icons.card_giftcard;
        case CoinTransactionReason.promotionalBonus:
          return Icons.local_offer;
        case CoinTransactionReason.refund:
          return Icons.refresh;
        default:
          return Icons.add_circle;
      }
    } else {
      switch (reason) {
        case CoinTransactionReason.superLikePurchase:
          return Icons.star;
        case CoinTransactionReason.boostPurchase:
          return Icons.trending_up;
        case CoinTransactionReason.undoPurchase:
          return Icons.undo;
        case CoinTransactionReason.seeWhoLikedYouPurchase:
          return Icons.visibility;
        case CoinTransactionReason.giftSent:
          return Icons.card_giftcard;
        case CoinTransactionReason.expired:
          return Icons.access_time;
        default:
          return Icons.remove_circle;
      }
    }
  }

  void _showFilterDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(l10n.coinsFilterTransactions),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.coinsAllTransactions),
              leading: Radio<String>(
                value: 'all',
                groupValue: 'all',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: Text(l10n.coinsCreditsOnly),
              leading: Radio<String>(
                value: 'credits',
                groupValue: 'all',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: Text(l10n.coinsDebitsOnly),
              leading: Radio<String>(
                value: 'debits',
                groupValue: 'all',
                onChanged: (value) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.coinsCancelLabel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Apply filter
            },
            child: Text(l10n.coinsApply),
          ),
        ],
      ),
    );
  }
}
