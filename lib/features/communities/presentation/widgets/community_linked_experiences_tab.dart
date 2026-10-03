import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../../user_experiences/domain/entities/user_experience.dart';
import '../../../user_experiences/domain/repositories/user_experiences_repository.dart';
import '../../../user_experiences/presentation/experience_creation_gate.dart';
import '../../../user_experiences/presentation/screens/experience_detail_screen.dart';
import '../../../user_experiences/presentation/screens/experience_editor_screen.dart';
import '../../../user_experiences/presentation/widgets/experience_widgets.dart';
import '../../domain/entities/community.dart';

/// The Experiences tab inside a community — mirrors [CommunityEventsTab]:
/// lists the experiences posted in this community (published, pictures only,
/// newest first, 20 per page) and lets the owner/admins ([canManage], the
/// same rule as the Events tab's create button and the server check in
/// createUserExperience) post a new one pre-linked to the community. The
/// host's own drafts in this community are shown first, to them only.
class CommunityLinkedExperiencesTab extends StatefulWidget {
  const CommunityLinkedExperiencesTab({
    required this.community,
    required this.canManage,
    required this.currentUserId,
    this.repository,
    super.key,
  });

  final Community community;
  final bool canManage;
  final String currentUserId;

  /// Injected in tests; defaults to the app's registered repository.
  final UserExperiencesRepository? repository;

  @override
  State<CommunityLinkedExperiencesTab> createState() =>
      _CommunityLinkedExperiencesTabState();
}

class _CommunityLinkedExperiencesTabState
    extends State<CommunityLinkedExperiencesTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scroll = ScrollController();
  late UserExperiencesRepository _repo;
  ExperienceFeedPager? _pager;
  List<UserExperience> _items = const [];
  List<UserExperience> _drafts = const [];
  bool _loading = true;
  bool _loadingMore = false;
  int _generation = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? di.sl<UserExperiencesRepository>();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final gen = ++_generation;
    final pager = _repo.communityExperiences(widget.community.id);
    _pager = pager;
    if (mounted) setState(() => _loading = true);
    List<UserExperience> first = const [];
    List<UserExperience> drafts = const [];
    try {
      final results = await Future.wait([
        pager.next(),
        // Host-only, so only for those who can post here (bounded reads for
        // the many ordinary viewers).
        if (widget.canManage && widget.currentUserId.isNotEmpty)
          _repo.hostCommunityDrafts(widget.community.id, widget.currentUserId),
      ]);
      first = results[0];
      if (results.length > 1) drafts = results[1];
    } catch (e) {
      debugPrint('CommunityLinkedExperiencesTab load failed: $e');
    }
    if (!mounted || gen != _generation) return;
    setState(() {
      _items = first;
      _drafts = drafts;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    final pager = _pager;
    if (pager == null || _loadingMore || _loading || !pager.hasMore) return;
    final gen = _generation;
    setState(() => _loadingMore = true);
    List<UserExperience> more = const [];
    try {
      more = await pager.next();
    } catch (e) {
      debugPrint('CommunityLinkedExperiencesTab more failed: $e');
    }
    if (!mounted || gen != _generation) return;
    final seen = _items.map((e) => e.id).toSet();
    setState(() {
      _items = [..._items, ...more.where((e) => seen.add(e.id))];
      _loadingMore = false;
    });
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    if (p.maxScrollExtent - p.pixels < 400) _loadMore();
  }

  Future<void> _create() async {
    final ok = await ExperienceCreationGate(repository: _repo)
        .ensureCanCreate(context, widget.currentUserId);
    if (!ok || !mounted) return;
    await Navigator.of(context).push(ExperienceEditorScreen.route(
      currentUserId: widget.currentUserId,
      communityId: widget.community.id,
      communityName: widget.community.name,
    ));
    if (mounted) _load();
  }

  Future<void> _open(UserExperience e) async {
    final r = await Navigator.of(context).push(ExperienceDetailScreen.route(
        experienceId: e.id, currentUserId: widget.currentUserId, initial: e));
    if (mounted && (r?.deletedId != null || r?.updated != null)) _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (widget.canManage)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDimensions.paddingM,
                AppDimensions.paddingS, AppDimensions.paddingM, 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('communityCreateExperience'),
                onPressed: _create,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.richGold,
                  side: const BorderSide(color: AppColors.richGold),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.uexpCreate),
              ),
            ),
          ),
        Expanded(child: _body(l10n)),
      ],
    );
  }

  Widget _body(AppLocalizations l10n) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.richGold),
      );
    }
    final all = [..._drafts, ..._items];
    if (all.isEmpty) {
      return RefreshIndicator(
        color: AppColors.richGold,
        backgroundColor: AppColors.backgroundCard,
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: c.maxHeight,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore_outlined,
                        size: 56,
                        color: AppColors.textTertiary.withValues(alpha: 0.5)),
                    const SizedBox(height: AppDimensions.paddingM),
                    Text(
                      l10n.communitiesExperiencesEmpty,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.richGold,
      backgroundColor: AppColors.backgroundCard,
      onRefresh: _load,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        itemCount: all.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= all.length) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.richGold),
              ),
            );
          }
          final e = all[index];
          return ExperienceCard(
            key: ValueKey('cexp_${e.id}'),
            experience: e,
            // Drafts carry their status chip (host-only).
            showStatus: index < _drafts.length,
            onTap: () => _open(e),
          );
        },
      ),
    );
  }
}
