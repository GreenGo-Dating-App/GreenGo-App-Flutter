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

  const LoadCulturalTips({this.country, this.category});
  final String? country;
  final String? category;

  @override
  List<Object?> get props => [country, category];
}

class SubmitCulturalTip extends CulturalExchangeEvent {

  const SubmitCulturalTip(this.tip);
  final CulturalTip tip;

  @override
  List<Object?> get props => [tip];
}

class LikeCulturalTip extends CulturalExchangeEvent {

  const LikeCulturalTip({required this.tipId, required this.userId});
  final String tipId;
  final String userId;

  @override
  List<Object?> get props => [tipId, userId];
}

// ==================== Dating Etiquette Events ====================

class LoadDatingEtiquette extends CulturalExchangeEvent {

  const LoadDatingEtiquette(this.country);
  final String country;

  @override
  List<Object?> get props => [country];
}

class LoadAvailableCountries extends CulturalExchangeEvent {
  const LoadAvailableCountries();
}
