import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/blind_date.dart';
import '../bloc/blind_date_bloc.dart';
import '../bloc/blind_date_event.dart';
import '../bloc/blind_date_state.dart';
import '../widgets/blind_profile_card.dart';

/// Main Blind Date mode screen
class BlindDateScreen extends StatefulWidget {
  final String userId;

  const BlindDateScreen({
    super.key,
    required this.userId,
  });

  @override
  State<BlindDateScreen> createState() => _BlindDateScreenState();
}

class _BlindDateScreenState extends State<BlindDateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Check blind date status on load
    context.read<BlindDateBloc>().add(CheckBlindDateStatus(widget.userId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blind Date'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.explore), text: 'Discover'),
            Tab(icon: Icon(Icons.favorite), text: 'Matches'),
          ],
        ),
        actions: [
          BlocBuilder<BlindDateBloc, BlindDateState>(
            builder: (context, state) {
              if (state is BlindDateStatusLoaded && state.isActive) {
                return IconButton(
                  icon: const Icon(Icons.power_settings_new),
                  onPressed: () => _showDeactivateDialog(context),
                  tooltip: 'Deactivate Blind Date Mode',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<BlindDateBloc, BlindDateState>(
        listener: (context, state) {
          if (state is BlindDateError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is BlindDateModeActivated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Blind Date mode activated!'),
                backgroundColor: Colors.green,
              ),
            );
            // Load candidates after activation
            context.read<BlindDateBloc>().add(
                  LoadBlindCandidates(userId: widget.userId),
                );
          } else if (state is BlindLikeActionResult && state.isMatch) {
            _showMatchDialog(context);
          } else if (state is InstantRevealCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Photos revealed! ${state.coinsSpent} coins spent.'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is InsufficientCoinsForReveal) {
            _showInsufficientCoinsDialog(context, state);
          }
        },
        builder: (context, state) {
          if (state is BlindDateLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BlindDateStatusLoaded && !state.isActive) {
            return _buildActivationScreen(context);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDiscoverTab(context, state),
              _buildMatchesTab(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivationScreen(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: const Icon(
                Icons.visibility_off,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Blind Date Mode',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Match based on personality, not looks.\nPhotos reveal after ${BlindDateConfig.revealThreshold} messages.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                context.read<BlindDateBloc>().add(
                      ActivateBlindDateMode(widget.userId),
                    );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Activate Blind Date Mode'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildFeatureList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context) {
    final features = [
      ('No profile photos visible initially', Icons.visibility_off),
      ('Focus on personality & interests', Icons.psychology),
      ('Photos unlock after chatting', Icons.lock_open),
      ('Instant reveal for ${BlindDateConfig.instantRevealCost} coins', Icons.bolt),
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                feature.$2,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  feature.$1,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDiscoverTab(BuildContext context, BlindDateState state) {
    if (state is NoMoreCandidates) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                context.read<BlindDateBloc>().add(
                      LoadBlindCandidates(userId: widget.userId),
                    );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    if (state is BlindCandidatesLoaded) {
      final candidate = state.currentCandidate;
      if (candidate == null) {
        return const Center(child: Text('No candidates available'));
      }

      return BlindProfileCard(
        profile: candidate,
        onLike: () {
          context.read<BlindDateBloc>().add(
                LikeBlindProfileEvent(
                  userId: widget.userId,
                  targetUserId: candidate.odldid,
                ),
              );
        },
        onPass: () {
          context.read<BlindDateBloc>().add(
                PassBlindProfileEvent(
                  userId: widget.userId,
                  targetUserId: candidate.odldid,
                ),
              );
        },
      );
    }

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BlindDateBloc>().add(
            LoadBlindCandidates(userId: widget.userId),
          );
    });

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildMatchesTab(BuildContext context, BlindDateState state) {
    // Load matches if not already loaded
    if (state is! BlindMatchesLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<BlindDateBloc>().add(LoadBlindMatches(widget.userId));
      });
      return const Center(child: CircularProgressIndicator());
    }

    if (state.matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No matches yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start swiping to find your blind date!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        if (state.pendingMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Pending Reveal (${state.pendingMatches.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ...state.pendingMatches.map((match) {
            // In a real app, you'd fetch the other profile
            final otherProfile = BlindProfileView(
              odldid: match.getOtherUserId(widget.userId),
              displayName: 'Mystery Person',
              age: 25,
            );
            return BlindMatchCard(
              match: match,
              otherProfile: otherProfile,
              onTap: () => _navigateToChat(match),
              onReveal: () => _confirmInstantReveal(context, match),
            );
          }),
        ],
        if (state.revealedMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Revealed (${state.revealedMatches.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ...state.revealedMatches.map((match) {
            final otherProfile = BlindProfileView(
              odldid: match.getOtherUserId(widget.userId),
              displayName: 'Revealed Match',
              age: 25,
              isRevealed: true,
            );
            return BlindMatchCard(
              match: match,
              otherProfile: otherProfile,
              onTap: () => _navigateToChat(match),
            );
          }),
        ],
      ],
    );
  }

  void _showDeactivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Blind Date Mode?'),
        content: const Text(
          'Your blind date profile will be hidden. You can reactivate anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BlindDateBloc>().add(
                    DeactivateBlindDateMode(widget.userId),
                  );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _showMatchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.favorite,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text("It's a Match!"),
          ],
        ),
        content: const Text(
          'You both liked each other! Start chatting to reveal your photos.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _tabController.animateTo(1); // Go to matches tab
            },
            child: const Text('View Match'),
          ),
        ],
      ),
    );
  }

  void _showInsufficientCoinsDialog(
    BuildContext context,
    InsufficientCoinsForReveal state,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insufficient Coins'),
        content: Text(
          'You need ${state.required} coins for instant reveal, but you only have ${state.available}. Get ${state.shortfall} more coins.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to coin purchase
            },
            child: const Text('Get Coins'),
          ),
        ],
      ),
    );
  }

  void _confirmInstantReveal(BuildContext context, BlindMatch match) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Instant Reveal'),
        content: Text(
          'Spend ${BlindDateConfig.instantRevealCost} coins to reveal photos now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BlindDateBloc>().add(
                    RequestInstantReveal(
                      userId: widget.userId,
                      matchId: match.id,
                    ),
                  );
            },
            child: const Text('Reveal'),
          ),
        ],
      ),
    );
  }

  void _navigateToChat(BlindMatch match) {
    // Navigate to chat screen with match
    // Navigator.push(...)
  }
}
