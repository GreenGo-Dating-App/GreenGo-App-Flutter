import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/services/ai_coach_service.dart';
import '../../domain/entities/ai_coach_session.dart';
import '../bloc/language_learning_bloc.dart';
import '../widgets/coach_message_bubble.dart';
import '../widgets/coach_score_card.dart';
import '../widgets/scenario_selector.dart';

/// Full chat-like interface for AI Conversation Coach sessions.
///
/// Allows users to practice conversations in their target language
/// with an AI coach that provides real-time corrections and feedback.
class AiCoachScreen extends StatefulWidget {
  final String userId;
  final String targetLanguage;
  final String nativeLanguage;

  const AiCoachScreen({
    super.key,
    required this.userId,
    required this.targetLanguage,
    required this.nativeLanguage,
  });

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final AiCoachService _coachService = AiCoachService();

  CoachScenario? _selectedScenario;
  final List<CoachMessage> _messages = [];
  bool _isLoading = false;
  bool _isSessionEnded = false;
  CoachSessionScore? _sessionScore;

  // Running average scores for display
  final List<double> _grammarScores = [];
  final List<double> _vocabScores = [];
  final List<double> _fluencyScores = [];

  @override
  void initState() {
    super.initState();
    // Show scenario selector after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showScenarioSelector();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _showScenarioSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => ScenarioSelector(
        onScenarioSelected: (scenario) {
          Navigator.pop(context);
          _startSession(scenario);
        },
      ),
    );
  }

  Future<void> _startSession(CoachScenario scenario) async {
    setState(() {
      _selectedScenario = scenario;
      _isLoading = true;
    });

    // Notify BLoC about session start
    context.read<LanguageLearningBloc>().add(
          StartAiCoachSession(
            languageCode: widget.targetLanguage,
            scenario: scenario,
          ),
        );

    // Generate opening message from AI
    final openingMessage = await _coachService.generateOpeningMessage(
      targetLanguageName: widget.targetLanguage,
      nativeLanguage: widget.nativeLanguage,
      scenario: scenario,
    );

    setState(() {
      _messages.add(openingMessage);
      _isLoading = false;
    });

    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading || _isSessionEnded) return;

    HapticFeedback.lightImpact();

    // Add user message
    final userMessage = CoachMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUserMessage: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Send to AI and get response
    final response = await _coachService.sendMessage(
      userMessage: text,
      targetLanguageName: widget.targetLanguage,
      nativeLanguage: widget.nativeLanguage,
      scenario: _selectedScenario!,
      conversationHistory: _messages,
    );

    // Notify BLoC
    context.read<LanguageLearningBloc>().add(SendCoachMessage(text));

    setState(() {
      _messages.add(response);
      _isLoading = false;
    });

    _scrollToBottom();
  }

  void _onSuggestionTapped(String suggestion) {
    _messageController.text = suggestion;
    _sendMessage();
  }

  Future<void> _endSession() async {
    if (_isSessionEnded) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
    });

    // Generate session score
    final score = await _coachService.generateSessionScore(
      messages: _messages,
      targetLanguageName: widget.targetLanguage,
    );

    // Notify BLoC
    context.read<LanguageLearningBloc>().add(const EndCoachSession());

    setState(() {
      _sessionScore = score;
      _isSessionEnded = true;
      _isLoading = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Scenario banner
          if (_selectedScenario != null) _buildScenarioBanner(),

          // Messages list
          Expanded(
            child: _isSessionEnded && _sessionScore != null
                ? _buildScoreView()
                : _buildMessagesList(),
          ),

          // Input area
          if (!_isSessionEnded) _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () {
          if (_messages.isNotEmpty && !_isSessionEnded) {
            _showExitConfirmation();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Conversation Coach',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_selectedScenario != null)
            Text(
              widget.targetLanguage,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
        ],
      ),
      actions: [
        if (_selectedScenario != null && !_isSessionEnded)
          TextButton(
            onPressed: _endSession,
            child: const Text(
              'End Session',
              style: TextStyle(
                color: AppColors.richGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScenarioBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            _selectedScenario!.icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedScenario!.displayName,
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '10 coins/session  |  25 XP reward',
                  style: TextStyle(
                    color: AppColors.textTertiary.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_messages.where((m) => m.isUserMessage).length} msgs',
              style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_selectedScenario == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a scenario to begin',
              style: TextStyle(
                color: AppColors.textTertiary.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return _buildTypingIndicator();
        }

        final message = _messages[index];
        return CoachMessageBubble(
          message: message,
          onSuggestionTapped: _onSuggestionTapped,
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.textTertiary
                .withValues(alpha: 0.3 + (0.5 * (value % 1.0))),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          top: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundInput,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _inputFocusNode,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: _selectedScenario == null
                      ? 'Select a scenario first...'
                      : 'Type your message...',
                  hintStyle: TextStyle(
                    color: AppColors.textTertiary.withValues(alpha: 0.5),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                enabled: _selectedScenario != null && !_isLoading,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: 4,
                minLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _selectedScenario != null && !_isLoading
                    ? AppColors.richGold
                    : AppColors.divider,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                color: _selectedScenario != null && !_isLoading
                    ? AppColors.deepBlack
                    : AppColors.textTertiary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: CoachScoreCard(
        score: _sessionScore!,
        xpEarned: 25,
        messageCount:
            _messages.where((m) => m.isUserMessage).length,
        onPracticeAgain: () {
          setState(() {
            _messages.clear();
            _isSessionEnded = false;
            _sessionScore = null;
            _selectedScenario = null;
            _grammarScores.clear();
            _vocabScores.clear();
            _fluencyScores.clear();
          });
          _showScenarioSelector();
        },
        onDone: () => Navigator.pop(context),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'End Session?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Your current session progress will be lost. Would you like to end the session and see your score first?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Continue',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endSession();
            },
            child: const Text(
              'See Score',
              style: TextStyle(color: AppColors.richGold),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
