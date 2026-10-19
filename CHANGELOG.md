# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
- sarv-themed UI (design-system tokens) with light and dark app icons.

### Security
- Secrets are stored only in the OS-backed keystore (Android Keystore / iOS Keychain) — never in plain preferences, files, or over the network.
- Backup passphrases are never stored and cannot be recovered.

[Unreleased]: https://github.com/ankursarv/sarv_authenticator/compare/HEAD
