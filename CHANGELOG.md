# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- "Go back" on the scanner's camera-unavailable screen now works; the QR frame was drawn over the button and swallowed the tap.
- Exporting an encrypted backup now shows a loader while the backup is encrypted, instead of a pause with no feedback before the share sheet opens.
- Importing a backup now shows a loader while it is decrypted and saved, until the result or an error appears.
- Exporting a backup on iOS no longer fails with "sharePositionOrigin: argument must be set"; the share sheet is now anchored to the export row.

## [0.1.2] - 2026-10-26

### Changed
- Release CI now builds a signed Android App Bundle (AAB) alongside the APK and, when a Google Play service account is configured, uploads it to the Play internal testing track.

### Added
- README section explaining how codes are generated entirely offline, with a diagram of the enrollment, per-period and verification flow.

## [0.1.1] - 2026-10-23

### Added
- Clean-room TOTP (RFC 6238) and HOTP (RFC 4226) engine with SHA-1/256/512 and 6- or 8-digit codes.
- QR-code enrollment (`otpauth://` Key URI parsing) and manual setup-key entry with algorithm, digit-count and period selection.
- Biometric / device-credential app lock, on by default when the device supports it.
- Configurable auto-lock delay (immediately / after 30s / after 1m) when the lock is enabled.
- Blurred lock overlay that hides codes while the unlock prompt is showing.
- Encrypted backup export and import: AES-GCM-256 with PBKDF2-HMAC-SHA256 (600k iterations), passphrase-protected.
- Search/filter across accounts by issuer or label.
- Drag-to-reorder accounts, with the order persisted.
- Rename an account's issuer and label without touching its secret.
- Confirmation dialog before removing an account.
- FLAG_SECURE / screenshot protection so codes do not leak into screenshots or the app switcher.
- Sarv-themed UI (design-system tokens) with light and dark app icons.

### Security
- Secrets are stored only in the OS-backed keystore (Android Keystore / iOS Keychain) — never in plain preferences, files, or over the network.
- Backup passphrases are never stored and cannot be recovered.

[Unreleased]: https://github.com/Sarv/OTP/compare/v0.1.2...HEAD
[0.1.2]: https://github.com/Sarv/OTP/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/Sarv/OTP/releases/tag/v0.1.1
