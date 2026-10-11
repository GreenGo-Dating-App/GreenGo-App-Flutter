import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../events/domain/entities/event.dart';
import '../../../experience_bookings/domain/entities/booking.dart';
import '../../data/my_space_repository.dart';
import '../../domain/my_space_models.dart';

enum MySpaceSection { events, experiences }

enum MySpaceLoad { loading, ready }

class MySpaceState extends Equatable {
  const MySpaceState({
    this.counts = MySpaceCounts.zero,
    this.countsLoad = MySpaceLoad.loading,
    this.hosting = const <Event>[],
    this.attending = const <Event>[],
    this.eventsLoad = MySpaceLoad.loading,
    this.eventsFailed = false,
    this.sessions = const <CheckInSession>[],
    this.sessionsLoad = MySpaceLoad.loading,
    this.sessionsFailed = false,
    this.section = MySpaceSection.events,
  });

  final MySpaceCounts counts;
  final MySpaceLoad countsLoad;
  final List<Event> hosting;
  final List<Event> attending;
  final MySpaceLoad eventsLoad;
  final bool eventsFailed;
  final List<CheckInSession> sessions;
  final MySpaceLoad sessionsLoad;
  final bool sessionsFailed;
  final MySpaceSection section;

  /// Hosted events + sessions whose door is today.
  List<Object> todayCheckIns(DateTime now) => [
        for (final e in hosting)
          if (MySpaceRules.isCheckInDay(e.startDate, e.endDate, now)) e,
        for (final s in sessions)
          if (MySpaceRules.isCheckInDay(s.start, s.end, now)) s,
      ];

  MySpaceState copyWith({
    MySpaceCounts? counts,
    MySpaceLoad? countsLoad,
    List<Event>? hosting,
    List<Event>? attending,
    MySpaceLoad? eventsLoad,
    bool? eventsFailed,
    List<CheckInSession>? sessions,
    MySpaceLoad? sessionsLoad,
    bool? sessionsFailed,
    MySpaceSection? section,
  }) =>
      MySpaceState(
        counts: counts ?? this.counts,
        countsLoad: countsLoad ?? this.countsLoad,
        hosting: hosting ?? this.hosting,
        attending: attending ?? this.attending,
        eventsLoad: eventsLoad ?? this.eventsLoad,
        eventsFailed: eventsFailed ?? this.eventsFailed,
        sessions: sessions ?? this.sessions,
        sessionsLoad: sessionsLoad ?? this.sessionsLoad,
        sessionsFailed: sessionsFailed ?? this.sessionsFailed,
        section: section ?? this.section,
      );

  @override
  List<Object?> get props => [
        counts,
        countsLoad,
        hosting,
        attending,
        eventsLoad,
        eventsFailed,
        sessions,
        sessionsLoad,
        sessionsFailed,
        section,
      ];
}

/// My Space: loads the To-do counts, the user's events (hosting / attending)
/// and the host's upcoming sessions — three independent, failure-isolated
/// loads, so one slow or failing source never blanks the others.
class MySpaceCubit extends Cubit<MySpaceState> {
  MySpaceCubit({
    required MySpaceRepository repository,
    required this.uid,
    DateTime Function()? clock,
  })  : _repo = repository,
        _now = clock ?? DateTime.now,
        super(const MySpaceState());

  final MySpaceRepository _repo;
  final String uid;
  final DateTime Function() _now;

  DateTime now() => _now();

  Future<void> load() => Future.wait<void>([
        loadCounts(),
        _loadEvents(),
        _loadSessions(),
      ]);

  void selectSection(MySpaceSection s) {
    if (s != state.section) emit(state.copyWith(section: s));
  }

  static Future<int> _safe(Future<int> f) async {
    try {
      return await f;
    } catch (_) {
      return 0; // a missing badge never breaks the hub
    }
  }

  Future<void> loadCounts() async {
    final r = await Future.wait([
      _safe(_repo.bookingRequestsToConfirm(uid)),
      _safe(_repo.paymentsToConfirm(uid)),
      _safe(_repo.upcomingBookings(uid, BookingRole.guest)),
      _safe(_repo.upcomingBookings(uid, BookingRole.host)),
    ]);
    if (isClosed) return;
    emit(state.copyWith(
      countsLoad: MySpaceLoad.ready,
      counts: MySpaceCounts(
        bookingRequestsToConfirm: r[0],
        paymentsToConfirm: r[1],
        guestUpcomingBookings: r[2],
        hostUpcomingBookings: r[3],
      ),
    ));
  }

  Future<void> _loadEvents() async {
    try {
      final all = await _repo.myEvents(uid);
      if (isClosed) return;
      final now = _now();
      emit(state.copyWith(
        eventsLoad: MySpaceLoad.ready,
        eventsFailed: false,
        hosting: MySpaceRules.hosting(all, uid, now),
        attending: MySpaceRules.attending(all, uid, now),
      ));
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(eventsLoad: MySpaceLoad.ready, eventsFailed: true));
      }
    }
  }

  Future<void> _loadSessions() async {
    try {
      final b = await _repo.hostUpcomingConfirmed(uid);
      if (isClosed) return;
      emit(state.copyWith(
        sessionsLoad: MySpaceLoad.ready,
        sessionsFailed: false,
        sessions: CheckInSession.group(b),
      ));
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(
            sessionsLoad: MySpaceLoad.ready, sessionsFailed: true));
      }
    }
  }
}
