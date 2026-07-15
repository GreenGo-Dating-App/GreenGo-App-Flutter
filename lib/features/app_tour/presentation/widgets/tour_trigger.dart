import 'package:flutter/widgets.dart';

/// Marks whether the subtree it wraps is the *currently selected* tab.
///
/// [MainNavigationScreen] keeps every tab mounted inside an [IndexedStack], so a
/// screen's `initState` / first build fires long before the user actually opens
/// that tab. A per-page first-time tour must NOT start while its screen is
/// off-stage, so the navigation shell wraps each tab in a [VisibleTabScope] and
/// flips [isVisible] as the selected index changes. Screens opened as a normal
/// pushed route have no scope ancestor — there, absence means "visible now".
class VisibleTabScope extends InheritedWidget {
  const VisibleTabScope({
    required this.isVisible,
    required super.child,
    super.key,
  });

  final bool isVisible;

  static VisibleTabScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VisibleTabScope>();

  @override
  bool updateShouldNotify(VisibleTabScope oldWidget) =>
      isVisible != oldWidget.isVisible;
}

/// Fires [onVisible] exactly once — the first time this widget is visible —
/// in a post-frame callback whose [BuildContext] is a descendant of the
/// enclosing `ShowCaseWidget`. Drop it just inside a `ShowCaseWidget` builder so
/// a one-time mini-tour can resolve `ShowCaseWidget.of(context)` correctly while
/// still respecting [IndexedStack] tab visibility (see [VisibleTabScope]).
class TourTrigger extends StatefulWidget {
  const TourTrigger({
    required this.onVisible,
    required this.child,
    super.key,
  });

  final void Function(BuildContext showcaseContext) onVisible;
  final Widget child;

  @override
  State<TourTrigger> createState() => _TourTriggerState();
}

class _TourTriggerState extends State<TourTrigger> {
  bool _fired = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-evaluated whenever the VisibleTabScope flips (a dependency change).
    _maybeFire();
  }

  void _maybeFire() {
    if (_fired) return;
    // No scope (pushed route) ⇒ the screen is on-stage right now.
    final visible = VisibleTabScope.of(context)?.isVisible ?? true;
    if (!visible) return;
    _fired = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onVisible(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
