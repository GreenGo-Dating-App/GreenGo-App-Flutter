import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Icebreaker Suggestions Widget
///
/// A horizontal scrollable row of icebreaker cards shown at the top of chat
/// when a conversation has fewer than 3 messages. Tapping a card inserts the
/// icebreaker text into the message input field.
///
/// Loads icebreakers from Firestore filtered by the partner's country/language,
/// falling back to general icebreakers if country-specific ones are not found.
///
/// Usage:
/// ```dart
/// IcebreakerSuggestions(
///   partnerCountry: otherUserProfile.effectiveLocation.country,
///   partnerLanguages: otherUserProfile.languages,
///   messageCount: messages.length,
///   onIcebreakerSelected: (text) {
///     _messageController.text = text;
///   },
/// )
/// ```
class IcebreakerSuggestions extends StatefulWidget {
  /// The partner's country for filtering relevant icebreakers
  final String? partnerCountry;

  /// The partner's spoken languages for filtering
  final List<String> partnerLanguages;

  /// Current message count in the conversation
  final int messageCount;

  /// Callback when an icebreaker is tapped — provides the text to insert
  final ValueChanged<String> onIcebreakerSelected;

  /// Maximum messages before the widget auto-hides (default: 3)
  final int hideAfterMessages;

  const IcebreakerSuggestions({
    super.key,
    this.partnerCountry,
    this.partnerLanguages = const [],
    required this.messageCount,
    required this.onIcebreakerSelected,
    this.hideAfterMessages = 3,
  });

  @override
  State<IcebreakerSuggestions> createState() => _IcebreakerSuggestionsState();
}

