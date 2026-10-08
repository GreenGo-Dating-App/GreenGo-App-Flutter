import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/country_flag_helper.dart';
import '../../../../core/utils/country_names_l10n.dart';
import '../../../../generated/app_localizations.dart';
import '../bloc/globe_bloc.dart';
import '../bloc/globe_event.dart';

class GlobeCountrySearch {
  static Future<void> show(
    BuildContext context,
    List<String> countries,
  ) async {
    final selected = await showSearch<String?>(
      context: context,
      delegate: _CountrySearchDelegate(countries),
    );
    if (selected != null && context.mounted) {
      context.read<GlobeBloc>().add(GlobeFlyToCountry(country: selected));
    }
  }
}

class _CountrySearchDelegate extends SearchDelegate<String?> {

  _CountrySearchDelegate(this.countries);

  /// Stored (English) country names; only the display is localized.
  final List<String> countries;

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppColors.textTertiary),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear, color: AppColors.textSecondary),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Search matches both the localized and the stored English name; the
    // list is shown (and sorted) by the localized name.
    final filtered = countries
        .where((c) => countryMatchesQuery(l10n, c, query))
        .map((c) => (stored: c, label: localizedCountryName(l10n, c)))
        .toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return Container(
      color: AppColors.backgroundDark,
      child: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (_, i) => ListTile(
          leading: Text(
            _countryToFlagEmoji(filtered[i].stored),
            style: const TextStyle(fontSize: 24),
          ),
          title: Text(
            filtered[i].label,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          onTap: () => close(context, filtered[i].stored),
        ),
      ),
    );
  }

  String _countryToFlagEmoji(String country) {
    final code = countryCodeFor(country);
    if (code == null || code.length != 2) return '\u{1F30D}';
    return CountryFlagHelper.getFlag(code);
  }
}
