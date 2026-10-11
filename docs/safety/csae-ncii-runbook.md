# CSAE and NCII runbook

Owner: Trust & Safety (T&S). Last reviewed: 2026-10-11. Covers audit items BR-11, US-09 (NCII), US-10, BR-14, AS-08 and EU-19 (CSAE).

This runbook describes what the system does on its own, what the on-call moderator does, and what only the owner or superAdmin can do. Everything in the admin panel is under **Safety** (`/safety`).

## 1. Who is on call

| Role | Who | How they are reached |
|---|---|---|
| Primary on-call moderator | _fill in (name, phone)_ | P0 email + in-app admin notification |
| Backup / escalation | _fill in_ | The 1-hour escalation email |
| superAdmin (legal holds, NCMEC/PF reports) | Owner | Same emails; `greengochat.com@gmail.com` always receives them |
| Legal counsel (BR / US / EU) | _fill in_ | Phone, for law-enforcement requests and EU-19 decisions |

Alert recipients are `SECURITY_ALERT_EMAILS` (functions env), plus `greengochat.com@gmail.com`, plus `app_config/safety_settings.onCallEmails` (array, editable in Firestore). Set `app_config/safety_settings.adminPanelUrl` if the panel is not at `https://greengo-chat-admin.web.app`.

Alert emails never contain names, email addresses, uids, content links or descriptions. They contain only a short case id, the stage and the deadline.

## 2. Deadlines

| Case | Content hidden | Escalation alert | Target decision | Legal maximum |
|---|---|---|---|---|
| NCII (TAKE IT DOWN Act, Decreto 12.976/2026) | On submission, automatically | 1 h | **2 h** (Brazil) | **48 h** (US) |
| CSAE (18 USC 2258A, Lei 15.211/2025) | On report or hash match, automatically | 1 h | 24 h for the decision; report to NCMEC / PF **as soon as reasonably possible** | n/a |

`safetySlaSweep` runs every 10 minutes and sends one email per stage: 1 h escalation, 2 h breach, 48 h legal breach. A case stops escalating as soon as it is decided.

## 3. NCII (non-consensual intimate imagery)

### 3.1 How requests arrive
- **Public web form** (people without an account): `POST` to the `nciiTakedownRequest` function from the greengochat.com page. The form collects name, email, optional phone, whether the requester is the depicted person or acting for them, where the content is, a description, three statements (depicted or authorized; good-faith belief it was published without consent; accuracy) and a typed signature. These are the TAKE IT DOWN Act §3(a)(1)(B) elements. Limits: 5 per hour and 20 per day per IP, 5 per day per email, 300 per hour in total; a honeypot field drops bots. The requester gets an email with a confirm link and a status link (token-based, no account needed).
- **In the app**: Help & Support → "Remove an intimate image of me"; the report sheet on chat media, group and event chats and video profiles; the "⋮" menu on profiles. These use `submitSafetyRequest`, limited to 5 per day per user.
- **User reports** with the reason "Intimate image shared without consent" (or matching keywords) open an NCII case automatically.
- **Hash match**: a re-upload of a removed image to a public surface opens an NCII case on its own (§5).

### 3.2 What the system does at once
1. Every Storage object the request points at is moved to `safety_holds/{caseId}/…`. Old download links stop working immediately.
2. The photo URL is removed from `profiles/{uid}.photoUrls` and `privatePhotoUrls` (and from `profiles_private`).
3. A reported chat message is replaced by the "removed by a moderator" placeholder. The original fields are kept in `safety_cases/{id}/evidence`.
4. The image's perceptual hashes (dHash and pHash) and exact hashes go into `blocked_media_hashes` as *provisional*, so re-uploads are blocked while the case is reviewed.
5. A P0 email goes out, and in-app notifications are sent to admins.

Links the server cannot resolve (for example external sites) are listed in the case as **unresolved**. The moderator handles them manually. For external sites, send a removal request to that host or search engine.

### 3.3 Moderator steps (target: under 2 h)
1. Open Safety → NCII. The list is sorted by deadline.
2. Open the case. Check the requester details and statements. "View held content" gives 5-minute links; every view is logged.
3. Decide:
   - **Confirm removal**: the held copy is deleted, the hash becomes a permanent block, and the uploader gets a strike. Choose a sanction: strike only, suspend for 30 days, or ban (repeat or malicious uploads). The uploader receives a statement of reasons and can appeal (DSA art. 17/20). The requester is told the content was removed.
   - **Restore**: only when the request is clearly invalid (for example the requester is not the person shown and is not authorized, or the content is not intimate). Everything is put back and the hash block is lifted. The requester is told by email or in-app. Write the reason in the notes.
4. If the same person has more copies elsewhere, ask the requester for the links. Each new link is a new request.

### 3.4 Abuse of the process
Hiding happens before review, so a false request can hide someone's photo for up to 2 hours. Restore it quickly. Repeated false requests from the same email or IP are a ToS violation; record them in the notes. Rate limits cap volume.

## 4. CSAE (child sexual abuse / exploitation)

### 4.1 Triggers
- A user report with the reason "Child sexual abuse or exploitation", or CSAE keywords anywhere in the report text.
- A hash match on a **public** upload against `csam_hash_list` (§5).

