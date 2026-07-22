#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GreenGo — Architecture Blueprint generator (draw.io / diagrams.net)

Emits `GreenGo-Architecture.drawio`, a 12-page atlas:

  Page 00  MASTER  — one single zoomable schema (Plan C):
                     collapsible HLD<->LLD containers, flavor/tier overlays,
                     4 numbered runtime traces, atlas index.
  Pages 01..11     — LLD deep dives per domain (Plan B), linked from MASTER.

Regenerate with:  python docs/architecture/generate_architecture_drawio.py

Every count/name in this file was extracted from the repo (lib/features,
lib/core/services, functions/src/index.ts, firestore.rules, storage.rules,
pubspec.yaml, terraform/, docker/, codemagic.yaml).
"""

import html
import os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "GreenGo-Architecture.drawio")

# ---------------------------------------------------------------------------
# palette
# ---------------------------------------------------------------------------
C = {
    "actor":  ("#F1F8E9", "#558B2F"),
    "ui":     ("#E3F2FD", "#1565C0"),
    "state":  ("#FFF3E0", "#FB8C00"),
    "domain": ("#F3E5F5", "#7B1FA2"),
    "data":   ("#E8F5E9", "#2E7D32"),
    "fb":     ("#FFF8E1", "#F9A825"),
    "fn":     ("#FFCCBC", "#D84315"),
    "ext":    ("#ECEFF1", "#546E7A"),
    "infra":  ("#E0F2F1", "#00695C"),
    "safety": ("#FFEBEE", "#C62828"),
    "money":  ("#FCE4EC", "#AD1457"),
    "neutral": ("#FFFFFF", "#9E9E9E"),
}

TRACE = {
    1: ("#2E7D32", "① SEND GROUP MESSAGE"),
    2: ("#AD1457", "② SPEND / GRANT COINS"),
    3: ("#1565C0", "③ INGEST EXTERNAL EVENT"),
    4: ("#E65100", "④ DELIVER PUSH NOTIFICATION"),
}

OFF = "dashed=1;fillColor=#F5F5F5;strokeColor=#BDBDBD;fontColor=#9E9E9E;"


def chip_style(key, extra=""):
    f, s = C[key]
    return ("rounded=1;arcSize=30;whiteSpace=wrap;html=1;fontSize=10;"
            f"fillColor={f};strokeColor={s};fontColor=#263238;" + extra)


def group_style(key, extra=""):
    f, s = C[key]
    return ("swimlane;html=1;rounded=1;arcSize=4;startSize=24;fontSize=11;"
            f"fontStyle=1;fillColor={f};strokeColor={s};fontColor=#263238;"
            "swimlaneFillColor=#FFFFFF;collapsible=1;" + extra)


BAND = ("swimlane;html=1;rounded=1;arcSize=3;startSize=38;fontSize=19;"
        "fontStyle=1;fillColor=#ECEFF1;strokeColor=#455A64;fontColor=#263238;"
        "swimlaneFillColor=#FCFCFC;collapsible=1;")

TEXT = ("text;html=1;whiteSpace=wrap;align=left;verticalAlign=top;"
        "fontSize=11;fontColor=#37474F;")

NOTE = ("rounded=1;whiteSpace=wrap;html=1;align=left;verticalAlign=top;"
        "fillColor=#FFFDE7;strokeColor=#F9A825;fontSize=11;fontColor=#5D4037;"
        "spacing=8;")

LINKBTN = ("rounded=1;arcSize=40;whiteSpace=wrap;html=1;fontSize=11;fontStyle=1;"
           "fillColor=#263238;strokeColor=#263238;fontColor=#FFFFFF;")


def esc(s):
    return html.escape(str(s), quote=True)


# ---------------------------------------------------------------------------
# tiny draw.io DSL
# ---------------------------------------------------------------------------
class Page:
    def __init__(self, pid, name, w=1600, h=1200):
        self.pid, self.name, self.w, self.h = pid, name, w, h
        self.cells = []
        self.n = 0

    def nid(self, pre="c"):
        self.n += 1
        return "%s-%s%d" % (self.pid, pre, self.n)

    def placeholder(self):
        self.cells.append(None)
        return len(self.cells) - 1

    def fill(self, idx, xml):
        self.cells[idx] = xml

    # -- primitives ---------------------------------------------------------
    def box(self, label, x, y, w, h, style, parent="1", link=None, cid=None):
        cid = cid or self.nid()
        geo = ('<mxGeometry x="%d" y="%d" width="%d" height="%d" as="geometry"/>'
               % (x, y, w, h))
        if link:
            self.cells.append(
                '<UserObject label="%s" link="%s" id="%s">'
                '<mxCell style="%s" vertex="1" parent="%s">%s</mxCell>'
                '</UserObject>' % (esc(label), esc(link), cid, style, parent, geo))
        else:
            self.cells.append(
                '<mxCell id="%s" value="%s" style="%s" vertex="1" parent="%s">'
                '%s</mxCell>' % (cid, esc(label), style, parent, geo))
        return cid

    def group_xml(self, label, x, y, w, h, style, parent="1",
                  link=None, cid=None, collapsed=False, cw=260, ch=44):
        """Return the XML for a collapsible container (caller appends/fills)."""
        if collapsed:
            gw, gh, aw, ah = cw, ch, w, h
        else:
            gw, gh, aw, ah = w, h, cw, ch
        geo = ('<mxGeometry x="%d" y="%d" width="%d" height="%d" as="geometry">'
               '<mxRectangle x="%d" y="%d" width="%d" height="%d" as="alternateBounds"/>'
               '</mxGeometry>' % (x, y, gw, gh, x, y, aw, ah))
        coll = ' collapsed="1"' if collapsed else ''
        if link:
            return ('<UserObject label="%s" link="%s" id="%s">'
                    '<mxCell style="%s" vertex="1"%s parent="%s">%s</mxCell>'
                    '</UserObject>'
                    % (esc(label), esc(link), cid, style, coll, parent, geo))
        return ('<mxCell id="%s" value="%s" style="%s" vertex="1"%s parent="%s">'
                '%s</mxCell>' % (cid, esc(label), style, coll, parent, geo))

    def edge(self, src, tgt, label="", style="", parent="1"):
        cid = self.nid("e")
        base = ("edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;fontSize=10;"
                "jettySize=auto;orthogonalLoop=1;")
        self.cells.append(
            '<mxCell id="%s" value="%s" style="%s%s" edge="1" parent="%s" '
            'source="%s" target="%s"><mxGeometry relative="1" as="geometry"/>'
            '</mxCell>' % (cid, esc(label), base, style, parent, src, tgt))
        return cid

    def trace(self, src, tgt, n, label=""):
        col = TRACE[n][0]
        st = ("strokeColor=%s;strokeWidth=3;fontColor=%s;fontStyle=1;"
              "endArrow=blockThin;endFill=1;dashed=0;" % (col, col))
        return self.edge(src, tgt, label or ("%s" % "①②③④"[n - 1]), st)

    def xml(self):
        body = "\n        ".join(c for c in self.cells if c)
        return (
            '  <diagram id="%s" name="%s">\n'
            '    <mxGraphModel dx="1200" dy="800" grid="1" gridSize="10" guides="1" '
            'tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" '
            'pageWidth="%d" pageHeight="%d" math="0" shadow="0">\n'
            '      <root>\n'
            '        <mxCell id="0"/>\n'
            '        <mxCell id="1" parent="0"/>\n'
            '        %s\n'
            '      </root>\n'
            '    </mxGraphModel>\n'
            '  </diagram>\n' % (self.pid, esc(self.name), self.w, self.h, body))


# ---------------------------------------------------------------------------
# layout helpers
# ---------------------------------------------------------------------------
CHIP_H = 22
CHIP_GX = 6
CHIP_GY = 5


def mod_size(chips, cols, chipw, head=26, pad=9):
    rows = (len(chips) + cols - 1) // cols if chips else 0
    w = pad * 2 + cols * chipw + (cols - 1) * CHIP_GX
    h = head + pad + rows * CHIP_H + max(0, rows - 1) * CHIP_GY + pad
    return w, max(h, head + 24)


def draw_mod(p, parent, title, chips, x, y, cols, chipw, key,
             link=None, marks=None, head=26, pad=9, chipkey=None):
    """Container `title` with `chips` laid out in a grid. Returns (id, w, h)."""
    marks = marks or {}
    w, h = mod_size(chips, cols, chipw, head, pad)
    gid = p.nid("m")
    idx = p.placeholder()
    p.fill(idx, p.group_xml(title, x, y, w, h,
                            group_style(key, "startSize=%d;" % head),
                            parent=parent, link=link, cid=gid))
    ck = chipkey or key
    for i, ch in enumerate(chips):
        r, c = divmod(i, cols)
        cx = pad + c * (chipw + CHIP_GX)
        cy = head + pad + r * (CHIP_H + CHIP_GY)
        extra = marks.get(ch, "")
        p.box(ch, cx, cy, chipw, CHIP_H, chip_style(ck, extra), parent=gid)
    return gid, w, h


def flow(items, max_w, x0=14, y0=44, gap=16):
    """items: list of (w, h, place_fn). Returns total height used."""
    x, y, rowh = x0, y0, 0
    for (w, h, fn) in items:
        if x != x0 and x + w > max_w - x0:
            x = x0
            y += rowh + gap
            rowh = 0
        fn(x, y)
        rowh = max(rowh, h)
        x += w + gap
    return y + rowh + 16


def band(p, title, x, y, w, mods, style=BAND):
    """mods: list of dicts {t, key, cols, cw, chips, marks?, chipkey?, head?}."""
    bid = p.nid("g")
    idx = p.placeholder()
    items = []
    for m in mods:
        head = m.get("head", 26)
        mw, mh = mod_size(m["chips"], m["cols"], m["cw"], head)
        items.append((mw, mh, (lambda mm=m, hd=head: (lambda xx, yy: draw_mod(
            p, bid, mm["t"], mm["chips"], xx, yy, mm["cols"], mm["cw"], mm["key"],
            marks=mm.get("marks"), chipkey=mm.get("chipkey"), head=hd)))()))
    h = flow(items, w)
    p.fill(idx, p.group_xml(title, x, y, w, h, style, cid=bid))
    return h


_TICK = __import__("re").compile(r"`([^`]+)`")
_TAG = __import__("re").compile(r"<[^>]+>")


def note_box(p, text, x, y, w):
    """Yellow note whose height is derived from the rendered text length."""
    text = _TICK.sub(r"<b>\1</b>", text)
    cpl = max(20, int((w - 24) / 6.0))
    lines = 0
    for seg in text.split("<br>"):
        plain = _TAG.sub("", seg)
        lines += max(1, -(-len(plain) // cpl))
    h = lines * 17 + 34
    p.box(text, x, y, w, h, NOTE)
    return h


# ===========================================================================
# REPO DATA  (extracted 2026-07-21, branch main @ 1e952ac)
# ===========================================================================

# name, screens, blocs, usecases, entities, repos, widgets, total files
FEATURES = [
    ("accessibility", 0, 0, 0, 1, 0, 0, 1),
    ("admin", 11, 1, 0, 6, 4, 0, 28),
    ("analytics", 2, 0, 0, 2, 0, 2, 8),
    ("app_guide", 1, 0, 0, 0, 0, 0, 1),
    ("app_tour", 0, 0, 0, 0, 0, 5, 7),
    ("authentication", 6, 1, 2, 1, 2, 5, 21),
    ("blind_date", 1, 1, 1, 1, 2, 1, 11),
    ("business", 9, 0, 0, 0, 0, 5, 18),
    ("chat", 9, 4, 28, 3, 4, 12, 74),
    ("coins", 4, 1, 9, 9, 2, 2, 37),
    ("communities", 3, 1, 0, 3, 2, 16, 33),
    ("conversation_expiry", 0, 1, 1, 1, 2, 1, 10),
    ("cultural_exchange", 3, 1, 0, 4, 2, 3, 22),
    ("date_scheduler", 1, 1, 1, 1, 2, 0, 8),
    ("discovery", 6, 2, 4, 4, 2, 8, 33),
    ("events", 7, 1, 0, 4, 2, 9, 33),
    ("explore", 4, 0, 0, 0, 0, 1, 5),
    ("explore_map", 1, 1, 0, 1, 2, 0, 9),
    ("gamification", 9, 1, 12, 12, 4, 9, 57),
    ("glass_demo", 1, 0, 0, 0, 0, 0, 1),
    ("globe_explore", 1, 1, 2, 1, 2, 3, 15),
    ("icebreakers", 1, 0, 0, 1, 0, 0, 2),
    ("legal", 1, 0, 0, 0, 0, 0, 1),
    ("localization", 0, 0, 0, 1, 0, 0, 1),
    ("main", 1, 0, 0, 0, 0, 0, 1),
    ("matching", 0, 0, 3, 4, 2, 0, 12),
    ("membership", 0, 0, 0, 1, 0, 1, 5),
    ("notifications", 3, 2, 6, 3, 2, 1, 24),
    ("passport", 1, 0, 0, 1, 0, 0, 3),
    ("premium", 0, 0, 0, 1, 0, 0, 1),
    ("profile", 28, 2, 5, 3, 2, 8, 57),
    ("recommendations", 0, 0, 0, 0, 0, 0, 1),
    ("referral", 1, 0, 0, 0, 0, 0, 3),
    ("safety", 2, 0, 0, 4, 0, 3, 10),
    ("safety_academy", 3, 1, 0, 4, 2, 2, 20),
    ("saved_searches", 1, 0, 0, 1, 0, 0, 3),
    ("second_chance", 1, 1, 1, 1, 2, 0, 10),
    ("share_my_date", 0, 1, 1, 1, 1, 0, 5),
    ("special_modes", 0, 0, 0, 1, 0, 0, 1),
    ("splash", 1, 0, 0, 0, 0, 0, 1),
    ("spots", 2, 1, 0, 2, 2, 1, 13),
    ("stories", 1, 0, 0, 1, 0, 0, 2),
    ("subscription", 2, 1, 4, 2, 2, 0, 15),
    ("vibe_tags", 1, 1, 1, 1, 2, 1, 11),
    ("video_call", 1, 0, 0, 1, 0, 0, 2),
    ("video_calling", 1, 1, 7, 1, 2, 4, 21),
    ("video_profiles", 2, 1, 0, 1, 2, 2, 12),
    ("virtual_gifts", 1, 1, 1, 1, 2, 1, 11),
]

# OFF when FlavorConfig.current == AppFlavor.culture  (the default flavor)
FLAVOR_OFF = {
    "discovery", "matching", "blind_date", "date_scheduler", "second_chance",
    "share_my_date", "special_modes", "virtual_gifts", "video_profiles",
}

# paid-membership gated surfaces — verified by call sites of TierGate /
# TierEntitlements / TierLimitsService inside lib/features (not assumed):
#   analytics      analytics_screen            → ensureAnalytics
#   business       business_hub / _events      → ensureAnalytics
#   chat           connect_and_chat            → canConnectToday / recordConnect
#                  chat_screen                 → ensureValidMembership
#                  create_group_screen         → ensureValidMembershipByUid
#   communities    sponsorship_gate            → analyticsEnabled
#   events         events_screen               → ensureValidMembershipByUid + canCreateEvent
#   explore        network_discovery_screen    → discoveryFreeReveal
#   profile        edit_profile_screen         → ensureBoost + ensureTravelMode
#   subscription   subscription entity mirrors TierEntitlements
TIER_GATED = {
    "analytics", "business", "chat", "communities", "events", "explore",
    "profile", "subscription",
}

# tier ladder as encoded in lib/core/services/tier_entitlements.dart
TIER_LADDER = [
    ("maxEvents (ongoing)", "Base 1 · Silver 3 · Gold 5 · Platinum ∞"),
    ("maxGroups", "Base 1 · Silver ∞ · Gold ∞ · Platinum ∞"),
    ("maxDailyConnects", "Base 10 · Silver 50 · Gold 200 · Platinum ∞"),
    ("boostsPerMonth", "Base 0 · Silver 1 · Gold 4 · Platinum 30"),
    ("maxBoostedVisible", "Base 2 · Silver 5 · Gold 10 · Platinum 999"),
    ("monthlyCoins", "Base 100 · Silver 500 · Gold 1500 · Platinum 5000"),
    ("discoveryFreeReveal", "Base 30 · Silver 100 · Gold 300 · Platinum 100 000"),
    ("ttsCostCoins", "5 coins — flat, all tiers"),
    ("searchFilterLevel", "None / Basic / Standard / Advanced"),
    ("canSeeWhoConnected", "bool by tier"),
    ("travelModeEnabled", "bool by tier"),
    ("prioritySupport", "bool by tier"),
    ("analyticsEnabled", "bool by tier (+ business)"),
    ("canBecomeBusiness / isBusinessActive", "business account eligibility"),
]

CORE_SERVICES = [
    "access_control_service", "activity_tracking_service", "api_key_service",
    "app_sound_service", "blocked_users_service", "cache_service",
    "candidate_pool_service", "chat_learning_service", "city_coordinates_service",
    "content_filter_service", "data_preload_service", "deep_link_service",
    "early_access_service", "external_events_index_service", "feature_flags_service",
    "interaction_log_service", "legal_documents_service", "location_refresh_service",
    "location_share_service", "onboarding_gate", "photo_validation_service",
    "pre_sale_service", "presence_service", "pronunciation_service",
    "push_notification_service", "session_cache_gate", "setup_version_config",
    "stripe_web_checkout", "subscription_expiry_service", "tier_entitlements",
    "tier_gate", "tier_limits_service", "translation_service", "usage_limit_service",
    "user_directory_service", "version_check_service", "visual_vocabulary_service",
    "vocabulary_service", "vocabulary_tracking_service", "web_geocoding_service",
]

# functions/src/index.ts  — module -> exported callables/triggers
FN = [
    ("media/imageCompression", ["compressUploadedImage", "compressImage"]),
    ("media/videoProcessing", ["processUploadedVideo", "generateVideoThumbnail"]),
    ("media/voiceTranscription", ["transcribeVoiceMessage", "transcribeAudio", "batchTranscribe"]),
    ("media/disappearingMedia", ["cleanupDisappearingMedia", "markMediaAsDisappearing"]),
    ("messaging/translation", ["translateMessage", "autoTranslateMessage", "batchTranslateMessages", "getSupportedLanguages"]),
    ("messaging/scheduledMessages", ["sendScheduledMessages", "scheduleMessage", "cancelScheduledMessage", "getScheduledMessages"]),
    ("group_chat/fanout", ["onGroupMessageCreated"]),
    ("group_chat/membership", ["onGroupCreated", "onGroupParticipantsChanged", "onGroupInfoChanged"]),
    ("group_chat/groupCleanup", ["onGroupDeleted"]),
    ("external_events/ingest", ["ingestExternalEvents", "runIngestExternalEventsNow", "runBackfillViatorCategoriesNow"]),
    ("external_events/tiqets", ["ingestTiqetsAttractions", "runIngestTiqetsNow"]),
    ("external_events/geoapify", ["runIngestGeoapifyNow", "runBackfillGeoapifyWebsitesNow", "runCleanupNoImageNow"]),
    ("external_events/ticketmaster", ["ingestTicketmaster", "runIngestTicketmasterNow"]),
    ("external_events/build_index", ["runBuildExternalIndexNow"]),
    ("external_events/geohash", ["runBackfillGeohashNow", "runBackfillEventGeohashNow"]),
    ("events/country_aggregate", ["onEventWriteUpdateCountryStats"]),
    ("events/broadcast", ["onEventBroadcastCreated", "onEventMessageCreated"]),
    ("events/likes", ["onEventLikeCreated", "onEventLikeDeleted"]),
    ("events/business_new_event", ["onEventCreatedNotifyFollowers", "onEventPublishedNotifyFollowers"]),
    ("events/reminders", ["sendEventReminders"]),
    ("events/autoPublish", ["autoPublishScheduledEvents"]),
    ("communities/announcementFanout", ["onCommunityAnnouncementCreated"]),
    ("communities/eventFanout", ["onCommunityEventCreated", "onCommunityEventPublished", "onCommunityEventChanged"]),
    ("gamification (root)", ["refreshMyStats", "onMessageCreatedVocabulary"]),
    ("gamification/gamificationManager", ["grantXP", "trackAchievementProgress", "unlockAchievementReward", "claimLevelRewards", "trackChallengeProgress", "claimChallengeReward", "resetDailyChallenges", "updateLeaderboardRankings"]),
    ("admin/accountCleanup", ["onProfileDeleted"]),
    ("notifications/socialNotifications", ["onCommunityMemberJoined", "onEventAttendeeJoined", "onBusinessFollowed", "onBusinessRated", "onEventLiked"]),
    ("notifications/pushParity", ["onNotificationCreatedPush"]),
    ("notifications/cityAlerts", ["syncCitySubscribers", "onEventCityAlert"]),
    ("notifications/engagementNotifications", ["onProfileViewed", "onTicketScanned", "onProfileBoostStarted", "onEventBoostStarted", "checkBoostExpiries"]),
    ("notifications/pushNotifications", ["sendPushNotification", "sendBundledNotifications", "trackNotificationOpened", "getNotificationAnalytics"]),
    ("notifications/pushNotificationTriggers", ["onNewMessagePush", "onSupportMessagePush", "checkExpiringModes", "onVerificationStatusChange"]),
    ("notifications/emailCommunication (legacy SendGrid)", ["sendTransactionalEmail", "startWelcomeEmailSeries", "processWelcomeEmailSeries", "sendWeeklyDigestEmails", "sendReEngagementCampaign"]),
    ("notifications/brevoEmailService (primary)", ["sendBrevoEmailFunction", "getBrevoEmailTemplates", "updateBrevoEmailTemplate", "getBrevoEmailLogs", "getBrevoEmailAnalytics", "onUserCreatedSendWelcome", "onSubscriptionUpdated", "onPhotoModerationUpdated", "onAchievementUnlocked", "onPurchaseCreated", "sendBrevoWeeklyDigest", "sendBrevoReEngagement", "sendBrevoStreakReminder"]),
    ("backup/conversationBackup", ["backupConversation", "restoreConversation", "listBackups", "deleteBackup", "autoBackupConversations"]),
    ("backup/pdfExport", ["exportConversationToPDF", "listPDFExports", "cleanupExpiredExports"]),
    ("subscription/index", ["verifyPurchase", "checkExpiringMemberships", "handleExpiredMemberships"]),
    ("subscription/storeNotifications", ["appStoreNotificationsV2", "playStoreNotifications"]),
    ("payments/stripeCheckout", ["createStripeCheckoutSession", "stripeWebhook"]),
    ("coins", ["verifyGooglePlayCoinPurchase", "verifyAppStoreCoinPurchase", "grantMonthlyAllowances", "processExpiredCoins", "sendExpirationWarnings", "claimReward", "giftCoins"]),
    ("coupons + referral", ["redeemCoupon", "validateCoupon", "redeemReferral", "upsertCoupon", "listCoupons", "getCouponRedemptions", "setCouponDisabled", "applySignupGrants"]),
    ("analytics/revenueAnalytics", ["getRevenueDashboard", "exportRevenueData"]),
    ("analytics/cohortAnalytics", ["getCohortAnalysis"]),
    ("analytics/churnPrediction", ["trainChurnModel", "predictChurnDaily", "getUserChurnPrediction", "getAtRiskUsers"]),
    ("analytics/advancedAnalytics", ["createABTest", "assignUserToTest", "recordConversion", "getABTestResults", "detectFraud", "forecastMRR", "getARPU", "getRefundAnalytics", "calculateTax", "getTaxReport"]),
    ("analytics/userSegmentation", ["calculateUserSegment", "createUserCohort", "calculateCohortRetention", "predictUserChurn", "batchChurnPrediction"]),
    ("safety/contentModeration", ["moderatePhoto", "moderateText", "detectSpam", "detectFakeProfile", "detectScam"]),
    ("safety/reportingSystem", ["submitReport", "reviewReport", "submitAppeal", "blockUser", "unblockUser", "getBlockList"]),
    ("safety/reportCountTrigger", ["onUserReportCreated"]),
    ("safety/identityVerification", ["startPhotoVerification", "verifyPhotoSelfie", "verifyIDDocument", "calculateTrustScore"]),
    ("admin/adminDashboard", ["getUserActivityMetrics", "getUserGrowthChart", "getRevenueMetrics", "getEngagementMetrics", "getGeographicHeatmap", "getSystemHealthMetrics", "createSystemAlert", "resolveSystemAlert", "getAdminAuditLog"]),
    ("admin/roleManagement", ["createAdminUser", "updateAdminRole", "updateAdminPermissions", "deactivateAdminUser", "getAdminUsers", "recordAdminLogin"]),
    ("admin/userManagement", ["searchUsers", "getDetailedUserProfile", "editUserProfile", "suspendUserAccount", "unsuspendUserAccount", "banUserAccount", "unbanUserAccount", "deleteUserAccount", "overrideUserSubscription", "adjustUserCoins", "sendUserNotification", "impersonateUser", "executeMassAction", "adminBulkDeleteUsers"]),
    ("admin/moderationQueue", ["getModerationQueue", "getModerationReviewItem", "assignModerationItem", "takeModerationAction", "executeBulkModeration", "getModerationStatistics"]),
    ("admin/mvp_access", ["approveUser", "rejectUser", "updateUserTier", "getPendingUsers", "bulkApproveUsers", "sendBroadcastNotification", "sendNotificationToUser", "getMvpAccessStats"]),
    ("admin/adminPanelFunctions", ["send2FACode", "verify2FACode", "adminChangeUserPassword", "sendPasswordResetEmail", "forcePasswordChange", "adminDeleteUser", "adminSetUserDisabled", "sendTestEmail", "processAISupportMessage", "onSupportChatCreated", "onSupportMessageCreated", "cleanupOrphanedAuthUser", "sendWelcomeEmail", "sendPasswordResetViaResend", "reverseGeocodeProfileLocation"]),
    ("video_calling/videoCalling", ["initiateVideoCall", "answerVideoCall", "endVideoCall", "handleCallSignal", "updateCallQuality", "startCallRecording"]),
    ("video_calling/videoCallFeatures", ["enableVirtualBackground", "applyARFilter", "toggleBeautyMode", "enablePictureInPicture", "startScreenSharing", "stopScreenSharing", "toggleNoiseSuppression", "toggleEchoCancellation", "sendInCallReaction", "uploadCustomBackground", "getCallHistory", "getCallStatistics", "cleanupExpiredReactions"]),
    ("video_calling/groupVideoCalls", ["createGroupVideoCall", "joinGroupVideoCall", "leaveGroupVideoCall", "manageGroupParticipant", "changeGroupCallLayout", "createBreakoutRoom", "joinBreakoutRoom", "closeBreakoutRoom"]),
    ("security/securityAudit", ["runSecurityAudit", "scheduledSecurityAudit", "getSecurityAuditReport", "listSecurityAuditReports", "cleanupOldAuditReports"]),
    ("language_learning/languageLearningManager", ["submitTeacherApplication", "reviewTeacherApplication", "createLesson", "publishLesson", "purchaseLesson", "updateLessonProgress", "getLearningAnalytics", "getUserProgressReport", "getTeacherAnalytics", "getAdminLessons", "seedLessons", "deleteLesson", "updateLesson", "getLessonStats"]),
    ("discovery/candidatePoolPrecompute", ["precomputeCandidatePools", "triggerPoolRecompute", "getCandidatePoolStats"]),
    ("presence", ["onPresenceUpdate", "cleanupStalePresence"]),
]

FN_TOTAL = sum(len(f) for _, f in FN)

SNAPSHOT = "2026-07-21"

# Audited by grepping `memory:` declarations across functions/src/**/*.ts.
# The index loads ~200 MB RSS before any handler runs, so anything at or below
# 256 MiB can be OOM-killed on cold start — and a killed trigger DROPS its event.
MEMORY_POSTURE = [
    "102 .ts files · 49 declare memory · 53 declare none (platform default)",
    "128MiB × 17 declarations  ⚠ highest risk",
    "256MiB × 99 declarations  ⚠ at risk",
    "512MiB × 63 declarations  ✓ safe (push fns live here)",
    "1GiB × 15 · 2GiB × 2 · 1GB × 3 · 2GB × 3 · 512MB × 1",
    "128MiB files: backup/ · messaging/ · notification/ ·",
    "   notifications/brevoEmailService · safety/",
    "worst 256MiB offenders: admin/index (25) · video/index (20) ·",
    "   analytics/index (10) · gamification/index (6) · mvp_access (6)",
]

# firestore.rules top-level match paths, grouped by domain
COLLECTIONS = [
    ("Identity & Profile", ["users", "profiles", "nicknames", "user_passports",
                            "match_preferences", "user_vectors", "user_people_tags",
                            "saved_searches", "appConfig", "app_config"]),
    ("Messaging", ["conversations", "messages", "threads", "chat", "groups",
                   "members", "user_group_inbox", "user_group_tags",
                   "conversation_expiry", "message_reports", "support_chats",
                   "support_messages"]),
    ("Discovery & Matching", ["discovery_queue", "swipes", "likes", "matches",
                              "blindMatches", "secondChancePool", "interaction_matrix",
                              "user_interactions", "photo_likes", "constellation"]),
    ("Events", ["events", "attendees", "external_events", "external_events_index",
                "external_country_stats", "city_coordinates", "days", "hours",
                "rounds", "seasonal_events"]),
    ("Communities & Business", ["communities", "join_requests",
                                "user_favorite_communities", "business_followers",
                                "business_leads", "business_ratings",
                                "business_verification_requests",
                                "user_business_following"]),
    ("Money — coins", ["coinBalances", "coinTransactions", "coinOrders", "coinGifts",
                       "coinPromotions", "coin_balances", "coin_transactions",
                       "videoCoinBalances", "videoCoinTransactions", "virtualGifts"]),
    ("Money — membership", ["memberships", "membership_purchases", "subscriptions",
                            "invoices", "transactions", "tierConfigs", "usageLimits",
                            "dailyUsage", "coupons", "redemptions", "referrals",
                            "referral_codes", "claimedRewards"]),
    ("Gamification & Learning", ["achievement_progress", "challenge_progress",
                                 "mission_progress", "user_levels", "xp_transactions",
                                 "streaks", "game_rooms", "game_stats", "game_words",
                                 "game_invites", "game_matchmaking",
                                 "game_grammar_questions", "game_reported_words",
                                 "game_translation_race", "lessons", "words",
                                 "vocabulary_words", "user_vocabulary",
                                 "pronunciation_cache"]),
    ("Safety & Trust", ["reports", "user_reports", "blockedUsers", "blocked_users",
                        "album_access", "legalDocuments"]),
    ("Notifications", ["notifications", "notification_preferences"]),
    ("Ops / Admin / Flags", ["admin_users", "admin_actions", "admin_audit_index",
                             "featureFlags", "function_monitors", "analytics",
                             "databases"]),
]

STORAGE_PATHS = ["profiles/", "chat_images/", "chat_videos/", "chat_voice/",
                 "group_media/", "group_voice/", "communities/", "video_profiles/",
                 "verifications/", "business_verification/", "support_attachments/",
                 "pronunciation_audio/"]

EXTERNAL = [
    ("Stores & Payments", "money", ["Google Play Billing 8.x", "Apple StoreKit / App Store S2S",
                                    "Stripe Checkout + webhook", "in_app_purchase 3.3"]),
    ("Google Cloud AI", "ext", ["Cloud Translation", "Chirp 3 HD TTS (coin-gated, cached)",
                                "Speech-to-Text (voice msg)", "Vision / content moderation"]),
    ("Maps & Geo", "ext", ["Google Maps SDK", "flutter_map / OSM tiles",
                           "Geolocator + Geocoding", "web_geocoding_service"]),
    ("Event feeds", "ext", ["Geoapify (attractions)", "Viator", "Ticketmaster", "Tiqets"]),
    ("Comms", "ext", ["Brevo (primary email)", "SendGrid (legacy)", "Resend (password reset)",
                      "FCM push"]),
    ("Realtime media", "ext", ["Agora RTC (video call)", "WebRTC signalling via CF"]),
    ("On-device ML", "ext", ["ML Kit face detection 0.13.2",
                             "ML Kit image labeling 0.14.2",
                             "mobile_scanner 7.x (Apple Vision)"]),
]

INFRA = [
    ("Build & Release", "infra", ["codemagic.yaml — iOS TestFlight", "codemagic.yaml — Web deploy",
                                  "codemagic.yaml — Android APK", "greengo-release.keystore",
                                  "flavor: main.dart (culture)", "flavor: main_full.dart (full)"]),
    ("Firebase deploy", "infra", ["firebase.json", "firestore.rules(.production)",
                                  "storage.rules(.production)", "firestore.indexes.json",
                                  "deploy functions BY NAME"]),
    ("IaC — Terraform", "infra", ["terraform/main.tf", "modules/cloud_functions",
                                  "modules/kms", "modules/storage",
                                  "terraform/microservices"]),
    ("Local stack — Docker", "infra", ["firebase emulators", "postgres", "redis",
                                       "adminer", "redis-commander", "nginx"]),
    ("Quality gates", "infra", ["test/ + integration_test/", "functions/__tests__ (jest)",
                                "security_audit/", "firebase_test_lab.sh"]),
]

CROSS = [
    ("Security", "safety", ["App Check", "firestore.rules (110 paths)", "storage.rules (12 paths)",
                            "access_control_service", "api_key_service",
                            "security/securityAudit CF", "2FA (admin)"]),
    ("i18n", "ui", ["lib/l10n/app_en.arb (source of truth)", "flutter gen-l10n",
                    "AppLocalizations.of(context)!", "translation_service (runtime)"]),
    ("Config & Flags", "state", ["FlavorConfig (culture|full)", "feature_flags_service",
                                 "Remote Config", "app_config / environment",
                                 "setup_version_config", "version_check_service"]),
    ("Observability", "ext", ["Crashlytics", "Performance Monitoring", "Firebase Analytics",
                              "function_monitors", "admin System Health"]),
    ("Caching & Offline", "data", ["Hive (chat cache)", "shared_preferences", "cache_service",
                                   "data_preload_service", "session_cache_gate",
                                   "cached_network_image"]),
]

# LLD page registry: (page id, tab name, master-band button label)
PAGES = [
    ("p01", "01 · Identity, Onboarding & Profile"),
    ("p02", "02 · Explore, Discovery, Map & Globe"),
    ("p03", "03 · Messaging & Chat"),
    ("p04", "04 · Events & External Ingesters"),
    ("p05", "05 · Communities & Business"),
    ("p06", "06 · Monetization — Coins, Tiers, Payments"),
    ("p07", "07 · Notifications & Email"),
    ("p08", "08 · Safety, Moderation & Admin"),
    ("p09", "09 · Gamification & Language Learning"),
    ("p10", "10 · Media, Voice & Video Calling"),
    ("p11", "11 · Platform, Data Model & DevOps"),
]
PLINK = {pid: "data:page/id,%s" % pid for pid, _ in PAGES}
MASTER_LINK = "data:page/id,master"


# ===========================================================================
# PAGE 00 — MASTER
# ===========================================================================
def build_master():
    W = 4600
    p = Page("master", "00 · MASTER — Zoomable Blueprint", W, 5200)
    y = 20

    # ---- title -----------------------------------------------------------
    p.box("GreenGo — Mobile Application · Full Solution Design (HLD + LLD in one schema)",
          20, y, 2500, 44,
          "text;html=1;fontSize=26;fontStyle=1;fontColor=#1B5E20;align=left;verticalAlign=middle;")
    p.box(("Cross-cultural discovery · language-exchange · networking  —  NOT a dating app.\n"
           "Flutter 3.44 / Dart 3.12 · Clean Architecture + BLoC · Firebase + Cloud Functions · "
           "repo GreenGo-App-Flutter @ main · generated from source, 2026-07-21"),
          20, y + 46, 2500, 46,
          "text;html=1;fontSize=12;fontColor=#546E7A;align=left;verticalAlign=top;")

    # ---- legend ----------------------------------------------------------
    lg = p.nid("g")
    p.cells.append(p.group_xml("LEGEND  ·  overlays & runtime traces", 2600, y, 1980, 96,
                               group_style("neutral", "fontSize=13;startSize=26;"), cid=lg))
    lay = [("Presentation / UI", "ui"), ("BLoC / State", "state"), ("Domain", "domain"),
           ("Data / Services", "data"), ("Firebase", "fb"), ("Cloud Functions", "fn"),
           ("External SaaS", "ext"), ("Infra / CI", "infra"), ("Safety", "safety"),
           ("Money", "money")]
    for i, (lab, k) in enumerate(lay):
        p.box(lab, 10 + (i % 5) * 196, 32 + (i // 5) * 26, 190, 22, chip_style(k), parent=lg)
    p.box("⚪ dashed = OFF in `culture` flavor (default build)", 1010, 32, 470, 22,
          chip_style("neutral", OFF), parent=lg)
    p.box("🔒 = gated by paid membership tier", 1010, 58, 470, 22,
          chip_style("money"), parent=lg)
    for i in range(1, 5):
        col, lab = TRACE[i]
        p.box(lab, 1490 + (i - 1) % 2 * 240, 32 + ((i - 1) // 2) * 26, 234, 22,
              "rounded=1;html=1;fontSize=10;fontStyle=1;fillColor=#FFFFFF;"
              "strokeColor=%s;strokeWidth=2;fontColor=%s;" % (col, col), parent=lg)
    y += 108

    # ---- always-visible HLD strip ---------------------------------------
    hb = p.nid("g")
    hidx = p.placeholder()
    steps = [
        ("USERS\ntraveler · host · business · admin", "actor"),
        ("CLIENTS\nAndroid · iOS · Web PWA", "ui"),
        ("FLAVOR GATE\nculture (default) | full", "state"),
        ("FLUTTER APP\n49 features · 135 screens · 31 BLoC", "ui"),
        ("CORE SERVICES\n40 singletons via get_it", "data"),
        ("FIREBASE EDGE\nAuth · Firestore · Storage · FCM", "fb"),
        ("CLOUD FUNCTIONS\n%d fns · 28 modules" % FN_TOTAL, "fn"),
        ("EXTERNAL SaaS\nStripe · Agora · Brevo · feeds", "ext"),
        ("INFRA & CI\nTerraform · Docker · Codemagic", "infra"),
    ]
    ids = []
    for i, (lab, k) in enumerate(steps):
        ids.append(p.box(lab, 20 + i * 500, 46, 440, 74,
                         chip_style(k, "fontSize=13;fontStyle=1;verticalAlign=middle;"),
                         parent=hb))
    for a, b in zip(ids, ids[1:]):
        p.edge(a, b, "", "strokeColor=#455A64;strokeWidth=2;endArrow=blockThin;", parent=hb)
    p.fill(hidx, p.group_xml(
        "▸ HIGH-LEVEL SOLUTION DESIGN  —  always-visible 10 000-ft view "
        "(everything below is the LOW-LEVEL expansion of these 9 boxes)",
        20, y, W - 40, 146, BAND + "fillColor=#CFD8DC;", cid=hb))
    y += 158

    # ---- atlas index -----------------------------------------------------
    ab = p.nid("g")
    aidx = p.placeholder()
    for i, (pid, name) in enumerate(PAGES):
        p.box("▸ " + name, 14 + (i % 6) * 750, 40 + (i // 6) * 34, 736, 28,
              LINKBTN, parent=ab, link=PLINK[pid])
    p.fill(aidx, p.group_xml(
        "▸ ATLAS INDEX — click any button to jump to that domain's low-level deep dive",
        20, y, W - 40, 116, BAND + "fillColor=#B0BEC5;", cid=ab))
    y += 128

    # =====================================================================
    # ROW A — band 1 (actors)  |  band 2 (client runtime)
    # =====================================================================
    h1 = band(p, "1 · ACTORS, CHANNELS & PRODUCT CONSTRAINTS", 20, y, 1440, [
        dict(t="Human actors", key="actor", cols=2, cw=210,
             chips=["Traveler / newcomer", "Local host", "Language partner",
                    "Community moderator", "Business owner", "Support agent",
                    "Platform admin", "Teacher (language_learning)"]),
        dict(t="Entry channels", key="ui", cols=2, cw=210,
             chips=["Google Play (Android)", "App Store / TestFlight (iOS)",
                    "greengo-chat.web.app (PWA)", "Deep links (app_links)",
                    "Referral / coupon link", "QR ticket scan",
                    "Email (Brevo campaigns)", "Push notification tap"]),
        dict(t="Store-facing constraint", key="safety", cols=2, cw=210,
             chips=["Apple 4.3(b) — non-dating positioning",
                    "v3.0.0+101 repositioning build",
                    "culture flavor is the DEFAULT everywhere",
                    "dating code retained but flag-OFF"]),
    ])
    nav_full = ["Tab 0 · Discovery (swipe)", "Tab 1 · Messages", "Tab 2 · Groups",
                "Tab 3 · Events", "Tab 4 · Profile", "BottomNavigationBar + match badge"]
    h2 = band(p, "2 · CLIENT RUNTIME, FLAVOR GATE & NAVIGATION SHELL     "
                 "[dashed = not mounted in the default culture build]",
              1480, y, W - 1500, [
        dict(t="Entrypoints & bootstrap", key="ui", cols=2, cw=240,
             chips=["lib/main.dart → AppFlavor.culture", "lib/main_full.dart → AppFlavor.full",
                    "lib/main_preview.dart (design preview)", "AuthWrapper (route decision)",
                    "Firebase.initializeApp + App Check", "injection_container.dart (get_it)",
                    "onboarding_gate / session_cache_gate", "data_preload_service warm-up"]),
        dict(t="FlavorConfig switches (9)", key="state", cols=2, cw=210,
             chips=["enableSwipeDiscovery", "enableMatching", "enableBlindDate",
                    "enableDateScheduler", "enableSecondChance", "enableShareMyDate",
                    "enableSpecialModes", "enableVirtualGifts", "enableVideoProfiles",
                    "exploreFirst = !enableSwipe"]),
        dict(t="Navigation shell — culture (default)", key="ui", cols=1, cw=250,
             chips=["Tab 0 · Explore (glass)", "Tab 1 · Events", "Tab 2 · Community",
                    "Tab 3 · Messages", "Tab 4 · Profile", "GlassBottomNav (frosted)"]),
        dict(t="Navigation shell — full (opt-in) ⚪", key="ui", cols=1, cw=250,
             chips=nav_full, marks={c: OFF for c in nav_full}),
        dict(t="Platform targets", key="infra", cols=2, cw=190,
             chips=["android/ (minSdk 24)", "ios/ (Podfile, StoreKit)",
                    "web/ (PWA, service worker)", "windows/ linux/ macos/ (dev)"]),
    ])
    y += max(h1, h2) + 18

    # =====================================================================
    # BAND 3 — Flutter application (the big one)
    # =====================================================================
    fchips, fmarks = [], {}
    for (n, s, bl, uc, en, rp, wd, tot) in FEATURES:
        lock = " 🔒" if n in TIER_GATED else ""
        lab = "%s%s  ·  %ds/%db/%du  (%d)" % (n, lock, s, bl, uc, tot)
        fchips.append(lab)
        if n in FLAVOR_OFF:
            fmarks[lab] = OFF

    h = band(p, "3 · FLUTTER APPLICATION — Clean Architecture + BLoC   "
                "[826 .dart files · 49 features · 135 screens · 31 BLoC/Cubit]",
             20, y, W - 40, [
        dict(t="3a · FEATURE SLICES — 49 Clean-Arch modules   "
               "[name · screens/blocs/usecases (total .dart files)]",
             key="ui", cols=5, cw=250, chips=fchips, marks=fmarks, head=30),
        dict(t="3b · SLICE ANATOMY (every feature/)", key="domain", cols=1, cw=330,
             chips=["presentation/screens/*_screen.dart", "presentation/widgets/*",
                    "presentation/bloc/*_bloc|_cubit + event + state",
                    "domain/entities/*.dart",
                    "domain/repositories/*_repository.dart (abstract)",
                    "domain/usecases/*.dart (dartz Either&lt;Failure,T&gt;)",
                    "data/models/*_model.dart (toJson/fromJson)",
                    "data/datasources/*_remote|_local_datasource.dart",
                    "data/repositories/*_repository_impl.dart",
                    "core/error/failures.dart + exceptions.dart"]),
        dict(t="3c · CORE SERVICES — lib/core/services (40 singletons)",
             key="data", cols=3, cw=230, chips=CORE_SERVICES),
        dict(t="3d · STATE MGMT & DI", key="state", cols=1, cw=260,
             chips=["flutter_bloc 8.1 (31 BLoC/Cubit)",
                    "provider 6.1 (ChangeNotifier bridges)",
                    "get_it 7.6 + injectable 2.3", "equatable / formz (form state)",
                    "dartz Either&lt;Failure, T&gt;", "lib/core/providers/*",
                    "lib/core/di/injection_container.dart"]),
        dict(t="3e · SHARED UI KIT & THEME", key="ui", cols=1, cw=280,
             chips=["lib/core/theme (glass tokens, brand green)",
                    "lib/core/widgets/* (shared)", "GlassBottomNav / frosted surfaces",
                    "shimmer + staggered animations", "lottie / flutter_svg",
                    "showcaseview (gesture tour)", "fl_chart (analytics)",
                    "cached_network_image", "l10n → AppLocalizations (app_en.arb)"]),
        dict(t="3f · ON-DEVICE STORAGE", key="data", cols=1, cw=260,
             chips=["Hive 2.2 — chat message cache", "shared_preferences — flags/session",
                    "path_provider — media temp", "cache_service — TTL memory cache",
                    "session_cache_gate — cold-start gate",
                    "Firebase-managed keystore/secure prefs"]),
    ])
    y += h + 18

    # =====================================================================
    # BAND 4 — Firebase edge
    # =====================================================================
    mods = [dict(t="4a · FIREBASE SDK SURFACE", key="fb", cols=1, cw=290,
                 chips=["firebase_auth 5 (email, Google, Apple)",
                        "cloud_firestore 5 (primary store)",
                        "firebase_storage 12 (media)", "firebase_messaging 15 (FCM)",
                        "cloud_functions 5 (callables)", "firebase_remote_config 5",
                        "firebase_app_check 0.3", "firebase_crashlytics 4",
                        "firebase_performance 0.10", "firebase_analytics 11"])]
    for gname, cols in COLLECTIONS:
        mods.append(dict(t="Firestore · " + gname, key="fb", cols=2, cw=205,
                         chips=cols, chipkey="data"))
    mods.append(dict(t="4b · CLOUD STORAGE buckets/prefixes", key="fb", cols=2, cw=200,
                     chips=STORAGE_PATHS, chipkey="data"))
    mods.append(dict(t="4c · INDEXING & READ SHAPES", key="data", cols=1, cw=270,
                     chips=["firestore.indexes.json (composite)",
                            "external_events_index (sharded)", "geohash prefix buckets",
                            "attendees collection-group index",
                            "country_lower + nickname prefix",
                            "user_group_inbox per-user fan-out"]))
    h = band(p, "4 · FIREBASE EDGE — Auth, Firestore (110 rule-guarded paths), Storage, "
                "FCM, Remote Config, App Check, Crashlytics", 20, y, W - 40, mods)
    y += h + 18

    # =====================================================================
    # BAND 5 — Cloud Functions
    # =====================================================================
    h = band(p, "5 · CLOUD FUNCTIONS (Node/TypeScript) — functions/src, %d exported "
                "callables & triggers across %d modules   ⚠ deploy BY NAME; anything at "
                "≤256 MiB can be OOM-killed on cold start and silently DROP its trigger "
                "event" % (FN_TOTAL, len(FN)), 20, y, W - 40,
             [dict(t="⚠ MEMORY POSTURE (audited %s)" % SNAPSHOT, key="safety",
                   cols=1, cw=330, chips=MEMORY_POSTURE)] +
             [dict(t="%s  (%d)" % (m, len(f)), key="fn", cols=2, cw=215, chips=f)
              for m, f in FN])
    y += h + 18

    # =====================================================================
    # ROW B — band 6 (external) | band 7 (cross-cutting) | band 8 (infra)
    # =====================================================================
    h6 = band(p, "6 · EXTERNAL INTEGRATIONS & THIRD-PARTY SaaS", 20, y, 1440,
              [dict(t=t, key=k, cols=1, cw=265, chips=c) for t, k, c in EXTERNAL])
    h7 = band(p, "7 · CROSS-CUTTING CONCERNS", 1480, y, 1500,
              [dict(t=t, key=k, cols=1, cw=285, chips=c) for t, k, c in CROSS])
    h8 = band(p, "8 · PLATFORM, INFRASTRUCTURE & DELIVERY", 3000, y, W - 3020,
              [dict(t=t, key=k, cols=1, cw=275, chips=c) for t, k, c in INFRA])
    y += max(h6, h7, h8) + 18

    # =====================================================================
    # BAND 9 — runtime traces (sequence, written out)
    # =====================================================================
    b = p.nid("g")
    idx = p.placeholder()
    tr = [
        (1, ["1. GroupChatScreen → SendGroupMessage usecase",
             "2. repository_impl → Firestore groups/{gid}/messages",
             "3. TRIGGER onGroupMessageCreated (group_chat/fanout)",
             "4. fan-out write → user_group_inbox/{uid}/…",
             "5. onNewMessagePush → FCM multicast",
             "6. clients: Hive cache + realtime snapshot"]),
        (2, ["1. ShopScreen → verifyGooglePlayCoinPurchase (callable)",
             "2. server verifies receipt w/ Play Developer API",
             "3. txn: coinBalances/{uid} ⟵ camelCase model ONLY",
             "4. coinTransactions/{id} audit row",
             "5. spend path → tier_limits_service + usage_limit_service",
             "6. giftCoins → coinGifts + notification + push"]),
        (3, ["1. Scheduler (pub/sub cron) → ingestExternalEvents",
             "2. per-source adapters: Viator · Ticketmaster · Tiqets · Geoapify",
             "3. normalise → external_events/{id} (+ geohash)",
             "4. runBuildExternalIndexNow → external_events_index shards",
             "5. onEventWriteUpdateCountryStats → external_country_stats",
             "6. client pager reads nearest-first, cache-first"]),
        (4, ["1. domain trigger writes notifications/{uid}/items/{id}",
             "2. onNotificationCreatedPush (pushParity) picks it up",
             "3. shouldNotify() gate ⟵ notification_preferences (paid tier)",
             "4. sendPushNotification → FCM token multicast",
             "5. client: firebase_messaging + flutter_local_notifications",
             "6. trackNotificationOpened → analytics"]),
    ]
    inner = []
    for n, steps in tr:
        col, lab = TRACE[n]
        w, hh = mod_size(steps, 1, 400)
        inner.append((w, hh, (lambda t=lab, s=steps, c=col: (lambda x, yy: draw_mod(
            p, b, t, s, x, yy, 1, 400, "neutral",
            marks={q: "strokeColor=%s;" % c for q in s})))()))
    h = flow(inner, W - 40)
    p.fill(idx, p.group_xml("9 · CRITICAL RUNTIME TRACES (end-to-end sequences)",
                            20, y, W - 40, h, BAND, cid=b))
    y += h + 18

    # ---- constraints note ------------------------------------------------
    h = note_box(
        p,
        "<b>ARCHITECTURAL CONSTRAINTS &amp; KNOWN TRAPS (carry these into every change)</b><br><br>"
        "• <b>Flavor first.</b> `culture` is the default on web/iOS/Android; the 9 dating switches are OFF. "
        "Anything dashed above must not mount, listen, or count usage in the default build (Apple 4.3(b)).<br>"
        "• <b>Coin model split.</b> The client reads <i>camelCase</i> `coinBalances` only. The snake_case "
        "`coin_balances` / `coin_transactions` functions are phantom — do not wire new code to them.<br>"
        "• <b>Functions memory.</b> The functions index needs ~200 MB RSS just to load, so a function at or "
        "below 256 MiB can be OOM-killed on cold start — and a killed trigger drops its event silently. "
        "Audited state: <b>17 declarations at 128 MiB and 99 at 256 MiB are still at risk</b>, 63 are at "
        "512 MiB (that is where the push functions were moved), and 53 of the 102 .ts files declare no "
        "memory at all and inherit the platform default. See the MEMORY POSTURE panel in band 5.<br>"
        "• <b>Deploy by name.</b> Orphaned production functions abort a full `firebase deploy --only functions`.<br>"
        "• <b>Rules do not cascade.</b> A `match /users/{uid}` rule does NOT cover `users/{uid}/sub/{doc}` — "
        "subcollections need their own match blocks (this broke chat-media upload and coin-gift notifications).<br>"
        "• <b>Scale posture.</b> Every read path must paginate, denormalise or shard — no unbounded collection "
        "scans. Fan-out on write (user_group_inbox, external_events_index) is the house pattern.<br>"
        "• <b>i18n.</b> No hardcoded UI text: add the key to lib/l10n/app_en.arb → `flutter gen-l10n` → "
        "`AppLocalizations.of(context)!.key`.",
        20, y, W - 40)
    y += h + 20

    p.h = y + 40
    return p


# ===========================================================================
# LLD PAGE TEMPLATE
# ===========================================================================
def build_lld(pid, name, subtitle, lanes, notes, width=3400):
    """lanes: list of (lane_title, color_key, [(group_title, [chips], cols, chipw)])"""
    p = Page(pid, name, width, 2200)
    y0 = 100
    x = 20
    lane_ids = []
    maxh = 0
    for (ltitle, lkey, groups) in lanes:
        # measure
        inner_h = 44
        lw = 0
        sizes = []
        for (gt, chips, cols, cw) in groups:
            w, h = mod_size(chips, cols, cw)
            sizes.append((w, h))
            inner_h += h + 14
            lw = max(lw, w)
        lw += 28
        lid = p.nid("L")
        lidx = p.placeholder()
        yy = 40
        for (gt, chips, cols, cw), (w, h) in zip(groups, sizes):
            draw_mod(p, lid, gt, chips, 14, yy, cols, cw, lkey)
            yy += h + 14
        p.fill(lidx, p.group_xml(ltitle, x, y0, lw, inner_h,
                                 BAND + "startSize=32;fontSize=14;", cid=lid))
        lane_ids.append(lid)
        maxh = max(maxh, inner_h)
        x += lw + 46

    for a, b in zip(lane_ids, lane_ids[1:]):
        p.edge(a, b, "", "strokeColor=#37474F;strokeWidth=2;endArrow=blockThin;"
                          "exitX=1;exitY=0.08;exitDx=0;exitDy=0;"
                          "entryX=0;entryY=0.08;entryDx=0;entryDy=0;")

    ny = y0 + maxh + 24
    nw = max(1200, x - 66)
    nh = note_box(p, notes, 20, ny, nw)
    p.w = max(x + 40, nw + 60)
    p.h = ny + nh + 40
    p.box(name.split("·", 1)[1].strip() + "  —  Low-Level Design", 20, 16,
          p.w - 300, 34,
          "text;html=1;fontSize=22;fontStyle=1;fontColor=#1B5E20;align=left;"
          "verticalAlign=middle;")
    p.box(subtitle, 20, 54, p.w - 60, 36,
          "text;html=1;fontSize=12;fontColor=#546E7A;align=left;verticalAlign=top;")
    p.box("◀ back to MASTER", p.w - 240, 18, 200, 30, LINKBTN, link=MASTER_LINK)
    return p


# ---------------------------------------------------------------------------
# LLD page definitions
# ---------------------------------------------------------------------------
def lld_pages():
    P = []

    # 01 — identity / onboarding / profile ---------------------------------
    P.append(build_lld(
        "p01", PAGES[0][1],
        "authentication (21 files) · profile (57 files, 28 screens) · membership · passport · "
        "legal · accessibility · localization · app_tour / app_guide",
        [
            ("UI · Screens & Widgets", "ui", [
                ("authentication/presentation", ["SplashScreen", "LoginScreen", "RegisterScreen",
                                                 "ForgotPasswordScreen", "VerifyEmailScreen",
                                                 "OnboardingScreen", "auth widgets (5)"], 1, 240),
                ("profile/presentation (28 screens)", ["ProfileScreen", "EditProfileScreen",
                                                       "PhotoManagerScreen", "SettingsScreen",
                                                       "PrivacySettingsScreen",
                                                       "NotificationSettingsScreen 🔒",
                                                       "LanguageSettingsScreen", "BlockedUsersScreen",
                                                       "AccountDeletionScreen", "PassportScreen 🔒",
                                                       "VerificationScreen", "…18 more"], 1, 240),
                ("guidance", ["app_tour (showcaseview)", "app_guide", "glass_demo",
                              "legal/LegalDocumentsScreen"], 1, 240),
            ]),
            ("State · BLoC", "state", [
                ("blocs", ["AuthBloc (event/state)", "ProfileBloc", "ProfileCubit",
                           "formz validators"], 1, 230),
                ("gates", ["onboarding_gate", "session_cache_gate", "access_control_service",
                           "early_access_service", "pre_sale_service",
                           "version_check_service"], 1, 230),
            ]),
            ("Domain", "domain", [
                ("entities", ["User", "UserProfile", "Membership", "Passport",
                              "AccessibilityPrefs", "LocaleEntity"], 1, 220),
                ("usecases", ["SignIn / SignUp", "SignOut", "GetCurrentUser",
                              "UpdateProfile", "UploadPhoto", "DeleteAccount",
                              "GetProfileById"], 1, 220),
                ("repository contracts", ["AuthRepository", "ProfileRepository"], 1, 220),
            ]),
            ("Data · Services", "data", [
                ("datasources", ["auth_remote_datasource", "auth_local_datasource",
                                 "profile_remote_datasource", "profile_local_datasource"], 1, 250),
                ("core services", ["user_directory_service", "photo_validation_service",
                                   "location_refresh_service", "web_geocoding_service",
                                   "city_coordinates_service", "legal_documents_service",
                                   "tier_gate / tier_entitlements", "usage_limit_service",
                                   "blocked_users_service", "presence_service"], 1, 250),
            ]),
            ("Firebase", "fb", [
                ("Auth", ["Email/password", "Google Sign-In", "Sign in with Apple",
                          "App Check attestation", "2FA (admin only)"], 1, 210),
                ("Firestore", ["users/{uid}", "profiles/{uid}", "nicknames/{nick}",
                               "user_passports", "memberships", "match_preferences",
                               "blockedUsers", "legalDocuments", "appConfig"], 1, 210),
                ("Storage", ["profiles/{uid}/…", "verifications/{uid}/…"], 1, 210),
            ]),
            ("Cloud Functions", "fn", [
                ("identity", ["cleanupOrphanedAuthUser", "onProfileDeleted",
                              "reverseGeocodeProfileLocation", "onUserCreatedSendWelcome",
                              "sendWelcomeEmail", "sendPasswordResetViaResend"], 1, 230),
                ("verification", ["startPhotoVerification", "verifyPhotoSelfie",
                                  "verifyIDDocument", "calculateTrustScore",
                                  "onVerificationStatusChange"], 1, 230),
                ("access control", ["approveUser / rejectUser", "updateUserTier",
                                    "getPendingUsers", "bulkApproveUsers",
                                    "getMvpAccessStats"], 1, 230),
            ]),
        ],
        "<b>Notes.</b> AuthWrapper in main.dart decides Splash → Login → Onboarding → MainNavigation. "
        "`nicknames/` is a uniqueness index written transactionally with the profile. "
        "Explore search is case-insensitive and prefix-matches on BOTH name and nickname "
        "(hence the `country_lower` / lowercase backfill scripts in functions/). "
        "Deleting an account must fan out: Auth user, profiles, users, media in Storage, and every "
        "denormalised copy (attendees, members, user_group_inbox) — `onProfileDeleted` owns this.<br>"
        "<b>Trap.</b> firestore.rules do not cascade into `users/{uid}/**` subcollections; each needs "
        "its own match block or writes silently fail."))

    # 02 — explore / discovery --------------------------------------------
    P.append(build_lld(
        "p02", PAGES[1][1],
        "explore · explore_map · globe_explore · discovery ⚪ · matching ⚪ · spots · "
        "saved_searches · recommendations · vibe_tags · cultural_exchange",
        [
            ("UI · Screens", "ui", [
                ("culture (default)", ["ExploreScreen (glass home)", "ExploreSearchScreen",
                                       "ExploreFiltersScreen", "ExploreMapScreen",
                                       "GlobeExploreScreen", "SpotsScreen / SpotDetail",
                                       "SavedSearchesScreen 🔒", "VibeTagsScreen",
                                       "CulturalExchange (3 screens)"], 1, 250),
                ("full flavor only ⚪", ["DiscoveryScreen (swipe cards)", "SwipeCardWidget",
                                        "MatchesScreen", "MatchCelebration",
                                        "FiltersScreen", "GridToggle"], 1, 250),
            ]),
            ("State · BLoC", "state", [
                ("blocs", ["ExploreMapBloc", "GlobeExploreBloc", "SpotsBloc", "VibeTagsBloc",
                           "CulturalExchangeBloc", "DiscoveryBloc ⚪", "SwipeBloc ⚪"], 1, 235),
            ]),
            ("Domain", "domain", [
                ("usecases", ["GetNearbyPeople", "SearchUsers (prefix, lowercase)",
                              "GetGlobeClusters", "GetSpots", "SaveSearch",
                              "GetCandidates ⚪", "SwipeUser ⚪", "GetMatches ⚪"], 1, 230),
                ("entities", ["ExploreFilter", "MapCluster", "Spot", "VibeTag",
                              "Candidate ⚪", "Match ⚪", "SwipeAction ⚪"], 1, 230),
            ]),
            ("Data · Services", "data", [
                ("services", ["candidate_pool_service", "interaction_log_service",
                              "location_refresh_service", "location_share_service",
                              "city_coordinates_service", "web_geocoding_service",
                              "content_filter_service", "data_preload_service"], 1, 250),
                ("client geo", ["geolocator 10", "geocoding 2.1",
                                "google_maps_flutter 2.5", "flutter_map 6.1 (OSM)"], 1, 250),
            ]),
            ("Firestore", "fb", [
                ("read paths", ["users (paged, indexed)", "profiles", "user_vectors",
                                "interaction_matrix", "user_interactions", "saved_searches",
                                "constellation", "city_coordinates"], 1, 220),
                ("dating-only ⚪", ["discovery_queue", "swipes", "likes", "matches",
                                   "blindMatches", "secondChancePool", "photo_likes"], 1, 220),
            ]),
            ("Cloud Functions", "fn", [
                ("candidate pool", ["precomputeCandidatePools", "triggerPoolRecompute",
                                    "getCandidatePoolStats"], 1, 230),
                ("presence", ["onPresenceUpdate", "cleanupStalePresence"], 1, 230),
                ("segmentation", ["calculateUserSegment", "createUserCohort"], 1, 230),
            ]),
        ],
        "<b>Notes.</b> In the default `culture` flavor there is no swipe deck: `exploreFirst` "
        "(= !enableSwipeDiscovery) makes the app shell mount the glass ExploreScreen at tab 0 and skip "
        "the `matches` listener, usage counters and the swipe-card tour anchors entirely. "
        "Everything dashed/⚪ above is dead code in the shipped build and must stay that way.<br>"
        "<b>Scale.</b> Nearby reads are server-ordered and paginated; candidate pools are precomputed "
        "server-side rather than scanned per request. Network grid filters use a matched-overlay so "
        "filtering never re-queries the whole collection."))

    # 03 — messaging -------------------------------------------------------
    P.append(build_lld(
        "p03", PAGES[2][1],
        "chat (74 files · 9 screens · 4 BLoC · 28 usecases) · group chat · conversation_expiry · "
        "icebreakers · stories · translation · presence",
        [
            ("UI · Screens", "ui", [
                ("chat/presentation", ["ConversationsListScreen", "ChatScreen (1:1)",
                                       "GroupChatScreen", "CreateGroupScreen",
                                       "GroupInfoScreen", "MediaViewerScreen",
                                       "VoiceRecorderSheet", "MessageSearchScreen",
                                       "ChatSettingsScreen"], 1, 245),
                ("widgets (12)", ["MessageBubble (+translation)", "TypingIndicator",
                                  "ReadReceipts", "ReplyPreview", "AttachmentPicker",
                                  "IcebreakerChips", "GroupTagSheet"], 1, 245),
            ]),
            ("State · BLoC", "state", [
                ("blocs (4)", ["ChatBloc", "ConversationsBloc", "GroupChatBloc",
                               "ConversationExpiryBloc"], 1, 230),
            ]),
            ("Domain (28 usecases)", "domain", [
                ("messaging", ["SendMessage", "SendGroupMessage", "GetMessages (paged)",
                               "MarkAsRead", "DeleteMessage", "EditMessage",
                               "ReactToMessage", "ReplyToMessage", "ScheduleMessage",
                               "SearchMessages"], 1, 230),
                ("conversation", ["GetConversations", "CreateConversation", "CreateGroup",
                                  "AddParticipants", "LeaveGroup", "MuteConversation",
                                  "PinConversation", "ArchiveConversation",
                                  "SetExpiry", "TagConversation"], 1, 230),
                ("media & voice", ["UploadChatImage", "UploadChatVideo",
                                   "SendVoiceMessage", "TranscribeVoice",
                                   "TranslateMessage 🔒", "SpeakMessage (TTS) 🔒",
                                   "BackupConversation", "ExportPdf"], 1, 230),
            ]),
            ("Data · Cache", "data", [
                ("datasources", ["chat_remote_datasource", "chat_local_datasource (Hive)",
                                 "group_chat_remote_datasource"], 1, 250),
                ("services", ["translation_service", "chat_learning_service",
                              "presence_service", "pronunciation_service (TTS cache)",
                              "content_filter_service", "blocked_users_service",
                              "vocabulary_tracking_service"], 1, 250),
            ]),
            ("Firestore / Storage", "fb", [
                ("1:1", ["conversations/{cid}", "conversations/{cid}/messages/{mid}",
                         "threads", "chat", "conversation_expiry", "message_reports"], 1, 220),
                ("groups", ["groups/{gid}", "groups/{gid}/members", "groups/{gid}/messages",
                            "user_group_inbox/{uid}/…", "user_group_tags/{uid}/…"], 1, 220),
                ("storage", ["chat_images/", "chat_videos/", "chat_voice/",
                             "group_media/", "group_voice/"], 1, 220),
            ]),
            ("Cloud Functions", "fn", [
                ("group fan-out", ["onGroupMessageCreated", "onGroupCreated",
                                   "onGroupParticipantsChanged", "onGroupInfoChanged",
                                   "onGroupDeleted"], 1, 235),
                ("messaging", ["translateMessage", "autoTranslateMessage",
                               "batchTranslateMessages", "getSupportedLanguages",
                               "scheduleMessage", "sendScheduledMessages",
                               "cancelScheduledMessage"], 1, 235),
                ("media", ["compressUploadedImage", "processUploadedVideo",
                           "generateVideoThumbnail", "transcribeVoiceMessage",
                           "markMediaAsDisappearing", "cleanupDisappearingMedia"], 1, 235),
                ("backup", ["backupConversation", "restoreConversation",
                            "exportConversationToPDF", "autoBackupConversations"], 1, 235),
                ("push", ["onNewMessagePush"], 1, 235),
            ]),
        ],
        "<b>Trace ①.</b> GroupChatScreen → SendGroupMessage → groups/{gid}/messages → "
        "`onGroupMessageCreated` fans out one small doc per member into `user_group_inbox/{uid}` → "
        "`onNewMessagePush` multicasts FCM. Members never query the group collection to build their "
        "list — that is the fan-out-on-write pattern that keeps group chat O(1) per reader.<br>"
        "<b>Rules.</b> Group chat is a SEPARATE collection from 1:1 `conversations` — never merge them. "
        "Chat-media upload paths in storage.rules must stay explicitly allowed (a lockdown broke this once).<br>"
        "<b>Cache.</b> Hive backs the message list for instant cold-start; pagination is required on "
        "every message query."))

    # 04 — events ----------------------------------------------------------
    P.append(build_lld(
        "p04", PAGES[3][1],
        "events (33 files · 7 screens) · external_events cache + sharded index + geohash · "
        "4 ingesters · reminders · broadcasts · likes · tickets",
        [
            ("UI · Screens", "ui", [
                ("events/presentation", ["EventsScreen (tabs)", "EventDetailScreen",
                                         "CreateEventScreen", "MyEventsScreen",
                                         "EventChatScreen", "TicketScreen (QR)",
                                         "AttendeesScreen"], 1, 240),
                ("widgets (9)", ["EventCard", "ExternalEventCard", "NearestFirstPager",
                                 "EventFilters", "AttendeeAvatars", "GoingTabList",
                                 "CapacityBadge"], 1, 240),
            ]),
            ("State", "state", [
                ("blocs", ["EventsBloc"], 1, 220),
                ("services", ["external_events_index_service", "city_coordinates_service",
                              "location_refresh_service"], 1, 220),
            ]),
            ("Domain", "domain", [
                ("entities", ["Event", "ExternalEvent", "Attendee", "Ticket"], 1, 215),
                ("operations", ["CreateEvent", "PublishEvent", "JoinEvent / Leave",
                                "LikeEvent", "ScanTicket", "BroadcastToAttendees",
                                "GetNearbyEvents (geohash)"], 1, 215),
            ]),
            ("Firestore", "fb", [
                ("first-party", ["events/{eid}", "events/{eid}/attendees",
                                 "events/{eid}/messages", "events/{eid}/broadcasts",
                                 "likes", "days / hours / rounds", "seasonal_events"], 1, 225),
                ("external cache", ["external_events/{id}", "external_events_index/{shard}",
                                    "external_country_stats", "city_coordinates"], 1, 225),
            ]),
            ("Cloud Functions", "fn", [
                ("ingesters (cron)", ["ingestExternalEvents (Viator)", "ingestTicketmaster",
                                      "ingestTiqetsAttractions", "runIngestGeoapifyNow",
                                      "runBackfillViatorCategoriesNow",
                                      "runBackfillGeoapifyWebsitesNow",
                                      "runCleanupNoImageNow"], 1, 240),
                ("index & geo", ["runBuildExternalIndexNow", "runBackfillGeohashNow",
                                 "runBackfillEventGeohashNow",
                                 "onEventWriteUpdateCountryStats"], 1, 240),
                ("lifecycle", ["autoPublishScheduledEvents", "sendEventReminders",
                               "onEventBroadcastCreated", "onEventMessageCreated",
                               "onEventLikeCreated / Deleted",
                               "onEventCreatedNotifyFollowers",
                               "onEventPublishedNotifyFollowers"], 1, 240),
                ("engagement", ["onEventAttendeeJoined", "onEventLiked", "onTicketScanned",
                                "onEventBoostStarted", "onEventCityAlert",
                                "syncCitySubscribers"], 1, 240),
            ]),
            ("External feeds", "ext", [
                ("sources", ["Geoapify (attractions, free key)", "Viator (tours)",
                             "Ticketmaster (ticketed)", "Tiqets (attractions)"], 1, 235),
                ("keys", ["GEOAPIFY_API_KEY", "stored in greengo-credentials.txt",
                          "never committed"], 1, 235),
            ]),
        ],
        "<b>Trace ③.</b> cron → per-source adapter → normalise into `external_events` (+ geohash) → "
        "`runBuildExternalIndexNow` rebuilds the sharded `external_events_index` → clients read the index "
        "cache-first and page nearest-first with server-side ordering. Clients never scan the raw feed.<br>"
        "<b>Open item.</b> The `attendees` collection-group index is required for the \"Going\" tab to "
        "resolve a user's events across all events — verify it exists in firestore.indexes.json before "
        "shipping changes to that tab."))

    # 05 — communities & business -----------------------------------------
    P.append(build_lld(
        "p05", PAGES[4][1],
        "communities (33 files, 16 widgets) · business (18 files, 9 screens) · roles & moderation · "
        "join approval · community events · announcements",
        [
            ("UI · Screens", "ui", [
                ("communities", ["CommunitiesScreen", "CommunityDetailScreen (tabbed)",
                                 "CreateCommunityScreen", "Tab · Chat", "Tab · Tips",
                                 "Tab · Announcements", "Tab · Events",
                                 "RulesSheet", "MembersSheet", "JoinRequestsSheet"], 1, 245),
                ("business", ["BusinessProfileScreen", "BusinessDashboardScreen",
                              "BusinessEventsScreen", "BusinessLeadsScreen",
                              "BusinessRatingsScreen", "VerificationRequestScreen",
                              "FollowersScreen", "…9 total"], 1, 245),
            ]),
            ("State", "state", [
                ("blocs", ["CommunitiesBloc"], 1, 225),
                ("roles", ["owner", "admin / moderator", "member", "pending (join approval)",
                           "banned"], 1, 225),
            ]),
            ("Domain", "domain", [
                ("entities", ["Community", "CommunityMember", "JoinRequest",
                              "Announcement", "CommunityEvent", "BusinessProfile"], 1, 225),
                ("operations", ["CreateCommunity", "RequestToJoin / Approve",
                                "PostAnnouncement", "ModerateMessage", "AssignRole",
                                "CreateCommunityEvent", "TranslateCommunityPost 🔒",
                                "FollowBusiness / Rate"], 1, 225),
            ]),
            ("Firestore", "fb", [
                ("communities", ["communities/{cid}", "communities/{cid}/members",
                                 "join_requests", "user_favorite_communities",
                                 "communities/{cid}/announcements",
                                 "communities/{cid}/events"], 1, 230),
                ("business", ["business_followers", "business_leads", "business_ratings",
                              "business_verification_requests", "user_business_following"], 1, 230),
                ("storage", ["communities/{cid}/…"], 1, 230),
            ]),
            ("Cloud Functions", "fn", [
                ("fan-out", ["onCommunityAnnouncementCreated", "onCommunityEventCreated",
                             "onCommunityEventPublished", "onCommunityEventChanged"], 1, 240),
                ("social notifications", ["onCommunityMemberJoined", "onBusinessFollowed",
                                          "onBusinessRated",
                                          "onEventCreatedNotifyFollowers",
                                          "onEventPublishedNotifyFollowers"], 1, 240),
            ]),
        ],
        "<b>Status.</b> Communities \"Core\" is fully shipped and deployed to production — tabbed detail "
        "(Chat / Tips / Announcements / Events), rules, roles &amp; moderation, join approval, community "
        "events and translation. Client + 3 Cloud Functions + firestore.rules are all live.<br>"
        "<b>Pattern.</b> Announcements and community events fan out to members on write rather than being "
        "polled — same shape as group chat. Member lists are subcollections with their own rule blocks."))

    # 06 — monetization ----------------------------------------------------
    P.append(build_lld(
        "p06", PAGES[5][1],
        "coins (37 files · 9 usecases · 9 entities) · membership / subscription · payments · "
        "referral · coupons · virtual_gifts ⚪ · premium · revenue analytics",
        [
            ("UI · Screens", "ui", [
                ("coins", ["ShopScreen (coin packs)", "CoinBalanceScreen",
                           "CoinHistoryScreen", "GiftCoinsScreen"], 1, 235),
                ("membership", ["MembershipScreen", "PaywallScreen",
                                "ReferralScreen", "premium widgets"], 1, 235),
            ]),
            ("State", "state", [
                ("blocs", ["CoinsBloc", "SubscriptionBloc"], 1, 225),
                ("TierGate — enforcement points",
                 ["hasValidMembership(profile)", "ensureValidMembership(ctx, profile)",
                  "ensureValidMembershipByUid(ctx, uid)", "ensureBoost(ctx, uid)",
                  "ensureTravelMode(ctx, uid)", "ensureAnalytics(ctx, uid)",
                  "canConnectToday / recordConnect", "showConnectLimitDialog"], 1, 265),
                ("TierLimitsService",
                 ["canCreateEvent(userId)", "canCreateGroup(userId)"], 1, 265),
                ("supporting", ["usage_limit_service", "subscription_expiry_service",
                                "access_control_service"], 1, 265),
            ]),
            ("Domain", "domain", [
                ("TierEntitlements — the single source of truth",
                 ["%s  —  %s" % (k, v) for k, v in TIER_LADDER], 1, 380),
                ("tiers", ["MembershipTier.base (free)", "MembershipTier.silver",
                           "MembershipTier.gold", "MembershipTier.platinum",
                           "+ business account flag"], 1, 380),
                ("coin usecases (9)", ["GetBalance", "SpendCoins", "PurchaseCoins",
                                       "GiftCoins", "ClaimReward", "GetTransactions",
                                       "ApplyPromotion", "CheckExpiry",
                                       "GrantMonthlyAllowance"], 1, 230),
            ]),
            ("Firestore", "fb", [
                ("coins — CANONICAL", ["coinBalances/{uid}", "coinTransactions/{id}",
                                       "coinOrders", "coinGifts", "coinPromotions",
                                       "claimedRewards"], 1, 235),
                ("coins — PHANTOM ⚠", ["coin_balances", "coin_transactions"], 1, 235),
                ("membership", ["memberships", "membership_purchases", "subscriptions",
                                "invoices", "transactions", "tierConfigs",
                                "usageLimits", "dailyUsage"], 1, 235),
                ("growth", ["coupons", "redemptions", "referrals", "referral_codes"], 1, 235),
            ]),
            ("Cloud Functions", "fn", [
                ("coin purchase", ["verifyGooglePlayCoinPurchase",
                                   "verifyAppStoreCoinPurchase", "giftCoins",
                                   "claimReward", "grantMonthlyAllowances",
                                   "processExpiredCoins", "sendExpirationWarnings"], 1, 240),
                ("membership", ["verifyPurchase", "checkExpiringMemberships",
                                "handleExpiredMemberships", "appStoreNotificationsV2",
                                "playStoreNotifications"], 1, 240),
                ("web payments", ["createStripeCheckoutSession", "stripeWebhook"], 1, 240),
                ("growth", ["redeemCoupon", "validateCoupon", "redeemReferral",
                            "applySignupGrants", "upsertCoupon", "listCoupons",
                            "getCouponRedemptions", "setCouponDisabled"], 1, 240),
                ("revenue analytics", ["getRevenueDashboard", "exportRevenueData",
                                       "forecastMRR", "getARPU", "getRefundAnalytics",
                                       "calculateTax", "getTaxReport", "detectFraud",
                                       "getCohortAnalysis", "trainChurnModel",
                                       "predictChurnDaily", "getAtRiskUsers"], 1, 240),
            ]),
            ("Stores / PSP", "money", [
                ("mobile", ["Google Play Billing 8.x", "Apple StoreKit",
                            "in_app_purchase 3.3", "server receipt verification"], 1, 225),
                ("web", ["Stripe Checkout", "stripe_web_checkout.dart",
                         "stripeWebhook (idempotent)"], 1, 225),
            ]),
        ],
        "<b>Trace ②.</b> Purchase → server-side receipt verification → transactional write to "
        "`coinBalances/{uid}` + an audit row in `coinTransactions`. Spending goes through "
        "tier_limits_service / usage_limit_service so entitlement and balance are checked in one place.<br>"
        "<b>⚠ Data-model split.</b> The client reads <b>camelCase only</b>. The snake_case "
        "`coin_balances` / `coin_transactions` functions are phantom leftovers — they are what blocks the "
        "full rule-lockdown of the coin collections. Do not add new writers to them. The blatant "
        "client-side mint in ShopScreen was already fixed (133c8a8); balances must only ever be moved by "
        "a Cloud Function.<br>"
        "<b>Web deploy.</b> Referral changes need `firebase deploy --only functions` — by name."))

    # 07 — notifications ---------------------------------------------------
    P.append(build_lld(
        "p07", PAGES[6][1],
        "notifications (24 files · 2 BLoC · 6 usecases) · FCM push · per-category preferences 🔒 · "
        "city alerts · Brevo email · in-app inbox",
        [
            ("UI", "ui", [
                ("screens", ["NotificationsScreen (inbox)",
                             "NotificationSettingsScreen 🔒", "NotificationDetail"], 1, 245),
                ("client plumbing", ["firebase_messaging 15", "flutter_local_notifications 18",
                                     "push_notification_service", "deep_link_service",
                                     "channel branded \"GreenGo\""], 1, 245),
            ]),
            ("State", "state", [
                ("blocs", ["NotificationsBloc", "NotificationSettingsBloc"], 1, 230),
                ("usecases (6)", ["GetNotifications", "MarkRead", "MarkAllRead",
                                  "DeleteNotification", "GetPreferences",
                                  "UpdatePreferences 🔒"], 1, 230),
            ]),
            ("Firestore", "fb", [
                ("paths", ["notifications/{uid}/items/{id}", "notification_preferences/{uid}",
                           "users/{uid}.fcmTokens[]"], 1, 235),
                ("city alerts", ["city subscriber index", "syncCitySubscribers output"], 1, 235),
            ]),
            ("Cloud Functions", "fn", [
                ("delivery core", ["onNotificationCreatedPush (parity)",
                                   "sendPushNotification", "sendBundledNotifications",
                                   "trackNotificationOpened", "getNotificationAnalytics"], 1, 245),
                ("triggers", ["onNewMessagePush", "onSupportMessagePush",
                              "checkExpiringModes", "onVerificationStatusChange"], 1, 245),
                ("social", ["onCommunityMemberJoined", "onEventAttendeeJoined",
                            "onBusinessFollowed", "onBusinessRated", "onEventLiked"], 1, 245),
                ("engagement", ["onProfileViewed", "onTicketScanned",
                                "onProfileBoostStarted", "onEventBoostStarted",
                                "checkBoostExpiries"], 1, 245),
                ("city alerts", ["syncCitySubscribers", "onEventCityAlert"], 1, 245),
            ]),
            ("Email", "ext", [
                ("Brevo (primary)", ["sendBrevoEmailFunction", "onUserCreatedSendWelcome",
                                     "onSubscriptionUpdated", "onPhotoModerationUpdated",
                                     "onAchievementUnlocked", "onPurchaseCreated",
                                     "sendBrevoWeeklyDigest", "sendBrevoReEngagement",
                                     "sendBrevoStreakReminder", "getBrevoEmailAnalytics"], 1, 235),
                ("SendGrid (legacy)", ["sendTransactionalEmail", "startWelcomeEmailSeries",
                                       "processWelcomeEmailSeries", "sendWeeklyDigestEmails",
                                       "sendReEngagementCampaign"], 1, 235),
                ("Resend", ["sendPasswordResetViaResend"], 1, 235),
            ]),
        ],
        "<b>Trace ④.</b> Any domain trigger writes `notifications/{uid}/items/{id}`; "
        "`onNotificationCreatedPush` is the single parity point that converts an inbox row into a push. "
        "The server-side `shouldNotify` gate reads `notification_preferences` — per-category preferences "
        "are a paid-tier feature, so free users take the default policy.<br>"
        "<b>⚠ Memory trap.</b> The functions index needs ~200 MB RSS just to load, so a function at or below "
        "256 MiB can be OOM-killed on cold start and <i>its trigger event is dropped silently</i> — this is "
        "what killed Android push once. Audited on 2026-07-21 across functions/src: 63 declarations sit at "
        "512 MiB (the push path), but <b>99 are still at 256 MiB and 17 at 128 MiB</b> "
        "(backup/, messaging/, notification/, notifications/brevoEmailService, safety/), and 53 of the 102 "
        ".ts files declare no memory at all. brevoEmailService carries 128 MiB declarations while also "
        "owning 13 email triggers — treat it as the next one to raise.<br>"
        "<b>Deploy.</b> Always deploy functions BY NAME — orphaned prod functions abort a full deploy."))

    # 08 — safety / admin --------------------------------------------------
    P.append(build_lld(
        "p08", PAGES[7][1],
        "safety · safety_academy · content moderation · reporting & appeals · identity verification · "
        "admin (28 files · 11 screens) · support · security audit",
        [
            ("UI", "ui", [
                ("user-facing safety", ["SafetyCenterScreen", "ReportUserScreen",
                                        "BlockedUsersScreen", "SafetyAcademy (3 screens)",
                                        "safety widgets (3)"], 1, 245),
                ("admin console (11)", ["AdminDashboardScreen", "UserManagementScreen",
                                        "ModerationQueueScreen", "ReportsScreen",
                                        "RevenueScreen", "SystemHealthScreen",
                                        "CouponsScreen", "BroadcastScreen",
                                        "SupportChatScreen", "RolesScreen",
                                        "MvpAccessScreen"], 1, 245),
            ]),
            ("State", "state", [
                ("blocs", ["AdminBloc", "SafetyAcademyBloc"], 1, 225),
                ("services", ["content_filter_service", "blocked_users_service",
                              "access_control_service", "api_key_service",
                              "interaction_log_service"], 1, 225),
            ]),
            ("Firestore", "fb", [
                ("safety", ["reports", "user_reports", "blockedUsers / blocked_users",
                            "message_reports", "album_access"], 1, 230),
                ("admin", ["admin_users", "admin_actions", "admin_audit_index",
                           "support_chats", "support_messages", "function_monitors"], 1, 230),
                ("storage", ["verifications/", "business_verification/",
                             "support_attachments/"], 1, 230),
            ]),
            ("Cloud Functions", "fn", [
                ("moderation", ["moderatePhoto", "moderateText", "detectSpam",
                                "detectFakeProfile", "detectScam"], 1, 240),
                ("reporting", ["submitReport", "reviewReport", "submitAppeal",
                               "blockUser", "unblockUser", "getBlockList",
                               "onUserReportCreated"], 1, 240),
                ("identity", ["startPhotoVerification", "verifyPhotoSelfie",
                              "verifyIDDocument", "calculateTrustScore"], 1, 240),
                ("admin · users", ["searchUsers", "getDetailedUserProfile",
                                   "editUserProfile", "suspendUserAccount",
                                   "banUserAccount", "deleteUserAccount",
                                   "overrideUserSubscription", "adjustUserCoins",
                                   "impersonateUser", "executeMassAction",
                                   "adminBulkDeleteUsers"], 1, 240),
                ("admin · queue & roles", ["getModerationQueue", "assignModerationItem",
                                           "takeModerationAction", "executeBulkModeration",
                                           "createAdminUser", "updateAdminRole",
                                           "updateAdminPermissions", "recordAdminLogin"], 1, 240),
                ("admin · panel", ["send2FACode", "verify2FACode",
                                   "adminChangeUserPassword", "forcePasswordChange",
                                   "adminSetUserDisabled", "processAISupportMessage",
                                   "onSupportChatCreated", "onSupportMessageCreated"], 1, 240),
                ("security audit", ["runSecurityAudit", "scheduledSecurityAudit",
                                    "getSecurityAuditReport", "listSecurityAuditReports",
                                    "cleanupOldAuditReports"], 1, 240),
            ]),
            ("On-device / AI", "ext", [
                ("ML Kit", ["face detection 0.13.2", "image labeling 0.14.2",
                            "mobile_scanner 7.x (Apple Vision)"], 1, 220),
                ("server AI", ["Vision moderation", "AI support replies"], 1, 220),
            ]),
        ],
        "<b>Blast radius.</b> Admin functions are the highest-privilege surface in the system "
        "(impersonateUser, adjustUserCoins, executeMassAction, adminBulkDeleteUsers). They must be "
        "guarded by `admin_users` role checks server-side — never by client-side routing — and every "
        "call writes to `admin_actions` / `admin_audit_index`.<br>"
        "<b>Rules regression watch.</b> The July-2026 storage/firestore lockdown broke chat-media upload, "
        "`users/**` subcollection writes and coin-gift notifications. Re-check those exact paths after "
        "any rules change; remember rules do NOT cascade into subcollections."))

    # 09 — gamification / language learning -------------------------------
    P.append(build_lld(
        "p09", PAGES[8][1],
        "gamification (57 files · 9 screens · 12 usecases · 12 entities) · language learning & lessons · "
        "vocabulary · pronunciation · word games · streaks & leaderboards",
        [
            ("UI", "ui", [
                ("gamification (9)", ["AchievementsScreen", "ChallengesScreen",
                                      "LeaderboardScreen", "LevelsScreen", "StreakScreen",
                                      "RewardsScreen", "MissionsScreen",
                                      "GameLobbyScreen", "GameRoomScreen"], 1, 240),
                ("learning", ["LessonsScreen", "LessonDetailScreen",
                              "VocabularyScreen", "PronunciationPractice 🔒",
                              "TranslationRaceScreen", "GrammarQuizScreen"], 1, 240),
            ]),
            ("State", "state", [
                ("blocs", ["GamificationBloc"], 1, 225),
                ("services", ["vocabulary_service", "vocabulary_tracking_service",
                              "visual_vocabulary_service", "pronunciation_service",
                              "chat_learning_service", "app_sound_service"], 1, 225),
            ]),
            ("Domain", "domain", [
                ("entities (12)", ["Achievement", "Challenge", "Mission", "Level",
                                   "XpTransaction", "Streak", "LeaderboardEntry",
                                   "Reward", "GameRoom", "GameWord", "Lesson",
                                   "VocabularyWord"], 1, 225),
                ("usecases (12)", ["GrantXp", "TrackAchievement", "ClaimReward",
                                   "TrackChallenge", "GetLeaderboard", "GetStreak",
                                   "JoinGameRoom", "SubmitAnswer", "PurchaseLesson",
                                   "UpdateLessonProgress", "GetProgressReport",
                                   "LookupWord"], 1, 225),
            ]),
            ("Firestore", "fb", [
                ("progress", ["achievement_progress", "challenge_progress",
                              "mission_progress", "user_levels", "xp_transactions",
                              "streaks", "claimedRewards"], 1, 230),
                ("games", ["game_rooms", "game_stats", "game_words", "game_invites",
                           "game_matchmaking", "game_grammar_questions",
                           "game_translation_race", "game_reported_words"], 1, 230),
                ("learning", ["lessons", "words", "vocabulary_words", "user_vocabulary",
                              "pronunciation_cache"], 1, 230),
                ("storage", ["pronunciation_audio/"], 1, 230),
            ]),
            ("Cloud Functions", "fn", [
                ("gamification", ["grantXP", "trackAchievementProgress",
                                  "unlockAchievementReward", "claimLevelRewards",
                                  "trackChallengeProgress", "claimChallengeReward",
                                  "resetDailyChallenges", "updateLeaderboardRankings",
                                  "refreshMyStats", "onMessageCreatedVocabulary"], 1, 245),
                ("language learning", ["submitTeacherApplication",
                                       "reviewTeacherApplication", "createLesson",
                                       "publishLesson", "purchaseLesson",
                                       "updateLessonProgress", "getLearningAnalytics",
                                       "getUserProgressReport", "getTeacherAnalytics",
                                       "getAdminLessons", "seedLessons", "deleteLesson",
                                       "updateLesson", "getLessonStats"], 1, 245),
            ]),
            ("Speech / TTS", "ext", [
                ("voice", ["Chirp 3 HD TTS (coin-gated + cached)", "flutter_tts (fallback)",
                           "record 5.2 / audioplayers 6.1",
                           "pronunciation_cache dedupes cost"], 1, 235),
            ]),
        ],
        "<b>Learning-by-doing.</b> Gamification is not a bolt-on: `onMessageCreatedVocabulary` mines real "
        "chat messages for vocabulary, which feeds `user_vocabulary` and the word games. That loop is the "
        "product thesis — XP comes from actually communicating across a language barrier.<br>"
        "<b>Cost control.</b> Chirp 3 HD TTS is coin-gated AND cached in `pronunciation_cache`; the "
        "per-tier `tierPerkTtsCost` decides the coin price. Never call TTS without checking the cache first.<br>"
        "<b>Leaderboards.</b> `updateLeaderboardRankings` is scheduled — never compute rankings by scanning "
        "users on read."))

    # 10 — media / video ---------------------------------------------------
    P.append(build_lld(
        "p10", PAGES[9][1],
        "media pipeline (image / video / voice) · video_calling (21 files · 7 usecases) · "
        "group calls & breakout rooms · video_profiles ⚪ · stories · disappearing media",
        [
            ("UI", "ui", [
                ("calls", ["VideoCallScreen", "IncomingCallOverlay", "GroupCallScreen",
                           "BreakoutRoomSheet", "CallControls (4 widgets)",
                           "CallHistoryScreen"], 1, 240),
                ("media", ["MediaViewer", "VoiceRecorder", "StoriesScreen",
                           "VideoProfileScreen ⚪", "VideoProfileRecorder ⚪"], 1, 240),
            ]),
            ("State", "state", [
                ("blocs", ["VideoCallingBloc", "VideoProfilesBloc ⚪"], 1, 225),
                ("client SDK", ["Agora RTC", "video_player 2.8", "record 5.2",
                                "flutter_image_compress 2.1", "image_picker 1.0",
                                "file_picker 10.1", "permission_handler 11"], 1, 225),
            ]),
            ("Domain (7 usecases)", "domain", [
                ("call lifecycle", ["InitiateCall", "AnswerCall", "EndCall",
                                    "HandleSignal", "UpdateQuality", "StartRecording",
                                    "GetCallHistory"], 1, 225),
            ]),
            ("Firestore / Storage", "fb", [
                ("call state", ["videoCoinBalances", "videoCoinTransactions",
                                "call signalling docs", "call history"], 1, 230),
                ("storage", ["chat_images/", "chat_videos/", "chat_voice/",
                             "group_media/", "group_voice/", "video_profiles/"], 1, 230),
            ]),
            ("Cloud Functions", "fn", [
                ("media pipeline", ["compressUploadedImage", "compressImage",
                                    "processUploadedVideo", "generateVideoThumbnail",
                                    "transcribeVoiceMessage", "transcribeAudio",
                                    "batchTranscribe", "markMediaAsDisappearing",
                                    "cleanupDisappearingMedia"], 1, 245),
                ("1:1 calls", ["initiateVideoCall", "answerVideoCall", "endVideoCall",
                               "handleCallSignal", "updateCallQuality",
                               "startCallRecording"], 1, 245),
                ("call features", ["enableVirtualBackground", "applyARFilter",
                                   "toggleBeautyMode", "enablePictureInPicture",
                                   "startScreenSharing", "stopScreenSharing",
                                   "toggleNoiseSuppression", "toggleEchoCancellation",
                                   "sendInCallReaction", "uploadCustomBackground",
                                   "getCallHistory", "getCallStatistics",
                                   "cleanupExpiredReactions"], 1, 245),
                ("group calls", ["createGroupVideoCall", "joinGroupVideoCall",
                                 "leaveGroupVideoCall", "manageGroupParticipant",
                                 "changeGroupCallLayout", "createBreakoutRoom",
                                 "joinBreakoutRoom", "closeBreakoutRoom"], 1, 245),
            ]),
        ],
        "<b>iOS pod constraint.</b> Firebase 11 requires GoogleDataTransport ~&gt;10. Keep ML Kit on the "
        "GoogleMLKit 9.0 generation (face 0.13.2 / image labeling 0.14.2) and mobile_scanner 7.x "
        "(Apple Vision — pulls no MLKit pod) or the Podfile will not resolve. This is verifiable from the "
        "pub-cache podspecs and the CocoaPods CDN without a Mac.<br>"
        "<b>Media cost.</b> Uploads are compressed server-side after write, never trusted from the client; "
        "thumbnails and transcriptions are derived assets with their own lifecycle "
        "(`cleanupDisappearingMedia` is scheduled)."))

    # 11 — platform / devops ----------------------------------------------
    P.append(build_lld(
        "p11", PAGES[10][1],
        "build flavors · CI/CD · security rules matrix · indexes · Terraform · Docker · testing · "
        "GCP enterprise migration path",
        [
            ("Build & Release", "infra", [
                ("flavors", ["main.dart → culture (default)",
                             "main_full.dart → full (opt-in)",
                             "main_preview.dart (design)",
                             "flutter build apk --target lib/main_full.dart"], 1, 250),
                ("versioning", ["v3.0.0+101 (Apple repositioning)",
                                "iOS build no. must exceed 90",
                                "check HEAD pubspec for true versionCode",
                                "greengo-release.keystore"], 1, 250),
                ("codemagic.yaml", ["iOS TestFlight Beta", "Web Build & Deploy",
                                    "Android APK Build", "Flutter 3.44.4 + disable SPM"], 1, 250),
            ]),
            ("Security & Rules", "safety", [
                ("rule files", ["firestore.rules", "firestore.rules.production",
                                "storage.rules", "storage.rules.production",
                                "firestore.indexes.json"], 1, 235),
                ("must stay allowed", ["chat media upload paths",
                                       "users/{uid}/** subcollection writes",
                                       "coin-gift notification writes"], 1, 235),
                ("hardening", ["App Check", "api_key_service", "2FA for admins",
                               "security_audit/ suite", "scheduledSecurityAudit"], 1, 235),
            ]),
            ("Infrastructure", "infra", [
                ("Terraform", ["terraform/main.tf", "modules/cloud_functions",
                               "modules/kms", "modules/storage",
                               "terraform/microservices/*"], 1, 235),
                ("Docker (local)", ["firebase emulators", "postgres", "redis",
                                    "adminer", "redis-commander", "nginx",
                                    "docker-compose.prod.yml"], 1, 235),
                ("Aux backend", ["backend/ (Python, manage.py)", "devops/", "scripts/"], 1, 235),
            ]),
            ("Quality", "infra", [
                ("test suites", ["test/ (unit + widget)", "integration_test/",
                                 "functions/__tests__ (jest)", "firebase_test_lab.sh",
                                 "generate_html_report.dart"], 1, 235),
                ("observability", ["Crashlytics", "Performance Monitoring",
                                   "Firebase Analytics", "function_monitors",
                                   "admin System Health metrics"], 1, 235),
            ]),
            ("Deploy runbook", "fn", [
                ("order", ["1 · flutter gen-l10n",
                           "2 · deploy firestore.rules + indexes",
                           "3 · deploy storage.rules",
                           "4 · firebase deploy --only functions:<NAME>",
                           "5 · build + upload app / firebase hosting",
                           "6 · adb uninstall before install (Android)"], 1, 255),
                ("gotchas", ["deploy functions BY NAME (orphans abort)",
                             "NODE_TLS_REJECT_UNAUTHORIZED=0 behind corp TLS proxy",
                             "AVG TLS MITM blocks Gradle downloads",
                             "restore 3 gitignored configs on fresh clone"], 1, 255),
            ]),
            ("Future — GCP migration", "ext", [
                ("approved 2026-07-07", ["hybrid strangler-fig (keep Firestore)",
                                         "AlloyDB (relational core)",
                                         "GKE Autopilot (services)",
                                         "Pub/Sub (events)",
                                         "Terraform + Argo CD",
                                         "8 phases · docs/migration/"], 1, 245),
            ]),
        ],
        "<b>Fresh-clone build.</b> Three gitignored configs must be restored before anything builds: "
        "`firebase_options.dart`, `google-services.json`, and the release keystore. Keys live in the "
        "credentials file, never in git.<br>"
        "<b>Runnable is the bar.</b> A change is not done when it compiles — the app must boot and "
        "smoke-test. On Android always `adb uninstall` before installing, and disable Impeller on "
        "emulators (it renders black); `adb screencap` cannot capture the Flutter surface.<br>"
        "<b>Scale posture.</b> Everything here is designed to reach millions of users: pagination, "
        "denormalisation, batched fan-out and per-user indexed reads are mandatory, not optional."))

    return P


# ---------------------------------------------------------------------------
def main():
    pages = [build_master()] + lld_pages()
    body = "".join(pg.xml() for pg in pages)
    xml = ('<mxfile host="app.diagrams.net" agent="GreenGo architecture generator" '
           'version="24.7.17" type="device">\n' + body + '</mxfile>\n')
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(xml)
    cells = sum(len([c for c in pg.cells if c]) for pg in pages)
    print("wrote %s" % OUT)
    print("pages: %d   cells: %d   cloud functions catalogued: %d"
          % (len(pages), cells, FN_TOTAL))


if __name__ == "__main__":
    main()
