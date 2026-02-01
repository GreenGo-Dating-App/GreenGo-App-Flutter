import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/virtual_gift.dart';
import '../../domain/usecases/virtual_gift_usecases.dart';
import 'virtual_gift_event.dart';
import 'virtual_gift_state.dart';

/// Virtual Gift BLoC
/// Manages gift catalog, sending, and receiving gifts
class VirtualGiftBloc extends Bloc<VirtualGiftEvent, VirtualGiftState> {
  final GetGiftCatalog getGiftCatalog;
  final GetGiftsByCategory getGiftsByCategory;
  final SendVirtualGift sendVirtualGift;
  final GetReceivedGifts getReceivedGifts;
  final GetSentGifts getSentGifts;
  final MarkGiftViewed markGiftViewed;
  final GetGiftStats getGiftStats;
  final GetUnviewedGiftCount getUnviewedGiftCount;

  // Cache
  List<VirtualGift> _catalogCache = [];
  int? _userCoins;

  VirtualGiftBloc({
    required this.getGiftCatalog,
    required this.getGiftsByCategory,
    required this.sendVirtualGift,
    required this.getReceivedGifts,
    required this.getSentGifts,
    required this.markGiftViewed,
    required this.getGiftStats,
    required this.getUnviewedGiftCount,
  }) : super(const VirtualGiftInitial()) {
    on<LoadGiftCatalog>(_onLoadGiftCatalog);
    on<LoadGiftsByCategory>(_onLoadGiftsByCategory);
    on<SendGiftEvent>(_onSendGift);
    on<LoadReceivedGifts>(_onLoadReceivedGifts);
    on<SubscribeToReceivedGifts>(_onSubscribeToReceivedGifts);
    on<LoadSentGifts>(_onLoadSentGifts);
    on<MarkGiftViewedEvent>(_onMarkGiftViewed);
    on<LoadGiftStats>(_onLoadGiftStats);
    on<LoadUnviewedGiftCount>(_onLoadUnviewedGiftCount);
    on<SelectGift>(_onSelectGift);
    on<ClearGiftSelection>(_onClearGiftSelection);
  }

  /// Set user's coin balance (called from CoinBloc)
  void setUserCoins(int coins) {
    _userCoins = coins;
    // If catalog is loaded, update state
    if (state is GiftCatalogLoaded) {
      final currentState = state as GiftCatalogLoaded;
      // ignore: invalid_use_of_visible_for_testing_member
      emit(currentState.copyWith(userCoins: coins));
    }
  }

  /// Load gift catalog
  Future<void> _onLoadGiftCatalog(
    LoadGiftCatalog event,
    Emitter<VirtualGiftState> emit,
  ) async {
    emit(const VirtualGiftLoading());

    final result = await getGiftCatalog();

    result.fold(
      (failure) => emit(VirtualGiftError(failure.toString())),
      (gifts) {
        _catalogCache = gifts;
        emit(GiftCatalogLoaded(
          gifts: gifts,
          userCoins: _userCoins,
        ));
      },
    );
  }

  /// Load gifts by category
  Future<void> _onLoadGiftsByCategory(
    LoadGiftsByCategory event,
    Emitter<VirtualGiftState> emit,
  ) async {
    emit(const VirtualGiftLoading());

    final result = await getGiftsByCategory(event.category);

    result.fold(
      (failure) => emit(VirtualGiftError(failure.toString())),
      (gifts) => emit(GiftCatalogLoaded(
        gifts: gifts,
        userCoins: _userCoins,
      )),
    );
  }

  /// Send a gift
  Future<void> _onSendGift(
    SendGiftEvent event,
    Emitter<VirtualGiftState> emit,
  ) async {
    // Find gift to check price
    VirtualGift? gift;
    try {
      gift = _catalogCache.firstWhere((g) => g.id == event.giftId);
    } catch (_) {
      emit(const VirtualGiftError('Gift not found'));
      return;
    }

    // Check if user can afford
    if (_userCoins != null && !gift.isAffordable(_userCoins!)) {
      emit(InsufficientCoins(
        required: gift.price,
        available: _userCoins!,
      ));
      return;
    }

    emit(GiftSending(giftId: event.giftId, receiverId: event.receiverId));

    final result = await sendVirtualGift(
      senderId: event.senderId,
      senderName: event.senderName,
      receiverId: event.receiverId,
      receiverName: event.receiverName,
      giftId: event.giftId,
      message: event.message,
    );

    result.fold(
      (failure) => emit(VirtualGiftError(failure.toString())),
      (sentGift) {
        // Update user coins if we know the cost
        if (_userCoins != null) {
          _userCoins = _userCoins! - gift!.price;
        }
        emit(GiftSent(sentGift));
      },
    );
  }