### 4.2 What the system does at once
1. Hides the reported content: chat message placeholder and media moved, or all profile photos for a profile report.
2. Opens a **1-year legal hold** `legal_holds/csae_{uid}` and copies into it:
   - the user's `users`, `profiles`, `profiles_private` and `age_assurance` docs and the Auth record (email, phone, creation and last sign-in);
   - reports about the user, moderation items, image-moderation verdicts and strikes;
   - access logs (`access_logs`), once BR-09 logging exists;
   - every file under the user's Storage prefixes, plus the hidden content.
3. Sends a P0 email.

**Account deletion does not destroy evidence.** `deleteMyAccount`, the website deletion and `onUserDeletedCleanup` refresh the hold first. If the refresh fails, nothing is deleted. Moderation records about the user are kept while the hold is active.

### 4.3 Moderator steps
- **Do not open, download, forward, screenshot or email any image.** The panel never shows CSAE content. Decide from the report, the hash-match type and the metadata.
- **Confirm** (usually with **ban**): the copies move into the legal hold. The suspect is **not** notified, to avoid tipping them off.
- **Restore** is superAdmin-only (for example a confirmed false positive from a perceptual hash match).

### 4.4 Reporting (superAdmin)
1. Safety → open the case → **Generate report package** for NCMEC, PF_BR or SAFERNET. The package (JSON) holds the case timeline, reported-person identifiers, account dates, IP logs if any, file list with hashes, and the legal-hold Storage paths. It is stored under `legal_holds/{holdId}/report_packages`. Nothing is sent automatically.
2. **NCMEC CyberTipline** (US law; also a Google Play requirement): submit through the ESP portal or API with the registered ESP account. Upload the files from `legal_holds/{holdId}/files/` through the portal only. Then use **Mark reported** to record the CyberTipline report number.
3. **Brazil**: report to the Polícia Federal through its online channel for crimes against children (or the channel set by Decreto 12.882/2026), and/or to **SaferNet Brasil** (https://new.safernet.org.br/denuncie). Give identifiers and metadata. Arrange delivery of the media only through the channel the authority specifies. Record the protocol number with **Mark reported**.
4. Answer law-enforcement preservation and production requests from the hold. Use **Extend hold** when an investigation needs the data for longer than 1 year.

### 4.5 Retention
Holds last 365 days (REPORT Act). `legalHoldExpirySweep` runs daily and marks expired holds `expired_pending_purge` with an alert. It deletes preserved data only when counsel has set `app_config/safety_settings.autoPurgeExpiredHolds = true`.

## 5. Hash matching (scope: EU-19)
- **Scanned**: public uploads only. That means profile photos (not private-album photos), community media, storefronts, video-profile thumbnails and event covers (`profiles/`, `communities/`, `storefronts/`, `video_profiles/`).
- **Not scanned, for anyone**: private chat, group and support images. The EU derogation for voluntary scanning of private messages (Reg. 2021/1232) lapsed on 3 Apr 2026. Do not enable scanning there until counsel decides. Reports of private content still work, because a report is not scanning.
- **Lists**:
  - `blocked_media_hashes`: images we removed ourselves.
  - `csam_hash_list`: external lists imported by a superAdmin through `safetyAdmin {op:'importCsamHashes'}`. Supported entries: md5, sha1 and sha256 (exact); dhash and phash (our 64-bit format). PDQ and PhotoDNA entries are stored but not matched yet.
- **Matching**: a perceptual match needs both dHash ≤ 7 and pHash ≤ 12 bits apart. Near-blank images are matched exactly only.
- **Google Content Safety API**: stub in `functions/src/safety/takedowns/contentSafetyApi.ts`, off unless `CONTENT_SAFETY_API_ENABLED=true` and `CONTENT_SAFETY_API_KEY` are set.

## 6. Owner steps (not done in code)
1. **Register GreenGo as an ESP with NCMEC** (CyberTipline reporting account; espteam@ncmec.org). Record the ESP id in this runbook.
2. Apply for **NCMEC hash-sharing** and/or industry lists (Tech Coalition / Thorn Safer), and for the **Google Content Safety API**. Import hashes with `importCsamHashes`.
3. Set the **Play Console child-safety contact** and keep the published CSAE standards page up to date (AS-08).
4. Fill in the on-call table (§1) and `app_config/safety_settings.onCallEmails`.
5. Publish the public NCII form on greengochat.com. It posts JSON to the `nciiTakedownRequest` URL. Set `NCII_ENDPOINT_URL` to that URL so email links point to it.
6. Counsel: confirm the Decreto 12.976 and 12.882 channels and deadlines (the audit took them from law-firm summaries), EU-19 private scanning, and `autoPurgeExpiredHolds`.
7. Enable Marco Civil access logging (BR-09), so report packages contain IP and port logs.

## 7. Evidence-handling rules
- Only a superAdmin can see a legal hold, and every view is audit-logged (`admin_audit_log` → security email).
- Never move CSAM out of the hold except through the authority's channel. Never attach it to email or chat.
- Every case keeps an audit trail in `safety_cases/{id}/audit`, recording who did what and when.
