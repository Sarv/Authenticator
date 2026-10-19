<p align="center">
  <img src="assets/authenticator-icon.svg" alt="Sarv Authenticator" width="120" />
</p>

<h1 align="center">Sarv Authenticator</h1>

A clean-room, **Google Authenticator-compatible** TOTP/HOTP app built with Flutter
(Android + iOS from one codebase) and themed with the **Sarv design system**.

It is not a copy of Google's app — it implements the two open standards Google
Authenticator is built on, so it interoperates with every service that supports
"Authenticator app" 2FA (Google, GitHub, AWS, ...):

- **RFC 4226** — HOTP (HMAC-based one-time passwords)
- **RFC 6238** — TOTP (time-based, the 30-second rolling codes)
- **Key Uri Format** — the `otpauth://` URI a QR code encodes

## Screenshots

| Codes (light) | Codes (dark) | Settings | Add account |
|:---:|:---:|:---:|:---:|
| <img src="docs/screenshots/01-home-light.png" width="200" alt="Home screen, light theme" /> | <img src="docs/screenshots/02-home-dark.png" width="200" alt="Home screen, dark theme" /> | <img src="docs/screenshots/03-settings-light.png" width="200" alt="Settings: theme, app lock, backup" /> | <img src="docs/screenshots/04-add-light.png" width="200" alt="Add account: scan QR or enter a key" /> |

Long-press a row for the actions menu; swipe to edit or delete:

| Actions menu (long-press) | Swipe to edit / delete |
|:---:|:---:|
| <img src="docs/screenshots/05-menu-light.png" width="200" alt="Long-press actions menu: Rename or Remove" /> | <img src="docs/screenshots/06-swipe-light.png" width="200" alt="Swiping a row reveals the Edit action" /> |

> Codes shown are from demo accounts seeded for the screenshots — not live
> secrets. On device, `FLAG_SECURE` blocks screenshots of real codes.

## How a code is produced (entirely offline, no network)

1. Scan a QR → store the Base32 `secret` in the OS keystore. Nothing is ever sent.
2. Every 30 s: `counter = floor(unixTimeUTC / 30)`.
3. `hmac = HMAC-SHA1(secret, counter)` → dynamic truncation → `mod 10^6` → 6 digits.
4. The server runs the identical math with the same secret and compares.

## Layout

| Path | Responsibility |
|------|----------------|
| `lib/core/totp.dart` | HOTP/TOTP engine — pure functions, the cryptographic heart |
| `lib/core/base32.dart` | RFC 4648 Base32 decoder for secrets |
| `lib/core/otpauth_uri.dart` | Parses the `otpauth://` QR payload |
| `lib/data/account.dart` | Immutable account model + JSON |
| `lib/data/account_store.dart` | Encrypted persistence (Keystore/Keychain) — the only I/O edge |
| `lib/ui/theme.dart` | Sarv design tokens → Flutter theme (the only file with literal values) |
| `lib/ui/app_logo.dart` | Theme-aware brand mark (light/dark SVG variant) |
| `lib/ui/auth_gate.dart` · `lock_screen.dart` | Biometric app-lock gate + lock UI |
| `lib/ui/settings_screen.dart` · `passphrase_dialog.dart` | Settings — app-lock toggle + backup/restore |
| `lib/core/backup.dart` | Encrypted backup envelope (AES-GCM-256 + PBKDF2), pure & testable |
| `lib/data/backup_service.dart` | Backup file I/O — share-sheet export, file-picker import |
| `lib/data/app_lock.dart` | `local_auth` wrapper + persisted on/off preference |
| `lib/ui/manual_entry_screen.dart` | Manual enrollment: issuer/account/secret + SHA1/256/512, 6/8 digits, 30/60s |
| `lib/ui/*.dart` | Google Authenticator-style UI: code list, countdown ring, QR scanner |
| `test/totp_test.dart` | Verifies against the official RFC 4226 / 6238 test vectors |

## Biometric app-lock

When enabled, `AuthGate` prompts for biometrics on launch (and every time the app
returns from the background), falling back to the device PIN/pattern, so codes are
never shown on an unattended, unlocked device. It is **off by default** — turn it
on from the **Settings screen** (gear icon, top-right).

Turning the lock *on* requires a successful auth first, so you can't lock yourself
out with a credential that doesn't work; the change arms the gate on the next
background.

## Encrypted export / import

Settings → **Backup & restore** lets you move accounts between devices:

