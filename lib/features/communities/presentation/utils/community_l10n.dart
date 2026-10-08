import '../../../../generated/app_localizations.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_member.dart';

// Display-time localization for community enums/values. The domain keeps
// stable enum values (and English displayName fallbacks); the UI maps them
// to the viewer's language here.

String communityTypeLabel(AppLocalizations l10n, CommunityType type) {
  switch (type) {
    case CommunityType.languageCircle:
      return l10n.communitiesTypeLanguageCircle;
    case CommunityType.culturalInterest:
      return l10n.communitiesTypeCulturalInterest;
    case CommunityType.travelGroup:
      return l10n.communitiesTypeTravelGroup;
    case CommunityType.localGuides:
      return l10n.communitiesTypeLocalGuides;
    case CommunityType.studyGroup:
      return l10n.communitiesTypeStudyGroup;
    case CommunityType.general:
      return l10n.communitiesTypeGeneral;
  }
}

String communityRoleLabel(AppLocalizations l10n, CommunityRole role) {
  switch (role) {
    case CommunityRole.owner:
      return l10n.communitiesRoleOwner;
    case CommunityRole.admin:
      return l10n.communitiesRoleAdmin;
    case CommunityRole.member:
      return l10n.communitiesRoleMember;
  }
}

/// Localized "time since last activity" for a community list row.
String communityLastActivityLabel(AppLocalizations l10n, Community community) {
  final at = community.lastActivityAt;
  if (at == null) return l10n.communitiesNoActivityYet;
  final difference = DateTime.now().difference(at);
  if (difference.inMinutes < 1) return l10n.chatJustNow;
  if (difference.inMinutes < 60) return l10n.chatMinutesAgo(difference.inMinutes);
  if (difference.inHours < 24) return l10n.chatHoursAgo(difference.inHours);
  if (difference.inDays < 7) return l10n.chatDaysAgo(difference.inDays);
  return '${at.month}/${at.day}/${at.year}';
}

/// Localized language name for a community language code (en, es, zh, ...).
/// Unknown codes are shown as-is (upper-cased).
String communityLanguageName(AppLocalizations l10n, String code) {
  switch (code) {
    case 'en':
      return l10n.languageNameEnglish;
    case 'es':
      return l10n.languageNameSpanish;
    case 'fr':
      return l10n.languageNameFrench;
    case 'de':
      return l10n.languageNameGerman;
    case 'it':
      return l10n.languageNameItalian;
    case 'pt':
      return l10n.languageNamePortuguese;
    case 'ja':
      return l10n.languageNameJapanese;
    case 'ko':
      return l10n.languageNameKorean;
    case 'zh':
      return l10n.communitiesLanguageMandarin;
    case 'ar':
      return l10n.languageNameArabic;
    case 'hi':
      return l10n.languageNameHindi;
    case 'ru':
      return l10n.languageNameRussian;
    case 'tr':
      return l10n.languageNameTurkish;
    case 'nl':
      return l10n.languageNameDutch;
    case 'sv':
      return l10n.languageNameSwedish;
    case 'pl':
      return l10n.languageNamePolish;
    case 'th':
      return l10n.communitiesLanguageThai;
    case 'vi':
      return l10n.communitiesLanguageVietnamese;
    case 'ca':
      return l10n.communitiesLanguageCatalan;
    case 'he':
      return l10n.communitiesLanguageHebrew;
    default:
      return code.toUpperCase();
  }
}
