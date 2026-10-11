# Screenshot, screen-recording and image-theft protection

Owner request: no screenshots of the app, on mobile and on web. This page
says exactly what is **blocked**, what is only **detected**, and what is only
**deterred** on each platform, and what is still open.

Code entry point: `lib/core/security/screen_security_service.dart`
(channel `greengo/screen_security`).

## Per platform

| | Blocked (the capture is black/blank) | Detected (reported, not stopped) | Deterred (best effort) |
|---|---|---|---|
| **Android** | `FLAG_SECURE` app-wide, set in `MainActivity.onCreate` before the first frame: screenshots, screen recordings, casting to non-secure displays, recents thumbnail | Android 14+: screenshots via `ScreenCaptureCallback` (only fires while FLAG_SECURE is off, i.e. after the kill-switch). Android 15+: screen-recording state (`addScreenRecordingCallback`) | Capture cover overlay while a recording is reported |
| **iOS** | Secure-layer technique (window layer hosted inside a `UITextField(isSecureTextEntry)` canvas): screenshots, recordings, mirroring/AirPlay, app-switcher snapshot render blank. **Needs a Mac/device to verify** | `userDidTakeScreenshotNotification` (chat gets "X took a screenshot"); `UIScreen.capturedDidChangeNotification` / `isCaptured` | Full-screen blur + "Screen recording is not allowed" cover while captured |
| **Web** | Nothing can be blocked by a web page (OS shortcuts, phone cameras, external recorders never reach it) | PrintScreen key, print, save-page, Firefox screenshot shortcut, window blur / tab hidden | CSS blur + opaque cover when the window loses focus or the tab is hidden (defeats most snipping tools, which take focus first); clipboard cleared after PrintScreen where permitted; Ctrl/Cmd+P and Ctrl/Cmd+S swallowed; printing renders a blank page; no context menu / drag / iOS callout on media; viewer watermark on every photo; private albums and ID verification are app-only |

## Watermark

`ViewerWatermark` (lib/core/security/viewer_watermark.dart) tiles
`@nickname · uid-prefix` of the **viewer** diagonally over the image, so a
leaked capture or phone photo of the screen is traceable to the account that
leaked it.

- All platforms: other people's private album photos (grid + full screen),
  chat and group full-screen images, the admin ID-selfie viewer.
- Web only: the profile photo carousel (every photo on web).

## App-only on web

`isAppOnlyContentBlocked()` / `AppOnlyContentScreen` show "Open in the
GreenGo app to view" (button -> https://greengochat.com/app) instead of:

- another user's shared private album (`ChatScreen._viewOtherUserAlbum`);
- ID / age verification (`AgeVerificationScreen`) and the re-verification
  selfie (`ReverificationScreen`). Consequence: on web a user cannot complete
  ID age assurance; flows that require it (publishing, regional assurance)
  send the user to the app.

Not gated: the onboarding selfie step (`Step3VerificationScreen`) is the
user's OWN capture and is mandatory for web sign-up; gating it would lock web
users out. The admin review screen stays usable on web but is watermarked.
"Disappearing media" does not exist in the app yet; when it is built it must
call `isAppOnlyContentBlocked()` too.

## Screenshot notice in chats

`ChatScreenshotNotice` writes a client system line (`type: system`,
`metadata.systemKey = screenshotTaken`, `systemParams.name`) to
`conversations/{id}/messages` or `groups/{id}/messages`, as the person who
took the screenshot (rules allow members to post as themselves only), with an
English `content` fallback. Throttled to one line per chat per 30 s.
Rendered via `chatSystemText` in the reader's language (7 ARBs).

## Kill-switch

`app_config/feature_flags.flags.screenProtection` (default `true`). Off:
FLAG_SECURE cleared, iOS secure field set non-secure (and the next launch
does not install the layer at all: persisted in UserDefaults
`gg_secure_layer_off`), no cover, web shim disabled. Info.plist
`GGSecureLayerDisabled = YES` disables the iOS layer in a build.

## iOS secure layer: risks to check on a device

- Depends on private UIKit layer order (canvas = first sublayer before
  iOS 17, last since). Unknown structure -> not installed (unprotected,
  never broken). If a future iOS shows black on the device itself: flip the
  kill-switch, users recover on next launch.
- Check: rotation / iPad split view, keyboard + AutoFill on password fields,
  Google Maps / video platform views, status-bar taps, app-switcher snapshot,
  screen recording from Control Center, QuickTime mirroring.

## Short-lived media URLs

Photos and chat media are stored as Firebase download URLs
(`...?alt=media&token=...`): a permanent bearer credential that bypasses
Storage rules.

**Done (private albums):** `getSharedAlbum` now returns V4 signed URLs valid
10 minutes for photos in the owner's own `profiles/{ownerId}/` folder
(`signAlbumUrls`; anything else, e.g. a `verifications/` path an owner might
plant in their album, is never signed). Signing failure falls back to the
stored URL (previous behaviour). The app caches by object path
(`stableMediaCacheKey`), so the image cache still works. The owner keeps
reading their own album from `profiles_private`.
Deploy BY NAME: `firebase deploy --only functions:getSharedAlbum`.
Prerequisite (already needed by `getMediaUrl` / `getVerificationPhotoUrl`):
runtime service account has `roles/iam.serviceAccountTokenCreator` on itself.

**Plan (chat media, not done - would break old clients today):**

1. Client: resolve every `chat_images/`, `chat_videos/`, `chat_voice/`,
   `group_media/`, `group_voice/`, `support_attachments/` URL through the
   existing `getMediaUrl` callable at display time (cache the signed URL until
   `expiresAt`, image cache keyed by `stableMediaCacheKey`), falling back to
   the stored URL on any error. Ship and wait for adoption.
2. Bump the minimum supported version; new messages store the object PATH in
   `metadata.mediaPath` and no token URL in `content`.
3. Backfill script: rewrite old messages to path-only and revoke the download
   tokens (`firebaseStorageDownloadTokens` metadata) of chat-media objects.
4. Private album photos shared INTO a chat (`_sendAlbumPhotosSequentially`)
   currently copy the permanent album URL into the message; after step 2 they
   must be sent as paths too.
5. Storage rules: once nothing reads private album photos by SDK, restrict
   `profiles/{uid}/**` reads of objects with `metadata.visibility == 'private'`
   to the owner.
