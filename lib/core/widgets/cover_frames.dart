import '../../generated/app_localizations.dart';
import 'cover_positioner.dart';

/// The real places each kind of cover is shown, at their real logical sizes
/// (phone width 390 for full-width frames). Keep in sync with the widgets:
///   * Explore community card 240 x 108 (explore_screen _CommunityCard)
///   * Community page header full width x 140 (community_detail_screen)
///   * Communities list avatar 56 x 56 (community_card)
///   * Storefront header full width x 220 (business_storefront_screen)
///   * Explore featured event 320 x 230, Explore event card 300 x 132
///   * Events list card full width x 150, event page header x 250
///   * Explore top experience 150 x 210 (portrait), experience card x 170,
///     experience page header x 280
///   * Storefront logo: 96 circle (storefront / editor), 48 circle (lists)
class CoverFrames {
  const CoverFrames._();

  static const double phoneWidth = 390;

  static List<CoverPreviewFrame> community(AppLocalizations l) => [
        CoverPreviewFrame(label: l.coverFrameExplore, width: 240, height: 108),
        CoverPreviewFrame(
            label: l.coverFrameHeader, width: phoneWidth, height: 140),
        CoverPreviewFrame(
            label: l.coverFrameList,
            width: 56,
            height: 56,
            kind: CoverFrameKind.thumbnail),
      ];

  static List<CoverPreviewFrame> storefrontFeatured(AppLocalizations l) => [
        CoverPreviewFrame(
            label: l.coverFrameHeader, width: phoneWidth, height: 220),
      ];

  static List<CoverPreviewFrame> event(AppLocalizations l) => [
        CoverPreviewFrame(label: l.coverFrameExplore, width: 320, height: 230),
        CoverPreviewFrame(label: l.coverFrameExplore, width: 300, height: 132),
        CoverPreviewFrame(
            label: l.coverFrameCard, width: phoneWidth - 32, height: 150),
        CoverPreviewFrame(
            label: l.coverFrameHeader, width: phoneWidth, height: 250),
      ];

  static List<CoverPreviewFrame> experience(AppLocalizations l) => [
        CoverPreviewFrame(label: l.coverFrameExplore, width: 150, height: 210),
        CoverPreviewFrame(
            label: l.coverFrameCard, width: phoneWidth - 32, height: 170),
        CoverPreviewFrame(
            label: l.coverFrameHeader, width: phoneWidth, height: 280),
      ];

  static List<CoverPreviewFrame> logo(AppLocalizations l) => [
        CoverPreviewFrame(
            label: l.coverFrameAvatar,
            width: 96,
            height: 96,
            kind: CoverFrameKind.circle),
        CoverPreviewFrame(
            label: l.coverFrameList,
            width: 48,
            height: 48,
            kind: CoverFrameKind.circle),
      ];
}
