import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized sound management for the GreenGo app.
///
/// Plays short asset-based sound effects from `assets/sounds/`. They can be
/// turned off in Profile > Settings > Sound effects (saved on this device, so
/// it applies from the first frame). Push-notification sounds are separate
/// (Notification settings > Sound).
class AppSoundService {
  factory AppSoundService() => _instance;
  AppSoundService._();
  static final AppSoundService _instance = AppSoundService._();

  static const String _prefKey = 'app_sounds_enabled';

  /// A small pool so a quick tap does not cut off a celebration that is still
  /// playing (one shared player stopped the previous sound on every play).
  static const int _poolSize = 3;
  final List<AudioPlayer> _players = List.generate(
    _poolSize,
    (i) => AudioPlayer(playerId: 'greengo_sfx_$i'),
  );
  int _next = 0;

  /// The same sound re-triggered within this window is skipped (double taps,
  /// several list rows reacting to one event).
  static const Duration _minRepeat = Duration(milliseconds: 80);
  final Map<AppSound, DateTime> _lastPlayed = {};

  bool _soundEnabled = true;
  double _volume = 0.85;
  bool _ready = false;
  Future<void>? _initializing;

  Future<void> initialize() => _initializing ??= _init();

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool(_prefKey) ?? true;
    } catch (_) {}
    try {
      // iOS needs an explicit audio session or SFX silently don't play.
      // `playback` is audible regardless of the mute switch; `mixWithOthers`
      // keeps it from interrupting the user's music. Android keeps its defaults.
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
          android: const AudioContextAndroid(),
        ),
      );
      for (final p in _players) {
        await p.setReleaseMode(ReleaseMode.stop);
        // Use the default media-player mode. lowLatency (SoundPool on Android)
        // silently dropped playback after stop() — sounds wouldn't play.
        await p.setPlayerMode(PlayerMode.mediaPlayer);
      }
      _ready = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Sound] init failed: $e');
    }
  }

  Future<void> play(AppSound sound) async {
    if (!_soundEnabled) return;
    final now = DateTime.now();
    final last = _lastPlayed[sound];
    if (last != null && now.difference(last) < _minRepeat) return;
    _lastPlayed[sound] = now;
    final vol = (_volume * sound.volumeMultiplier).clamp(0.0, 1.0);
    await _playPath(sound.assetPath, vol);
  }

  Future<void> playWithVolume(AppSound sound, double volume) async {
    if (!_soundEnabled) return;
    await _playPath(sound.assetPath, volume.clamp(0.0, 1.0));
  }

  Future<void> _playPath(String assetPath, double volume) async {
    try {
      if (!_ready) await initialize();
      final player = _players[_next];
      _next = (_next + 1) % _poolSize;
      // Restart so rapid effects (e.g. quick messages) retrigger cleanly.
      await player.stop();
      await player.play(AssetSource(assetPath), volume: volume);
    } catch (e) {
      // Missing asset / platform issue — never let SFX break the app.
      if (kDebugMode) debugPrint('[Sound] play $assetPath failed: $e');
    }
  }

  /// Turns in-app sound effects on or off and remembers it on this device.
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    if (!enabled) await stopAll();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled);
    } catch (_) {}
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
  }

  bool get isSoundEnabled => _soundEnabled;
  double get volume => _volume;

  Future<void> playBgMusic(AppSound sound) async {}
  Future<void> stopBgMusic() async {}
  Future<void> stopAll() async {
    for (final p in _players) {
      try {
        await p.stop();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    for (final p in _players) {
      try {
        await p.dispose();
      } catch (_) {}
    }
  }
}

/// All sounds used across the GreenGo app (files in `assets/sounds/`, made
/// with the earshot sound bank: low / mid sounds, no bells or high notes).
/// Quiet everyday UI sounds use a low volume multiplier.
enum AppSound {
  // Chat
  newMessage('sounds/new_message.mp3', category: SoundCategory.chat),
  newMessageFirstTime('sounds/new_message_first.mp3', category: SoundCategory.chat),
  messageSent('sounds/sent_message.mp3', category: SoundCategory.chat),
  messageReceived('sounds/new_message.mp3', category: SoundCategory.chat),
  typingIndicator('sounds/typing.mp3', category: SoundCategory.chat, volumeMultiplier: 0.3),
  reaction('sounds/reaction.mp3', category: SoundCategory.chat, volumeMultiplier: 0.6),
  messageDeleted('sounds/message_deleted.mp3', category: SoundCategory.chat, volumeMultiplier: 0.6),
  // Social
  like('sounds/like.mp3', category: SoundCategory.social, volumeMultiplier: 0.6),
  follow('sounds/follow.mp3', category: SoundCategory.social, volumeMultiplier: 0.7),
  longPress('sounds/long_press.mp3', category: SoundCategory.ui, volumeMultiplier: 0.3),
  // Communities / events
  communityJoin('sounds/community_join.mp3', category: SoundCategory.social),
  eventRsvp('sounds/event_rsvp.mp3', category: SoundCategory.events),
  eventReminder('sounds/event_reminder.mp3', category: SoundCategory.events),
  ticketPurchased('sounds/ticket_purchased.mp3', category: SoundCategory.events),
  scanOk('sounds/scan_ok.mp3', category: SoundCategory.events),
  scanDenied('sounds/scan_denied.mp3', category: SoundCategory.events),
  // Coins / purchases
  coinEarned('sounds/coin_earned.mp3', category: SoundCategory.gamification, volumeMultiplier: 0.7),
  purchaseSuccess('sounds/purchase_success.mp3', category: SoundCategory.gamification),
  giftSent('sounds/gift_sent.mp3', category: SoundCategory.gamification, volumeMultiplier: 0.8),
  limitReached('sounds/limit_reached.mp3', category: SoundCategory.ui, volumeMultiplier: 0.6),
  // Learning (no screen uses these yet)
  correctAnswer('sounds/correct_answer.mp3', category: SoundCategory.learning),
  wrongAnswer('sounds/wrong_answer.mp3', category: SoundCategory.learning),
  flashcardFlip('sounds/flashcard_flip.mp3', category: SoundCategory.learning, volumeMultiplier: 0.5),
  lessonComplete('sounds/lesson_complete.mp3', category: SoundCategory.learning),
  quizStart('sounds/quiz_start.mp3', category: SoundCategory.learning),
  quizComplete('sounds/quiz_complete.mp3', category: SoundCategory.learning),
  streakMilestone('sounds/streak_milestone.mp3', category: SoundCategory.learning),
  wordLearned('sounds/word_learned.mp3', category: SoundCategory.learning, volumeMultiplier: 0.5),
  // Gamification
  xpGained('sounds/xp_gained.mp3', category: SoundCategory.gamification, volumeMultiplier: 0.6),
  levelUp('sounds/level_up.mp3', category: SoundCategory.gamification),
  achievementUnlocked('sounds/achievement_unlocked.mp3', category: SoundCategory.gamification),
  badgeEarned('sounds/badge_earned.mp3', category: SoundCategory.gamification),
  dailyChallengeComplete('sounds/daily_challenge.mp3', category: SoundCategory.gamification),
  streakCelebration('sounds/streak_celebration.mp3', category: SoundCategory.gamification),
  // Notifications
  notification('sounds/notification.mp3', category: SoundCategory.notification),
  alert('sounds/alert.mp3', category: SoundCategory.notification),
  reminder('sounds/reminder.mp3', category: SoundCategory.notification, volumeMultiplier: 0.6),
  dismiss('sounds/dismiss.mp3', category: SoundCategory.notification, volumeMultiplier: 0.5),
  // UI
  tabSwitch('sounds/tab_switch.mp3', category: SoundCategory.ui, volumeMultiplier: 0.3),
  buttonTap('sounds/button_tap.mp3', category: SoundCategory.ui, volumeMultiplier: 0.3),
  success('sounds/success.mp3', category: SoundCategory.ui),
  error('sounds/error.mp3', category: SoundCategory.ui),
  refresh('sounds/refresh.mp3', category: SoundCategory.ui, volumeMultiplier: 0.5),
  toggleOn('sounds/toggle_on.mp3', category: SoundCategory.ui, volumeMultiplier: 0.3),
  toggleOff('sounds/toggle_off.mp3', category: SoundCategory.ui, volumeMultiplier: 0.3),
  sheetOpen('sounds/sheet_open.mp3', category: SoundCategory.ui, volumeMultiplier: 0.25),
  copy('sounds/copy.mp3', category: SoundCategory.ui, volumeMultiplier: 0.4),
  share('sounds/share.mp3', category: SoundCategory.ui, volumeMultiplier: 0.5),
  tourStep('sounds/tour_step.mp3', category: SoundCategory.ui, volumeMultiplier: 0.3),
  translate('sounds/translate.mp3', category: SoundCategory.ui, volumeMultiplier: 0.4),
  // Media
  photoCapture('sounds/photo_capture.mp3', category: SoundCategory.video, volumeMultiplier: 0.6),
  uploadComplete('sounds/upload_complete.mp3', category: SoundCategory.video, volumeMultiplier: 0.6),
  // Safety
  safetyTipAppear('sounds/safety_tip.mp3', category: SoundCategory.safety, volumeMultiplier: 0.5),
  safetyModuleComplete('sounds/safety_complete.mp3', category: SoundCategory.safety),
  videoRecordStart('sounds/record_start.mp3', category: SoundCategory.video),
  videoRecordStop('sounds/record_stop.mp3', category: SoundCategory.video),
  // Games (no screen uses these yet)
  gameWaiting('sounds/game_waiting.mp3', category: SoundCategory.games, volumeMultiplier: 0.4),
  gameCountdown('sounds/game_countdown.mp3', category: SoundCategory.games),
  gameStart('sounds/game_start.mp3', category: SoundCategory.games),
  gameEnd('sounds/game_end.mp3', category: SoundCategory.games),
  gameCorrect('sounds/game_correct.mp3', category: SoundCategory.games, volumeMultiplier: 0.6),
  gameWrong('sounds/game_wrong.mp3', category: SoundCategory.games, volumeMultiplier: 0.6),
  gameVictory('sounds/game_victory.mp3', category: SoundCategory.games),
  gameDefeat('sounds/game_defeat.mp3', category: SoundCategory.games),
  bombTick('sounds/bomb_tick.mp3', category: SoundCategory.games, volumeMultiplier: 0.5),
  bombExplode('sounds/bomb_explode.mp3', category: SoundCategory.games),
  ;

  final String assetPath;
  final SoundCategory category;
  final double volumeMultiplier;

  const AppSound(
    this.assetPath, {
    required this.category,
    this.volumeMultiplier = 1.0,
  });
}

enum SoundCategory {
  chat('Chat Sounds'),
  social('Social Sounds'),
  learning('Learning Sounds'),
  gamification('Gamification Sounds'),
  notification('Notification Sounds'),
  ui('UI Sounds'),
  safety('Safety Sounds'),
  events('Event Sounds'),
  video('Video Sounds'),
  games('Game Sounds');

  final String displayName;
  const SoundCategory(this.displayName);
}
