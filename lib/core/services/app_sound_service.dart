import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized sound management for the entire GreenGo app.
///
/// All app sounds are organized by purpose/category and played through
/// a pooled set of AudioPlayers for performance. Sounds can be globally
/// muted via settings.
///
/// Usage:
///   AppSoundService().play(AppSound.newMessage);
///   AppSoundService().play(AppSound.correctAnswer);
///   AppSoundService().play(AppSound.levelUp);
class AppSoundService {
  static final AppSoundService _instance = AppSoundService._();
  factory AppSoundService() => _instance;
  AppSoundService._();

  // Pool of players for concurrent sounds
  final List<AudioPlayer> _playerPool = [];
  static const int _poolSize = 4;

  bool _initialized = false;
  bool _soundEnabled = true;
  double _volume = 0.7;

  static const String _soundEnabledKey = 'app_sound_enabled';
  static const String _volumeKey = 'app_sound_volume';

  /// Initialize the sound service. Call once at app startup.
  Future<void> initialize() async {
    if (_initialized) return;

    // Create player pool
    for (int i = 0; i < _poolSize; i++) {
      _playerPool.add(AudioPlayer());
    }

    // Load preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
      _volume = prefs.getDouble(_volumeKey) ?? 0.7;
    } catch (e) {
      debugPrint('AppSoundService: Failed to load preferences: $e');
    }

    _initialized = true;
  }

  /// Get an available player from the pool
  AudioPlayer _getPlayer() {
    // Find a player that's not currently playing
    for (final player in _playerPool) {
      if (player.state != PlayerState.playing) {
        return player;
      }
    }
    // If all busy, return the first one (it will be interrupted)
    return _playerPool.first;
  }

  /// Play a sound by its enum identifier
  Future<void> play(AppSound sound) async {
    if (!_soundEnabled || !_initialized) return;

    try {
      final player = _getPlayer();
      await player.setVolume(_volume * sound.volumeMultiplier);
      await player.play(AssetSource(sound.assetPath));
    } catch (e) {
      debugPrint('AppSoundService: Failed to play ${sound.name}: $e');
    }
  }

  /// Play a sound with custom volume (0.0 to 1.0)
  Future<void> playWithVolume(AppSound sound, double volume) async {
    if (!_soundEnabled || !_initialized) return;

    try {
      final player = _getPlayer();
      await player.setVolume(volume);
      await player.play(AssetSource(sound.assetPath));
    } catch (e) {
      debugPrint('AppSoundService: Failed to play ${sound.name}: $e');
    }
  }

  /// Enable or disable all sounds
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundEnabledKey, enabled);
    } catch (_) {}
  }

  /// Set global volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_volumeKey, _volume);
    } catch (_) {}
  }

  bool get isSoundEnabled => _soundEnabled;
  double get volume => _volume;

  // Dedicated player for looping background music
  AudioPlayer? _bgMusicPlayer;

  /// Play a sound in a loop (for background music / waiting rooms).
  /// Call [stopBgMusic] to stop.
  Future<void> playBgMusic(AppSound sound) async {
    if (!_soundEnabled || !_initialized) return;

    try {
      await stopBgMusic();
      _bgMusicPlayer = AudioPlayer();
      await _bgMusicPlayer!.setVolume(_volume * sound.volumeMultiplier);
      await _bgMusicPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgMusicPlayer!.play(AssetSource(sound.assetPath));
    } catch (e) {
      debugPrint('AppSoundService: Failed to play bg music ${sound.name}: $e');
    }
  }

  /// Stop background music loop
  Future<void> stopBgMusic() async {
    try {
      await _bgMusicPlayer?.stop();
      await _bgMusicPlayer?.dispose();
      _bgMusicPlayer = null;
    } catch (_) {}
  }

  /// Stop all currently playing sounds
  Future<void> stopAll() async {
    await stopBgMusic();
    for (final player in _playerPool) {
      await player.stop();
    }
  }

  /// Dispose all players (call on app shutdown)
  Future<void> dispose() async {
    for (final player in _playerPool) {
      await player.dispose();
    }
    _playerPool.clear();
    _initialized = false;
  }
}

