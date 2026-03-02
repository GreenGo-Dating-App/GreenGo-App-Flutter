part of 'cultural_exchange_bloc.dart';

enum CulturalExchangeStatus {
  initial,
  loading,
  loaded,
  error,
}

class CulturalExchangeState extends Equatable {
  final CulturalExchangeStatus status;
  final String? errorMessage;

  // Spotlight
  final CountrySpotlight? activeSpotlight;
  final List<CountrySpotlight> spotlightHistory;
  final bool isSpotlightLoading;

  // Cultural Tips
  final List<CulturalTip> culturalTips;
  final bool isTipsLoading;

  // Dating Etiquette
  final DatingEtiquette? selectedEtiquette;
  final bool isEtiquetteLoading;

  // Countries
  final List<String> availableCountries;

  const CulturalExchangeState({
    this.status = CulturalExchangeStatus.initial,
    this.errorMessage,
    this.activeSpotlight,
    this.spotlightHistory = const [],
    this.isSpotlightLoading = false,
    this.culturalTips = const [],
    this.isTipsLoading = false,
    this.selectedEtiquette,
    this.isEtiquetteLoading = false,
    this.availableCountries = const [],
  });

  CulturalExchangeState copyWith({
    CulturalExchangeStatus? status,
    String? errorMessage,
    CountrySpotlight? activeSpotlight,
    List<CountrySpotlight>? spotlightHistory,
    bool? isSpotlightLoading,
    List<CulturalTip>? culturalTips,
    bool? isTipsLoading,
    DatingEtiquette? selectedEtiquette,
    bool? isEtiquetteLoading,
    List<String>? availableCountries,
  }) {
    return CulturalExchangeState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      activeSpotlight: activeSpotlight ?? this.activeSpotlight,
      spotlightHistory: spotlightHistory ?? this.spotlightHistory,
      isSpotlightLoading: isSpotlightLoading ?? this.isSpotlightLoading,
      culturalTips: culturalTips ?? this.culturalTips,
      isTipsLoading: isTipsLoading ?? this.isTipsLoading,
      selectedEtiquette: selectedEtiquette ?? this.selectedEtiquette,
      isEtiquetteLoading: isEtiquetteLoading ?? this.isEtiquetteLoading,
      availableCountries: availableCountries ?? this.availableCountries,
    );
  }

  bool get hasSpotlight => activeSpotlight != null;
  bool get hasTips => culturalTips.isNotEmpty;
  bool get hasEtiquette => selectedEtiquette != null;

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        activeSpotlight,
        spotlightHistory,
        isSpotlightLoading,
        culturalTips,
        isTipsLoading,
        selectedEtiquette,
        isEtiquetteLoading,
        availableCountries,
      ];
}
