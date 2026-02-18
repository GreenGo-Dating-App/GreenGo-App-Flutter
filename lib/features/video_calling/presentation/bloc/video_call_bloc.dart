import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
// Agora SDK disabled for development
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../domain/entities/video_call.dart';
import '../../domain/usecases/initiate_call.dart';
import '../../domain/usecases/answer_call.dart';
import '../../domain/usecases/decline_call.dart';
import '../../domain/usecases/end_call.dart';
import '../../domain/usecases/listen_for_incoming_calls.dart';
import '../../domain/usecases/get_sdk_config.dart';
import '../../domain/usecases/get_call_history.dart';
import '../../domain/repositories/video_calling_repository.dart';
import '../../../chat/domain/usecases/block_user.dart';
import 'video_call_event.dart';
import 'video_call_state.dart';

// Stub types for when Agora SDK is disabled
class RtcEngine {
  Future<void> muteLocalAudioStream(bool mute) async {}
  Future<void> muteLocalVideoStream(bool mute) async {}
  Future<void> switchCamera() async {}
  Future<void> setEnableSpeakerphone(bool enabled) async {}
  Future<void> leaveChannel() async {}
  Future<void> release() async {}
  Future<void> initialize(RtcEngineContext context) async {}
  void registerEventHandler(RtcEngineEventHandler handler) {}
  Future<void> enableVideo() async {}
  Future<void> startPreview() async {}
  Future<void> joinChannel({
    required String token,
    required String channelId,
    required int uid,
    required ChannelMediaOptions options,
  }) async {}
}

RtcEngine createAgoraRtcEngine() => RtcEngine();

class RtcEngineContext {
  final String appId;
  final ChannelProfileType channelProfile;
  const RtcEngineContext({required this.appId, required this.channelProfile});
}

class RtcEngineEventHandler {
  final void Function(RtcConnection, int)? onJoinChannelSuccess;
  final void Function(RtcConnection, int, int)? onUserJoined;
  final void Function(RtcConnection, int, UserOfflineReasonType)? onUserOffline;
  final void Function(ErrorCodeType, String)? onError;
  final void Function(RtcConnection, int, QualityType, QualityType)? onNetworkQuality;

  const RtcEngineEventHandler({
    this.onJoinChannelSuccess,
    this.onUserJoined,
    this.onUserOffline,
    this.onError,
    this.onNetworkQuality,
  });
}

class RtcConnection {
  final String? channelId;
  const RtcConnection({this.channelId});
}

enum ChannelProfileType { channelProfileCommunication }
enum ClientRoleType { clientRoleBroadcaster }
enum UserOfflineReasonType { userOfflineQuit }
enum ErrorCodeType { errOk }

class ChannelMediaOptions {
  final ClientRoleType? clientRoleType;
  final ChannelProfileType? channelProfile;
  const ChannelMediaOptions({this.clientRoleType, this.channelProfile});
}

class QualityType {
  static const qualityExcellent = QualityType._('excellent');
  static const qualityGood = QualityType._('good');
  static const qualityPoor = QualityType._('poor');
  static const qualityBad = QualityType._('bad');
  static const qualityVbad = QualityType._('vbad');
  static const qualityDown = QualityType._('down');
  static const qualityUnknown = QualityType._('unknown');
  final String _value;
  const QualityType._(this._value);
}

/// Video Call BLoC
///
/// Manages video calling state including Agora SDK integration
class VideoCallBloc extends Bloc<VideoCallEvent, VideoCallState> {
  final InitiateCall initiateCall;
  final AnswerCall answerCall;
  final DeclineCall declineCall;
  final EndCall endCall;
  final ListenForIncomingCalls listenForIncomingCalls;
  final GetSDKConfig getSDKConfig;
  final GetCallHistory getCallHistory;
  final VideoCallingRepository repository;
  final IsUserBlocked? isUserBlocked;