/// All sounds used across the GreenGo app, organized by category.
///
/// Asset files should be placed in assets/sounds/ and registered in pubspec.yaml.
/// Use short, lightweight audio files (< 100KB each, .mp3 or .wav).
enum AppSound {
  // ── Chat & Messaging ──
  newMessage('sounds/new_message.mp3', category: SoundCategory.chat),
  messageSent('sounds/message_sent.mp3', category: SoundCategory.chat),
  messageReceived('sounds/message_received.mp3', category: SoundCategory.chat),
  typingIndicator('sounds/typing.mp3', category: SoundCategory.chat, volumeMultiplier: 0.3),

  // ── Matching & Discovery ──
  newMatch('sounds/new_match.mp3', category: SoundCategory.matching),
  superLike('sounds/super_like.mp3', category: SoundCategory.matching),
  swipeRight('sounds/swipe_right.mp3', category: SoundCategory.matching, volumeMultiplier: 0.5),
  swipeLeft('sounds/swipe_left.mp3', category: SoundCategory.matching, volumeMultiplier: 0.4),
  cardFlip('sounds/card_flip.mp3', category: SoundCategory.matching, volumeMultiplier: 0.5),

  // ── Language Learning ──
  correctAnswer('sounds/correct_answer.mp3', category: SoundCategory.learning),
  wrongAnswer('sounds/wrong_answer.mp3', category: SoundCategory.learning),
  flashcardFlip('sounds/flashcard_flip.mp3', category: SoundCategory.learning, volumeMultiplier: 0.5),
  lessonComplete('sounds/lesson_complete.mp3', category: SoundCategory.learning),
  quizStart('sounds/quiz_start.mp3', category: SoundCategory.learning),
  quizComplete('sounds/quiz_complete.mp3', category: SoundCategory.learning),
  streakMilestone('sounds/streak_milestone.mp3', category: SoundCategory.learning),
  wordLearned('sounds/word_learned.mp3', category: SoundCategory.learning, volumeMultiplier: 0.5),

  // ── Gamification & XP ──
  xpGained('sounds/xp_gained.mp3', category: SoundCategory.gamification, volumeMultiplier: 0.6),
  levelUp('sounds/level_up.mp3', category: SoundCategory.gamification),
  achievementUnlocked('sounds/achievement_unlocked.mp3', category: SoundCategory.gamification),
  badgeEarned('sounds/badge_earned.mp3', category: SoundCategory.gamification),
  dailyChallengeComplete('sounds/daily_challenge.mp3', category: SoundCategory.gamification),
  streakCelebration('sounds/streak_celebration.mp3', category: SoundCategory.gamification),
  coinEarned('sounds/coin_earned.mp3', category: SoundCategory.gamification, volumeMultiplier: 0.5),

  // ── Notifications & Alerts ──
  notification('sounds/notification.mp3', category: SoundCategory.notification),
  alert('sounds/alert.mp3', category: SoundCategory.notification),
  reminder('sounds/reminder.mp3', category: SoundCategory.notification, volumeMultiplier: 0.6),

  // ── Navigation & UI ──
  tabSwitch('sounds/tab_switch.mp3', category: SoundCategory.ui, volumeMultiplier: 0.3),
  buttonTap('sounds/button_tap.mp3', category: SoundCategory.ui, volumeMultiplier: 0.3),
  success('sounds/success.mp3', category: SoundCategory.ui),
  error('sounds/error.mp3', category: SoundCategory.ui),
  refresh('sounds/refresh.mp3', category: SoundCategory.ui, volumeMultiplier: 0.4),

  // ── Safety & Social ──
  safetyTipAppear('sounds/safety_tip.mp3', category: SoundCategory.safety, volumeMultiplier: 0.5),
  safetyModuleComplete('sounds/safety_complete.mp3', category: SoundCategory.safety),

  // ── Events ──
  eventRsvp('sounds/event_rsvp.mp3', category: SoundCategory.events),
  eventReminder('sounds/event_reminder.mp3', category: SoundCategory.events),

  // ── Video Profile ──
  videoRecordStart('sounds/record_start.mp3', category: SoundCategory.video),
  videoRecordStop('sounds/record_stop.mp3', category: SoundCategory.video),

  // ── Language Games ──
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

/// Sound categories for granular mute control
enum SoundCategory {
  chat('Chat Sounds'),
  matching('Match Sounds'),
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
