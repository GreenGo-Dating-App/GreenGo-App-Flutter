import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/verification_admin_repository.dart';
import 'verification_admin_event.dart';
import 'verification_admin_state.dart';

class VerificationAdminBloc extends Bloc<VerificationAdminEvent, VerificationAdminState> {
  final VerificationAdminRepository repository;

  VerificationAdminBloc({required this.repository}) : super(const VerificationAdminInitial()) {
    on<LoadPendingVerifications>(_onLoadPendingVerifications);
    on<LoadVerificationHistory>(_onLoadVerificationHistory);
    on<ApproveVerification>(_onApproveVerification);
    on<RejectVerification>(_onRejectVerification);
    on<RequestBetterPhoto>(_onRequestBetterPhoto);
    on<RefreshVerifications>(_onRefreshVerifications);
    on<BulkApproveVerifications>(_onBulkApproveVerifications);
    on<BulkRequestBetterPhoto>(_onBulkRequestBetterPhoto);
  }

  Future<void> _onLoadPendingVerifications(
    LoadPendingVerifications event,
    Emitter<VerificationAdminState> emit,
  ) async {
    emit(const VerificationAdminLoading());

    final result = await repository.getPendingVerifications();

    result.fold(
      (failure) => emit(VerificationAdminError(message: failure.message)),
      (verifications) => emit(VerificationAdminLoaded(pendingVerifications: verifications)),
    );
  }

  Future<void> _onLoadVerificationHistory(
    LoadVerificationHistory event,
    Emitter<VerificationAdminState> emit,
  ) async {
    final currentState = state;
    if (currentState is VerificationAdminLoaded) {
      final result = await repository.getVerificationHistory(limit: event.limit);

      result.fold(
        (failure) => emit(VerificationAdminError(
          message: failure.message,
          pendingVerifications: currentState.pendingVerifications,
        )),
        (history) => emit(currentState.copyWith(verificationHistory: history)),
      );
    }
  }

  Future<void> _onApproveVerification(
    ApproveVerification event,
    Emitter<VerificationAdminState> emit,
  ) async {
    final currentState = state;
    if (currentState is VerificationAdminLoaded) {
      emit(VerificationAdminActionLoading(
        pendingVerifications: currentState.pendingVerifications,
        verificationHistory: currentState.verificationHistory,
        userId: event.userId,
      ));

      final result = await repository.approveVerification(event.userId, event.adminId);

      await result.fold(
        (failure) async => emit(VerificationAdminError(
          message: failure.message,
          pendingVerifications: currentState.pendingVerifications,
          verificationHistory: currentState.verificationHistory,
        )),
        (_) async {
          // Reload pending verifications
          final refreshResult = await repository.getPendingVerifications();
          refreshResult.fold(
            (failure) => emit(VerificationAdminActionSuccess(
              pendingVerifications: currentState.pendingVerifications
                  .where((p) => p.userId != event.userId)
                  .toList(),
              verificationHistory: currentState.verificationHistory,
              message: 'Verification approved successfully',
            )),
            (verifications) => emit(VerificationAdminActionSuccess(
              pendingVerifications: verifications,
              verificationHistory: currentState.verificationHistory,
              message: 'Verification approved successfully',
            )),
          );
        },
      );
    }
  }

  Future<void> _onRejectVerification(
    RejectVerification event,
    Emitter<VerificationAdminState> emit,
  ) async {
    final currentState = state;
    if (currentState is VerificationAdminLoaded) {
      emit(VerificationAdminActionLoading(
        pendingVerifications: currentState.pendingVerifications,
        verificationHistory: currentState.verificationHistory,
        userId: event.userId,
      ));

      final result = await repository.rejectVerification(
        event.userId,
        event.adminId,
        event.reason,
      );

      await result.fold(
        (failure) async => emit(VerificationAdminError(
          message: failure.message,
          pendingVerifications: currentState.pendingVerifications,
          verificationHistory: currentState.verificationHistory,
        )),
        (_) async {
          // Reload pending verifications
          final refreshResult = await repository.getPendingVerifications();
          refreshResult.fold(
            (failure) => emit(VerificationAdminActionSuccess(
              pendingVerifications: currentState.pendingVerifications
                  .where((p) => p.userId != event.userId)
                  .toList(),
              verificationHistory: currentState.verificationHistory,
              message: 'Verification rejected',
            )),
            (verifications) => emit(VerificationAdminActionSuccess(
              pendingVerifications: verifications,
              verificationHistory: currentState.verificationHistory,
              message: 'Verification rejected',
            )),
          );
        },
      );
    }
  }

