# Privacy Policy

**Sarv OTP**
_Last updated: 2026-10-22_

Sarv OTP is a two-factor authentication (2FA) app that generates
one-time codes (TOTP/HOTP) entirely on your device. It is built so that your
secrets never leave the device and we never see them.

## What we collect

**Nothing.** Sarv OTP does not collect, transmit, store off-device,
sell, or share any personal data. There are:

- **No accounts or sign-in** — you do not create an account to use the app.
- **No analytics, telemetry, tracking, or advertising** — no SDKs of that kind
  are bundled.
- **No network transmission of your data** — code generation is fully offline.
  The app does not send your 2FA secrets, generated codes, or usage information
  anywhere.

## What is stored, and where

Everything stays on your device:

- **2FA secrets** are stored in the operating system's encrypted store — the
  **iOS Keychain** (and the Android Keystore on Android). They are never written
  to plain files, logs, or any server.
- **Encrypted backups** you choose to create are protected with **AES-GCM-256**
  using a key derived from your passphrase via **PBKDF2-HMAC-SHA256**. The
  passphrase is never stored and cannot be recovered. Backup files go only where
  you send them via the system share sheet; the app does not upload them.
- **App preferences** (such as your theme choice and whether app-lock is on)
  are stored locally on the device.

## Camera

The app requests camera access **only** to scan QR codes when you add an
account. Camera frames are processed on-device to read the `otpauth://` code and
are never stored or transmitted.

## Biometrics

If you enable app-lock, the app uses the system biometric/passcode prompt
(Face ID / Touch ID / device passcode). Biometric data is handled entirely by
the operating system; the app never receives or stores it.

## Children's privacy

The app collects no data from anyone, including children.

## Changes to this policy

If this policy changes, the updated version will be published in the app's
repository with a new "Last updated" date.

## Contact

For privacy questions, contact **privacy@sarv.com**.
