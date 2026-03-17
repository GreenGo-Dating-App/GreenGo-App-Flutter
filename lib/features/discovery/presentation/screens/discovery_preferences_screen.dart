import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/match_preferences.dart';
import '../../../membership/domain/entities/membership.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Discovery Preferences Screen
///
/// Allows users to configure their matching preferences
class DiscoveryPreferencesScreen extends StatefulWidget {
  final String userId;
  final MatchPreferences? currentPreferences;
  final Function(MatchPreferences)? onSave;

  const DiscoveryPreferencesScreen({
    super.key,
    required this.userId,
    this.currentPreferences,
    this.onSave,
  });

  @override
  State<DiscoveryPreferencesScreen> createState() =>
      _DiscoveryPreferencesScreenState();
}

class _DiscoveryPreferencesScreenState
    extends State<DiscoveryPreferencesScreen> {
  late MatchPreferences _preferences;
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isRestarting = false;
  DateTime? _lastRestartDate;
  MembershipTier _membershipTier = MembershipTier.free;

  @override
  void initState() {
    super.initState();
    _preferences = widget.currentPreferences ??
        MatchPreferences.defaultFor(widget.userId);
    _loadRestartInfo();
  }

  Future<void> _loadRestartInfo() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      final profileDoc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.userId)
          .get();
      if (mounted) {
        setState(() {
          final ts = userDoc.data()?['lastDiscoveryRestart'] as Timestamp?;
          _lastRestartDate = ts?.toDate();
          final tierStr = profileDoc.data()?['membershipTier'] as String? ?? 'FREE';
          _membershipTier = MembershipTier.values.firstWhere(
            (t) => t.value == tierStr,
            orElse: () => MembershipTier.free,
          );
        });
      }
    } catch (_) {}
  }

  int _getCooldownDays() {
    switch (_membershipTier) {
      case MembershipTier.gold:
      case MembershipTier.platinum:
      case MembershipTier.test:
        return 7;
      case MembershipTier.silver:
        return 15;
      case MembershipTier.free:
        return 30;
    }
  }

  int? _daysUntilRestart() {
    if (_lastRestartDate == null) return null;
    final cooldown = _getCooldownDays();
    final nextAllowed = _lastRestartDate!.add(Duration(days: cooldown));
    final remaining = nextAllowed.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : null;
  }

  Future<void> _restartDiscovery() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          l10n.profileRestartDiscoveryDialogTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.profileRestartDiscoveryDialogContent,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.profileRestart),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isRestarting = true);
    try {
      // Delete all swipes for this user in batches
      final firestore = FirebaseFirestore.instance;
      WriteBatch batch = firestore.batch();
      int count = 0;
      QuerySnapshot snapshot;
      do {
        snapshot = await firestore
            .collection('swipes')
            .where('userId', isEqualTo: widget.userId)
            .limit(500)
            .get();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
          count++;
          if (count % 500 == 0) {
            await batch.commit();
            batch = firestore.batch();
          }
        }
        if (snapshot.docs.isNotEmpty && count % 500 != 0) {
          await batch.commit();
          batch = firestore.batch();
        }
      } while (snapshot.docs.length == 500);

      // Record the restart timestamp
      await firestore.collection('users').doc(widget.userId).set(
        {'lastDiscoveryRestart': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

      if (mounted) {
        setState(() {
          _lastRestartDate = DateTime.now();
          _isRestarting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileDiscoveryRestarted),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRestarting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileFailedRestartDiscovery(e.toString())),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _updatePreferences(MatchPreferences newPreferences) {
    setState(() {
      _preferences = newPreferences;
      _hasChanges = true;
    });
  }

  Future<void> _savePreferences() async {
    if (!_hasChanges || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({
            'matchPreferences': _preferences.toMap(),
          }, SetOptions(merge: true));

      if (mounted) {
        // Pop with the saved preferences as result — the discovery screen
        // handles the refresh in its .then() callback after pop completes
        Navigator.of(context).pop(_preferences);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToSavePreferences(e.toString())),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showDealBreakerDialog() {
    final availableOptions = [
      'Smoking',
      'Drinking',
      'No bio',
      'No photos',
      'Different religion',
      'Different politics',
      'Has children',
      'Wants children',
      'Long distance',
      'Non-monogamy',
    ];

    // Filter out already selected deal breakers
    final availableToAdd = availableOptions
        .where((option) => !_preferences.dealBreakers.contains(option))
        .toList();

    if (availableToAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.allDealBreakersAdded),
          backgroundColor: AppColors.richGold,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          AppLocalizations.of(context)!.addDealBreakerTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableToAdd.length,
            itemBuilder: (context, index) {
              final option = availableToAdd[index];
              return ListTile(
                title: Text(
                  option,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  _updatePreferences(
                    _preferences.copyWith(
                      dealBreakers: [..._preferences.dealBreakers, option],
                    ),
                  );
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(context)!.cancelLabel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  /// Priority countries that are always shown in the "Most Popular" section
  static const _priorityCountries = [
    'United States', 'Brazil', 'Mexico', 'Colombia', 'Canada',
    'Spain', 'Italy', 'France', 'United Kingdom', 'Portugal',
  ];

  /// Fetch top countries by registered user count from Firestore,
  /// always including the priority countries
  Future<List<MapEntry<String, int>>> _fetchTopCountries() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .get();

      final countryCount = <String, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        // Try nested location.country first, then top-level country
        String? country;
        if (data['location'] is Map) {
          country = (data['location'] as Map)['country'] as String?;
        }
        country ??= data['country'] as String?;
        if (country != null && country.isNotEmpty && country != 'Unknown') {
          countryCount[country] = (countryCount[country] ?? 0) + 1;
        }
      }

      // Ensure all priority countries are included (even with 0 users)
      for (final country in _priorityCountries) {
        countryCount.putIfAbsent(country, () => 0);
      }

      // Sort: priority countries first (by user count), then others by count
      final priorityEntries = <MapEntry<String, int>>[];
      final otherEntries = <MapEntry<String, int>>[];

      for (final entry in countryCount.entries) {
        if (_priorityCountries.contains(entry.key)) {
          priorityEntries.add(entry);
        } else if (entry.value > 0) {
          otherEntries.add(entry);
        }
      }

      priorityEntries.sort((a, b) => b.value.compareTo(a.value));
      otherEntries.sort((a, b) => b.value.compareTo(a.value));

      // Return priority countries first, then top others (up to 15 total)
      final result = [...priorityEntries];
      for (final entry in otherEntries) {
        if (result.length >= 15) break;
        result.add(entry);
      }

      return result;
    } catch (e) {
      // Fallback: return priority countries with 0 count
      return _priorityCountries
          .map((c) => MapEntry(c, 0))
          .toList();
    }
  }

  void _showCountryPickerDialog() {
    final searchController = TextEditingController();
    final countries = [
      'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola',
      'Argentina', 'Armenia', 'Australia', 'Austria', 'Azerbaijan',
      'Bahamas', 'Bahrain', 'Bangladesh', 'Barbados', 'Belarus',
      'Belgium', 'Belize', 'Benin', 'Bhutan', 'Bolivia',
      'Bosnia and Herzegovina', 'Botswana', 'Brazil', 'Brunei', 'Bulgaria',
      'Burkina Faso', 'Burundi', 'Cambodia', 'Cameroon', 'Canada',
      'Cape Verde', 'Central African Republic', 'Chad', 'Chile', 'China',
      'Colombia', 'Comoros', 'Congo', 'Costa Rica', 'Croatia',
      'Cuba', 'Cyprus', 'Czech Republic', 'Denmark', 'Djibouti',
      'Dominican Republic', 'Ecuador', 'Egypt', 'El Salvador', 'Equatorial Guinea',
      'Eritrea', 'Estonia', 'Eswatini', 'Ethiopia', 'Fiji',
      'Finland', 'France', 'Gabon', 'Gambia', 'Georgia',
      'Germany', 'Ghana', 'Greece', 'Grenada', 'Guatemala',
      'Guinea', 'Guinea-Bissau', 'Guyana', 'Haiti', 'Honduras',
      'Hungary', 'Iceland', 'India', 'Indonesia', 'Iran',
      'Iraq', 'Ireland', 'Israel', 'Italy', 'Ivory Coast',
      'Jamaica', 'Japan', 'Jordan', 'Kazakhstan', 'Kenya',
      'Kuwait', 'Kyrgyzstan', 'Laos', 'Latvia', 'Lebanon',
      'Lesotho', 'Liberia', 'Libya', 'Liechtenstein', 'Lithuania',
      'Luxembourg', 'Madagascar', 'Malawi', 'Malaysia', 'Maldives',
      'Mali', 'Malta', 'Mauritania', 'Mauritius', 'Mexico',
      'Moldova', 'Monaco', 'Mongolia', 'Montenegro', 'Morocco',
      'Mozambique', 'Myanmar', 'Namibia', 'Nepal', 'Netherlands',
      'New Zealand', 'Nicaragua', 'Niger', 'Nigeria', 'North Korea',
      'North Macedonia', 'Norway', 'Oman', 'Pakistan', 'Panama',
      'Papua New Guinea', 'Paraguay', 'Peru', 'Philippines', 'Poland',
      'Portugal', 'Qatar', 'Romania', 'Russia', 'Rwanda',
      'Saudi Arabia', 'Senegal', 'Serbia', 'Sierra Leone', 'Singapore',
      'Slovakia', 'Slovenia', 'Somalia', 'South Africa', 'South Korea',
      'South Sudan', 'Spain', 'Sri Lanka', 'Sudan', 'Suriname',
      'Sweden', 'Switzerland', 'Syria', 'Taiwan', 'Tajikistan',
      'Tanzania', 'Thailand', 'Togo', 'Trinidad and Tobago', 'Tunisia',
      'Turkey', 'Turkmenistan', 'Uganda', 'Ukraine', 'United Arab Emirates',
      'United Kingdom', 'United States', 'Uruguay', 'Uzbekistan', 'Venezuela',
      'Vietnam', 'Yemen', 'Zambia', 'Zimbabwe',
    ];

    // Filter out already selected countries
    final availableCountries = countries
        .where((c) => !_preferences.preferredCountries.contains(c))
        .toList();

    // Fetch top countries from Firestore
    List<MapEntry<String, int>> topCountries = [];
    Map<String, int> countryUserCounts = {};
    bool isLoadingTop = true;
    bool sortByUsers = false; // false = alphabetical, true = by user count

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Fetch top countries once
            if (isLoadingTop) {
              _fetchTopCountries().then((result) {
                setDialogState(() {
                  topCountries = result
                      .where((e) => !_preferences.preferredCountries.contains(e.key))
                      .toList();
                  countryUserCounts = {for (final e in result) e.key: e.value};
                  isLoadingTop = false;
                });
              });
            }

            final query = searchController.text.toLowerCase();
            final isSearching = query.isNotEmpty;
            var filtered = isSearching
                ? availableCountries
                    .where((c) => c.toLowerCase().contains(query))
                    .toList()
                : availableCountries.toList();

            // Sort by user count (descending) when toggled
            if (sortByUsers && !isLoadingTop) {
              filtered.sort((a, b) {
                final aCount = countryUserCounts[a] ?? 0;
                final bCount = countryUserCounts[b] ?? 0;
                return bCount.compareTo(aCount); // Descending
              });
            }

            // Top country names for marking in the full list
            final topCountryNames = topCountries.map((e) => e.key).toSet();

            return AlertDialog(
              backgroundColor: AppColors.backgroundCard,
              title: Text(
                AppLocalizations.of(context)!.preferenceSelectCountry,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 450,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchCountryHint,
                        hintStyle: const TextStyle(color: AppColors.textTertiary),
                        prefixIcon: const Icon(Icons.search, color: AppColors.richGold),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.richGold),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),
                    // Sort toggle: Alphabetical / By Users
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => sortByUsers = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !sortByUsers ? AppColors.richGold.withOpacity(0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: !sortByUsers ? AppColors.richGold : AppColors.divider,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sort_by_alpha, size: 16, color: !sortByUsers ? AppColors.richGold : AppColors.textTertiary),
                                  const SizedBox(width: 4),
                                  Text('A-Z', style: TextStyle(color: !sortByUsers ? AppColors.richGold : AppColors.textTertiary, fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => sortByUsers = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: sortByUsers ? AppColors.richGold.withOpacity(0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: sortByUsers ? AppColors.richGold : AppColors.divider,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people, size: 16, color: sortByUsers ? AppColors.richGold : AppColors.textTertiary),
                                  const SizedBox(width: 4),
                                  Text(AppLocalizations.of(context)!.preferenceByUsers, style: TextStyle(color: sortByUsers ? AppColors.richGold : AppColors.textTertiary, fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        children: [
                          // Top 10 countries section (shown when alphabetical, hidden during search or user-count sort)
                          if (!isSearching && !sortByUsers && topCountries.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: AppColors.richGold, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.preferenceMostPopular,
                                    style: const TextStyle(
                                      color: AppColors.richGold,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...topCountries.map((entry) => ListTile(
                              leading: const Icon(
                                Icons.star,
                                color: AppColors.richGold,
                                size: 20,
                              ),
                              title: Text(
                                entry.key,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: Text(
                                '${entry.value} users',
                                style: const TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () {
                                _updatePreferences(
                                  _preferences.copyWith(
                                    preferredCountries: [
                                      ..._preferences.preferredCountries,
                                      entry.key,
                                    ],
                                  ),
                                );
                                Navigator.of(context).pop();
                              },
                            )),
                            const Divider(color: AppColors.divider),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              child: Text(
                                AppLocalizations.of(context)!.preferenceAllCountries,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          if (!isSearching && isLoadingTop)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.richGold,
                                  ),
                                ),
                              ),
                            ),
                          // Full country list (or search results)
                          if (filtered.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  AppLocalizations.of(context)!.preferenceNoCountriesFound,
                                  style: const TextStyle(color: AppColors.textTertiary),
                                ),
                              ),
                            )
                          else
                            ...filtered.map((country) {
                              final isTop = topCountryNames.contains(country);
                              final userCount = countryUserCounts[country] ?? 0;
                              return ListTile(
                                leading: Icon(
                                  isTop ? Icons.star : Icons.public,
                                  color: AppColors.richGold,
                                  size: 20,
                                ),
                                title: Text(
                                  country,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: isTop ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                                trailing: (sortByUsers || isTop) && userCount > 0
                                    ? Text(
                                        '$userCount',
                                        style: const TextStyle(
                                          color: AppColors.textTertiary,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                                onTap: () {
                                  _updatePreferences(
                                    _preferences.copyWith(
                                      preferredCountries: [
                                        ..._preferences.preferredCountries,
                                        country,
                                      ],
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                },
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showInterestPickerDialog() {
    final searchController = TextEditingController();
    // Same list as profile edit (edit_interests_screen.dart)
    final allInterests = [
      'Travel', 'Photography', 'Music', 'Fitness', 'Cooking',
      'Reading', 'Movies', 'Gaming', 'Art', 'Dance',
      'Yoga', 'Hiking', 'Swimming', 'Cycling', 'Running',
      'Sports', 'Fashion', 'Technology', 'Writing', 'Coffee',
      'Wine', 'Beer', 'Food', 'Vegetarian', 'Vegan',
      'Pets', 'Dogs', 'Cats', 'Nature', 'Beach',
      'Mountains', 'Camping', 'Surfing', 'Skiing', 'Snowboarding',
      'Meditation', 'Spirituality', 'Volunteering', 'Environment',
      'Politics', 'Science', 'History', 'Languages', 'Teaching',
    ];

    final available = allInterests
        .where((i) => !_preferences.preferredInterests.contains(i))
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final query = searchController.text.toLowerCase();
            final filtered = query.isNotEmpty
                ? available.where((i) => i.toLowerCase().contains(query)).toList()
                : available;

            return AlertDialog(
              backgroundColor: AppColors.backgroundCard,
              title: Text(
                AppLocalizations.of(context)!.preferenceAddInterest,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.preferenceSearchInterest,
                        hintStyle: const TextStyle(color: AppColors.textTertiary),
                        prefixIcon: const Icon(Icons.search, color: AppColors.richGold),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.richGold),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                AppLocalizations.of(context)!.preferenceNoInterestsFound,
                                style: const TextStyle(color: AppColors.textTertiary),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final interest = filtered[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.interests,
                                    color: AppColors.richGold,
                                    size: 20,
                                  ),
                                  title: Text(
                                    interest,
                                    style: const TextStyle(color: AppColors.textPrimary),
                                  ),
                                  onTap: () {
                                    _updatePreferences(
                                      _preferences.copyWith(
                                        preferredInterests: [
                                          ..._preferences.preferredInterests,
                                          interest,
                                        ],
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppLocalizations.of(context)!.cancelLabel,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.discoveryPreferencesTitle,
          style: TextStyle(
            color: AppColors.richGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_hasChanges)
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _savePreferences,
                    child: Text(
                      l10n.preferenceSave,
                      style: TextStyle(
                        color: AppColors.richGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Age range
          _buildSectionCard(
            title: l10n.preferenceAgeRange,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.preferenceAgeRange,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${_preferences.minAge} - ${_preferences.maxAge}',
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: RangeValues(
                    _preferences.minAge.toDouble(),
                    _preferences.maxAge.toDouble(),
                  ),
                  min: 18,
                  max: 100,
                  divisions: 82,
                  activeColor: AppColors.richGold,
                  inactiveColor: AppColors.divider,
                  onChanged: (RangeValues values) {
                    _updatePreferences(
                      _preferences.copyWith(
                        minAge: values.start.toInt(),
                        maxAge: values.end.toInt(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Distance
          _buildSectionCard(
            title: l10n.preferenceMaxDistance,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.preferenceWithin,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _preferences.maxDistanceKm != null
                          ? l10n.preferenceDistanceKm(_preferences.maxDistanceKm!)
                          : l10n.preferenceUnlimited,
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: (_preferences.maxDistanceKm?.toDouble() ?? 200).clamp(1, 200),
                  min: 1,
                  max: 200,
                  divisions: 199,
                  activeColor: AppColors.richGold,
                  inactiveColor: AppColors.divider,
                  onChanged: (double value) {
                    _updatePreferences(
                      _preferences.copyWith(
                        maxDistanceKm: value.toInt(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: Text(
                    l10n.preferenceNoDistanceLimit,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  value: _preferences.maxDistanceKm == null,
                  activeColor: AppColors.richGold,
                  onChanged: (bool value) {
                    _updatePreferences(
                      _preferences.copyWith(
                        clearMaxDistance: value,
                        maxDistanceKm: value ? null : 50,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Country filter
          _buildSectionCard(
            title: l10n.preferenceCountry,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.preferenceCountryDescription,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                if (_preferences.preferredCountries.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _preferences.preferredCountries
                        .map((country) => Chip(
                              label: Text(
                                country,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              deleteIcon: const Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.errorRed,
                              ),
                              onDeleted: () {
                                      _updatePreferences(
                                        _preferences.copyWith(
                                          preferredCountries: List.from(
                                              _preferences.preferredCountries)
                                            ..remove(country),
                                        ),
                                      );
                                    },
                              backgroundColor: AppColors.backgroundDark,
                              side: const BorderSide(color: AppColors.richGold),
                            ))
                        .toList(),
                  )
                else
                  Text(
                    l10n.preferenceNoCountryFilter,
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _showCountryPickerDialog,
                  icon: const Icon(
                    Icons.add,
                    color: AppColors.richGold,
                  ),
                  label: Text(
                    l10n.preferenceAddCountry,
                    style: TextStyle(
                      color: AppColors.richGold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Language filter
          _buildSectionCard(
            title: l10n.preferenceLanguageFilter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.preferenceLanguageFilterDesc,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _preferences.languageFilter,
                  dropdownColor: AppColors.backgroundCard,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.richGold),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  hint: Text(
                    l10n.preferenceAnyLanguage,
                    style: const TextStyle(color: AppColors.textTertiary),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(l10n.preferenceAnyLanguage),
                    ),
                    // Only the 7 app-supported languages
                    ...['English', 'German', 'Spanish', 'French', 'Italian',
                        'Portuguese', 'Portuguese (Brazil)']
                        .map((lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(lang),
                            )),
                  ],
                  onChanged: (value) {
                    _updatePreferences(
                      _preferences.copyWith(
                        languageFilter: value,
                        clearLanguageFilter: value == null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Interest filter
          _buildSectionCard(
            title: l10n.preferenceInterestFilter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.preferenceInterestFilterDesc,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                if (_preferences.preferredInterests.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _preferences.preferredInterests
                        .map((interest) => Chip(
                              label: Text(
                                interest,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              deleteIcon: const Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.errorRed,
                              ),
                              onDeleted: () {
                                _updatePreferences(
                                  _preferences.copyWith(
                                    preferredInterests: List.from(
                                        _preferences.preferredInterests)
                                      ..remove(interest),
                                  ),
                                );
                              },
                              backgroundColor: AppColors.backgroundDark,
                              side: const BorderSide(color: AppColors.richGold),
                            ))
                        .toList(),
                  )
                else
                  Text(
                    l10n.preferenceNoInterestFilter,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _showInterestPickerDialog,
                  icon: const Icon(
                    Icons.add,
                    color: AppColors.richGold,
                  ),
                  label: Text(
                    l10n.preferenceAddInterest,
                    style: const TextStyle(
                      color: AppColors.richGold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Gender preference
          _buildSectionCard(
            title: l10n.preferenceShowMe,
            child: Column(
              children: [
                _buildRadioOption(
                  value: 'men',
                  groupValue: _preferences.interestedInGender,
                  label: l10n.preferenceMen,
                  onChanged: (value) {
                    _updatePreferences(
                      _preferences.copyWith(interestedInGender: value),
                    );
                  },
                ),
                _buildRadioOption(
                  value: 'women',
                  groupValue: _preferences.interestedInGender,
                  label: l10n.preferenceWomen,
                  onChanged: (value) {
                    _updatePreferences(
                      _preferences.copyWith(interestedInGender: value),
                    );
                  },
                ),
                _buildRadioOption(
                  value: 'everyone',
                  groupValue: _preferences.interestedInGender,
                  label: l10n.preferenceEveryone,
                  onChanged: (value) {
                    _updatePreferences(
                      _preferences.copyWith(interestedInGender: value),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sexual Orientation filter
          _buildSectionCard(
            title: l10n.preferenceSexualOrientation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.preferenceOrientationDescription,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...['Straight', 'Gay', 'Bisexual', 'Other'].map((orientation) {
                  final isSelected = _preferences.preferredOrientations.contains(orientation);
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      orientation,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    value: isSelected,
                    activeColor: AppColors.richGold,
                    onChanged: (bool? value) {
                      final current = List<String>.from(_preferences.preferredOrientations);
                      if (value == true) {
                        current.add(orientation);
                      } else {
                        current.remove(orientation);
                      }
                      _updatePreferences(
                        _preferences.copyWith(preferredOrientations: current),
                      );
                    },
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Advanced filters
          _buildSectionCard(
            title: l10n.preferenceAdvancedFilters,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.preferenceOnlyVerified,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    l10n.preferenceAllVerified,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  value: true,
                  activeColor: AppColors.richGold,
                  onChanged: null,
                ),
                const Divider(color: AppColors.divider),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.preferenceRecentlyActive,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    l10n.preferenceRecentlyActiveDesc,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  value: _preferences.onlyRecentlyActive,
                  activeColor: AppColors.richGold,
                  onChanged: (bool value) {
                    _updatePreferences(
                      _preferences.copyWith(onlyRecentlyActive: value),
                    );
                  },
                ),
                SwitchListTile(
                  title: Text(
                    l10n.preferenceOnlineNow,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    l10n.preferenceOnlineNowDesc,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  value: _preferences.onlyOnlineNow,
                  activeColor: AppColors.richGold,
                  onChanged: (bool value) {
                    _updatePreferences(
                      _preferences.copyWith(onlyOnlineNow: value),
                    );
                  },
                ),
                const Divider(color: AppColors.divider),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.randomMode,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    l10n.randomModeDescription,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  value: _preferences.randomMode,
                  activeColor: AppColors.richGold,
                  onChanged: (bool value) {
                    _updatePreferences(
                      _preferences.copyWith(randomMode: value),
                    );
                  },
                ),
                const Divider(color: AppColors.divider),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.showSupportUser,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    l10n.showSupportUserDescription,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  value: _preferences.showSupportUser,
                  activeColor: AppColors.richGold,
                  onChanged: (bool value) {
                    _updatePreferences(
                      _preferences.copyWith(showSupportUser: value),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Deal breakers
          _buildSectionCard(
            title: l10n.preferenceDealBreakers,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.preferenceDealBreakersDesc,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                if (_preferences.dealBreakers.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _preferences.dealBreakers
                        .map((dealBreaker) => _buildDealBreakerChip(dealBreaker))
                        .toList(),
                  )
                else
                  Text(
                    l10n.preferenceNoDealBreakers,
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _showDealBreakerDialog,
                  icon: const Icon(
                    Icons.add,
                    color: AppColors.richGold,
                  ),
                  label: Text(
                    l10n.preferenceAddDealBreaker,
                    style: const TextStyle(
                      color: AppColors.richGold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Restart Discovery button
          Builder(builder: (context) {
            final daysLeft = _daysUntilRestart();
            final canRestart = daysLeft == null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: canRestart && !_isRestarting ? _restartDiscovery : null,
                  icon: _isRestarting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.restart_alt),
                  label: Text(AppLocalizations.of(context)!.profileRestartDiscovery),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canRestart ? Colors.red.shade700 : AppColors.backgroundCard,
                    foregroundColor: canRestart ? Colors.white : AppColors.textSecondary,
                    disabledBackgroundColor: AppColors.backgroundCard,
                    disabledForegroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                if (!canRestart)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Available again in $daysLeft day${daysLeft == 1 ? '' : 's'}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.profileRestartDiscoverySubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            );
          }),

          const SizedBox(height: 24),

          // Reset button
          OutlinedButton(
            onPressed: () {
              setState(() {
                _preferences = MatchPreferences.defaultFor(widget.userId);
                _hasChanges = true;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.divider),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(l10n.resetToDefault),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String value,
    required String? groupValue,
    required String label,
    required Function(String?) onChanged,
  }) {
    return RadioListTile<String>(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
      ),
      value: value,
      groupValue: groupValue,
      activeColor: AppColors.richGold,
      onChanged: onChanged,
    );
  }

  Widget _buildDealBreakerChip(String dealBreaker) {
    return Chip(
      label: Text(
        dealBreaker,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      deleteIcon: const Icon(
        Icons.close,
        size: 18,
        color: AppColors.errorRed,
      ),
      onDeleted: () {
        _updatePreferences(
          _preferences.copyWith(
            dealBreakers: List.from(_preferences.dealBreakers)
              ..remove(dealBreaker),
          ),
        );
      },
      backgroundColor: AppColors.backgroundDark,
      side: const BorderSide(color: AppColors.divider),
    );
  }
}
