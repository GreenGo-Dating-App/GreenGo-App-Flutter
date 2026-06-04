import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/share_my_date.dart';
import '../../domain/usecases/share_my_date_usecases.dart';

// Events
abstract class ShareMyDateEvent extends Equatable {
  const ShareMyDateEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrustedContacts extends ShareMyDateEvent {
  const LoadTrustedContacts(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class AddContactEvent extends ShareMyDateEvent {

  const AddContactEvent({
    required this.userId,
    required this.contactName,
    required this.contactPhone,
    this.contactEmail,
  });
  final String userId;
  final String contactName;
  final String contactPhone;
  final String? contactEmail;

  @override
  List<Object?> get props => [userId, contactName, contactPhone, contactEmail];
}

class RemoveContactEvent extends ShareMyDateEvent {
  const RemoveContactEvent(this.contactId);
  final String contactId;

  @override
  List<Object?> get props => [contactId];
}

class ShareDateEvent extends ShareMyDateEvent {

  const ShareDateEvent({
    required this.userId,
    required this.scheduledDateId,
    required this.matchName,
    required this.dateTime, this.matchPhotoUrl,
    this.venueName,
    this.venueAddress,
    this.venueLat,
    this.venueLng,
    this.contactIds = const [],
  });
  final String userId;
  final String scheduledDateId;
  final String matchName;
  final String? matchPhotoUrl;
  final DateTime dateTime;
  final String? venueName;
  final String? venueAddress;
  final double? venueLat;
  final double? venueLng;
  final List<String> contactIds;

  @override
  List<Object?> get props => [
        userId,
        scheduledDateId,
        matchName,
        matchPhotoUrl,
        dateTime,
        venueName,
        venueAddress,
        venueLat,
        venueLng,
        contactIds,
      ];
}

class CheckInEvent extends ShareMyDateEvent {

  const CheckInEvent({
    required this.sharedDateId,
    this.lat,
    this.lng,
    this.note,
  });
  final String sharedDateId;
  final double? lat;
  final double? lng;
  final String? note;

  @override
  List<Object?> get props => [sharedDateId, lat, lng, note];
}

class MarkSafeArrivalEvent extends ShareMyDateEvent {
  const MarkSafeArrivalEvent(this.sharedDateId);
  final String sharedDateId;

  @override
  List<Object?> get props => [sharedDateId];
}

class TriggerEmergencyEvent extends ShareMyDateEvent {

  const TriggerEmergencyEvent({
    required this.sharedDateId,
    required this.userId,
    this.lat,
    this.lng,
    this.note,
  });
  final String sharedDateId;
  final String userId;
  final double? lat;
  final double? lng;
  final String? note;

  @override
  List<Object?> get props => [sharedDateId, userId, lat, lng, note];
}

class LoadActiveDate extends ShareMyDateEvent {
  const LoadActiveDate(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

// States
abstract class ShareMyDateState extends Equatable {
  const ShareMyDateState();

  @override
  List<Object?> get props => [];
}

class ShareMyDateInitial extends ShareMyDateState {
  const ShareMyDateInitial();
}

class ShareMyDateLoading extends ShareMyDateState {
  const ShareMyDateLoading();
}

class ShareMyDateError extends ShareMyDateState {
  const ShareMyDateError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class TrustedContactsLoaded extends ShareMyDateState {

  const TrustedContactsLoaded(this.contacts);
  final List<TrustedContact> contacts;

  bool get canAddMore => contacts.length < ShareMyDateConfig.maxTrustedContacts;

  @override
  List<Object?> get props => [contacts];
}

class ContactAdded extends ShareMyDateState {
  const ContactAdded(this.contact);
  final TrustedContact contact;

  @override
  List<Object?> get props => [contact];
}

class ContactRemoved extends ShareMyDateState {
  const ContactRemoved();
}

class DateShared extends ShareMyDateState {
  const DateShared(this.sharedDate);
  final SharedDate sharedDate;

  @override
  List<Object?> get props => [sharedDate];
}

class CheckedIn extends ShareMyDateState {
  const CheckedIn(this.checkIn);
  final SafetyCheckIn checkIn;

  @override
  List<Object?> get props => [checkIn];
}

class SafeArrivalMarked extends ShareMyDateState {
  const SafeArrivalMarked(this.sharedDate);
  final SharedDate sharedDate;

  @override
  List<Object?> get props => [sharedDate];
}

class EmergencyTriggered extends ShareMyDateState {
  const EmergencyTriggered(this.alert);
  final EmergencyAlert alert;

  @override
  List<Object?> get props => [alert];
}

class ActiveDateLoaded extends ShareMyDateState {
  const ActiveDateLoaded(this.activeDate);
  final SharedDate? activeDate;

  @override
  List<Object?> get props => [activeDate];
}

// BLoC
class ShareMyDateBloc extends Bloc<ShareMyDateEvent, ShareMyDateState> {

  ShareMyDateBloc({
    required this.addTrustedContact,
    required this.removeTrustedContact,
    required this.getTrustedContacts,
    required this.shareDate,
    required this.checkInAtDate,
    required this.markSafeArrival,
    required this.triggerEmergency,
    required this.getActiveSharedDate,
  }) : super(const ShareMyDateInitial()) {
    on<LoadTrustedContacts>(_onLoadContacts);
    on<AddContactEvent>(_onAddContact);
    on<RemoveContactEvent>(_onRemoveContact);
    on<ShareDateEvent>(_onShareDate);
    on<CheckInEvent>(_onCheckIn);
    on<MarkSafeArrivalEvent>(_onMarkSafeArrival);
    on<TriggerEmergencyEvent>(_onTriggerEmergency);
    on<LoadActiveDate>(_onLoadActiveDate);
  }
  final AddTrustedContact addTrustedContact;
  final RemoveTrustedContact removeTrustedContact;
  final GetTrustedContacts getTrustedContacts;
  final ShareDate shareDate;
  final CheckInAtDate checkInAtDate;
  final MarkSafeArrival markSafeArrival;
  final TriggerEmergency triggerEmergency;
  final GetActiveSharedDate getActiveSharedDate;

  List<TrustedContact> _contactsCache = [];

  Future<void> _onLoadContacts(
    LoadTrustedContacts event,
    Emitter<ShareMyDateState> emit,
  ) async {
    emit(const ShareMyDateLoading());

    final result = await getTrustedContacts(event.userId);

    result.fold(
      (failure) => emit(ShareMyDateError(failure.toString())),
      (contacts) {
        _contactsCache = contacts;
        emit(TrustedContactsLoaded(contacts));
      },
    );
  }

  Future<void> _onAddContact(
    AddContactEvent event,
    Emitter<ShareMyDateState> emit,
  ) async {
    if (_contactsCache.length >= ShareMyDateConfig.maxTrustedContacts) {
      emit(const ShareMyDateError(
        'Maximum ${ShareMyDateConfig.maxTrustedContacts} contacts allowed',
      ));
      return;
    }

    emit(const ShareMyDateLoading());

    final result = await addTrustedContact(
      userId: event.userId,
      contactName: event.contactName,
      contactPhone: event.contactPhone,
      contactEmail: event.contactEmail,
    );

    result.fold(
      (failure) => emit(ShareMyDateError(failure.toString())),
      (contact) {
        _contactsCache.add(contact);
        emit(ContactAdded(contact));
        emit(TrustedContactsLoaded(_contactsCache));
      },
    );
  }

  Future<void> _onRemoveContact(
    RemoveContactEvent event,
    Emitter<ShareMyDateState> emit,
  ) async {
    final result = await removeTrustedContact(event.contactId);

    result.fold(
      (failure) => emit(ShareMyDateError(failure.toString())),
      (_) {
        _contactsCache.removeWhere((c) => c.id == event.contactId);
        emit(const ContactRemoved());
        emit(TrustedContactsLoaded(_contactsCache));
      },
    );
  }

  Future<void> _onShareDate(
    ShareDateEvent event,
    Emitter<ShareMyDateState> emit,
  ) async {
    emit(const ShareMyDateLoading());

    final result = await shareDate(
      userId: event.userId,
      scheduledDateId: event.scheduledDateId,
      matchName: event.matchName,
      matchPhotoUrl: event.matchPhotoUrl,
      dateTime: event.dateTime,
      venueName: event.venueName,
      venueAddress: event.venueAddress,
      venueLat: event.venueLat,
      venueLng: event.venueLng,
      contactIds: event.contactIds,
    );

    result.fold(
      (failure) => emit(ShareMyDateError(failure.toString())),
      (sharedDate) => emit(DateShared(sharedDate)),
    );
  }

  Future<void> _onCheckIn(
    CheckInEvent event,
    Emitter<ShareMyDateState> emit,
  ) async {
    final result = await checkInAtDate(
      sharedDateId: event.sharedDateId,
      lat: event.lat,
      lng: event.lng,
      note: event.note,
    );

    result.fold(
      (failure) => emit(ShareMyDateError(failure.toString())),
      (checkIn) => emit(CheckedIn(checkIn)),
    );
  }

  Future<void> _onMarkSafeArrival(
    MarkSafeArrivalEvent event,
    Emitter<ShareMyDateState> emit,
  ) async {
    final result = await markSafeArrival(event.sharedDateId);

    result.fold(
      (failure) => emit(ShareMyDateError(failure.toString())),
      (sharedDate) => emit(SafeArrivalMarked(sharedDate)),
    );
  }

  Future<void> _onTriggerEmergency(
    TriggerEmergencyEvent event,
    Emitter<ShareMyDateState> emit,
  ) async {
    final result = await triggerEmergency(
      sharedDateId: event.sharedDateId,
      userId: event.userId,
      lat: event.lat,
      lng: event.lng,
      note: event.note,
    );

    result.fold(
      (failure) => emit(ShareMyDateError(failure.toString())),
      (alert) => emit(EmergencyTriggered(alert)),
    );
  }

  Future<void> _onLoadActiveDate(
    LoadActiveDate event,
    Emitter<ShareMyDateState> emit,
  ) async {
    final result = await getActiveSharedDate(event.userId);

    result.fold(
      (failure) => emit(ShareMyDateError(failure.toString())),
      (activeDate) => emit(ActiveDateLoaded(activeDate)),
    );
  }
}
