import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/country_flag_helper.dart';
import '../../../../core/widgets/country_flag_badge.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/services/passport_service.dart';
import '../../domain/entities/cultural_passport.dart';

/// Cultural Passport — a glass "passport" of stamps the user collects for the
/// countries, languages and event categories they engage with.
///
/// Three sections (Countries / Languages / Events), each a grid of stamp tiles:
/// earned tiles glow gold, locked tiles are dimmed outlines. A progress header
/// summarises how much of the passport is filled.
class CulturalPassportScreen extends StatefulWidget {
  const CulturalPassportScreen({
    required this.userId,
    super.key,
    this.passportService,
  });

  final String userId;

  /// Injectable for tests; defaults to the DI singleton.
  final PassportService? passportService;

  @override
  State<CulturalPassportScreen> createState() => _CulturalPassportScreenState();
}

class _CulturalPassportScreenState extends State<CulturalPassportScreen> {
  late final PassportService _service;
  late Future<CulturalPassport> _future;

  // ── Collectible catalogs (locked tiles shown alongside earned stamps) ──

  /// EVERY country in the world (ISO 3166-1 alpha-2, ~197 entries from the
  /// canonical [CountryFlagHelper.allCountries] table); earned codes are unioned
  /// in. This makes the passport a complete, collectible world map.
  static final List<String> _countryCatalog = <String>[
    for (final c in CountryFlagHelper.allCountries) c.isoCode,
  ];

  /// Popular languages; earned languages are unioned in.
  static const List<String> _languageCatalog = <String>[
    'English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese',
    'Russian', 'Chinese', 'Japanese', 'Korean', 'Arabic', 'Hindi',
    'Dutch', 'Swedish', 'Turkish', 'Greek',
  ];

  /// Event categories (mirrors EventCategory, excluding the catch-all "other").
  static const List<String> _eventCatalog = <String>[
    'dating', 'social', 'sports', 'food', 'nightlife', 'outdoor',
    'arts', 'gaming', 'travel', 'wellness', 'languageExchange',
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.passportService ?? di.sl<PassportService>();
    _future = _service.load(widget.userId);
  }

  Future<void> _reload() async {
    _service.invalidate(widget.userId);
    setState(() {
      _future = _service.load(widget.userId);
    });
    await _future;
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
          l10n.culturalPassportTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<CulturalPassport>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _LoadingView(label: l10n.passportLoading);
          }
          final passport =
              snapshot.data ?? const CulturalPassport.empty();
          return _PassportBody(
            passport: passport,
            countryCatalog: _countryCatalog,
            languageCatalog: _languageCatalog,
            eventCatalog: _eventCatalog,
            onRefresh: _reload,
          );
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.richGold.withOpacity(0.3),
                  AppColors.richGold.withOpacity(0.1),
                ],
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(15),
              child: CircularProgressIndicator(
                color: AppColors.richGold,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _PassportBody extends StatelessWidget {
  const _PassportBody({
    required this.passport,
    required this.countryCatalog,
    required this.languageCatalog,
    required this.eventCatalog,
    required this.onRefresh,
  });

  final CulturalPassport passport;
  final List<String> countryCatalog;
  final List<String> languageCatalog;
  final List<String> eventCatalog;
  final Future<void> Function() onRefresh;

  /// Merge earned stamps (first, in gold) with the locked catalog, deduped.
  List<_Stamp> _stamps(
    List<String> earned,
    List<String> catalog,
    String Function(String) keyOf,
  ) {
    final seen = <String>{};
    final out = <_Stamp>[];
    for (final v in earned) {
      final k = keyOf(v);
      if (k.isEmpty || !seen.add(k)) continue;
      out.add(_Stamp(value: k, earned: true));
    }
    for (final v in catalog) {
      final k = keyOf(v);
      if (k.isEmpty || !seen.add(k)) continue;
      out.add(_Stamp(value: k, earned: false));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final countries = _stamps(
      passport.countryStamps,
      countryCatalog,
      (v) => v.trim().toUpperCase(),
    );
    final languages = _stamps(
      passport.languageStamps,
      languageCatalog,
      (v) => v.trim(),
    );
    final events = _stamps(
      passport.eventStamps,
      eventCatalog,
      (v) => v.trim(),
    );

    final earnedCountries = countries.where((s) => s.earned).length;
    final earnedLanguages = languages.where((s) => s.earned).length;
    final earnedEvents = events.where((s) => s.earned).length;

    // Overall % = average fill across the three families (bounded 0–100).
    double fill(int earned, int total) => total == 0 ? 0 : earned / total;
    final overall = (((fill(earnedCountries, countries.length) +
                    fill(earnedLanguages, languages.length) +
                    fill(earnedEvents, events.length)) /
                3) *
            100)
        .round()
        .clamp(0, 100);

    return RefreshIndicator(
      color: AppColors.richGold,
      backgroundColor: Colors.black,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _ProgressHeader(
            countries: earnedCountries,
            languages: earnedLanguages,
            events: earnedEvents,
            overallPercent: overall,
          ),
          if (passport.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                l10n.passportEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          _Section(
            title: l10n.passportSectionCountries,
            icon: Icons.public,
            stamps: countries,
            builder: (stamp) => _CountryStampTile(stamp: stamp),
          ),
          _Section(
            title: l10n.passportSectionLanguages,
            icon: Icons.translate,
            stamps: languages,
            builder: (stamp) => _LanguageStampTile(stamp: stamp),
          ),
          _Section(
            title: l10n.passportSectionEvents,
            icon: Icons.event,
            stamps: events,
            builder: (stamp) => _EventStampTile(stamp: stamp),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.countries,
    required this.languages,
    required this.events,
    required this.overallPercent,
  });

  final int countries;
  final int languages;
  final int events;
  final int overallPercent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.richGold.withOpacity(0.2),
                AppColors.richGold.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: AppColors.richGold.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              const Text('🛂', style: TextStyle(fontSize: 30)),
              const SizedBox(height: 8),
              Text(
                l10n.passportProgressSummary(countries, languages, events),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.passportOverallProgress(overallPercent),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  height: 10,
                  color: Colors.white.withOpacity(0.1),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: (overallPercent / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), AppColors.richGold],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.richGold.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.stamps,
    required this.builder,
  });

  final String title;
  final IconData icon;
  final List<_Stamp> stamps;
  final Widget Function(_Stamp) builder;

  @override
  Widget build(BuildContext context) {
    final earned = stamps.where((s) => s.earned).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.richGold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$earned/${stamps.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.82,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: stamps.length,
          itemBuilder: (context, index) => builder(stamps[index]),
        ),
      ],
    );
  }
}

