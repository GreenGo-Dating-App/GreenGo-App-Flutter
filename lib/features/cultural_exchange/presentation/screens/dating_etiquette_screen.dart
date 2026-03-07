import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/dating_etiquette.dart';
import '../bloc/cultural_exchange_bloc.dart';

/// Screen for viewing dating etiquette by country
class DatingEtiquetteScreen extends StatefulWidget {
  final String? initialCountry;

  const DatingEtiquetteScreen({
    super.key,
    this.initialCountry,
  });

  @override
  State<DatingEtiquetteScreen> createState() => _DatingEtiquetteScreenState();
}

class _DatingEtiquetteScreenState extends State<DatingEtiquetteScreen> {
  String? _selectedCountry;

  @override
  void initState() {
    super.initState();
    // Load available countries if not already loaded
    final state = context.read<CulturalExchangeBloc>().state;
    if (state.availableCountries.isEmpty) {
      context
          .read<CulturalExchangeBloc>()
          .add(const LoadAvailableCountries());
    }

    // Load initial country etiquette if provided
    if (widget.initialCountry != null) {
      _selectedCountry = widget.initialCountry;
      context
          .read<CulturalExchangeBloc>()
          .add(LoadDatingEtiquette(widget.initialCountry!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.culturalExchangeDatingEtiquette,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<CulturalExchangeBloc, CulturalExchangeState>(
        builder: (context, state) {
          return Column(
            children: [
              // Country selector
              _buildCountrySelector(state),
              const Divider(color: AppColors.divider, height: 1),

              // Content
              Expanded(
                child: state.isEtiquetteLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.richGold,
                        ),
                      )
                    : state.hasEtiquette
                        ? _buildEtiquetteContent(state.selectedEtiquette!)
                        : _buildSelectCountryPrompt(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCountrySelector(CulturalExchangeState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.backgroundCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a Country',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.backgroundInput,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.divider,
                width: 0.5,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountry,
                hint: const Text(
                  'Choose a country...',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                  ),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.richGold,
                ),
                dropdownColor: AppColors.backgroundCard,
                isExpanded: true,
                items: state.availableCountries.map((country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(
                      country,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCountry = value);
                    context
                        .read<CulturalExchangeBloc>()
                        .add(LoadDatingEtiquette(value));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectCountryPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.public,
            size: 64,
            color: AppColors.richGold.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a country above',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Learn dating etiquette from 20+ countries\naround the world',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtiquetteContent(DatingEtiquette etiquette) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: etiquette.sections.length,
      itemBuilder: (context, index) {
        return _buildEtiquetteSection(etiquette.sections[index]);
      },
    );
  }

  Widget _buildEtiquetteSection(EtiquetteSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              section.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Section content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              section.content,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Do's list
          if (section.doList.isNotEmpty) ...[
            const Divider(color: AppColors.divider, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.successGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Do\'s',
                    style: TextStyle(
                      color: AppColors.successGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...section.doList.map(
              (item) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.check,
                        color: AppColors.successGreen.withValues(alpha: 0.7),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Don'ts list
          if (section.dontList.isNotEmpty) ...[
            const Divider(color: AppColors.divider, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.cancel,
                    color: AppColors.errorRed,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Don\'ts',
                    style: TextStyle(
                      color: AppColors.errorRed,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...section.dontList.map(
              (item) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.close,
                        color: AppColors.errorRed.withValues(alpha: 0.7),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
