import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
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
  final List<String> countries;

  _CountrySearchDelegate(this.countries);

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
    final filtered = countries
        .where((c) => c.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return Container(
      color: AppColors.backgroundDark,
      child: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (_, i) => ListTile(
          leading: Text(
            _countryToFlagEmoji(filtered[i]),
            style: const TextStyle(fontSize: 24),
          ),
          title: Text(
            filtered[i],
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          onTap: () => close(context, filtered[i]),
        ),
      ),
    );
  }

  String _countryToFlagEmoji(String country) {
    // Map common country names to ISO 3166-1 alpha-2 codes
    const countryToCode = {
      'Afghanistan': 'AF', 'Albania': 'AL', 'Algeria': 'DZ',
      'Argentina': 'AR', 'Australia': 'AU', 'Austria': 'AT',
      'Bangladesh': 'BD', 'Belgium': 'BE', 'Brazil': 'BR',
      'Canada': 'CA', 'Chile': 'CL', 'China': 'CN',
      'Colombia': 'CO', 'Czech Republic': 'CZ', 'Czechia': 'CZ',
      'Denmark': 'DK', 'Egypt': 'EG', 'Finland': 'FI',
      'France': 'FR', 'Germany': 'DE', 'Greece': 'GR',
      'Hungary': 'HU', 'India': 'IN', 'Indonesia': 'ID',
      'Iran': 'IR', 'Iraq': 'IQ', 'Ireland': 'IE',
      'Israel': 'IL', 'Italy': 'IT', 'Japan': 'JP',
      'Kenya': 'KE', 'Malaysia': 'MY', 'Mexico': 'MX',
      'Morocco': 'MA', 'Netherlands': 'NL', 'New Zealand': 'NZ',
      'Nigeria': 'NG', 'Norway': 'NO', 'Pakistan': 'PK',
      'Peru': 'PE', 'Philippines': 'PH', 'Poland': 'PL',
      'Portugal': 'PT', 'Romania': 'RO', 'Russia': 'RU',
      'Saudi Arabia': 'SA', 'Singapore': 'SG', 'South Africa': 'ZA',
      'South Korea': 'KR', 'Spain': 'ES', 'Sweden': 'SE',
      'Switzerland': 'CH', 'Thailand': 'TH', 'Turkey': 'TR',
      'Ukraine': 'UA', 'United Arab Emirates': 'AE',
      'United Kingdom': 'GB', 'United States': 'US', 'Vietnam': 'VN',
    };
    final code = countryToCode[country];
    if (code == null || code.length != 2) return '\u{1F30D}';
    final flag = String.fromCharCode(code.codeUnitAt(0) + 0x1F1A5) +
        String.fromCharCode(code.codeUnitAt(1) + 0x1F1A5);
    return flag;
  }
}
