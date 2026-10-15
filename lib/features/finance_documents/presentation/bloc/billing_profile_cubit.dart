import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/billing_profile_repository.dart';
import '../../domain/billing_profile.dart';

enum BillingLoadStatus { loading, ready, failed }

class BillingProfileState extends Equatable {
  const BillingProfileState({
    this.status = BillingLoadStatus.loading,
    this.data = const BillingStatus(),
    this.saving = false,
    this.fieldError,
    this.saveFailed = false,
    this.savedCount = 0,
  });

  final BillingLoadStatus status;
  final BillingStatus data;
  final bool saving;

  /// The field the server rejected on the last save (shown under that field).
  final BillingFieldError? fieldError;

  /// Last save failed for another reason (network, server).
  final bool saveFailed;

  /// Increments on every successful save (the screen shows a snackbar).
  final int savedCount;

  bool get complete => data.complete;

  BillingProfileState copyWith({
    BillingLoadStatus? status,
    BillingStatus? data,
    bool? saving,
    BillingFieldError? Function()? fieldError,
    bool? saveFailed,
    int? savedCount,
  }) =>
      BillingProfileState(
        status: status ?? this.status,
        data: data ?? this.data,
        saving: saving ?? this.saving,
        fieldError: fieldError != null ? fieldError() : this.fieldError,
        saveFailed: saveFailed ?? this.saveFailed,
        savedCount: savedCount ?? this.savedCount,
      );

  @override
  List<Object?> get props => [status, data, saving, fieldError, saveFailed, savedCount];
}

/// The signed-in seller's invoice details: load (hub status + form) and save.
class BillingProfileCubit extends Cubit<BillingProfileState> {
  BillingProfileCubit(this._repo) : super(const BillingProfileState());

  final BillingProfileRepository _repo;

  Future<void> load() async {
    if (state.status != BillingLoadStatus.ready) emit(state.copyWith(status: BillingLoadStatus.loading));
    try {
      final data = await _repo.get();
      if (isClosed) return;
      emit(state.copyWith(status: BillingLoadStatus.ready, data: data));
    } catch (e) {
      debugPrint('[Billing] load failed: $e');
      if (isClosed) return;
      emit(state.copyWith(status: state.status == BillingLoadStatus.ready ? BillingLoadStatus.ready : BillingLoadStatus.failed));
    }
  }

  /// Returns true when saved.
  Future<bool> save(BillingDraft draft) async {
    if (state.saving) return false;
    emit(state.copyWith(saving: true, fieldError: () => null, saveFailed: false));
    try {
      final data = await _repo.save(draft);
      if (isClosed) return true;
      emit(state.copyWith(status: BillingLoadStatus.ready, data: data, saving: false, savedCount: state.savedCount + 1));
      return true;
    } on BillingValidationException catch (e) {
      if (!isClosed) emit(state.copyWith(saving: false, fieldError: () => e.error));
      return false;
    } catch (e) {
      debugPrint('[Billing] save failed: $e');
      if (!isClosed) emit(state.copyWith(saving: false, saveFailed: true));
      return false;
    }
  }

  /// The user edited the rejected field: hide its error.
  void clearFieldError(String field) {
    if (state.fieldError?.field == field) emit(state.copyWith(fieldError: () => null));
  }
}
