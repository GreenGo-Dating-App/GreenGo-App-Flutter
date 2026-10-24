import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/buddy_catalog.dart';
import '../../domain/buddy_exception.dart';
import '../../domain/entities/buddy.dart';
import '../../domain/repositories/buddies_repository.dart';

/// The Buddy builder (owner 2026-10-24): (1) four selects: main category
/// ([group]), topic of that category ([topic]), [language] and [tone];
/// (2) name + picture.
class BuddyBuilderState extends Equatable {
  const BuddyBuilderState({
    required this.language,
    this.step = 0,
    this.group,
    this.topic,
    this.tone = 'warm',
    this.name = '',
    this.avatar,
    this.nameTouched = false,
    this.saving = false,
  });

  static const int steps = 2;

  final int step;

  /// The main category: one of [kBuddyTopicGroups].
  final String? group;

  /// A topic of [group] (reset when the main category changes).
  final String? topic;
  final String language;
  final String tone;
  final String name;

  /// A `buddy_avatars` id (or the legacy fallback when no picture loads).
  final String? avatar;
  final bool nameTouched;
  final bool saving;

  bool get isLastStep => step == steps - 1;

  /// The topics the second select offers (empty until a category is chosen).
  List<BuddyTopic> get groupTopics => group == null ? const [] : BuddyCatalog.topicsOf(group!);

  /// The name as the server stores it, or null when it would be refused.
  String? get cleanName => BuddyCatalog.cleanName(name);

  bool get showNameError => nameTouched && cleanName == null;

  /// Whether Next (or Create on the last step) is enabled.
  bool get canNext {
    if (saving) return false;
    switch (step) {
      case 0:
        return topic != null &&
            BuddyCatalog.languages.contains(language) &&
            BuddyCatalog.tones.contains(tone);
      default:
        return cleanName != null && avatar != null;
    }
  }

  /// The callable payload: role / level / CEFR are left to the server.
  BuddySettings? toSettings() {
    final n = cleanName;
    if (n == null || topic == null || avatar == null) return null;
    return BuddySettings(name: n, avatar: avatar!, topic: topic!, tone: tone, language: language);
  }

  BuddyBuilderState copyWith({
    int? step,
    String? group,
    String? Function()? topic,
    String? language,
    String? tone,
    String? name,
    String? avatar,
    bool? nameTouched,
    bool? saving,
  }) =>
      BuddyBuilderState(
        step: step ?? this.step,
        group: group ?? this.group,
        topic: topic != null ? topic() : this.topic,
        language: language ?? this.language,
        tone: tone ?? this.tone,
        name: name ?? this.name,
        avatar: avatar ?? this.avatar,
        nameTouched: nameTouched ?? this.nameTouched,
        saving: saving ?? this.saving,
      );

  @override
  List<Object?> get props =>
      [step, group, topic, language, tone, name, avatar, nameTouched, saving];
}

class BuddyBuilderCubit extends Cubit<BuddyBuilderState> {
  BuddyBuilderCubit({required BuddiesRepository repository, required String language})
      : _repo = repository,
        super(BuddyBuilderState(
            language: BuddyCatalog.languages.contains(language) ? language : 'en'));

  final BuddiesRepository _repo;

  /// The main category. A different one clears the topic (it belonged to
  /// the previous category).
  void selectGroup(String group) {
    if (!kBuddyTopicGroups.contains(group) || group == state.group) return;
    emit(state.copyWith(group: group, topic: () => null));
  }

  /// A topic (of any category: its category is selected with it). A
  /// practice topic ("Practise Italian") also sets the Buddy language.
  void selectTopic(String id) {
    final t = BuddyCatalog.topicById(id);
    if (t == null) return;
    emit(state.copyWith(
      group: t.group,
      topic: () => id,
      language: BuddyCatalog.practiceLanguage(id),
    ));
  }

  void selectLanguage(String code) {
    if (BuddyCatalog.languages.contains(code)) emit(state.copyWith(language: code));
  }

  void selectTone(String tone) {
    if (BuddyCatalog.tones.contains(tone)) emit(state.copyWith(tone: tone));
  }

  void setName(String name) => emit(state.copyWith(name: name, nameTouched: true));

  void selectAvatar(String id) => emit(state.copyWith(avatar: id));

  /// Preselects [id] unless the user already picked a picture.
  void defaultAvatar(String id) {
    if (state.avatar == null) emit(state.copyWith(avatar: id));
  }

  void next() {
    if (state.canNext && !state.isLastStep) emit(state.copyWith(step: state.step + 1));
  }

  /// False on the first step (the screen may close).
  bool back() {
    if (state.step == 0 || state.saving) return false;
    emit(state.copyWith(step: state.step - 1));
    return true;
  }

  /// Creates the Buddy and returns its id; null when the form is not
  /// complete. Failures are rethrown as [BuddyException].
  Future<String?> create() async {
    final settings = state.toSettings();
    if (settings == null || state.saving) {
      emit(state.copyWith(nameTouched: true));
      return null;
    }
    emit(state.copyWith(saving: true));
    try {
      return await _repo.createBuddy(settings);
    } catch (e) {
      emit(state.copyWith(saving: false));
      throw BuddyException.from(e);
    }
  }
}