  RtcEngine? _engine;
  StreamSubscription? _incomingCallSubscription;
  StreamSubscription? _callUpdatesSubscription;
  Timer? _durationTimer;
  Duration _callDuration = Duration.zero;

  // Agora config - should be set from environment
  String? _agoraAppId;
  String? _agoraToken;
  String? _currentChannelId;
  int? _localUid;

  VideoCallBloc({
    required this.initiateCall,
    required this.answerCall,
    required this.declineCall,
    required this.endCall,
    required this.listenForIncomingCalls,
    required this.getSDKConfig,
    required this.getCallHistory,
    required this.repository,
    this.isUserBlocked,
  }) : super(const VideoCallInitial()) {
    on<VideoCallStartListening>(_onStartListening);
    on<VideoCallStopListening>(_onStopListening);
    on<VideoCallIncoming>(_onIncomingCall);
    on<VideoCallInitiate>(_onInitiateCall);
    on<VideoCallAnswer>(_onAnswerCall);
    on<VideoCallDecline>(_onDeclineCall);
    on<VideoCallEnd>(_onEndCall);
    on<VideoCallToggleAudio>(_onToggleAudio);
    on<VideoCallToggleVideo>(_onToggleVideo);
    on<VideoCallSwitchCamera>(_onSwitchCamera);
    on<VideoCallToggleSpeaker>(_onToggleSpeaker);
    on<VideoCallRemoteUserJoined>(_onRemoteUserJoined);
    on<VideoCallRemoteUserLeft>(_onRemoteUserLeft);
    on<VideoCallStatusUpdated>(_onStatusUpdated);
    on<VideoCallQualityChanged>(_onQualityChanged);
    on<VideoCallError>(_onError);
    on<VideoCallConnected>(_onConnected);
    on<VideoCallLoadHistory>(_onLoadHistory);
    on<VideoCallSubmitFeedback>(_onSubmitFeedback);
    on<VideoCallDurationTick>(_onDurationTick);
  }

  /// Start listening for incoming calls
  Future<void> _onStartListening(
    VideoCallStartListening event,
    Emitter<VideoCallState> emit,
  ) async {
    emit(VideoCallListening(event.userId));

    await _incomingCallSubscription?.cancel();
    _incomingCallSubscription = listenForIncomingCalls(event.userId).listen(
      (result) {
        result.fold(
          (failure) => add(VideoCallError(failure.message)),
          (call) {
            if (call != null) {
              add(VideoCallIncoming(call));
            }
          },
        );
      },
    );
  }

  /// Stop listening for incoming calls
  Future<void> _onStopListening(
    VideoCallStopListening event,
    Emitter<VideoCallState> emit,
  ) async {
    await _incomingCallSubscription?.cancel();
    emit(const VideoCallInitial());
  }

  /// Handle incoming call
  Future<void> _onIncomingCall(
    VideoCallIncoming event,
    Emitter<VideoCallState> emit,
  ) async {
    // Check if caller is blocked
    if (isUserBlocked != null) {
      final blockedResult = await isUserBlocked!(
        IsUserBlockedParams(
          userId: event.call.receiverId,
          otherUserId: event.call.callerId,
        ),
      );

      final isBlocked = blockedResult.fold(
        (failure) => false,
        (blocked) => blocked,
      );

      if (isBlocked) {
        // Silently decline - don't show incoming call from blocked user
        await declineCall(DeclineCallParams(
          callId: event.call.callId,
          userId: event.call.receiverId,
        ));
        return;
      }
    }

    // TODO: Get caller info from user profile
    emit(VideoCallRinging(
      call: event.call,
      callerName: 'Caller', // Fetch from user profile
      callerPhotoUrl: null,
    ));
  }

