import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';

class PersonalStatsScreen extends StatefulWidget {
  final String userId;

  const PersonalStatsScreen({super.key, required this.userId});

  @override
  State<PersonalStatsScreen> createState() => _PersonalStatsScreenState();
}

class _PersonalStatsScreenState extends State<PersonalStatsScreen> {
  bool _isLoading = true;

  // Level XP thresholds (must match backend LEVEL_XP_REQUIREMENTS)
  static const _levelXpRequirements = [
    0, 100, 250, 500, 1000, 2000, 3500, 5500, 8000, 11000, 15000, 20000,
    26000, 33000, 41000, 50000,
  ];

  // XP & Level
  int _totalXp = 0;
  int _currentLevel = 1;

  // Chat stats
  int _totalMessagesSent = 0;
  int _totalConversations = 0;

  // Achievements
  int _achievementsUnlocked = 0;
  int _challengesCompleted = 0;

  // Words per language (all tracked)
  Map<String, int> _wordsPerLanguage = {};
  // Words learned per language (useCount >= 3)
  Map<String, int> _wordsLearnedPerLanguage = {};

  // Activity (messages per day, last 7 days)
  Map<String, int> _dailyActivity = {};

  /// XP needed to reach the next level from current XP
  int get _xpForNextLevel {
    if (_currentLevel >= _levelXpRequirements.length) return 0;
    return _levelXpRequirements[_currentLevel] - _totalXp;
  }

  /// Progress fraction within the current level (0.0 to 1.0)
  double get _levelProgress {
    final currentThreshold =
        _currentLevel <= _levelXpRequirements.length
            ? _levelXpRequirements[_currentLevel - 1]
            : _levelXpRequirements.last;
    final nextThreshold =
        _currentLevel < _levelXpRequirements.length
            ? _levelXpRequirements[_currentLevel]
            : currentThreshold + 10000;
    final range = nextThreshold - currentThreshold;
    if (range <= 0) return 1.0;
    return ((_totalXp - currentThreshold) / range).clamp(0.0, 1.0);
  }

  /// XP earned within the current level and total needed for this level
  int get _xpInCurrentLevel {
    final currentThreshold =
        _currentLevel <= _levelXpRequirements.length
            ? _levelXpRequirements[_currentLevel - 1]
            : _levelXpRequirements.last;
    return _totalXp - currentThreshold;
  }