  /// Load received gifts
  Future<void> _onLoadReceivedGifts(
    LoadReceivedGifts event,
    Emitter<VirtualGiftState> emit,
  ) async {
    emit(const VirtualGiftLoading());

    final result = await getReceivedGifts(
      userId: event.userId,
      limit: event.limit,
      lastGiftId: event.lastGiftId,
    );

    result.fold(
      (failure) => emit(VirtualGiftError(failure.toString())),
      (gifts) {
        final unviewedCount = gifts.where((g) => g.isNew).length;
        emit(ReceivedGiftsLoaded(
          gifts: gifts,
          hasMore: gifts.length >= event.limit,
          unviewedCount: unviewedCount,
        ));
      },
    );
  }

  /// Subscribe to received gifts stream
  Future<void> _onSubscribeToReceivedGifts(
    SubscribeToReceivedGifts event,
    Emitter<VirtualGiftState> emit,
  ) async {
    await emit.forEach(
      getReceivedGifts.stream(event.userId),
      onData: (result) {
        return result.fold(
          (failure) => VirtualGiftError(failure.toString()),
          (gifts) {
            final unviewedCount = gifts.where((g) => g.isNew).length;
            return ReceivedGiftsLoaded(
              gifts: gifts,
              hasMore: false,
              unviewedCount: unviewedCount,
            );
          },
        );
      },
    );
  }

  /// Load sent gifts
  Future<void> _onLoadSentGifts(
    LoadSentGifts event,
    Emitter<VirtualGiftState> emit,
  ) async {
    emit(const VirtualGiftLoading());

    final result = await getSentGifts(
      userId: event.userId,
      limit: event.limit,
      lastGiftId: event.lastGiftId,
    );

    result.fold(
      (failure) => emit(VirtualGiftError(failure.toString())),
      (gifts) => emit(SentGiftsLoaded(
        gifts: gifts,
        hasMore: gifts.length >= event.limit,
      )),
    );
  }

  /// Mark gift as viewed
  Future<void> _onMarkGiftViewed(
    MarkGiftViewedEvent event,
    Emitter<VirtualGiftState> emit,
  ) async {
    final result = await markGiftViewed(event.giftId);

    result.fold(
      (failure) => emit(VirtualGiftError(failure.toString())),
      (_) => emit(GiftMarkedViewed(event.giftId)),
    );
  }

  /// Load gift statistics
  Future<void> _onLoadGiftStats(
    LoadGiftStats event,
    Emitter<VirtualGiftState> emit,
  ) async {
    emit(const VirtualGiftLoading());

    final result = await getGiftStats(event.userId);

    result.fold(
      (failure) => emit(VirtualGiftError(failure.toString())),
      (stats) => emit(GiftStatsLoaded(stats)),
    );
  }

  /// Load unviewed gift count
  Future<void> _onLoadUnviewedGiftCount(
    LoadUnviewedGiftCount event,
    Emitter<VirtualGiftState> emit,
  ) async {
    final result = await getUnviewedGiftCount(event.userId);

    result.fold(
      (failure) => emit(VirtualGiftError(failure.toString())),
      (count) => emit(UnviewedGiftCountLoaded(count)),
    );
  }

  /// Select a gift for sending
  Future<void> _onSelectGift(
    SelectGift event,
    Emitter<VirtualGiftState> emit,
  ) async {
    if (state is GiftCatalogLoaded) {
      final currentState = state as GiftCatalogLoaded;
      emit(currentState.copyWith(selectedGiftId: event.giftId));
    } else {
      // Load catalog first, then select
      final result = await getGiftCatalog();
      result.fold(
        (failure) => emit(VirtualGiftError(failure.toString())),
        (gifts) {
          _catalogCache = gifts;
          emit(GiftCatalogLoaded(
            gifts: gifts,
            selectedGiftId: event.giftId,
            userCoins: _userCoins,
          ));
        },
      );
    }
  }

  /// Clear gift selection
  Future<void> _onClearGiftSelection(
    ClearGiftSelection event,
    Emitter<VirtualGiftState> emit,
  ) async {
    if (state is GiftCatalogLoaded) {
      final currentState = state as GiftCatalogLoaded;
      emit(currentState.copyWith(clearSelection: true));
    }
  }
}
