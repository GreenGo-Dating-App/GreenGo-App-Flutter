import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_glass.dart';
import '../../../core/widgets/glass_bottom_nav.dart';
import '../../../core/widgets/glass_container.dart';

/// Isolated showcase for the "liquid glass" design system (Track F / Phase 2).
///
/// Self-contained: no routing changes, no network, no external packages. The
/// copy below is hardcoded placeholder content purely to demonstrate the glass
/// surfaces reading against a colourful backdrop.
///
/// Follow-up: replace the hardcoded strings with i18n keys
/// (lib/l10n/app_en.arb) and live cultural-event data before shipping.
class GlassDemoScreen extends StatefulWidget {
  const GlassDemoScreen({super.key});

  @override
  State<GlassDemoScreen> createState() => _GlassDemoScreenState();
}

class _GlassDemoScreenState extends State<GlassDemoScreen> {
  int _navIndex = 0;

  static const String _fontFamily = 'Poppins';

  static const List<GlassNavItem> _navItems = [
    GlassNavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Explore',
    ),
    GlassNavItem(
      icon: Icons.event_outlined,
      activeIcon: Icons.event,
      label: 'Events',
    ),
    GlassNavItem(
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups,
      label: 'Community',
    ),
    GlassNavItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Messages',
    ),
    GlassNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      extendBody: true,
      body: Stack(
        children: [
          // Base dark gradient.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.deepBlack, AppColors.charcoal],
              ),
            ),
            child: SizedBox.expand(),
          ),

          // Colourful backdrop band so the frosted glass has something to
          // refract. Positioned near the top behind the cards.
          Positioned(
            top: -60,
            left: -40,
            right: -40,
            height: 320,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF7C4DFF).withOpacity(0.55),
                    const Color(0xFF29B6F6).withOpacity(0.45),
                    AppColors.richGold.withOpacity(0.40),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildGlassAppBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    children: [
                      _buildEventCard(
                        title: 'Fado Night in Alfama',
                        subtitle: 'Live music · Lisbon · Tonight 21:00',
                        icon: Icons.music_note,
                        active: true,
                      ),
                      const SizedBox(height: 16),
                      _buildEventCard(
                        title: 'Language café · Príncipe Real',
                        subtitle: 'PT ↔ EN exchange · Free · Sat 17:00',
                        icon: Icons.translate,
                      ),
                      const SizedBox(height: 16),
                      _buildEventCard(
                        title: 'Street food crawl · Mercado',
                        subtitle: 'Meet travelers · Sun 12:30',
                        icon: Icons.restaurant,
                      ),
                      const SizedBox(height: 24),
                      _buildPrimaryCta(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: GlassBottomNav(
        items: _navItems,
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }

  Widget _buildGlassAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GlassContainer(
        borderRadius: AppGlass.radiusPill,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            const Text(
              'GreenGo',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.richGold,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            _buildCoinPill(),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.richGold.withOpacity(0.13),
        borderRadius: BorderRadius.circular(AppGlass.radiusPill),
        border: Border.all(color: AppGlass.borderGold),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on, color: AppColors.richGold, size: 18),
          SizedBox(width: 6),
          Text(
            '250',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.richGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard({
    required String title,
    required String subtitle,
    required IconData icon,
    bool active = false,
  }) {
    return GlassContainer(
      active: active,
      padding: const EdgeInsets.all(16),
      onTap: () {},
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.richGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.richGold, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.white.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCta() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppGlass.radiusPill),
        boxShadow: AppGlass.goldGlow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppGlass.radiusPill),
          onTap: () {},
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(AppGlass.radiusPill),
            ),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Text(
                'Join the experience',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepBlack,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