- **Export** encrypts the account list and opens the share sheet to save/send a
  `.sauthbackup` file. **Import** picks a backup file and merges it (duplicates,
  matched on issuer+account+secret, are skipped).
- Scheme: the accounts JSON is encrypted with **AES-GCM-256** under a key derived
  from your passphrase via **PBKDF2-HMAC-SHA256 (600k iterations)**, with a fresh
  random salt and nonce per export. The GCM auth tag means a wrong passphrase (or
  a tampered file) fails loudly instead of returning garbage.
- The passphrase is never stored and cannot be recovered — lose it and the backup
  is unreadable, by design.

All crypto uses the vetted `cryptography` package (`lib/core/backup.dart`); the
round-trip, wrong-passphrase and tamper behaviours are covered by
`test/backup_test.dart`.

## Branding & app icon

The brand mark lives in `assets/` in two theme variants, recoloured with the
design-system tokens:

| Asset | Colours | Use |
|-------|---------|-----|
| `authenticator-icon-light.svg` | brand `#2F5FAC` / accent `#E3701A` | light UI + light launcher |
| `authenticator-icon-dark.svg` | dark-token `#5B92D2` / `#FF8533` | dark UI + Android 13+ themed icon |
| `icon-{light,dark}-1024.png` | on `--surface` | iOS/store square icons |
| `adaptive-fg-{light,dark}-1024.png` | transparent, padded | Android adaptive foreground |

`AppLogo` picks the right SVG for the current theme automatically (lock screen,
app bar). Generate the platform launcher icons with:

```bash
flutter pub get
dart run flutter_launcher_icons   # config is in pubspec.yaml
```

## Theming

All colours, radii, spacing, fonts and type sizes come from
`../sarv_theme/design-system.css`, transcribed once into `lib/ui/theme.dart`
(`AppTokens.light` / `AppTokens.dark`). No component hard-codes a value.
Light and dark both follow the `.dark` block in the design system.

Fonts (Plus Jakarta Sans, JetBrains Mono) mirror `sarv_theme/fonts.css`; drop the
`.ttf` files into `assets/fonts/` and uncomment the `fonts:` block in
`pubspec.yaml` to bundle them offline.

## Run it

```bash
flutter create .      # one-time: generate the android/ ios/ platform folders
flutter pub get
flutter test          # verifies the engine against the RFC vectors
flutter run           # on a connected device/emulator
```

### One-time native setup (after `flutter create .`)

**Android** — biometrics needs a FragmentActivity, plus the permission:

- In `android/app/src/main/.../MainActivity.kt` change the base class to
  `FlutterFragmentActivity` (from `FlutterActivity`).
- In `android/app/src/main/AndroidManifest.xml` add inside `<manifest>`:
  ```xml
  <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
  <uses-permission android:name="android.permission.CAMERA"/>
  ```

**iOS** — add to `ios/Runner/Info.plist`:
```xml
<key>NSFaceIDUsageDescription</key>
<string>Unlock Sarv Authenticator with Face ID to view your codes.</string>
<key>NSCameraUsageDescription</key>
<string>Scan QR codes to add authenticator accounts</string>
```

## Correctness

`test/totp_test.dart` asserts the engine reproduces every published vector from
RFC 6238 Appendix B (SHA1) and RFC 4226 Appendix D. These same vectors were
independently confirmed against a Python reference during development.

## Security notes

- Secrets live only in the OS-encrypted store, never in plain preferences, a
  file, logs, or the network.
- Biometric/PIN app-lock gates access and re-locks on backgrounding.
- Encrypted, passphrase-protected export/import (AES-GCM-256 + PBKDF2).
- **Screenshot/recording blocked** — `enableSecureDisplay()` (called at startup
  in `main.dart`) sets Android `FLAG_SECURE` and covers the iOS app-switcher
  snapshot, so live codes can't be captured. This mirrors Google Authenticator,
  whose window is `FLAG_SECURE` too (a screenshot of it comes back black).
  Zero-dependency alternative: skip the `screen_protector` package and instead
  add this to `MainActivity` after `flutter create .`:
  ```kotlin
  override fun onCreate(savedInstanceState: Bundle?) {
      super.onCreate(savedInstanceState)
      window.setFlags(WindowManager.LayoutParams.FLAG_SECURE,
                      WindowManager.LayoutParams.FLAG_SECURE)
  }
  ```
- Consider adding: SHA256/512 selection in the enrollment UI (the engine already
  handles all three algorithms), and iCloud/Drive backup destinations.
