# Wallet passes — Apple Wallet & Google Wallet event tickets

Server-side generation of a signed event ticket that attendees can add to
**Apple Wallet** (`.pkpass`) or **Google Wallet** ("Save to Google Wallet"
link). Both encode the same barcode payload as the in-app QR ticket, so the
organizer's existing check-in scanner validates them unchanged:

```
greengo:{"e":"<eventId>","u":"<userId>"}
```

Two callables (both require Firebase Auth; both verify the caller is a *going*
attendee of `events/{eventId}`):

| Function                 | Input                   | Output                                   |
|--------------------------|-------------------------|------------------------------------------|
| `getAppleWalletPass`     | `{ eventId, userId }`   | `{ pkpass: <base64 .pkpass>, fileName }` |
| `getGoogleWalletSaveUrl` | `{ eventId, userId }`   | `{ saveUrl: "https://pay.google.com/gp/v/save/<jwt>" }` |

> **Status: INERT until provisioned.** The code compiles and deploys without
> any certificates. Each function throws a descriptive *"…not configured"*
> error at call time until its secrets are set (the client then shows the
> generic `walletError` snackbar). Search the source for `TODO(provisioning)`.

---

## 1. Apple Wallet provisioning

You need an Apple Developer Program membership.

1. **Create a Pass Type ID**
   - Apple Developer → Certificates, Identifiers & Profiles → *Identifiers* →
     add a **Pass Type IDs** identifier, e.g. `pass.com.greengo.eventticket`.
2. **Create the Pass Type ID certificate**
   - Generate a CSR (Keychain Access → *Request a Certificate From a Certificate
     Authority*), upload it, download the resulting `pass.cer`.
   - Import `pass.cer` into Keychain, then export the cert **and** its private
     key. Convert to PEM:
     ```bash
     # cert (from the .cer)
     openssl x509 -inform DER -in pass.cer -out signerCert.pem
     # private key (from the .p12 you exported)
     openssl pkcs12 -in Certificates.p12 -nocerts -out signerKey.pem   # sets a passphrase
     ```
3. **Apple WWDR intermediate certificate**
   - Download **Apple Worldwide Developer Relations G4** from
     https://www.apple.com/certificateauthority/ and convert to PEM:
     ```bash
     openssl x509 -inform DER -in AppleWWDRCAG4.cer -out wwdr.pem
     ```
4. **Image assets (required at runtime by Apple)** — a `.pkpass` must contain at
   least `icon.png` (also `icon@2x.png`, `logo.png`). Drop them into
   `functions/src/wallet/models/greengo.pass/` and load them as buffers in
   `appleWallet.ts` (see the `modelBuffers` NOTE there).
5. **Set the secrets** (PEM/DER stored **base64-encoded** so newlines survive):
   ```bash
   base64 -w0 signerCert.pem | firebase functions:secrets:set APPLE_PASS_CERT
   base64 -w0 signerKey.pem  | firebase functions:secrets:set APPLE_PASS_KEY
   base64 -w0 wwdr.pem       | firebase functions:secrets:set APPLE_WWDR_CERT
   firebase functions:secrets:set APPLE_PASS_KEY_PASSPHRASE   # the export passphrase
   firebase functions:secrets:set APPLE_PASS_TYPE_ID          # pass.com.greengo.eventticket
   firebase functions:secrets:set APPLE_TEAM_ID               # your 10-char Team ID
   ```

## 2. Google Wallet provisioning

1. **Get a Wallet issuer account**
   - https://pay.google.com/business/console → enable the **Google Wallet API**
     and request an **Issuer ID** (a numeric id).
2. **Service account key**
   - In the linked Google Cloud project, create a service account, grant it the
     Wallet Object Issuer role, and download a **JSON key**.
   - In the Wallet console, authorize that service account email under
     *Users / API access*.
3. **Set the secrets**:
   ```bash
   firebase functions:secrets:set GOOGLE_WALLET_ISSUER_ID     # the numeric issuer id
   # the SA JSON (raw JSON or base64 both accepted by the loader):
   base64 -w0 wallet-sa.json | firebase functions:secrets:set GOOGLE_WALLET_SA_KEY
   ```
   The first time the class is created it is `UNDER_REVIEW`; Google auto-approves
   most standard event ticket classes.

## 3. Dependencies

Added to `functions/package.json`:

- `passkit-generator` — builds + signs the Apple `.pkpass`.
- `jsonwebtoken` — signs the Google "Save to Wallet" JWT *(already present)*.
- `google-auth-library` — authenticates Wallet REST calls *(already present)*.

Install (once the corp network allows npm):

```bash
cd functions && npm install
```

## 4. Deploy

```bash
cd functions && npm run build
firebase deploy --only functions:getAppleWalletPass,functions:getGoogleWalletSaveUrl
```