  /// Initiate outgoing call
  Future<void> _onInitiateCall(
    VideoCallInitiate event,
    Emitter<VideoCallState> emit,
  ) async {
    // Check if receiver is blocked
    if (isUserBlocked != null) {
      final blockedResult = await isUserBlocked!(
        IsUserBlockedParams(
          userId: event.callerId,
          otherUserId: event.receiverId,
        ),
      );

      final isBlocked = blockedResult.fold(
        (failure) => false,
        (blocked) => blocked,
      );

      if (isBlocked) {
        emit(const VideoCallFailure(
          'Cannot call this user. They may have blocked you or you have blocked them.',
        ));
        return;
      }
    }

    final result = await initiateCall(InitiateCallParams(
      callerId: event.callerId,
      receiverId: event.receiverId,
    ));

    result.fold(
      (failure) => emit(VideoCallFailure(failure.message)),
      (call) {
        emit(VideoCallOutgoing(
          call: call,
          receiverName: event.receiverName,
          receiverPhotoUrl: event.receiverPhotoUrl,
        ));

        // Listen for call status updates
        _listenToCallUpdates(call.callId);
      },
    );
  }

  /// Answer incoming call
  Future<void> _onAnswerCall(
    VideoCallAnswer event,
    Emitter<VideoCallState> emit,
  ) async {
    if (state is! VideoCallRinging) return;
    final ringingState = state as VideoCallRinging;

    emit(VideoCallConnecting(ringingState.call));

    final result = await answerCall(AnswerCallParams(
      callId: event.callId,
      userId: event.userId,
    ));

    await result.fold(
      (failure) async => emit(VideoCallFailure(failure.message)),
      (call) async {
        // Initialize Agora and join channel
        await _initializeAgora(call, event.userId);
      },
    );
  }

  /// Decline incoming call
  Future<void> _onDeclineCall(
    VideoCallDecline event,
    Emitter<VideoCallState> emit,
  ) async {
    final result = await declineCall(DeclineCallParams(
      callId: event.callId,
      userId: event.userId,
    ));

    result.fold(
      (failure) => emit(VideoCallFailure(failure.message)),
      (_) => emit(const VideoCallInitial()),
    );
  }

  /// End active call
  Future<void> _onEndCall(
    VideoCallEnd event,
    Emitter<VideoCallState> emit,
  ) async {
    VideoCall? currentCall;
    if (state is VideoCallActive) {
      currentCall = (state as VideoCallActive).call;
    } else if (state is VideoCallOutgoing) {
      currentCall = (state as VideoCallOutgoing).call;
    } else if (state is VideoCallConnecting) {
      currentCall = (state as VideoCallConnecting).call;
    }

    // Leave Agora channel
    await _leaveChannel();

    final result = await endCall(EndCallParams(
      callId: event.callId,
      userId: event.userId,
    ));

    result.fold(
      (failure) => emit(VideoCallFailure(failure.message)),
      (_) {
        if (currentCall != null) {
          emit(VideoCallEnded(
            call: currentCall,
            duration: _callDuration,
          ));
        } else {
          emit(const VideoCallInitial());
        }
      },
    );
  }

  /// Toggle audio mute
  Future<void> _onToggleAudio(
    VideoCallToggleAudio event,
    Emitter<VideoCallState> emit,
  ) async {
    if (state is! VideoCallActive) return;
    final currentState = state as VideoCallActive;

    final newMuteState = !currentState.isAudioMuted;
    await _engine?.muteLocalAudioStream(newMuteState);

    emit(currentState.copyWith(isAudioMuted: newMuteState));
  }

  /// Toggle video mute
  Future<void> _onToggleVideo(
    VideoCallToggleVideo event,
    Emitter<VideoCallState> emit,
  ) async {
    if (state is! VideoCallActive) return;
    final currentState = state as VideoCallActive;

    final newMuteState = !currentState.isVideoMuted;
    await _engine?.muteLocalVideoStream(newMuteState);

    emit(currentState.copyWith(isVideoMuted: newMuteState));
  }

  /// Switch camera
  Future<void> _onSwitchCamera(
    VideoCallSwitchCamera event,
    Emitter<VideoCallState> emit,
  ) async {
    if (state is! VideoCallActive) return;
    final currentState = state as VideoCallActive;

    await _engine?.switchCamera();

    emit(currentState.copyWith(isFrontCamera: !currentState.isFrontCamera));
  }

