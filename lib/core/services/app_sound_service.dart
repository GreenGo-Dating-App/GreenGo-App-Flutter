/// Centralized sound management for the GreenGo app.
///
/// Sounds are currently disabled. All play methods are no-ops.
class AppSoundService {
  static final AppSoundService _instance = AppSoundService._();
  factory AppSoundService() => _instance;
  AppSoundService._();

  bool _soundEnabled = false;
  double _volume = 0.7;

  Future<void> initialize() async {}
  Future<void> play(AppSound sound) async {}
  Future<void> playWithVolume(AppSound sound, double volume) async {}
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
  }
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
  }
  bool get isSoundEnabled => _soundEnabled;
  double get volume => _volume;
  Future<void> playBgMusic(AppSound sound) async {}
  Future<void> stopBgMusic() async {}
  Future<void> stopAll() async {}
  Future<void> dispose() async {}
}

/// All sounds used across the GreenGo app.
enum AppSound {
  newMessage('sounds/new_message.mp3', category: SoundCategory.chat),
  messageSent('sounds/message_sent.mp3', category: SoundCategory.chat),
  messageReceived('sounds/message_received.mp3', category: SoundCategory.chat),
  typingIndicator('sounds/typing.mp3', category: SoundCategory.chat, volumeMultiplier: 0.3),
  newMatch('sounds/new_match.mp3', category: SoundCategory.matching),
  superLike('sounds/super_like.mp3', category: SoundCategory.matching),
  swipeRight('sounds/swipe_right.mp3', category: SoundCategory.matching, volumeMultiplier: 0.5),
  swipeLeft('sounds/swipe_left.mp3', category: SoundCategory.matching, volumeMultiplier: 0.4),
  cardFlip('sounds/card_flip.mp3', category: SoundCategory.matching, volumeMultiplier: 0.5),
  correctAnswer('sounds/correct_answer.mp3', category: SoundCategory.learning),
  wrongAnswer('sounds/wrong_answer.mp3', category: SoundCategory.learning),
  flashcardFlip('sounds/flashcard_flip.mp3', category: SoundCategory.learning, volumeMultiplier: 0.5),
  lessonComplete('sounds/lesson_complete.mp3', category: SoundCategory.learning),
  quizStart('sounds/quiz_start.mp3', category: SoundCategory.learning),
  quizComplete('sounds/quiz_complete.mp3', category: SoundCategory.learning),
  streakMilestone('sounds/streak_milestone.mp3', category: SoundCategory.learning),
  wordLearned('sounds/word_learned.mp3', category: SoundCategory.learning, volumeMultiplier: 0.5),
  xpGained('sounds/xp_gained.mp3', category: SoundCategory.gamification, volumeMultiplier: 0.6),
  levelUp('sounds/level_up.mp3', category: SoundCategory.gamification),
  achievementUnlocked('sounds/achievement_unlocked.mp3', category: SoundCategory.gamification),
  badgeEarned('sounds/badge_earned.mp3', category: SoundCategory.gamification),
  dailyChallengeComplete('sounds/daily_challenge.mp3', category: SoundCategory.gamification),
  streakCelebration('sounds/streak_celebration.mp3', category: SoundCategory.gamification),
  coinEarned('sounds/coin_earned.mp3', category: SoundCategory.gamification, volumeMultiplier: 0.5),
  notification('sounds/notification.mp3', category: SoundCategory.notification),
  alert('sounds/alert.mp3', category: SoundCategory.notification),
  reminder('sounds/reminder.mp3', category: SoundCategory.notification, volumeMultiplier: 0.6),
  tabSwitch('sounds/tab_switch.mp3', category: SoundCategory.ui, volumeMultiplier: 0.3),
  buttonTap('sounds/button_tap.mp3', category: SoundCategory.ui, volumeMultiplier: 0.3),
  success('sounds/success.mp3', category: SoundCategory.ui),
  error('sounds/error.mp3', category: SoundCategory.ui),
  refresh('sounds/refresh.mp3', category: SoundCategory.ui, volumeMultiplier: 0.4),
  safetyTipAppear('sounds/safety_tip.mp3', category: SoundCategory.safety, volumeMultiplier: 0.5),
  safetyModuleComplete('sounds/safety_complete.mp3', category: SoundCategory.safety),
  eventRsvp('sounds/event_rsvp.mp3', category: SoundCategory.events),
  eventReminder('sounds/event_reminder.mp3', category: SoundCategory.events),
  videoRecordStart('sounds/record_start.mp3', category: SoundCategory.video),
  videoRecordStop('sounds/record_stop.mp3', category: SoundCategory.video),
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