/// One passport stamp: a value (ISO code / language / event category) + state.
class _Stamp {
  const _Stamp({required this.value, required this.earned});
  final String value;
  final bool earned;
}

/// Shared frosted-glass stamp card shell (gold when earned, dimmed when locked).
class _StampCard extends StatelessWidget {
  const _StampCard({
    required this.earned,
    required this.emblem,
    required this.label,
  });

  final bool earned;
  final Widget emblem;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = earned ? AppColors.richGold : Colors.grey;
    return Semantics(
      label: '$label · ${earned ? l10n.passportEarned : l10n.passportLocked}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(earned ? 0.22 : 0.06),
                  color.withOpacity(earned ? 0.05 : 0.02),
                ],
              ),
              border: Border.all(
                color: color.withOpacity(earned ? 0.45 : 0.15),
              ),
              boxShadow: earned
                  ? [
                      BoxShadow(
                        color: AppColors.richGold.withOpacity(0.25),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(opacity: earned ? 1.0 : 0.45, child: emblem),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: earned ? Colors.white : Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountryStampTile extends StatelessWidget {
  const _CountryStampTile({required this.stamp});
  final _Stamp stamp;

  @override
  Widget build(BuildContext context) {
    final flag = CountryFlagHelper.getFlag(stamp.value);
    final name = CountryFlagHelper.allCountries
            .where((c) => c.isoCode == stamp.value)
            .map((c) => c.name)
            .fold<String?>(null, (prev, e) => prev ?? e) ??
        stamp.value;
    return _StampCard(
      earned: stamp.earned,
      emblem: Text(
        flag.isNotEmpty ? flag : '🏳️',
        style: const TextStyle(fontSize: 30),
      ),
      label: name,
    );
  }
}

class _LanguageStampTile extends StatelessWidget {
  const _LanguageStampTile({required this.stamp});
  final _Stamp stamp;

  @override
  Widget build(BuildContext context) {
    final badge = LanguageFlagBadge(
      languages: [stamp.value],
      fontSize: 30,
      maxFlags: 1,
    );
    return _StampCard(
      earned: stamp.earned,
      emblem: SizedBox(
        height: 34,
        child: Center(
          child: badge.languages.isNotEmpty
              ? badge
              : const Text('🗣️', style: TextStyle(fontSize: 28)),
        ),
      ),
      label: stamp.value,
    );
  }
}

class _EventStampTile extends StatelessWidget {
  const _EventStampTile({required this.stamp});
  final _Stamp stamp;

  static IconData _iconFor(String category) {
    switch (category) {
      case 'dating':
        return Icons.favorite;
      case 'social':
        return Icons.groups;
      case 'sports':
        return Icons.sports_soccer;
      case 'food':
        return Icons.restaurant;
      case 'nightlife':
        return Icons.nightlife;
      case 'outdoor':
        return Icons.terrain;
      case 'arts':
        return Icons.palette;
      case 'gaming':
        return Icons.sports_esports;
      case 'travel':
        return Icons.flight;
      case 'wellness':
        return Icons.spa;
      case 'languageExchange':
        return Icons.translate;
      default:
        return Icons.event;
    }
  }

  static String _labelFor(BuildContext context, String category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case 'dating':
        return l10n.passportEventDating;
      case 'social':
        return l10n.passportEventSocial;
      case 'sports':
        return l10n.passportEventSports;
      case 'food':
        return l10n.passportEventFood;
      case 'nightlife':
        return l10n.passportEventNightlife;
      case 'outdoor':
        return l10n.passportEventOutdoor;
      case 'arts':
        return l10n.passportEventArts;
      case 'gaming':
        return l10n.passportEventGaming;
      case 'travel':
        return l10n.passportEventTravel;
      case 'wellness':
        return l10n.passportEventWellness;
      case 'languageExchange':
        return l10n.passportEventLanguageExchange;
      default:
        return l10n.passportEventOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = stamp.earned ? AppColors.richGold : Colors.grey;
    return _StampCard(
      earned: stamp.earned,
      emblem: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(stamp.earned ? 0.25 : 0.12),
        ),
        child: Icon(
          _iconFor(stamp.value),
          size: 18,
          color: stamp.earned ? Colors.white : Colors.grey,
        ),
      ),
      label: _labelFor(context, stamp.value),
    );
  }
}
