import 'package:flutter/widgets.dart';

/// Global anchor keys for every showcase target in the app tour.
///
/// MainNavigationScreen owns the app-bar / bottom-nav targets; the discovery
/// grid registers its first visible card. Keys live here so screens in
/// different features can be part of one chained tour.
class TourKeys {
  TourKeys._();

  // ── Tier 1: Discovery tab ──
  static final GlobalKey gridBody = GlobalKey(debugLabel: 'tour_grid_body');
  static final GlobalKey firstCard = GlobalKey(debugLabel: 'tour_first_card');
  static final GlobalKey cardEdges = GlobalKey(debugLabel: 'tour_card_edges');
  static final GlobalKey cardHold = GlobalKey(debugLabel: 'tour_card_hold');
  static final GlobalKey pullRefresh = GlobalKey(debugLabel: 'tour_pull_refresh');

  // ── Tier 1: Discovery app bar ──
  static final GlobalKey modeToggle = GlobalKey(debugLabel: 'tour_mode_toggle');
  static final GlobalKey globe = GlobalKey(debugLabel: 'tour_globe');
  static final GlobalKey search = GlobalKey(debugLabel: 'tour_search');
  static final GlobalKey preferences = GlobalKey(debugLabel: 'tour_preferences');
  static final GlobalKey coins = GlobalKey(debugLabel: 'tour_coins');
  static final GlobalKey help = GlobalKey(debugLabel: 'tour_help');

  // ── Tier 1: Bottom navigation ──
  static final GlobalKey navMessages = GlobalKey(debugLabel: 'tour_nav_messages');
  static final GlobalKey navLeaderboard = GlobalKey(debugLabel: 'tour_nav_leaderboard');
  static final GlobalKey navShop = GlobalKey(debugLabel: 'tour_nav_shop');
  static final GlobalKey navProfile = GlobalKey(debugLabel: 'tour_nav_profile');

  // ── Tier 2: contextual mini-tours ──
  static final GlobalKey chatBubbleHold = GlobalKey(debugLabel: 'tour_chat_hold');
  static final GlobalKey chatBubbleDoubleTap = GlobalKey(debugLabel: 'tour_chat_double_tap');
  static final GlobalKey chatLanguageMenu = GlobalKey(debugLabel: 'tour_chat_language_menu');
  static final GlobalKey chatSettings = GlobalKey(debugLabel: 'tour_chat_settings');
  static final GlobalKey detailPhotoDoubleTap = GlobalKey(debugLabel: 'tour_detail_double_tap');
}
