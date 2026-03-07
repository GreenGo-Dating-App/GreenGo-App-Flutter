import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../domain/entities/second_chance.dart';
import '../bloc/second_chance_bloc.dart';
import '../bloc/second_chance_event.dart';
import '../bloc/second_chance_state.dart';

/// Second Chance Screen
class SecondChanceScreen extends StatefulWidget {
  final String userId;

  const SecondChanceScreen({
    super.key,
    required this.userId,
  });

  @override
  State<SecondChanceScreen> createState() => _SecondChanceScreenState();
}

class _SecondChanceScreenState extends State<SecondChanceScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SecondChanceBloc>().add(
          LoadSecondChanceProfiles(widget.userId),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.secondChanceTitle),
        actions: [
          BlocBuilder<SecondChanceBloc, SecondChanceState>(
            builder: (context, state) {
              if (state is SecondChanceProfilesLoaded) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildUsageBadge(state.usage),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<SecondChanceBloc, SecondChanceState>(
        listener: (context, state) {
          if (state is SecondChanceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is SecondChanceLikeResult && state.isMatch) {
            _showMatchDialog(context);
          } else if (state is NeedMoreSecondChances) {
            _showPurchaseDialog(context, state.usage);
          } else if (state is UnlimitedPurchased) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.secondChanceUnlimitedUnlocked),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SecondChanceLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NoMoreSecondChances) {
            return _buildEmptyState(context);
          }

          if (state is SecondChanceProfilesLoaded) {
            return _buildProfileCard(context, state);
          }

          return _buildInfoScreen(context);
        },
      ),
    );
  }

  Widget _buildUsageBadge(SecondChanceUsage usage) {
    final l10n = AppLocalizations.of(context)!;
    if (usage.hasUnlimited) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.all_inclusive, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              l10n.secondChanceUnlimited,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        l10n.secondChanceFreeRemaining(usage.freeRemaining, SecondChanceConfig.freePerDay),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Icon(
                Icons.replay,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.secondChanceTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.secondChanceDescription,
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
                context.read<SecondChanceBloc>().add(
                      LoadSecondChanceProfiles(widget.userId),
                    );
              },
              icon: const Icon(Icons.search),
              label: Text(l10n.secondChanceFindButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_satisfied_alt,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.secondChanceEmpty,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.secondChanceEmptySubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                context.read<SecondChanceBloc>().add(
                      LoadSecondChanceProfiles(widget.userId),
                    );
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.secondChanceRefresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    SecondChanceProfilesLoaded state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final profile = state.currentProfile;
    if (profile == null) return _buildEmptyState(context);

    return Column(
      children: [
        // Header with "They liked you" badge
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.pink.shade300,
                Colors.pink.shade400,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.secondChanceLikedYouAgo(profile.likedYouAgo),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Profile card
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo
                  if (profile.primaryPhoto != null)
                    Image.network(
                      profile.primaryPhoto!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 100,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Info
                  Positioned(
                    bottom: 100,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              profile.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${profile.age}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            ),
                            if (profile.isVerified) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 24,
                              ),
                            ],
                          ],
                        ),
                        if (profile.distance != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.secondChanceDistanceAway(profile.distance!.toStringAsFixed(1)),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        if (profile.bio != null && profile.bio!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              profile.bio!,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Expiry timer
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            profile.entry.formattedTimeRemaining,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Action buttons
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                context,
                icon: Icons.close,
                color: Colors.red,
                label: l10n.secondChancePass,
                onTap: () {
                  context.read<SecondChanceBloc>().add(
                        PassSecondChanceEvent(
                          userId: widget.userId,
                          entryId: profile.entry.id,
                        ),
                      );
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.favorite,
                color: Colors.green,
                label: l10n.secondChanceLike,
                isLarge: true,
                onTap: () {
                  context.read<SecondChanceBloc>().add(
                        LikeSecondChanceEvent(
                          userId: widget.userId,
                          entryId: profile.entry.id,
                        ),
                      );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    VoidCallback? onTap,
    bool isLarge = false,
  }) {
    final size = isLarge ? 70.0 : 56.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: isLarge ? 32 : 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showMatchDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.swap_horiz, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(l10n.secondChanceMatchTitle),
          ],
        ),
        content: Text(
          l10n.secondChanceMatchBody,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.secondChanceStartChat),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context, SecondChanceUsage usage) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.secondChanceOutOf),
        content: Text(
          l10n.secondChancePurchaseBody(SecondChanceConfig.freePerDay, SecondChanceConfig.unlimitedCost),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Maybe Later'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SecondChanceBloc>().add(
                    PurchaseUnlimitedEvent(widget.userId),
                  );
            },
            icon: const Icon(Icons.all_inclusive),
            label: Text(l10n.secondChanceGetUnlimited(SecondChanceConfig.unlimitedCost)),
          ),
        ],
      ),
    );
  }
}
