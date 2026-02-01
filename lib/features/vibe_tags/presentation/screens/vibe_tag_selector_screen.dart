import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/vibe_tag.dart';
import '../bloc/vibe_tag_bloc.dart';
import '../bloc/vibe_tag_event.dart';
import '../bloc/vibe_tag_state.dart';
import '../widgets/vibe_tag_chip.dart';

/// Vibe Tag Selector Screen
/// Allows users to select up to their limit of vibe tags
class VibeTagSelectorScreen extends StatefulWidget {
  final String userId;
  final bool isPremium;

  const VibeTagSelectorScreen({
    super.key,
    required this.userId,
    this.isPremium = false,
  });

  @override
  State<VibeTagSelectorScreen> createState() => _VibeTagSelectorScreenState();
}

class _VibeTagSelectorScreenState extends State<VibeTagSelectorScreen> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<VibeTagBloc>();
    bloc.setPremiumStatus(widget.isPremium);
    bloc.add(LoadUserVibeTags(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Vibe'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
      body: BlocConsumer<VibeTagBloc, VibeTagState>(
        listener: (context, state) {
          if (state is VibeTagError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
              ),
            );
          } else if (state is VibeTagLimitReached) {
            _showLimitReachedDialog(context, state);
          }
        },
        builder: (context, state) {
          if (state is VibeTagLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is VibeTagSelectionState) {
            return _buildContent(context, state);
          }

          return const Center(child: Text('No tags available'));
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, VibeTagSelectionState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomScrollView(
      slivers: [
        // Header with selected tags count
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.primaryContainer.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Show your vibe',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select tags that match your current mood and intentions',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTagCounter(context, state),
              ],
            ),
          ),
        ),

        // Selected tags section
        if (state.selectedTags.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Your Selected Tags',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: VibeTagChipList(
                tags: state.selectedTags,
                selectedTagIds: state.userTags.selectedTagIds,
                temporaryTagId: state.userTags.temporaryTagId,
                showAll: true,
                onTagTap: (tag) => _onTagTap(tag),
              ),
            ),
          ),
        ],

        // Temporary tag section
        if (state.temporaryTag != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 20,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Temporary Tag (24h)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: VibeTagChip(
                tag: state.temporaryTag!,
                isTemporary: true,
              ),
            ),
          ),
        ],

        // Divider
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
        ),

        // Tags by category
        ...state.tagsByCategory.entries.map((entry) {
          final category = entry.key;
          final tags = entry.value;
          final categoryEnum = VibeTagCategoryExtension.fromString(category);

          return SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      _getCategoryIcon(categoryEnum, colorScheme),
                      const SizedBox(width: 8),
                      Text(
                        categoryEnum.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: VibeTagChipList(
                    tags: tags,
                    selectedTagIds: state.userTags.selectedTagIds,
                    temporaryTagId: state.userTags.temporaryTagId,
                    showAll: true,
                    isSelectable: true,
                    maxSelectable: state.tagLimit,
                    onTagTap: (tag) => _onTagTap(tag),
                    onTagLongPress: (tag) => _onTagLongPress(context, tag),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        }),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }

  Widget _buildTagCounter(BuildContext context, VibeTagSelectionState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedCount = state.userTags.selectedTagIds.length;
    final limit = state.tagLimit;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selectedCount >= limit
                ? colorScheme.error.withOpacity(0.1)
                : colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$selectedCount / $limit tags selected',
            style: theme.textTheme.bodyMedium?.copyWith(
              color:
                  selectedCount >= limit ? colorScheme.error : colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        if (!state.isPremium)
          TextButton.icon(
            onPressed: () => _showUpgradeDialog(context),
            icon: const Icon(Icons.star, size: 16),
            label: const Text('Get 5 tags'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.amber.shade700,
            ),
          ),
      ],
    );
  }

  Widget _getCategoryIcon(VibeTagCategory category, ColorScheme colorScheme) {
    IconData icon;
    Color color;

    switch (category) {
      case VibeTagCategory.mood:
        icon = Icons.mood;
        color = Colors.orange;
        break;
      case VibeTagCategory.activity:
        icon = Icons.sports_tennis;
        color = Colors.green;
        break;
      case VibeTagCategory.intention:
        icon = Icons.favorite;
        color = Colors.pink;
        break;
      case VibeTagCategory.lifestyle:
        icon = Icons.nightlife;
        color = Colors.purple;
        break;
    }

    return Icon(icon, size: 20, color: color);
  }

  void _onTagTap(VibeTag tag) {
    context.read<VibeTagBloc>().add(
          ToggleVibeTag(
            userId: widget.userId,
            tagId: tag.id,
            isPremium: widget.isPremium,
          ),
        );
  }

  void _onTagLongPress(BuildContext context, VibeTag tag) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _buildTagOptionsSheet(ctx, tag),
    );
  }

  Widget _buildTagOptionsSheet(BuildContext context, VibeTag tag) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Set as temporary tag (24h)'),
            subtitle: const Text('Show this vibe for the next 24 hours'),
            onTap: () {
              Navigator.pop(context);
              context.read<VibeTagBloc>().add(
                    SetTemporaryVibeTagEvent(
                      userId: widget.userId,
                      tagId: tag.id,
                    ),
                  );
            },
          ),
          if (context
              .read<VibeTagBloc>()
              .state is VibeTagSelectionState &&
              (context.read<VibeTagBloc>().state as VibeTagSelectionState)
                  .isTagSelected(tag.id))
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Remove tag'),
              onTap: () {
                Navigator.pop(context);
                context.read<VibeTagBloc>().add(
                      RemoveVibeTagEvent(
                        userId: widget.userId,
                        tagId: tag.id,
                      ),
                    );
              },
            ),
        ],
      ),
    );
  }

  void _showLimitReachedDialog(
      BuildContext context, VibeTagLimitReached state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tag Limit Reached'),
        content: Text(
          state.isPremium
              ? 'You\'ve reached your maximum of ${state.limit} tags. Remove one to add another.'
              : 'Free users can select up to ${state.limit} tags. Upgrade to Premium for 5 tags!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
          if (!state.isPremium)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showUpgradeDialog(context);
              },
              child: const Text('Upgrade'),
            ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber.shade600),
            const SizedBox(width: 8),
            const Text('Upgrade to Premium'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Get access to:'),
            SizedBox(height: 8),
            Text('• 5 vibe tags instead of 3'),
            Text('• Exclusive premium tags'),
            Text('• Priority in search results'),
            Text('• And much more!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to subscription page
              // Navigator.pushNamed(context, '/subscription');
            },
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }
}