  /// Toggle speaker
  Future<void> _onToggleSpeaker(
    VideoCallToggleSpeaker event,
    Emitter<VideoCallState> emit,
  ) async {
    if (state is! VideoCallActive) return;
    final currentState = state as VideoCallActive;

    final newSpeakerState = !currentState.isSpeakerOn;
    await _engine?.setEnableSpeakerphone(newSpeakerState);

    emit(currentState.copyWith(isSpeakerOn: newSpeakerState));
  }

  /// Remote user joined
  Future<void> _onRemoteUserJoined(
    VideoCallRemoteUserJoined event,
    Emitter<VideoCallState> emit,
  ) async {
    if (state is! VideoCallActive) return;
    final currentState = state as VideoCallActive;

    emit(currentState.copyWith(remoteUid: event.remoteUid));
  }

  /// Remote user left
  Future<void> _onRemoteUserLeft(
    VideoCallRemoteUserLeft event,
    Emitter<VideoCallState> emit,
  ) async {
    // Remote user left, end the call
    if (state is VideoCallActive) {
      final activeState = state as VideoCallActive;
      add(VideoCallEnd(
        callId: activeState.call.callId,
        userId: activeState.call.callerId,
      ));
    }
  }

  /// Call status updated
  Future<void> _onStatusUpdated(
    VideoCallStatusUpdated event,
    Emitter<VideoCallState> emit,
  ) async {
    final call = event.call;

    switch (call.status) {
      case VideoCallStatus.active:
        if (state is VideoCallOutgoing) {
          final outgoingState = state as VideoCallOutgoing;
          // Call was answered, initialize Agora
          await _initializeAgora(call, call.callerId);
        }
        break;
      case VideoCallStatus.declined:
        emit(VideoCallDeclined(call));
        await _leaveChannel();
        break;
      case VideoCallStatus.ended:
        emit(VideoCallEnded(call: call, duration: call.duration));
        await _leaveChannel();
        break;
      case VideoCallStatus.missed:
        emit(VideoCallMissed(call));
        break;
      case VideoCallStatus.failed:
        emit(VideoCallFailure('Call failed', call: call));
        await _leaveChannel();
        break;
      default:
        break;
    }
  }

  /// Quality changed
  Future<void> _onQualityChanged(
    VideoCallQualityChanged event,
    Emitter<VideoCallState> emit,
  ) async {
    if (state is! VideoCallActive) return;
    final currentState = state as VideoCallActive;

    emit(currentState.copyWith(connectionQuality: event.quality));
  }

  /// Error occurred
  Future<void> _onError(
    VideoCallError event,
    Emitter<VideoCallState> emit,
  ) async {
    emit(VideoCallFailure(event.message));
  }

  /// Call connected
  Future<void> _onConnected(
    VideoCallConnected event,
    Emitter<VideoCallState> emit,
  ) async {
    // This is called when Agora successfully joins the channel
    // The active state should already be set
  }

  /// Load call history
  Future<void> _onLoadHistory(
    VideoCallLoadHistory event,
    Emitter<VideoCallState> emit,
  ) async {
    final result = await getCallHistory(GetCallHistoryParams(
      userId: event.userId,
    ));

    result.fold(
      (failure) => emit(VideoCallFailure(failure.message)),
      (history) => emit(VideoCallHistoryLoaded(history)),
    );
  }

  /// Submit feedback
  Future<void> _onSubmitFeedback(
    VideoCallSubmitFeedback event,
    Emitter<VideoCallState> emit,
  ) async {
    final result = await repository.submitFeedback(
      callId: event.callId,
      userId: event.userId,
      rating: event.rating,
      issues: event.issues,
      comments: event.comments,
    );

    result.fold(
      (failure) => emit(VideoCallFailure(failure.message)),
      (_) => emit(const VideoCallFeedbackSubmitted()),
    );
  }

