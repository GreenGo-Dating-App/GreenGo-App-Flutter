import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/user_experience.dart';
import '../../domain/repositories/user_experiences_repository.dart';
import '../bloc/experience_feed_bloc.dart';
import '../experience_creation_gate.dart';
import '../widgets/experience_widgets.dart';
import 'experience_detail_screen.dart';
import 'experience_editor_screen.dart';

/// The host's own experiences (drafts, published, hidden): open, edit,
/// publish / unpublish, delete. Paginated 20 at a time.
class MyExperiencesScreen extends StatelessWidget {
  const MyExperiencesScreen({super.key, required this.currentUserId});
  final String currentUserId;

  static Route<void> route(String currentUserId) => MaterialPageRoute(
      builder: (_) => MyExperiencesScreen(currentUserId: currentUserId));

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExperienceFeedBloc(
          repository: di.sl<UserExperiencesRepository>())
        ..add(ExperienceFeedStarted(hostId: currentUserId)),
      child: _MyExperiencesView(currentUserId: currentUserId),
    );
  }
}

class _MyExperiencesView extends StatefulWidget {
  const _MyExperiencesView({required this.currentUserId});
  final String currentUserId;

  @override
  State<_MyExperiencesView> createState() => _MyExperiencesViewState();
}

class _MyExperiencesViewState extends State<_MyExperiencesView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.maxScrollExtent - _scroll.position.pixels < 400) {
        context.read<ExperienceFeedBloc>().add(const ExperienceFeedMoreRequested());
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final bloc = context.read<ExperienceFeedBloc>();
    final ok = await ExperienceCreationGate(
            repository: di.sl<UserExperiencesRepository>())
        .ensureCanCreate(context, widget.currentUserId);
    if (!ok || !mounted) return;
    final saved = await Navigator.of(context).push(
        ExperienceEditorScreen.route(currentUserId: widget.currentUserId));
    if (saved != null) bloc.add(ExperienceFeedItemUpserted(saved));
  }

  Future<void> _open(UserExperience e) async {
    final bloc = context.read<ExperienceFeedBloc>();
    final r = await Navigator.of(context).push(ExperienceDetailScreen.route(
        experienceId: e.id, currentUserId: widget.currentUserId, initial: e));
    if (r?.deletedId != null) bloc.add(ExperienceFeedItemRemoved(r!.deletedId!));
    if (r?.updated != null) bloc.add(ExperienceFeedItemUpserted(r!.updated!));
  }

  Future<void> _edit(UserExperience e) async {
    final bloc = context.read<ExperienceFeedBloc>();
    final saved = await Navigator.of(context).push(ExperienceEditorScreen.route(
        currentUserId: widget.currentUserId, existing: e));
    if (saved != null) bloc.add(ExperienceFeedItemUpserted(saved));
  }

  Future<void> _setStatus(UserExperience e, ExperienceStatus s) async {
    final l = AppLocalizations.of(context)!;
    final bloc = context.read<ExperienceFeedBloc>();
    final m = ScaffoldMessenger.of(context);
    final r = await di.sl<UserExperiencesRepository>().setStatus(e.id, s);
    r.fold(
      (_) => m.showSnackBar(SnackBar(
          content: Text(l.somethingWentWrong),
          backgroundColor: AppColors.errorRed)),
      (_) {
        bloc.add(ExperienceFeedItemUpserted(e.copyWith(status: s)));
        m.showSnackBar(SnackBar(
            content: Text(s == ExperienceStatus.published
                ? l.uexpPublished
                : l.uexpUnpublished)));
      },
    );
  }

  Future<void> _delete(UserExperience e) async {
    final l = AppLocalizations.of(context)!;
    final bloc = context.read<ExperienceFeedBloc>();
    final m = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l.uexpDeleteConfirmTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l.uexpDeleteConfirmBody,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.uexpDelete,
                style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final r = await di.sl<UserExperiencesRepository>().deleteExperience(e.id);
    r.fold(
      (_) => m.showSnackBar(SnackBar(
          content: Text(l.somethingWentWrong),
          backgroundColor: AppColors.errorRed)),
      (_) {
        bloc.add(ExperienceFeedItemRemoved(e.id));
        m.showSnackBar(SnackBar(content: Text(l.uexpDeleted)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(l.uexpMine,
            style: const TextStyle(color: AppColors.textPrimary)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.richGold,
        foregroundColor: AppColors.deepBlack,
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: Text(l.uexpCreate),
      ),
      body: BlocBuilder<ExperienceFeedBloc, ExperienceFeedState>(
        builder: (context, s) {
          if (s.status == ExperienceFeedStatus.loading ||
              s.status == ExperienceFeedStatus.initial) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.richGold));
          }
          if (s.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  s.status == ExperienceFeedStatus.failure
                      ? l.somethingWentWrong
                      : l.uexpMineEmpty,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.richGold,
            onRefresh: () async => context
                .read<ExperienceFeedBloc>()
                .add(const ExperienceFeedRefreshed()),
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemCount: s.items.length + (s.hasMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= s.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.richGold)),
                  );
                }
                final e = s.items[i];
                return Stack(children: [
                  ExperienceCard(
                    experience: e,
                    showStatus: true,
                    onTap: () => _open(e),
                  ),
                  Positioned(
                    right: 8,
                    top: 120,
                    child: PopupMenuButton<String>(
                      icon: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.more_vert,
                            size: 18, color: Colors.white),
                      ),
                      color: AppColors.backgroundCard,
                      onSelected: (v) {
                        switch (v) {
                          case 'edit':
                            _edit(e);
                          case 'publish':
                            _setStatus(e, ExperienceStatus.published);
                          case 'unpublish':
                            _setStatus(e, ExperienceStatus.draft);
                          case 'delete':
                            _delete(e);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                            value: 'edit',
                            child: Text(l.uexpEdit,
                                style: const TextStyle(
                                    color: AppColors.textPrimary))),
                        if (e.status == ExperienceStatus.draft)
                          PopupMenuItem(
                              value: 'publish',
                              child: Text(l.uexpPublish,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary))),
                        if (e.isPublished)
                          PopupMenuItem(
                              value: 'unpublish',
                              child: Text(l.uexpUnpublish,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary))),
                        PopupMenuItem(
                            value: 'delete',
                            child: Text(l.uexpDelete,
                                style: const TextStyle(
                                    color: AppColors.errorRed))),
                      ],
                    ),
                  ),
                ]);
              },
            ),
          );
        },
      ),
    );
  }
}
