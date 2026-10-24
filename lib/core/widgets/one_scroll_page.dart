import 'package:flutter/material.dart';

/// Pages that scroll as ONE scroll view (owner 2026-10-24): the app bar,
/// the tab bar and each page's header scroll away together with the content,
/// nothing stays fixed at the top. Used by the Shop (Coins / Membership tabs)
/// and the Membership screen.

/// A page with an app bar and a body that scrolls with it (not pinned).
class OneScrollPage extends StatelessWidget {
  const OneScrollPage({
    required this.title,
    required this.child,
    this.backgroundColor = Colors.black,
    this.appBarColor,
    this.foregroundColor,
    this.leading,
    this.centerTitle,
    this.padding = EdgeInsets.zero,
    this.overlay,
    super.key,
  });

  final Widget title;

  /// The page content (laid out at full width, under the app bar).
  final Widget child;
  final Color backgroundColor;
  final Color? appBarColor;
  final Color? foregroundColor;
  final Widget? leading;
  final bool? centerTitle;
  final EdgeInsetsGeometry padding;

  /// Drawn over everything (e.g. a loading veil); not scrolled.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            key: const ValueKey('one-scroll-page'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverAppBar(
                title: title,
                leading: leading,
                centerTitle: centerTitle,
                backgroundColor: appBarColor ?? backgroundColor,
                foregroundColor: foregroundColor,
                elevation: 0,
                // Everything scrolls away (owner): never pinned / floating.
                pinned: false,
                floating: false,
              ),
              SliverPadding(
                padding: padding,
                sliver: SliverToBoxAdapter(child: child),
              ),
            ],
          ),
          if (overlay != null) Positioned.fill(child: overlay!),
        ],
      ),
    );
  }
}

/// A page with an app bar + tab bar above a [TabBarView]: the app bar and
/// the tab bar scroll away with the tab content ([NestedScrollView]). Each
/// tab should be a [OneScrollTab] (or another scroll view without its own
/// controller) so its header scrolls too.
class OneScrollTabsScaffold extends StatelessWidget {
  const OneScrollTabsScaffold({
    required this.title,
    required this.tabBar,
    required this.controller,
    required this.tabs,
    this.tabBarHeight = 48,
    this.backgroundColor = Colors.black,
    this.appBarColor,
    this.leading,
    this.centerTitle = true,
    super.key,
  });

  final Widget title;
  final Widget tabBar;
  final double tabBarHeight;
  final TabController controller;
  final List<Widget> tabs;
  final Color backgroundColor;
  final Color? appBarColor;
  final Widget? leading;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: NestedScrollView(
        key: const ValueKey('one-scroll-tabs'),
        headerSliverBuilder: (context, innerScrolled) => [
          SliverAppBar(
            title: title,
            leading: leading,
            centerTitle: centerTitle,
            automaticallyImplyLeading: leading == null,
            backgroundColor: appBarColor ?? backgroundColor,
            elevation: 0,
            forceElevated: innerScrolled,
            pinned: false,
            floating: false,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(tabBarHeight),
              child: tabBar,
            ),
          ),
        ],
        body: TabBarView(controller: controller, children: tabs),
      ),
    );
  }
}

/// One tab of a [OneScrollTabsScaffold]: its [header] widgets and [items]
/// in a single list (the header scrolls away with the content), plus an
/// optional [bottomBar] (e.g. the purchase button) that stays under the list.
class OneScrollTab extends StatelessWidget {
  const OneScrollTab({
    required this.header,
    required this.items,
    this.padding = const EdgeInsets.all(16),
    this.bottomBar,
    super.key,
  });

  final List<Widget> header;
  final List<Widget> items;

  /// Around [items] (the header is full width).
  final EdgeInsetsGeometry padding;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          // The primary controller (explicitly, also on web / desktop where
          // it is not inherited by default): inside a NestedScrollView this
          // list and the app bar above scroll as one.
          child: ListView(
            primary: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.zero,
            children: [
              ...header,
              Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: items,
                ),
              ),
            ],
          ),
        ),
        if (bottomBar != null) bottomBar!,
      ],
    );
  }
}
