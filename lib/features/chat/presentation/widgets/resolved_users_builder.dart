import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/services/user_directory_service.dart';

/// Shows [placeholder] until every uid in [uids] is resolved by
/// [UserDirectoryService] (name + photo known, or confirmed deleted), then
/// [builder]. This is what keeps raw user ids — or a flash of "Unknown" — off
/// the screen: data is loaded fully before it is shown.
///
///  * One batched resolve per distinct uid set (memoised; rebuilds and stream
///    re-emissions with the same members don't re-request anything).
///  * Rebuilds when late briefs arrive (listens to the directory).
///  * With [maxWait], stops waiting after that long and calls [builder] with
///    `ready == false`, so a slow network never blocks the screen forever —
///    the builder must then hide unresolved labels, never show ids.
class ResolvedUsersBuilder extends StatefulWidget {
  const ResolvedUsersBuilder({
    super.key,
    required this.uids,
    required this.builder,
    required this.placeholder,
    this.maxWait,
    this.profiles = false,
  });

  final Iterable<String> uids;

  /// [ready] is true when all uids resolved, false when [maxWait] expired.
  final Widget Function(BuildContext context, bool ready) builder;
  final Widget placeholder;
  final Duration? maxWait;

  /// Resolve FULL profiles ([UserDirectoryService.resolveProfiles]) instead of
  /// briefs.
  final bool profiles;

  @override
  State<ResolvedUsersBuilder> createState() => _ResolvedUsersBuilderState();
}

class _ResolvedUsersBuilderState extends State<ResolvedUsersBuilder> {
  final _dir = UserDirectoryService.instance;
  Set<String> _requested = const {};
  Timer? _timer;
  bool _timedOut = false;
  bool _everReady = false;

  @override
  void initState() {
    super.initState();
    _dir.addListener(_onDir);
    _request();
    if (widget.maxWait != null && !_allResolved()) {
      _timer = Timer(widget.maxWait!, () {
        if (mounted) setState(() => _timedOut = true);
      });
    }
  }

  @override
  void didUpdateWidget(covariant ResolvedUsersBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _request();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dir.removeListener(_onDir);
    super.dispose();
  }

  Set<String> get _ids => widget.uids.where((u) => u.isNotEmpty).toSet();

  bool _allResolved() {
    final ids = _ids;
    return widget.profiles
        ? ids.every(_dir.isProfileResolved)
        : ids.every(_dir.isResolved);
  }

  void _request() {
    final ids = _ids;
    if (setEquals(ids, _requested)) return;
    _requested = ids;
    _attempts = 0;
    _fetch(ids);
  }

  int _attempts = 0;

  /// Resolves [ids]; on a network failure (some still unresolved) retries a
  /// few times with backoff.
  Future<void> _fetch(Set<String> ids) async {
    if (ids.isEmpty) return;
    if (widget.profiles) {
      await _dir.resolveProfiles(ids);
    } else {
      await _dir.resolve(ids);
    }
    if (!mounted || !setEquals(ids, _requested) || _allResolved()) return;
    if (++_attempts > 3) return;
    await Future<void>.delayed(Duration(seconds: 2 * _attempts));
    if (mounted && setEquals(ids, _requested)) _fetch(ids);
  }

  void _onDir() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ready = _allResolved();
    if (ready) _everReady = true;
    // Once shown, never flip back to the placeholder (e.g. a new member joins)
    // — new ids render with their label space reserved until they resolve.
    if (ready || _everReady || _timedOut) {
      return widget.builder(context, ready);
    }
    return widget.placeholder;
  }
}