  Future<void> _onRequestBetterPhoto(
    RequestBetterPhoto event,
    Emitter<VerificationAdminState> emit,
  ) async {
    final currentState = state;
    if (currentState is VerificationAdminLoaded) {
      emit(VerificationAdminActionLoading(
        pendingVerifications: currentState.pendingVerifications,
        verificationHistory: currentState.verificationHistory,
        userId: event.userId,
      ));

      final result = await repository.requestBetterPhoto(
        event.userId,
        event.adminId,
        event.reason,
      );

      await result.fold(
        (failure) async => emit(VerificationAdminError(
          message: failure.message,
          pendingVerifications: currentState.pendingVerifications,
          verificationHistory: currentState.verificationHistory,
        )),
        (_) async {
          // Reload pending verifications
          final refreshResult = await repository.getPendingVerifications();
          refreshResult.fold(
            (failure) => emit(VerificationAdminActionSuccess(
              pendingVerifications: currentState.pendingVerifications
                  .where((p) => p.userId != event.userId)
                  .toList(),
              verificationHistory: currentState.verificationHistory,
              message: 'Better photo requested',
            )),
            (verifications) => emit(VerificationAdminActionSuccess(
              pendingVerifications: verifications,
              verificationHistory: currentState.verificationHistory,
              message: 'Better photo requested',
            )),
          );
        },
      );
    }
  }

  Future<void> _onRefreshVerifications(
    RefreshVerifications event,
    Emitter<VerificationAdminState> emit,
  ) async {
    final result = await repository.getPendingVerifications();

    result.fold(
      (failure) => emit(VerificationAdminError(message: failure.message)),
      (verifications) => emit(VerificationAdminLoaded(pendingVerifications: verifications)),
    );
  }

  Future<void> _onBulkApproveVerifications(
    BulkApproveVerifications event,
    Emitter<VerificationAdminState> emit,
  ) async {
    final currentState = state;
    if (currentState is VerificationAdminLoaded) {
      emit(VerificationAdminBulkActionLoading(
        pendingVerifications: currentState.pendingVerifications,
        verificationHistory: currentState.verificationHistory,
        userIds: event.userIds,
      ));

      final result = await repository.bulkApproveVerifications(
        event.userIds,
        event.adminId,
      );

      await result.fold(
        (failure) async => emit(VerificationAdminError(
          message: failure.message,
          pendingVerifications: currentState.pendingVerifications,
          verificationHistory: currentState.verificationHistory,
        )),
        (_) async {
          final refreshResult = await repository.getPendingVerifications();
          refreshResult.fold(
            (failure) => emit(VerificationAdminActionSuccess(
              pendingVerifications: currentState.pendingVerifications
                  .where((p) => !event.userIds.contains(p.userId))
                  .toList(),
              verificationHistory: currentState.verificationHistory,
              message: '${event.userIds.length} verifications approved',
            )),
            (verifications) => emit(VerificationAdminActionSuccess(
              pendingVerifications: verifications,
              verificationHistory: currentState.verificationHistory,
              message: '${event.userIds.length} verifications approved',
            )),
          );
        },
      );
    }
  }

  Future<void> _onBulkRequestBetterPhoto(
    BulkRequestBetterPhoto event,
    Emitter<VerificationAdminState> emit,
  ) async {
    final currentState = state;
    if (currentState is VerificationAdminLoaded) {
      emit(VerificationAdminBulkActionLoading(
        pendingVerifications: currentState.pendingVerifications,
        verificationHistory: currentState.verificationHistory,
        userIds: event.userIds,
      ));

      final result = await repository.bulkRequestBetterPhoto(
        event.userIds,
        event.adminId,
        event.reason,
      );

      await result.fold(
        (failure) async => emit(VerificationAdminError(
          message: failure.message,
          pendingVerifications: currentState.pendingVerifications,
          verificationHistory: currentState.verificationHistory,
        )),
        (_) async {
          final refreshResult = await repository.getPendingVerifications();
          refreshResult.fold(
            (failure) => emit(VerificationAdminActionSuccess(
              pendingVerifications: currentState.pendingVerifications
                  .where((p) => !event.userIds.contains(p.userId))
                  .toList(),
              verificationHistory: currentState.verificationHistory,
              message: 'Better photo requested for ${event.userIds.length} users',
            )),
            (verifications) => emit(VerificationAdminActionSuccess(
              pendingVerifications: verifications,
              verificationHistory: currentState.verificationHistory,
              message: 'Better photo requested for ${event.userIds.length} users',
            )),
          );
        },
      );
    }
  }
}
