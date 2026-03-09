import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final firestore = FirebaseFirestore.instance;
    final userId = widget.userId;

    try {
      // Always read XP from user_levels (authoritative source) to avoid stale cache
      int totalXp = 0;
      int level = 1;
      final userLevelDoc = await firestore.collection('user_levels').doc(userId).get();
      if (userLevelDoc.exists) {
        final lvlData = userLevelDoc.data()!;
        totalXp = (lvlData['totalXP'] as num?)?.toInt() ?? 0;
        level = (lvlData['level'] as num?)?.toInt() ?? ((totalXp / 100).floor() + 1);
      }

      // Try to read other stats from the denormalized user_stats document (fast path)
      final statsDoc = await firestore.collection('user_stats').doc(userId).get();

      // Always load learned words from source (not cached, since useCount changes)
      final learnedWords = await _loadLearnedWords(firestore, userId);

      if (statsDoc.exists) {
        final data = statsDoc.data()!;
        final wordsMap = data['wordsPerLanguage'] as Map<String, dynamic>? ?? {};
        final activityMap = data['dailyActivity'] as Map<String, dynamic>? ?? {};

        if (mounted) {
          setState(() {
            _totalXp = totalXp;
            _currentLevel = level;
            _totalMessagesSent = (data['messagesSent'] as num?)?.toInt() ?? 0;
            _totalConversations = (data['totalConversations'] as num?)?.toInt() ?? 0;
            _wordsPerLanguage = wordsMap.map((k, v) => MapEntry(k, (v as num).toInt()));
            _wordsLearnedPerLanguage = learnedWords;
            _achievementsUnlocked = (data['achievementsUnlocked'] as num?)?.toInt() ?? 0;
            _challengesCompleted = (data['challengesCompleted'] as num?)?.toInt() ?? 0;
            _dailyActivity = activityMap.map((k, v) => MapEntry(k, (v as num).toInt()));
            _isLoading = false;
          });
        }
        return;
      }

      // Fallback: compute stats from source collections and write to user_stats
      await _computeAndCacheStats(firestore, userId);
    } catch (e) {
      debugPrint('Error loading personal stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      level = (totalXp / 100).floor() + 1;
    }

    // Also check xp_transactions for additional XP + daily activity
    final Map<String, int> dailyActivity = {};
    int txnXp = 0;
    final xpDocs = await firestore
        .collection('xp_transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(500)
        .get();
    for (final doc in xpDocs.docs) {
      final data = doc.data();
      txnXp += (data['xpAmount'] as num?)?.toInt() ?? 0;
      final createdAt = data['createdAt'] as Timestamp?;
      if (createdAt != null) {
        final date = createdAt.toDate();
        final key = '${date.month}/${date.day}';
        dailyActivity[key] = (dailyActivity[key] ?? 0) + 1;
      }
    }
    if (txnXp > totalXp) totalXp = txnXp;

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

  /// Load learned words (useCount >= 3) per language from Firestore
  Future<Map<String, int>> _loadLearnedWords(
    FirebaseFirestore firestore,
    String userId,
  ) async {
    final Map<String, int> learned = {};
    try {
      final vocabDocs = await firestore
          .collection('user_vocabulary')
          .doc(userId)
          .collection('words')
          .where('useCount', isGreaterThanOrEqualTo: 3)
          .get();
      for (final doc in vocabDocs.docs) {
        final lang = doc.data()['language'] as String? ?? 'unknown';
        learned[lang] = (learned[lang] ?? 0) + 1;
      }
    } catch (e) {
      debugPrint('Error loading learned words: $e');
    }
    return learned;
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
            onPressed: () {
              setState(() => _isLoading = true);
              // Force recompute by deleting cached doc first
              FirebaseFirestore.instance
                  .collection('user_stats')
                  .doc(widget.userId)
                  .delete()
                  .catchError((_) {});
              _loadStats();
            },
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
                            _buildStatItem(l10n.personalStatsNextLevel, '${100 - (_totalXp % 100)}', Icons.arrow_upward),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // XP progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (_totalXp % 100) / 100,
                            backgroundColor: AppColors.backgroundDark,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.richGold),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_totalXp % 100}/100 XP',
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
              const Expanded(
                flex: 3,
                child: Text(
                  'Language',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Learned',
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'Discovered',
                  style: TextStyle(
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
              const Expanded(
                flex: 3,
                child: Text(
                  'Total',
                  style: TextStyle(
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

  String _langLabel(String code) {
    const labels = {
      'en': 'EN',
      'de': 'DE',
      'es': 'ES',
      'fr': 'FR',
      'it': 'IT',
      'pt': 'PT',
      'pt_br': 'BR',
    };
    return labels[code.toLowerCase()] ?? code.toUpperCase();
  }
}
