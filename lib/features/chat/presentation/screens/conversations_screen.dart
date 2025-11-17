import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../profile/domain/repositories/profile_repository.dart';
import '../bloc/conversations_bloc.dart';
import '../bloc/conversations_event.dart';
import '../bloc/conversations_state.dart';
import '../widgets/conversation_card.dart';
import 'chat_screen.dart';

/// Conversations Screen
///
/// Displays list of user's conversations
class ConversationsScreen extends StatelessWidget {
  final String userId;

  const ConversationsScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ConversationsBloc>()
        ..add(ConversationsLoadRequested(userId)),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundCard,
          elevation: 0,
          title: const Text(
            'Messages',
            style: TextStyle(
              color: AppColors.richGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                // TODO: Implement search
              },
            ),
          ],
        ),
        body: BlocBuilder<ConversationsBloc, ConversationsState>(
          builder: (context, state) {
            if (state is ConversationsLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.richGold,
                ),
              );
            }

            if (state is ConversationsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.errorRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<ConversationsBloc>()
                            .add(const ConversationsRefreshRequested());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: AppColors.deepBlack,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is ConversationsEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 80,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No messages yet',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Start swiping and matching to chat with people!',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is ConversationsLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<ConversationsBloc>()
                      .add(const ConversationsRefreshRequested());
                },
                color: AppColors.richGold,
                child: ListView.builder(
                  itemCount: state.conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = state.conversations[index];
                    final otherUserId =
                        conversation.getOtherUserId(userId);

                    return FutureBuilder(
                      future: di
                          .sl<ProfileRepository>()
                          .getProfile(otherUserId),
                      builder: (context, snapshot) {
                        final profile = snapshot.data?.fold(
                          (l) => null,
                          (r) => r,
                        );

                        return ConversationCard(
                          conversation: conversation,
                          otherUserProfile: profile,
                          currentUserId: userId,
                          onTap: () async {
                            if (profile != null) {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    matchId: conversation.matchId,
                                    currentUserId: userId,
                                    otherUserId: otherUserId,
                                    otherUserProfile: profile,
                                  ),
                                ),
                              );

                              // Refresh conversations after returning from chat
                              if (context.mounted) {
                                context
                                    .read<ConversationsBloc>()
                                    .add(const ConversationsRefreshRequested());
                              }
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
