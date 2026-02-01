import 'package:equatable/equatable.dart';
import '../../domain/entities/conversation_expiry.dart';

/// Conversation Expiry States
abstract class ConversationExpiryState extends Equatable {
  const ConversationExpiryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ConversationExpiryInitial extends ConversationExpiryState {
  const ConversationExpiryInitial();
}

/// Loading state
class ConversationExpiryLoading extends ConversationExpiryState {
  const ConversationExpiryLoading();
}

/// Error state
class ConversationExpiryError extends ConversationExpiryState {
  final String message;

  const ConversationExpiryError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Single expiry loaded
class ConversationExpiryLoaded extends ConversationExpiryState {
  final ConversationExpiry expiry;

  const ConversationExpiryLoaded(this.expiry);

  @override
  List<Object?> get props => [expiry];
}

/// User expiries loaded
class UserExpiriesLoaded extends ConversationExpiryState {
  final List<ConversationExpiry> expiries;
  final List<ConversationExpiry> expiringSoon;
  final List<ConversationExpiry> active;

  UserExpiriesLoaded({required this.expiries})
      : expiringSoon = expiries
            .where((e) => e.isWarning || e.isCritical)
            .toList()
          ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt)),
        active = expiries.where((e) => !e.isExpired).toList();

  @override
  List<Object?> get props => [expiries, expiringSoon, active];
}

/// Extension successful
class ConversationExtended extends ConversationExpiryState {
  final ConversationExpiry expiry;
  final int coinsSpent;

  const ConversationExtended({
    required this.expiry,
    required this.coinsSpent,
  });

  @override
  List<Object?> get props => [expiry, coinsSpent];
}

/// Extension failed due to insufficient coins
class InsufficientCoinsForExtension extends ConversationExpiryState {
  final int required;
  final int available;

  const InsufficientCoinsForExtension({
    required this.required,
    required this.available,
  });

  int get shortfall => required - available;

  @override
  List<Object?> get props => [required, available];
}

/// Conversation expired
class ConversationExpiredState extends ConversationExpiryState {
  final String conversationId;

  const ConversationExpiredState(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Activity recorded
class ActivityRecorded extends ConversationExpiryState {
  final ConversationExpiry expiry;

  const ActivityRecorded(this.expiry);

  @override
  List<Object?> get props => [expiry];
}
