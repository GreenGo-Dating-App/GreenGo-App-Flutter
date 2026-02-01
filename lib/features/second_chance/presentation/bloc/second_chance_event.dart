import 'package:equatable/equatable.dart';

/// Second Chance Events
abstract class SecondChanceEvent extends Equatable {
  const SecondChanceEvent();

  @override
  List<Object?> get props => [];
}

/// Load second chance profiles
class LoadSecondChanceProfiles extends SecondChanceEvent {
  final String userId;

  const LoadSecondChanceProfiles(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Load usage for today
class LoadSecondChanceUsage extends SecondChanceEvent {
  final String userId;

  const LoadSecondChanceUsage(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Like a second chance profile
class LikeSecondChanceEvent extends SecondChanceEvent {
  final String userId;
  final String entryId;

  const LikeSecondChanceEvent({
    required this.userId,
    required this.entryId,
  });

  @override
  List<Object?> get props => [userId, entryId];
}

/// Pass on a second chance profile
class PassSecondChanceEvent extends SecondChanceEvent {
  final String userId;
  final String entryId;

  const PassSecondChanceEvent({
    required this.userId,
    required this.entryId,
  });

  @override
  List<Object?> get props => [userId, entryId];
}

/// Purchase unlimited second chances
class PurchaseUnlimitedEvent extends SecondChanceEvent {
  final String userId;

  const PurchaseUnlimitedEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Select a profile to view
class SelectSecondChanceProfile extends SecondChanceEvent {
  final int index;

  const SelectSecondChanceProfile(this.index);

  @override
  List<Object?> get props => [index];
}