  /// Initialize Agora SDK
  Future<void> _initializeAgora(VideoCall call, String userId) async {
    try {
      // Get SDK config (includes token)
      final configResult = await getSDKConfig(GetSDKConfigParams(
        callId: call.callId,
        userId: userId,
      ));

      final config = configResult.fold(
        (failure) => throw Exception(failure.message),
        (config) => config,
      );

      _agoraAppId = config.appId;
      _agoraToken = config.token;
      _currentChannelId = config.channelId;
      _localUid = config.uid;

      // Create Agora engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: _agoraAppId!,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Set up event handlers
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          add(const VideoCallConnected());
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          add(VideoCallRemoteUserJoined(remoteUid));
        },
        onUserOffline: (connection, remoteUid, reason) {
          add(VideoCallRemoteUserLeft(remoteUid));
        },
        onError: (err, msg) {
          add(VideoCallError('Agora error: $msg'));
        },
        onNetworkQuality: (connection, remoteUid, txQuality, rxQuality) {
          final quality = _mapAgoraQuality(txQuality);
          add(VideoCallQualityChanged(quality));
        },
      ));

      // Enable video
      await _engine!.enableVideo();
      await _engine!.startPreview();

      // Join channel
      if (_currentChannelId == null || _localUid == null) {
        throw Exception('Channel ID or UID not configured');
      }
      await _engine!.joinChannel(
        token: _agoraToken ?? '',
        channelId: _currentChannelId!,
        uid: _localUid!,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      // Start duration timer
      _startDurationTimer();

      // Emit active state
      emit(VideoCallActive(
        call: call,
        localUid: _localUid,
      ));
    } catch (e) {
      emit(VideoCallFailure('Failed to initialize video call: $e'));
    }
  }

  /// Leave Agora channel
  Future<void> _leaveChannel() async {
    _durationTimer?.cancel();
    _callUpdatesSubscription?.cancel();

    try {
      await _engine?.leaveChannel();
      await _engine?.release();
      _engine = null;
    } catch (e) {
      // Ignore errors during cleanup
    }

    _callDuration = Duration.zero;
  }

  /// Handle duration tick from timer
  void _onDurationTick(
    VideoCallDurationTick event,
    Emitter<VideoCallState> emit,
  ) {
    if (state is VideoCallActive) {
      final currentState = state as VideoCallActive;
      emit(currentState.copyWith(callDuration: event.duration));
    }
  }

  /// Start call duration timer
  void _startDurationTimer() {
    _callDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDuration += const Duration(seconds: 1);
      if (!isClosed) {
        add(VideoCallDurationTick(_callDuration));
      }
    });
  }

  /// Listen to call status updates
  void _listenToCallUpdates(String callId) {
    _callUpdatesSubscription?.cancel();
    _callUpdatesSubscription = repository.listenToCallUpdates(callId).listen(
      (result) {
        result.fold(
          (failure) => add(VideoCallError(failure.message)),
          (call) => add(VideoCallStatusUpdated(call)),
        );
      },
    );
  }

  /// Map Agora quality to our ConnectionQuality enum
  ConnectionQuality _mapAgoraQuality(QualityType quality) {
    switch (quality) {
      case QualityType.qualityExcellent:
        return ConnectionQuality.excellent;
      case QualityType.qualityGood:
        return ConnectionQuality.good;
      case QualityType.qualityPoor:
        return ConnectionQuality.fair;
      case QualityType.qualityBad:
        return ConnectionQuality.poor;
      case QualityType.qualityVbad:
      case QualityType.qualityDown:
        return ConnectionQuality.veryPoor;
      default:
        return ConnectionQuality.good;
    }
  }

  /// Get the Agora engine for video views
  RtcEngine? get engine => _engine;

  @override
  Future<void> close() {
    _incomingCallSubscription?.cancel();
    _callUpdatesSubscription?.cancel();
    _durationTimer?.cancel();
    _engine?.release();
    return super.close();
  }
}
