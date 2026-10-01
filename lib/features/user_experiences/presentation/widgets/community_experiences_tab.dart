import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/geo_query.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/user_experience.dart';
import '../../domain/repositories/user_experiences_repository.dart';
import '../bloc/experience_feed_bloc.dart';
import '../experience_creation_gate.dart';
import '../experience_l10n.dart';
import '../screens/experience_detail_screen.dart';
import '../screens/experience_editor_screen.dart';
import '../screens/my_experiences_screen.dart';
import 'experience_widgets.dart';

/// "Community" segment of the Events → Experiences tab: published
/// member-hosted experiences (nearest-first when the viewer's location is
/// known, else newest), 20 per page with infinite scroll, plus "Create
/// experience" and "My experiences".
class CommunityExperiencesTab extends StatelessWidget {
  const CommunityExperiencesTab({
    super.key,
    required this.currentUserId,
    required this.gridView,
    this.query = '',
    this.userLat,
    this.userLng,
  });

  final String currentUserId;
  final bool gridView;
  final String query;
  final double? userLat;
  final double? userLng;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExperienceFeedBloc(
          repository: di.sl<UserExperiencesRepository>()),
      child: _CommunityView(
        currentUserId: currentUserId,
        gridView: gridView,
        query: query,
        userLat: userLat,
        userLng: userLng,
      ),
    );
  }
}

class _CommunityView extends StatefulWidget {
  const _CommunityView({
    required this.currentUserId,
    required this.gridView,
    required this.query,
    this.userLat,
    this.userLng,
  });

  final String currentUserId;
  final bool gridView;
  final String query;
  final double? userLat;
  final double? userLng;

  @override
  State<_CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends State<_CommunityView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Separate controllers: only one of grid / list is mounted at a time.
  final _gridScroll = ScrollController();
  final _listScroll = ScrollController();
  ExperienceCategory? _category;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _gridScroll.addListener(_onScroll);
    _listScroll.addListener(_onScroll);
    _load();
  }

  @override
  void didUpdateWidget(_CommunityView old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), _load);
    } else if (old.userLat != widget.userLat || old.userLng != widget.userLng) {
      _load();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _gridScroll.dispose();
    _listScroll.dispose();
    super.dispose();
  }

  void _load() {
    if (!mounted) return;
    context.read<ExperienceFeedBloc>().add(ExperienceFeedStarted(
          lat: widget.userLat,
          lng: widget.userLng,
          category: _category,
          query: widget.query.trim(),
        ));
  }

  void _onScroll() {
    final c = _gridScroll.hasClients
        ? _gridScroll
        : (_listScroll.hasClients ? _listScroll : null);
    if (c == null) return;
    if (c.position.maxScrollExtent - c.position.pixels < 400) {
      context.read<ExperienceFeedBloc>().add(const ExperienceFeedMoreRequested());
    }
  }

  Future<void> _create() async {
    final bloc = context.read<ExperienceFeedBloc>();
    final ok = await ExperienceCreationGate(
            repository: di.sl<UserExperiencesRepository>())
        .ensureCanCreate(context, widget.currentUserId);
    if (!ok || !mounted) return;
    final saved = await Navigator.of(context).push(
        ExperienceEditorScreen.route(currentUserId: widget.currentUserId));
    if (saved != null && saved.isPublished) {
      bloc.add(ExperienceFeedItemUpserted(saved));
    }
  }

  Future<void> _open(UserExperience e) async {
    final bloc = context.read<ExperienceFeedBloc>();
    final r = await Navigator.of(context).push(ExperienceDetailScreen.route(
        experienceId: e.id, currentUserId: widget.currentUserId, initial: e));
    if (r?.deletedId != null) bloc.add(ExperienceFeedItemRemoved(r!.deletedId!));
    final u = r?.updated;
    if (u != null) {
      bloc.add(u.isPublished
          ? ExperienceFeedItemUpserted(u)
          : ExperienceFeedItemRemoved(u.id));
    }
  }

  double? _distanceKm(UserExperience e) {
    final lat = widget.userLat, lng = widget.userLng;
    if (lat == null || lng == null || !e.hasCoordinates) return null;
    return GeoQuery.distanceMeters(lat, lng, e.lat!, e.lng!) / 1000;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _create,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l.uexpCreate, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.richGold,
                  side: const BorderSide(color: AppColors.richGold),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => Navigator.of(context)
                    .push(MyExperiencesScreen.route(widget.currentUserId)),
                icon: const Icon(Icons.person_outline, size: 18),
                label: Text(l.uexpMine, overflow: TextOverflow.ellipsis),
              ),
            ),
          ]),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              _chip(l.uexpAll, null),
              for (final c in ExperienceCategory.values)
                _chip(ExperienceL10n.category(l, c), c),
            ],
          ),
        ),
        Expanded(child: _body(l)),
      ],
    );
  }

  Widget _chip(String label, ExperienceCategory? value) {
    final selected = _category == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: AppColors.richGold,
        backgroundColor: AppColors.backgroundCard,
        labelStyle: TextStyle(
          color: selected ? AppColors.deepBlack : AppColors.textSecondary,
          fontSize: 12,
        ),
        visualDensity: VisualDensity.compact,
        onSelected: (_) {
          setState(() => _category = value);
          _load();
        },
      ),
    );
  }

  Widget _body(AppLocalizations l) {
    return BlocBuilder<ExperienceFeedBloc, ExperienceFeedState>(
      builder: (context, s) {
        if (s.status == ExperienceFeedStatus.initial ||
            s.status == ExperienceFeedStatus.loading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.richGold));
        }
        if (s.items.isEmpty) {
          return RefreshIndicator(
            color: AppColors.richGold,
            onRefresh: () async => _load(),
            child: ListView(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
                child: Column(children: [
                  const Icon(Icons.travel_explore,
                      size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: 12),
                  Text(
                    s.status == ExperienceFeedStatus.failure
                        ? l.somethingWentWrong
                        : l.uexpEmpty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ]),
              ),
            ]),
          );
        }

        final Widget child;
        if (widget.gridView) {
          final w = MediaQuery.of(context).size.width;
          final cols = w >= 1100 ? 6 : (w >= 800 ? 4 : 3);
          child = GridView.builder(
            key: const ValueKey('uexpGrid'),
            controller: _gridScroll,
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.66,
            ),
            itemCount: s.items.length,
            itemBuilder: (_, i) => ExperienceCard(
              experience: s.items[i],
              compact: true,
              onTap: () => _open(s.items[i]),
            ),
          );
        } else {
          child = ListView.builder(
            key: const ValueKey('uexpList'),
            controller: _listScroll,
            padding: const EdgeInsets.all(12),
            itemCount: s.items.length + (s.hasMore ? 1 : 0),
            itemBuilder: (_, i) {
              if (i >= s.items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.richGold)),
                );
              }
              final e = s.items[i];
              return ExperienceCard(
                experience: e,
                distanceKm: _distanceKm(e),
                onTap: () => _open(e),
              );
            },
          );
        }
        return RefreshIndicator(
          color: AppColors.richGold,
          onRefresh: () async => context
              .read<ExperienceFeedBloc>()
              .add(const ExperienceFeedRefreshed()),
          child: child,
        );
      },
    );
  }
}
