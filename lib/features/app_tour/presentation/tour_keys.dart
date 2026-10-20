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

  // ── Tier 2: Communities screen mini-tour ──
  static final GlobalKey communitiesTabs =
      GlobalKey(debugLabel: 'tour_communities_tabs');
  static final GlobalKey communitiesSearch =
      GlobalKey(debugLabel: 'tour_communities_search');
  static final GlobalKey communitiesCard =
      GlobalKey(debugLabel: 'tour_communities_card');
  static final GlobalKey communitiesCreate =
      GlobalKey(debugLabel: 'tour_communities_create');

  // ── Tier 2: Events screen mini-tour ──
  static final GlobalKey eventsCreate =
      GlobalKey(debugLabel: 'tour_events_create');
  static final GlobalKey eventsSearch =
      GlobalKey(debugLabel: 'tour_events_search');
  static final GlobalKey eventsTabs =
      GlobalKey(debugLabel: 'tour_events_tabs');

  // ── Tier 2: Edit-profile screen mini-tour ──
  static final GlobalKey profileHub =
      GlobalKey(debugLabel: 'tour_profile_hub');
  static final GlobalKey profileViewCard =
      GlobalKey(debugLabel: 'tour_profile_view_card');
  static final GlobalKey profileEditAccordion =
      GlobalKey(debugLabel: 'tour_profile_edit_accordion');

  // ── Tier 2: Explore screen mini-tour ──
  static final GlobalKey exploreSearch =
      GlobalKey(debugLabel: 'tour_explore_search');
  static final GlobalKey exploreQr = GlobalKey(debugLabel: 'tour_explore_qr');
  // The 4 stats tiles at the top (owner notes 2026-10-20), first in the tour.
  static final GlobalKey exploreStatCoins =
      GlobalKey(debugLabel: 'tour_explore_stat_coins');
  static final GlobalKey exploreStatMembership =
      GlobalKey(debugLabel: 'tour_explore_stat_membership');
  static final GlobalKey exploreStatCountries =
      GlobalKey(debugLabel: 'tour_explore_stat_countries');
  static final GlobalKey exploreStatFollowers =
      GlobalKey(debugLabel: 'tour_explore_stat_followers');

  /// The Explore tour, in display order: the 4 stats tiles, then the header
  /// actions (search, My Space).
  static List<GlobalKey> get exploreTour => [
        exploreStatCoins,
        exploreStatMembership,
        exploreStatCountries,
        exploreStatFollowers,
        exploreSearch,
        exploreQr,
      ];

  // ── Tier 2: Notifications screen mini-tour ──
  static final GlobalKey notifHub =
      GlobalKey(debugLabel: 'tour_notif_hub');
  static final GlobalKey notifFirstItem =
      GlobalKey(debugLabel: 'tour_notif_first_item');

  // ── Tier 2 (v2): Discover page tour ──
  static final GlobalKey discoverSwitch =
      GlobalKey(debugLabel: 'tour_discover_switch');
  static final GlobalKey discoverFilters =
      GlobalKey(debugLabel: 'tour_discover_filters');
  static final GlobalKey discoverSearch =
      GlobalKey(debugLabel: 'tour_discover_search');
  static final GlobalKey discoverSaved =
      GlobalKey(debugLabel: 'tour_discover_saved');
  static final GlobalKey discoverWorldMap =
      GlobalKey(debugLabel: 'tour_discover_world_map');

  // ── Tier 2 (v2): paid event detail ──
  static final GlobalKey eventPricePhases =
      GlobalKey(debugLabel: 'tour_event_price_phases');
  static final GlobalKey eventBuyTickets =
      GlobalKey(debugLabel: 'tour_event_buy_tickets');
  static final GlobalKey eventMessageOrganizer =
      GlobalKey(debugLabel: 'tour_event_message_organizer');

  // ── Tier 2 (v2): Business Center ──
  static final GlobalKey bcOverview = GlobalKey(debugLabel: 'tour_bc_overview');
  static final GlobalKey bcMySpace = GlobalKey(debugLabel: 'tour_bc_my_space');
  static final GlobalKey bcSales = GlobalKey(debugLabel: 'tour_bc_sales');
  static final GlobalKey bcMarketing =
      GlobalKey(debugLabel: 'tour_bc_marketing');
  static final GlobalKey bcCustomers =
      GlobalKey(debugLabel: 'tour_bc_customers');
  static final GlobalKey bcSettings = GlobalKey(debugLabel: 'tour_bc_settings');

  // ── Tier 2 (v2): storefront editor ──
  static final GlobalKey sfLogo = GlobalKey(debugLabel: 'tour_sf_logo');
  static final GlobalKey sfName = GlobalKey(debugLabel: 'tour_sf_name');
  static final GlobalKey sfFeatured = GlobalKey(debugLabel: 'tour_sf_featured');
  static final GlobalKey sfCategory = GlobalKey(debugLabel: 'tour_sf_category');
  static final GlobalKey sfAddress = GlobalKey(debugLabel: 'tour_sf_address');

  // ── Tier 2 (v2): followers ──
  static final GlobalKey ownFollowStats =
      GlobalKey(debugLabel: 'tour_own_follow_stats');
  static final GlobalKey publicFollowLine =
      GlobalKey(debugLabel: 'tour_public_follow_line');

  // ── Tier 2 (v2): feature tours (chat extras, communities, experiences,
  // shop, privacy, get paid, My Space, promote, safety, verification,
  // invite friends, attractions) ──
  static final GlobalKey chatAutoTranslate = GlobalKey(debugLabel: 'tour_chat_auto_translate');
  static final GlobalKey chatVoice = GlobalKey(debugLabel: 'tour_chat_voice');
  static final GlobalKey chatMenuSafety = GlobalKey(debugLabel: 'tour_chat_menu_safety');
  static final GlobalKey chatTripMap = GlobalKey(debugLabel: 'tour_chat_trip_map');
  static final GlobalKey communityTabs = GlobalKey(debugLabel: 'tour_community_tabs');
  static final GlobalKey communityJoin = GlobalKey(debugLabel: 'tour_community_join');
  static final GlobalKey communityRules = GlobalKey(debugLabel: 'tour_community_rules');
  static final GlobalKey expBook = GlobalKey(debugLabel: 'tour_exp_book');
  static final GlobalKey expDates = GlobalKey(debugLabel: 'tour_exp_dates');
  static final GlobalKey expMyBookings = GlobalKey(debugLabel: 'tour_exp_my_bookings');
  static final GlobalKey expHostRequests = GlobalKey(debugLabel: 'tour_exp_host_requests');
  static final GlobalKey expCreate = GlobalKey(debugLabel: 'tour_exp_create');
  static final GlobalKey expCalendar = GlobalKey(debugLabel: 'tour_exp_calendar');
  static final GlobalKey shopCoinsFor = GlobalKey(debugLabel: 'tour_shop_coins_for');
  static final GlobalKey shopSendCoins = GlobalKey(debugLabel: 'tour_shop_send_coins');
  static final GlobalKey shopTabs = GlobalKey(debugLabel: 'tour_shop_tabs');
  static final GlobalKey shopRestore = GlobalKey(debugLabel: 'tour_shop_restore');
  static final GlobalKey privacyGlobe = GlobalKey(debugLabel: 'tour_privacy_globe');
  static final GlobalKey privacyTraveler = GlobalKey(debugLabel: 'tour_privacy_traveler');
  static final GlobalKey privacyIncognito = GlobalKey(debugLabel: 'tour_privacy_incognito');
  static final GlobalKey getPaidProviders = GlobalKey(debugLabel: 'tour_get_paid_providers');
  static final GlobalKey getPaidFees = GlobalKey(debugLabel: 'tour_get_paid_fees');
  static final GlobalKey mySpaceScanner = GlobalKey(debugLabel: 'tour_my_space_scanner');
  static final GlobalKey mySpaceTickets = GlobalKey(debugLabel: 'tour_my_space_tickets');
  static final GlobalKey mySpaceCalendar = GlobalKey(debugLabel: 'tour_my_space_calendar');
  static final GlobalKey promoteStorefront = GlobalKey(debugLabel: 'tour_promote_storefront');
  static final GlobalKey promoteEvents = GlobalKey(debugLabel: 'tour_promote_events');
  static final GlobalKey safetyMenu = GlobalKey(debugLabel: 'tour_safety_menu');
  static final GlobalKey safetyAppeal = GlobalKey(debugLabel: 'tour_safety_appeal');
  static final GlobalKey verifyPhone = GlobalKey(debugLabel: 'tour_verify_phone');
  static final GlobalKey verifyId = GlobalKey(debugLabel: 'tour_verify_id');
  static final GlobalKey inviteShare = GlobalKey(debugLabel: 'tour_invite_share');
  static final GlobalKey inviteRules = GlobalKey(debugLabel: 'tour_invite_rules');
  static final GlobalKey inviteProgress = GlobalKey(debugLabel: 'tour_invite_progress');
  static final GlobalKey attractionTips = GlobalKey(debugLabel: 'tour_attraction_tips');
  static final GlobalKey attractionShare = GlobalKey(debugLabel: 'tour_attraction_share');
  static final GlobalKey attractionMaps = GlobalKey(debugLabel: 'tour_attraction_maps');
}
