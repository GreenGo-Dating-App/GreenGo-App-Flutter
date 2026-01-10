import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/video_call.dart';
import '../../domain/repositories/video_calling_repository.dart';
import '../datasources/video_calling_remote_datasource.dart';

/// Implementation of VideoCallingRepository
class VideoCallingRepositoryImpl implements VideoCallingRepository {
  final VideoCallingRemoteDataSource remoteDataSource;

  VideoCallingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, VideoCall>> initiateCall({
    required String callerId,
    required String receiverId,
    VideoCallType type = VideoCallType.oneOnOne,
  }) async {
    try {
      final result = await remoteDataSource.initiateCall(
        callerId: callerId,
        receiverId: receiverId,
        type: type,
      );
      return Right(result.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VideoCall>> answerCall({
    required String callId,
    required String userId,
  }) async {
    try {
      final result = await remoteDataSource.answerCall(
        callId: callId,
        userId: userId,
      );
      return Right(result.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> declineCall({
    required String callId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.declineCall(
        callId: callId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> endCall({
    required String callId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.endCall(
        callId: callId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VideoSDKConfig>> getSDKConfig({
    required String callId,
    required String userId,
  }) async {
    try {
      final result = await remoteDataSource.getSDKConfig(
        callId: callId,
        userId: userId,
      );
      return Right(result.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, VideoCall?>> listenForIncomingCalls(String userId) {
    return remoteDataSource
        .listenForIncomingCalls(userId)
        .map<Either<Failure, VideoCall?>>((call) {
      if (call == null) return const Right(null);
      return Right<Failure, VideoCall?>(call.toEntity());
    }).transform(
      StreamTransformer<Either<Failure, VideoCall?>,
          Either<Failure, VideoCall?>>.fromHandlers(
        handleData: (data, sink) => sink.add(data),
        handleError: (error, stackTrace, sink) =>
            sink.add(Left(ServerFailure(error.toString()))),
      ),
    );
  }

  @override
  Stream<Either<Failure, VideoCall>> listenToCallUpdates(String callId) {
    try {
      return remoteDataSource.listenToCallUpdates(callId).map((call) {
        return Right<Failure, VideoCall>(call.toEntity());
      }).handleError((error) {
        return Left<Failure, VideoCall>(ServerFailure(error.toString()));
      });
    } catch (e) {
      return Stream.value(Left(ServerFailure(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> sendSignal({
    required String callId,
    required CallSignalType type,
    required String fromUserId,
    required String toUserId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await remoteDataSource.sendSignal(
        callId: callId,
        type: type,
        fromUserId: fromUserId,
        toUserId: toUserId,
        data: data,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, CallSignal>> listenToSignals({
    required String callId,
    required String userId,
  }) {
    try {
      return remoteDataSource
          .listenToSignals(callId: callId, userId: userId)
          .map((signal) {
        return Right<Failure, CallSignal>(signal.toEntity());
      }).handleError((error) {
        return Left<Failure, CallSignal>(ServerFailure(error.toString()));
      });
    } catch (e) {
      return Stream.value(Left(ServerFailure(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> updateCallQuality({
    required String callId,
    required VideoCallQuality quality,
  }) async {
    try {
      await remoteDataSource.updateCallQuality(
        callId: callId,
        quality: quality,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CallHistoryEntry>>> getCallHistory({
    required String userId,
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      final result = await remoteDataSource.getCallHistory(
        userId: userId,
        limit: limit,
        before: before,
      );
      return Right(result.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VideoCall>> getCall(String callId) async {
    try {
      final result = await remoteDataSource.getCall(callId);
      return Right(result.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleMuteAudio({
    required String callId,
    required String userId,
    required bool isMuted,
  }) async {
    try {
      await remoteDataSource.toggleMuteAudio(
        callId: callId,
        userId: userId,
        isMuted: isMuted,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleMuteVideo({
    required String callId,
    required String userId,
    required bool isMuted,
  }) async {
    try {
      await remoteDataSource.toggleMuteVideo(
        callId: callId,
        userId: userId,
        isMuted: isMuted,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> switchCamera() async {
    // This is handled locally by Agora SDK
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> toggleSpeaker(bool enabled) async {
    // This is handled locally by Agora SDK
    return const Right(null);
  }

  @override
  Future<Either<Failure, CallRecording>> startRecording({
    required String callId,
    required String userId,
    required bool consentGiven,
  }) async {
    try {
      final result = await remoteDataSource.startRecording(
        callId: callId,
        userId: userId,
        consentGiven: consentGiven,
      );
      return Right(CallRecording(
        recordingId: result['recordingId'] as String,
        callId: callId,
        userId: userId,
        startedAt: DateTime.now(),
        fileSizeMB: 0,
        consentGiven: consentGiven,
        participants: [],
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CallRecording>> stopRecording({
    required String callId,
    required String recordingId,
  }) async {
    try {
      final result = await remoteDataSource.stopRecording(
        callId: callId,
        recordingId: recordingId,
      );
      return Right(CallRecording(
        recordingId: recordingId,
        callId: callId,
        userId: result['userId'] as String? ?? '',
        startedAt: DateTime.now(),
        endedAt: DateTime.now(),
        duration: Duration(seconds: result['duration'] as int? ?? 0),
        fileSizeMB: 0,
        consentGiven: true,
        participants: [],
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitFeedback({
    required String callId,
    required String userId,
    required int rating,
    List<String>? issues,
    String? comments,
  }) async {
    try {
      await remoteDataSource.submitFeedback(
        callId: callId,
        userId: userId,
        rating: rating,
        issues: issues,
        comments: comments,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CallStatistics>> getCallStatistics({
    required String userId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    try {
      final result = await remoteDataSource.getCallStatistics(
        userId: userId,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      return Right(CallStatistics(
        userId: userId,
        periodStart: periodStart,
        periodEnd: periodEnd,
        totalCalls: result['totalCalls'] as int? ?? 0,
        answeredCalls: result['answeredCalls'] as int? ?? 0,
        missedCalls: result['missedCalls'] as int? ?? 0,
        totalDuration:
            Duration(seconds: result['totalDurationSeconds'] as int? ?? 0),
        averageQuality: 4.0,
        connectionIssues: 0,
        qualityBreakdown: {},
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setVirtualBackground({
    required VirtualBackground background,
  }) async {
    // Handled locally by Agora SDK
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> setBeautyMode({
    required BeautyMode beautyMode,
  }) async {
    // Handled locally by Agora SDK
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> toggleNoiseSuppression(bool enabled) async {
    // Handled locally by Agora SDK
    return const Right(null);
  }

  @override
  Future<Either<Failure, VideoCall?>> getActiveCall(String userId) async {
    try {
      final result = await remoteDataSource.getActiveCall(userId);
      if (result == null) return const Right(null);
      return Right(result.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
