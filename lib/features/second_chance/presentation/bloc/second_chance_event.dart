import 'package:equatable/equatable.dart';

/// Second Chance Events
abstract class SecondChanceEvent extends Equatable {
  const SecondChanceEvent();

  @override
  List<Object?> get props => [];
}

/// Load second chance profiles
class LoadSecondChanceProfiles extends SecondChanceEvent {

  const LoadSecondChanceProfiles(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Load usage for today
class LoadSecondChanceUsage extends SecondChanceEvent {

  const LoadSecondChanceUsage(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Like a second chance profile
class LikeSecondChanceEvent extends SecondChanceEvent {

  const LikeSecondChanceEvent({
    required this.userId,
    required this.entryId,
  });
  final String userId;
  final String entryId;

  @override
  List<Object?> get props => [userId, entryId];
}

/// Pass on a second chance profile
class PassSecondChanceEvent extends SecondChanceEvent {

  const PassSecondChanceEvent({
    required this.userId,
    required this.entryId,
  });
  final String userId;
  final String entryId;

  @override
  List<Object?> get props => [userId, entryId];
}

/// Purchase unlimited second chances
class PurchaseUnlimitedEvent extends SecondChanceEvent {

  const PurchaseUnlimitedEvent(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Select a profile to view
class SelectSecondChanceProfile extends SecondChanceEvent {

  const SelectSecondChanceProfile(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}