  int get _xpRangeForCurrentLevel {
    final currentThreshold =
        _currentLevel <= _levelXpRequirements.length
            ? _levelXpRequirements[_currentLevel - 1]
            : _levelXpRequirements.last;
    final nextThreshold =
        _currentLevel < _levelXpRequirements.length
            ? _levelXpRequirements[_currentLevel]
            : currentThreshold + 10000;
    return nextThreshold - currentThreshold;
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final firestore = FirebaseFirestore.instance;
    final userId = widget.userId;

    try {
      // Always read XP from user_levels (authoritative source)
      int totalXp = 0;
      int level = 1;
      final userLevelDoc = await firestore.collection('user_levels').doc(userId).get();
      if (userLevelDoc.exists) {
        final lvlData = userLevelDoc.data()!;
        totalXp = (lvlData['totalXP'] as num?)?.toInt() ?? 0;
        level = (lvlData['level'] as num?)?.toInt() ?? _calculateLevel(totalXp);
      }

      // Read cached stats from user_stats (kept fresh by daily Cloud Function)
      final statsDoc = await firestore.collection('user_stats').doc(userId).get();

      if (statsDoc.exists) {
        _applyStatsFromDoc(statsDoc.data()!, totalXp, level);
        return;
      }

      // No cached stats yet — compute locally and cache
      await _computeAndCacheStats(firestore, userId);
    } catch (e) {
      debugPrint('Error loading personal stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Apply stats data from a Firestore document to the UI state
  void _applyStatsFromDoc(Map<String, dynamic> data, int totalXp, int level) {
    final wordsMap = data['wordsPerLanguage'] as Map<String, dynamic>? ?? {};
    final learnedMap = data['wordsLearnedPerLanguage'] as Map<String, dynamic>? ?? {};
    final activityMap = data['dailyActivity'] as Map<String, dynamic>? ?? {};

    if (mounted) {
      setState(() {
        _totalXp = totalXp;
        _currentLevel = level;
        _totalMessagesSent = (data['messagesSent'] as num?)?.toInt() ?? 0;
        _totalConversations = (data['totalConversations'] as num?)?.toInt() ?? 0;
        _wordsPerLanguage = wordsMap.map((k, v) => MapEntry(k, (v as num).toInt()));
        _wordsLearnedPerLanguage = learnedMap.map((k, v) => MapEntry(k, (v as num).toInt()));
        _achievementsUnlocked = (data['achievementsUnlocked'] as num?)?.toInt() ?? 0;
        _challengesCompleted = (data['challengesCompleted'] as num?)?.toInt() ?? 0;
        _dailyActivity = activityMap.map((k, v) => MapEntry(k, (v as num).toInt()));
        _isLoading = false;
      });
    }
  }

  /// Refresh stats by calling the Cloud Function, then reload from cache
  Future<void> _refreshStats() async {
    setState(() => _isLoading = true);
    try {
      // Call Cloud Function to recompute stats server-side
      await FirebaseFunctions.instance.httpsCallable('refreshMyStats').call({});
      // Reload from the freshly computed cache
      await _loadStats();
    } catch (e) {
      debugPrint('Error refreshing stats via Cloud Function: $e');
      // Fallback: compute locally
      await _computeAndCacheStats(FirebaseFirestore.instance, widget.userId);
    }
  }

  /// Compute stats from source collections and cache in user_stats/{userId}
  Future<void> _computeAndCacheStats(FirebaseFirestore firestore, String userId) async {
    // Load XP from user_levels (primary authoritative source)
    int totalXp = 0;
    int level = 1;
    final userLevelDoc = await firestore.collection('user_levels').doc(userId).get();
    if (userLevelDoc.exists) {
      final data = userLevelDoc.data()!;
      totalXp = (data['totalXP'] as num?)?.toInt() ?? 0;
      level = (data['level'] as num?)?.toInt() ?? 1;
    }

    // Fallback: check language_progress if user_levels has no data
    if (totalXp == 0) {
      final langDocs = await firestore
          .collection('language_progress')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in langDocs.docs) {
        totalXp += (doc.data()['totalXpEarned'] as num?)?.toInt() ?? 0;
      }
      level = _calculateLevel(totalXp);
    }

    // Load daily activity from xp_transactions (last 30 days only)
    final Map<String, int> dailyActivity = {};
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final xpDocs = await firestore
        .collection('xp_transactions')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
        .orderBy('createdAt', descending: true)
        .limit(1000)
        .get();
    for (final doc in xpDocs.docs) {
      final data = doc.data();
      final createdAt = data['createdAt'] as Timestamp?;
      if (createdAt != null) {
        final date = createdAt.toDate();
        final key = '${date.month}/${date.day}';
        dailyActivity[key] = (dailyActivity[key] ?? 0) + 1;
      }
    }

    // Conversations count (two queries, count only)
    final convos1 = await firestore
        .collection('conversations')
        .where('userId1', isEqualTo: userId)
        .count()
        .get();
    final convos2 = await firestore
        .collection('conversations')
        .where('userId2', isEqualTo: userId)
        .count()
        .get();
    final totalConvos = (convos1.count ?? 0) + (convos2.count ?? 0);

    // Messages sent count from profile or estimate
    int messagesSent = 0;
    final profileDoc = await firestore.collection('profiles').doc(userId).get();
    if (profileDoc.exists) {
      messagesSent = (profileDoc.data()?['messagesSent'] as num?)?.toInt() ?? 0;
    }

    // Vocabulary words per language (all tracked + learned with useCount >= 3)
    final Map<String, int> wordsPerLang = {};
    final Map<String, int> wordsLearnedPerLang = {};
    final vocabDocs = await firestore
        .collection('user_vocabulary')
        .doc(userId)
        .collection('words')
        .get();
    for (final doc in vocabDocs.docs) {
      final data = doc.data();
      final lang = data['language'] as String? ?? 'unknown';
      wordsPerLang[lang] = (wordsPerLang[lang] ?? 0) + 1;
      final useCount = (data['useCount'] as num?)?.toInt() ?? 0;
      if (useCount >= 3) {
        wordsLearnedPerLang[lang] = (wordsLearnedPerLang[lang] ?? 0) + 1;
      }
    }

    // Achievements unlocked count
    final achieveCount = await firestore
        .collection('user_achievements')
        .where('userId', isEqualTo: userId)
        .where('isUnlocked', isEqualTo: true)
        .count()
        .get();

    // Challenges completed count
    final challengeCount = await firestore
        .collection('user_challenges')
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: true)
        .count()
        .get();

    // Cache the computed stats for fast future reads
    final statsData = {
      'totalXp': totalXp,
      'level': level,
      'messagesSent': messagesSent,
      'totalConversations': totalConvos,
      'wordsPerLanguage': wordsPerLang,
      'wordsLearnedPerLanguage': wordsLearnedPerLang,
      'achievementsUnlocked': achieveCount.count ?? 0,
      'challengesCompleted': challengeCount.count ?? 0,
      'dailyActivity': dailyActivity,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    firestore.collection('user_stats').doc(userId).set(statsData).catchError((_) {});

    if (mounted) {
      setState(() {
        _totalXp = totalXp;
        _currentLevel = level;
        _totalMessagesSent = messagesSent;
        _totalConversations = totalConvos;
        _wordsPerLanguage = wordsPerLang;
        _wordsLearnedPerLanguage = wordsLearnedPerLang;
        _achievementsUnlocked = achieveCount.count ?? 0;
        _challengesCompleted = challengeCount.count ?? 0;
        _dailyActivity = dailyActivity;
        _isLoading = false;
      });
    }
  }

  /// Calculate level from XP using the same thresholds as the backend
  static int _calculateLevel(int totalXp) {
    int level = 1;
    while (level < _levelXpRequirements.length &&
        totalXp >= _levelXpRequirements[level]) {
      level++;
    }
    return level;
  }

  static String _flagForLanguage(String code) {
    const flags = {
      'en': '🇬🇧',
      'de': '🇩🇪',
      'es': '🇪🇸',
      'fr': '🇫🇷',
      'it': '🇮🇹',
      'pt': '🇵🇹',
      'pt_br': '🇧🇷',
    };
    return flags[code.toLowerCase()] ?? '🌐';
  }

  static String _languageName(String code) {
    const names = {
      'en': 'English',
      'de': 'Deutsch',
      'es': 'Español',
      'fr': 'Français',
      'it': 'Italiano',
      'pt': 'Português',
      'pt_br': 'Português (BR)',
    };
    return names[code.toLowerCase()] ?? code.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.personalStatistics,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _isLoading ? null : _refreshStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // XP Overview Card
                  _buildSectionCard(
                    icon: Icons.star,
                    title: l10n.personalStatsXpOverview,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(l10n.personalStatsLevel, '$_currentLevel', Icons.shield),
                            _buildStatItem('XP', '$_totalXp', Icons.star),
                            _buildStatItem(l10n.personalStatsNextLevel, '$_xpForNextLevel', Icons.arrow_upward),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // XP progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _levelProgress,
                            backgroundColor: AppColors.backgroundDark,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.richGold),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_xpInCurrentLevel/$_xpRangeForCurrentLevel XP',
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Chat Stats Card
                  _buildSectionCard(
                    icon: Icons.forum,
                    title: l10n.personalStatsChatStats,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(l10n.personalStatsTotalMessages, '$_totalMessagesSent', Icons.send),
                        _buildStatItem(l10n.personalStatsConversations, '$_totalConversations', Icons.chat_bubble_outline),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Goals Achieved Card
                  _buildSectionCard(
                    icon: Icons.emoji_events,
                    title: l10n.personalStatsGoalsAchieved,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(l10n.achievementsTitle, '$_achievementsUnlocked', Icons.emoji_events),
                        _buildStatItem(l10n.dailyChallengesTitle, '$_challengesCompleted', Icons.today),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Words Learned Card (table with flags)
                  _buildSectionCard(
                    icon: Icons.school,
                    title: l10n.personalStatsWordsLearned,
                    child: _buildWordsLearnedTable(),
                  ),

                  const SizedBox(height: 16),

                  // Recent Activity Card
                  _buildSectionCard(
                    icon: Icons.local_fire_department,
                    title: l10n.personalStatsActivity,
                    child: _dailyActivity.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              l10n.personalStatsNoActivityYet,
                              style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                            ),
                          )
                        : SizedBox(
                            height: 120,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: _buildActivityBars(),
                            ),
                          ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.richGold, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.richGold, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildWordsLearnedTable() {
    final l10n = AppLocalizations.of(context)!;
    // Always show all 7 supported languages
    const allLanguages = ['en', 'de', 'es', 'fr', 'it', 'pt', 'pt_br'];

    final totalLearned = _wordsLearnedPerLanguage.values.fold(0, (a, b) => a + b);
    final totalDiscovered = _wordsPerLanguage.values.fold(0, (a, b) => a + b);

    return Column(
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  l10n.personalStatsLanguage,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  l10n.personalStatsWordsLearned,
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  l10n.personalStatsWordsDiscovered,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 8),
        // Language rows
        ...allLanguages.map((lang) {
          final learned = _wordsLearnedPerLanguage[lang] ?? 0;
          final discovered = _wordsPerLanguage[lang] ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                // Flag + Language name
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Text(
                        _flagForLanguage(lang),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _languageName(lang),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Learned count
                Expanded(
                  flex: 2,
                  child: Text(
                    '$learned',
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Discovered count
                Expanded(
                  flex: 2,
                  child: Text(
                    '$discovered',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }),
        // Total row
        const SizedBox(height: 8),
        const Divider(color: AppColors.divider, height: 1),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  l10n.personalStatsTotal,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '$totalLearned',
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '$totalDiscovered',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActivityBars() {
    // Show last 7 entries
    final entries = _dailyActivity.entries.toList();
    final recent = entries.length > 7 ? entries.sublist(entries.length - 7) : entries;
    final maxVal = recent.isEmpty ? 1 : recent.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return recent.map((entry) {
      final height = maxVal > 0 ? (entry.value / maxVal) * 90 : 0.0;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${entry.value}',
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 9),
              ),
              const SizedBox(height: 4),
              Container(
                height: height.clamp(4.0, 90.0),
                decoration: BoxDecoration(
                  color: AppColors.richGold,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.key,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 9),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

}