class _IcebreakerSuggestionsState extends State<IcebreakerSuggestions>
    with SingleTickerProviderStateMixin {
  List<_Icebreaker> _icebreakers = [];
  bool _isLoading = true;
  bool _isDismissed = false;
  late AnimationController _dismissController;
  late Animation<double> _dismissAnimation;

  @override
  void initState() {
    super.initState();
    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _dismissAnimation = CurvedAnimation(
      parent: _dismissController,
      curve: Curves.easeOut,
    );
    _dismissController.value = 1.0; // Start visible
    _loadIcebreakers();
  }

  @override
  void dispose() {
    _dismissController.dispose();
    super.dispose();
  }

  Future<void> _loadIcebreakers() async {
    try {
      List<_Icebreaker> results = [];

      // Try to load country-specific icebreakers first
      if (widget.partnerCountry != null &&
          widget.partnerCountry!.isNotEmpty) {
        final countryQuery = await FirebaseFirestore.instance
            .collection('icebreakers')
            .where('country', isEqualTo: widget.partnerCountry)
            .where('isActive', isEqualTo: true)
            .limit(10)
            .get();

        results = countryQuery.docs
            .map((doc) => _Icebreaker.fromFirestore(doc))
            .toList();
      }

      // If not enough country-specific, try language-based
      if (results.length < 5 && widget.partnerLanguages.isNotEmpty) {
        final langQuery = await FirebaseFirestore.instance
            .collection('icebreakers')
            .where('language',
                whereIn: widget.partnerLanguages.take(10).toList())
            .where('isActive', isEqualTo: true)
            .limit(10 - results.length)
            .get();

        final existingIds = results.map((r) => r.id).toSet();
        results.addAll(
          langQuery.docs
              .where((doc) => !existingIds.contains(doc.id))
              .map((doc) => _Icebreaker.fromFirestore(doc)),
        );
      }

      // Fall back to general icebreakers if not enough found
      if (results.length < 5) {
        final generalQuery = await FirebaseFirestore.instance
            .collection('icebreakers')
            .where('isActive', isEqualTo: true)
            .where('country', isNull: true)
            .limit(10 - results.length)
            .get();

        final existingIds = results.map((r) => r.id).toSet();
        results.addAll(
          generalQuery.docs
              .where((doc) => !existingIds.contains(doc.id))
              .map((doc) => _Icebreaker.fromFirestore(doc)),
        );
      }

      // If Firestore has nothing at all, use hardcoded fallbacks
      if (results.isEmpty) {
        results = _defaultIcebreakers;
      }

      // Shuffle for variety
      results.shuffle();

      if (mounted) {
        setState(() {
          _icebreakers = results.take(8).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      // On any error, use hardcoded fallbacks
      if (mounted) {
        setState(() {
          _icebreakers = _defaultIcebreakers;
          _isLoading = false;
        });
      }
    }
  }

  void _dismiss() {
    HapticFeedback.lightImpact();
    _dismissController.reverse().then((_) {
      if (mounted) {
        setState(() => _isDismissed = true);
      }
    });
  }

  void _selectIcebreaker(_Icebreaker icebreaker) {
    HapticFeedback.selectionClick();
    widget.onIcebreakerSelected(icebreaker.text);
  }

  /// Default fallback icebreakers when Firestore is empty
  static final List<_Icebreaker> _defaultIcebreakers = [
    _Icebreaker(
      id: 'default_1',
      text: 'Hi! What languages do you speak?',
      emoji: '\u{1F44B}',
      category: 'language',
    ),
    _Icebreaker(
      id: 'default_2',
      text: 'What is your favorite word in your language?',
      emoji: '\u{2728}',
      category: 'language',
    ),
    _Icebreaker(
      id: 'default_3',
      text: 'Have you been to any interesting places recently?',
      emoji: '\u{2708}\u{FE0F}',
      category: 'travel',
    ),
    _Icebreaker(
      id: 'default_4',
      text: 'Can you teach me a greeting in your language?',
      emoji: '\u{1F4DA}',
      category: 'language',
    ),
    _Icebreaker(
      id: 'default_5',
      text: 'What is the most beautiful place in your country?',
      emoji: '\u{1F30D}',
      category: 'travel',
    ),
    _Icebreaker(
      id: 'default_6',
      text: 'What kind of music do you listen to?',
      emoji: '\u{1F3B5}',
      category: 'culture',
    ),
    _Icebreaker(
      id: 'default_7',
      text: 'What is a dish from your country I should try?',
      emoji: '\u{1F37D}\u{FE0F}',
      category: 'culture',
    ),
    _Icebreaker(
      id: 'default_8',
      text: 'Are you learning any new languages right now?',
      emoji: '\u{1F4AC}',
      category: 'language',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Don't show if conversation is established or dismissed
    if (widget.messageCount >= widget.hideAfterMessages) {
      return const SizedBox.shrink();
    }
    if (_isDismissed) return const SizedBox.shrink();
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.richGold,
            ),
          ),
        ),
      );
    }
    if (_icebreakers.isEmpty) return const SizedBox.shrink();

    return SizeTransition(
      sizeFactor: _dismissAnimation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _dismissAnimation,
        child: Container(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            border: Border(
              bottom: BorderSide(
                color: AppColors.divider.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with dismiss button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      size: 14,
                      color: AppColors.richGold.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.chatIcebreakers,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Scrollable icebreaker cards
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _icebreakers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final icebreaker = _icebreakers[index];
                    return _IcebreakerCard(
                      icebreaker: icebreaker,
                      onTap: () => _selectIcebreaker(icebreaker),
                    );
                  },
                ),
              ),

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual icebreaker card widget
class _IcebreakerCard extends StatelessWidget {
  final _Icebreaker icebreaker;
  final VoidCallback onTap;

  const _IcebreakerCard({
    required this.icebreaker,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: AppColors.divider.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icebreaker.emoji != null)
              Text(
                icebreaker.emoji!,
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                icebreaker.text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal icebreaker data model
class _Icebreaker {
  final String id;
  final String text;
  final String? emoji;
  final String? category;
  final String? country;
  final String? language;

  _Icebreaker({
    required this.id,
    required this.text,
    this.emoji,
    this.category,
    this.country,
    this.language,
  });

  factory _Icebreaker.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return _Icebreaker(
      id: doc.id,
      text: data['text'] as String? ?? '',
      emoji: data['emoji'] as String?,
      category: data['category'] as String?,
      country: data['country'] as String?,
      language: data['language'] as String?,
    );
  }
}
