part of 'cultural_exchange_bloc.dart';

abstract class CulturalExchangeEvent extends Equatable {
  const CulturalExchangeEvent();

  @override
  List<Object?> get props => [];
}

// ==================== Initialization ====================

class LoadCulturalExchangeData extends CulturalExchangeEvent {
  const LoadCulturalExchangeData();
}

// ==================== Spotlight Events ====================

class LoadActiveSpotlight extends CulturalExchangeEvent {
  const LoadActiveSpotlight();
}

class LoadSpotlightHistory extends CulturalExchangeEvent {
  const LoadSpotlightHistory();
}

// ==================== Cultural Tips Events ====================

class LoadCulturalTips extends CulturalExchangeEvent {
  final String? country;
  final String? category;

  const LoadCulturalTips({this.country, this.category});

  @override
  List<Object?> get props => [country, category];
}

class SubmitCulturalTip extends CulturalExchangeEvent {
  final CulturalTip tip;

  const SubmitCulturalTip(this.tip);

  @override
  List<Object?> get props => [tip];
}

class LikeCulturalTip extends CulturalExchangeEvent {
  final String tipId;
  final String userId;

  const LikeCulturalTip({required this.tipId, required this.userId});

  @override
  List<Object?> get props => [tipId, userId];
}

// ==================== Dating Etiquette Events ====================

class LoadDatingEtiquette extends CulturalExchangeEvent {
  final String country;

  const LoadDatingEtiquette(this.country);

  @override
  List<Object?> get props => [country];
}

class LoadAvailableCountries extends CulturalExchangeEvent {
  const LoadAvailableCountries();
}
