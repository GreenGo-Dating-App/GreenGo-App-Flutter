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

  const ConversationExpiryError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Single expiry loaded
class ConversationExpiryLoaded extends ConversationExpiryState {

  const ConversationExpiryLoaded(this.expiry);
  final ConversationExpiry expiry;

  @override
  List<Object?> get props => [expiry];
}

/// User expiries loaded
class UserExpiriesLoaded extends ConversationExpiryState {

  UserExpiriesLoaded({required this.expiries})
      : expiringSoon = expiries
            .where((e) => e.isWarning || e.isCritical)
            .toList()
          ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt)),
        active = expiries.where((e) => !e.isExpired).toList();
  final List<ConversationExpiry> expiries;
  final List<ConversationExpiry> expiringSoon;
  final List<ConversationExpiry> active;

  @override
  List<Object?> get props => [expiries, expiringSoon, active];
}

/// Extension successful
class ConversationExtended extends ConversationExpiryState {

  const ConversationExtended({
    required this.expiry,
    required this.coinsSpent,
  });
  final ConversationExpiry expiry;
  final int coinsSpent;

  @override
  List<Object?> get props => [expiry, coinsSpent];
}

/// Extension failed due to insufficient coins
class InsufficientCoinsForExtension extends ConversationExpiryState {

  const InsufficientCoinsForExtension({
    required this.required,
    required this.available,
  });
  final int required;
  final int available;

  int get shortfall => required - available;

  @override
  List<Object?> get props => [required, available];
}

/// Conversation expired
class ConversationExpiredState extends ConversationExpiryState {

  const ConversationExpiredState(this.conversationId);
  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// Activity recorded
class ActivityRecorded extends ConversationExpiryState {

  const ActivityRecorded(this.expiry);
  final ConversationExpiry expiry;

  @override
  List<Object?> get props => [expiry];
}
