# App Review notes — Sarv OTP

Paste this into the **App Review Information -> Notes** field in App Store Connect
when submitting. It lets the reviewer exercise the whole app without owning a
2FA-enabled account, which is the usual sticking point for authenticator apps.

---

## What the app does

Sarv OTP is a standards-based TOTP/HOTP two-factor authentication app
(RFC 6238 / RFC 4226) — the same kind of app as Google Authenticator. It
generates rolling 6-digit codes **entirely on-device and fully offline**. There
is **no account, no sign-in, and no network access** — nothing to log in to.

## No demo account is needed — add one in 20 seconds

The app opens to an empty list (no codes yet, by design — a fresh install has no
accounts). To see it working, add an account by **manual key**, which needs no
camera and no real service:

1. On the home screen tap the **+ (Add)** button.
2. Choose **"Enter a setup key"** (the manual-entry option; the other option is
   the QR scanner).
3. Enter these values:
   - **Issuer:** `Demo`
   - **Account:** `reviewer@example.com`
   - **Setup key (Base32):** `JBSWY3DPEHPK3PXP`
   - Leave the defaults (SHA1, 6 digits, 30 seconds).
4. Tap **Add account**.

A "Demo" entry appears showing a 6-digit code with a countdown ring that refreshes
every 30 seconds. This is the core feature. `JBSWY3DPEHPK3PXP` is a well-known
public test secret (not a real credential).

### Or scan a QR code

If you prefer the camera path, point the in-app scanner (**+ -> Scan a QR code**)
at this standard `otpauth://` QR:

- URI: `otpauth://totp/Demo:reviewer@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Demo`

Any online `otpauth://` QR generator will render it. Camera permission is
requested only here, with the usage string "Scan QR codes to add authenticator
accounts."

## Other features to review

- **Row gestures:** long-press a code for Rename / Remove; swipe a row to edit or
  delete.
- **Settings** (gear, top-right): light/dark theme, optional biometric app-lock,
  and encrypted backup/restore (AES-GCM-256 + PBKDF2, passphrase-protected).
- **Biometric app-lock** is **off by default**; enabling it uses Face ID / Touch
  ID / device passcode (usage string: "Unlock Sarv OTP with Face ID to
  view your codes"). It can be left off for review.

## Privacy & data

- **No data is collected or transmitted** — see the privacy policy (URL in the App
  Privacy section). The App Privacy answers are "Data Not Collected".
- Secrets are stored only in the **iOS Keychain**.
- **Screen capture is intentionally blocked** on the live app (the iOS
  app-switcher snapshot is covered) so one-time codes can't leak — this is the
  same protection Google Authenticator uses and is expected behaviour, not a bug.

## Export compliance

The app uses only standard cryptography for its own authentication (TOTP HMAC,
and AES-GCM/PBKDF2 for optional local backups), exempt under US EAR 740.17(b).
`ITSAppUsesNonExemptEncryption` is already set to `false` in `Info.plist`.
