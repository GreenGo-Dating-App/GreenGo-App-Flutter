import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/conversation_expiry.dart';
import '../../domain/usecases/conversation_expiry_usecases.dart';
import 'conversation_expiry_event.dart';
import 'conversation_expiry_state.dart';

/// Conversation Expiry BLoC
class ConversationExpiryBloc
    extends Bloc<ConversationExpiryEvent, ConversationExpiryState> {
  final GetConversationExpiry getConversationExpiry;
  final GetUserExpiries getUserExpiries;
  final GetExpiringSoon getExpiringSoon;
  final ExtendConversation extendConversation;
  final RecordConversationActivity recordConversationActivity;
  final StreamConversationExpiry streamConversationExpiry;

  Timer? _expiryTimer;
  ConversationExpiry? _currentExpiry;

  ConversationExpiryBloc({
    required this.getConversationExpiry,
    required this.getUserExpiries,
    required this.getExpiringSoon,
    required this.extendConversation,
    required this.recordConversationActivity,
    required this.streamConversationExpiry,
  }) : super(const ConversationExpiryInitial()) {
    on<LoadConversationExpiry>(_onLoadConversationExpiry);
    on<LoadUserExpiries>(_onLoadUserExpiries);
    on<LoadExpiringSoon>(_onLoadExpiringSoon);
    on<ExtendConversationEvent>(_onExtendConversation);
    on<SubscribeToExpiry>(_onSubscribeToExpiry);
    on<RecordActivity>(_onRecordActivity);
    on<UpdateExpiryTimer>(_onUpdateExpiryTimer);
  }

  @override
  Future<void> close() {
    _expiryTimer?.cancel();
    return super.close();
  }

  /// Load expiry for a conversation
  Future<void> _onLoadConversationExpiry(
    LoadConversationExpiry event,
    Emitter<ConversationExpiryState> emit,
  ) async {
    emit(const ConversationExpiryLoading());

    final result = await getConversationExpiry(event.conversationId);

    result.fold(
      (failure) => emit(ConversationExpiryError(failure.toString())),
      (expiry) {
        if (expiry == null) {
          emit(const ConversationExpiryError('No expiry found'));
        } else {
          _currentExpiry = expiry;
          _startExpiryTimer();
          emit(ConversationExpiryLoaded(expiry));
        }
      },
    );
  }

  /// Load all user expiries
  Future<void> _onLoadUserExpiries(
    LoadUserExpiries event,
    Emitter<ConversationExpiryState> emit,
  ) async {
    emit(const ConversationExpiryLoading());

    final result = await getUserExpiries(event.userId);

    result.fold(
      (failure) => emit(ConversationExpiryError(failure.toString())),
      (expiries) => emit(UserExpiriesLoaded(expiries: expiries)),
    );
  }

  /// Load expiring soon conversations
  Future<void> _onLoadExpiringSoon(
    LoadExpiringSoon event,
    Emitter<ConversationExpiryState> emit,
  ) async {
    emit(const ConversationExpiryLoading());

    final result = await getExpiringSoon(
      event.userId,
      withinHours: event.withinHours,
    );

    result.fold(
      (failure) => emit(ConversationExpiryError(failure.toString())),
      (expiries) => emit(UserExpiriesLoaded(expiries: expiries)),
    );
  }

  /// Extend a conversation
  Future<void> _onExtendConversation(
    ExtendConversationEvent event,
    Emitter<ConversationExpiryState> emit,
  ) async {
    emit(const ConversationExpiryLoading());

    final result = await extendConversation(
      conversationId: event.conversationId,
      userId: event.userId,
    );

    result.fold(
      (failure) => emit(ConversationExpiryError(failure.toString())),
      (extensionResult) {
        if (extensionResult.success && extensionResult.expiry != null) {
          _currentExpiry = extensionResult.expiry;
          _startExpiryTimer();
          emit(ConversationExtended(
            expiry: extensionResult.expiry!,
            coinsSpent: extensionResult.coinsSpent ?? ExpiryConfig.extensionCost,
          ));
        } else {
          emit(ConversationExpiryError(
            extensionResult.errorMessage ?? 'Failed to extend conversation',
          ));
        }
      },
    );
  }

  /// Subscribe to expiry updates
  Future<void> _onSubscribeToExpiry(
    SubscribeToExpiry event,
    Emitter<ConversationExpiryState> emit,
  ) async {
    await emit.forEach(
      streamConversationExpiry(event.conversationId),
      onData: (result) {
        return result.fold(
          (failure) => ConversationExpiryError(failure.toString()),
          (expiry) {
            _currentExpiry = expiry;
            if (expiry.isExpired) {
              return ConversationExpiredState(event.conversationId);
            }
            return ConversationExpiryLoaded(expiry);
          },
        );
      },
    );
  }

  /// Record conversation activity
  Future<void> _onRecordActivity(
    RecordActivity event,
    Emitter<ConversationExpiryState> emit,
  ) async {
    final result = await recordConversationActivity(event.conversationId);

    result.fold(
      (failure) => {}, // Silently fail for activity recording
      (expiry) {
        _currentExpiry = expiry;
        emit(ActivityRecorded(expiry));
      },
    );
  }

  /// Update expiry timer
  void _onUpdateExpiryTimer(
    UpdateExpiryTimer event,
    Emitter<ConversationExpiryState> emit,
  ) {
    if (_currentExpiry != null) {
      // Create updated expiry with current time check
      final updatedExpiry = ConversationExpiry(
        id: _currentExpiry!.id,
        matchId: _currentExpiry!.matchId,
        conversationId: _currentExpiry!.conversationId,
        createdAt: _currentExpiry!.createdAt,
        expiresAt: _currentExpiry!.expiresAt,
        isExpired: DateTime.now().isAfter(_currentExpiry!.expiresAt),
        hasActivity: _currentExpiry!.hasActivity,
        extensionCount: _currentExpiry!.extensionCount,
        lastExtendedAt: _currentExpiry!.lastExtendedAt,
        extendedByUserId: _currentExpiry!.extendedByUserId,
      );

      if (updatedExpiry.isExpired) {
        _expiryTimer?.cancel();
        emit(ConversationExpiredState(_currentExpiry!.conversationId));
      } else {
        emit(ConversationExpiryLoaded(updatedExpiry));
      }
    }
  }

  /// Start timer to update expiry countdown
  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => add(const UpdateExpiryTimer()),
    );
  }
}
