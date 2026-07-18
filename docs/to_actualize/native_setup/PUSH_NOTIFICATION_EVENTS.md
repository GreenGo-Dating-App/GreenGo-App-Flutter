# GreenGo — Events That Trigger a Push Notification

Every event below fires an FCM push (and, in most cases, also writes an in-app
`notifications` doc). Sources are Cloud Functions in `functions/src/**`.
Verified against the codebase on 2026-07-17.

> **Branding:** user-facing pushes show the title **"GreenGo"**; the specific
> text (old title + body, merged) is the notification body — see
> `functions/src/notifications/brand.ts` (`brandPush`).
>
> **Delivery mechanics:** a push reaches a user only if that user has an
> `fcmToken` saved (`profiles/{uid}.fcmToken` / `users/{uid}.fcmToken`) and, on
> iOS, has granted notification permission. See `PUSH_NOTIFICATIONS.md`.

Trigger types: **📄 Firestore** (fires on a document write) · **⏰ Scheduled**
(cron) · **📞 Callable** (invoked by the app/admin).

---

## 💬 Messaging
| Event | Trigger | Function | Channel |
|---|---|---|---|
| New 1:1 chat message | 📄 `conversations/{}/messages/{}` onCreate | `onNewMessagePush` | `greengo_notifications` |
| New group chat message | 📄 `groups/{}/messages/{}` onCreate | `onGroupMessageCreated` | `greengo_notifications` |
| Support/admin reply to user | 📄 onCreate | `onSupportMessagePush` | `greengo_notifications` |
| Scheduled message becomes due | ⏰ `sendScheduledMessages` | messaging/scheduledMessages | `greengo_notifications` |
| Auto-translation of an incoming message | 📄 `autoTranslateMessage` | messaging/translation | (in-app; push via parity) |

## 📅 Events
| Event | Trigger | Function | Channel |
|---|---|---|---|
| New event in a community | 📄 `communities/{}/events/{}` onCreate | `onCommunityEventCreated` | `greengo_notifications` |
| Community event published (draft → live) | 📄 onUpdate | `onCommunityEventPublished` | `greengo_notifications` |
| Community event changed (time/place) or cancelled | 📄 onUpdate | `onCommunityEventChanged` | `greengo_notifications` |
| Business posts a new event → notify followers | 📄 onCreate | `onEventCreatedNotifyFollowers` | `greengo_notifications` |
| Business event published → notify followers | 📄 onUpdate | `onEventPublishedNotifyFollowers` | `greengo_notifications` |
| Event broadcast (organizer → all attendees) | 📄 onCreate | `onEventBroadcastCreated` | `greengo_notifications` |
| New message in an event chat | 📄 onCreate | `onEventMessageCreated` | `greengo_notifications` |
| Event reminder (upcoming event you're going to) | ⏰ `sendEventReminders` | events/reminders | `greengo_notifications` |
| Someone RSVPs / joins your event | 📄 `events/{}/attendees/{}` onCreate | `onEventAttendeeJoined` | `greengo_notifications` |
| Someone likes your event | 📄 onCreate | `onEventLiked` | `greengo_notifications` |
| Your event ticket is scanned at the door | 📄 onUpdate | `onTicketScanned` | `greengo_notifications` |

## 🏘️ Communities
| Event | Trigger | Function | Channel |
|---|---|---|---|
| New community announcement | 📄 `communities/{}/announcements/{}` onCreate | `onCommunityAnnouncementCreated` | `greengo_notifications` |
| Someone joins your community | 📄 `communities/{}/members/{}` onCreate | `onCommunityMemberJoined` | `greengo_notifications` |

## 👤 Social & Engagement
| Event | Trigger | Function | Channel |
|---|---|---|---|
| Someone views your profile | 📄 onCreate | `onProfileViewed` | `greengo_notifications` |
| Someone follows your business | 📄 onCreate | `onBusinessFollowed` | `greengo_notifications` |
| Someone rates your business | 📄 onCreate | `onBusinessRated` | `greengo_notifications` |
| Your profile boost started | 📄 onUpdate | `onProfileBoostStarted` | `greengo_notifications` |
| Your event boost started | 📄 onUpdate | `onEventBoostStarted` | `greengo_notifications` |
| A boost is about to expire | ⏰ `checkBoostExpiries` (hourly) | engagementNotifications | `greengo_notifications` |
| Trial/subscription mode expiring | ⏰ `checkExpiringModes` | pushNotificationTriggers | `greengo_notifications` |

## 🛡️ Account & Admin
| Event | Trigger | Function | Channel |
|---|---|---|---|
| **Account approved** (one-time, on approval only) | 📞 `approveUser` (admin) | admin/mvp_access | `greengo_notifications` |
| Business verification status changes | 📄 onUpdate | `onVerificationStatusChange` | `greengo_notifications` |
| Admin broadcast to all/segment | 📞 `sendBroadcastNotification` | admin/mvp_access | `greengo_broadcasts` |
| Admin sends a direct message to a user | 📞 `sendNotificationToUser` | admin/mvp_access | `greengo_notifications` |
| Bundled activity summary | 📞 `sendBundledNotifications` | notification/index | `bundled_notifications` |
| Generic push (server/API triggered) | 📞 `sendPushNotification` | notification/index | `default` / `greengo_notifications` |

> **Account approved is one-time.** It fires only from the admin `approveUser`
> action, never on login. It no longer writes an in-app feed doc (removed
> 2026-07-17) — only the single push — so it never re-surfaces in the list.

## 🔁 Universal fallback — `onNotificationCreatedPush` (pushParity)
📄 Fires on **any** `notifications/{}` doc created **without** `pushSent: true`.
It delivers a push for notification types that write a doc but don't send their
own push (coin gifts, gamification rewards, subscription changes, admin-index
notifications, etc.). This is the safety net that guarantees "every in-app
notification also pushes." Producers that send their own push stamp
`pushSent: true` to avoid a double-push.

## 🚫 Not active
| Area | Status |
|---|---|
| Video/voice call invites (`video_calling/*`) | Code present but **disabled** (Agora commented out in pubspec) — channel `video_calls` |
| Dating-style like/match/super-like | **Removed** (repositioned product); legacy docs are filtered client-side |
| Security-audit alerts (`securityAudit`) | Internal/admin only, not a normal user push |

---

## How to add a new push event
1. Write the `notifications/{}` doc (and set `pushSent: true` only if you send your own push).
2. If you send your own push, wrap the top-level `notification` in `brandPush(title, body, imageUrl)` and set a valid `channelId` that the client registers (see `push_notification_service.dart`).
3. Add a routing case in `push_notification_service._navigateFromNotificationData` + `deep_link_service.dart` so the tap opens the right screen.
4. Add the row to this table.

*Companion: `PUSH_NOTIFICATIONS.md` (setup/runbook) · `DEEP_LINKING.md` (tap routing).*
