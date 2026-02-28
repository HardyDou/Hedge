# Hedge

A **Local-First** password manager with native experience.

Your passwords, your cloud, your control.

## Features

- **Zero-Knowledge** - Data encrypted locally with AES-256-GCM, never touches third-party servers
- **Your Cloud, Your Rules** - Sync via iCloud Drive / Android SAF, no vendor lock-in
- **Native Experience** - Pixel-perfect Cupertino design on iOS, macOS, and Android
- **Biometric Unlock** - Face ID / Touch ID / Fingerprint support
- **Cross-Platform** - One codebase for mobile and desktop

## Why Hedge?

| | Hedge | 1Password | Bitwarden | KeePass |
|---|:---:|:---:|:---:|:---:|
| Data Storage | Your Cloud | Vendor Server | Vendor/Self-host | Local |
| Price | Free | $2.99+/mo | Free/$10/yr | Free |
| UI | Native | Native | Web-style | Legacy |
| Cross-Platform | Yes | Yes | Yes | Limited |

## Getting Started

### Prerequisites

- Flutter 3.x
- Xcode 15+ (for iOS/macOS)
- Android Studio (for Android)

### Build & Run

```bash
# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Generate localization
flutter gen-l10n

# Run on macOS
flutter run -d macos

# Run on iOS Simulator
flutter run -d iphonesimulator
```

## Architecture

```
lib/
├── core/           # Business logic, encryption, models
├── data/           # Repositories, storage adapters
├── presentation/   # UI (Cupertino widgets, Riverpod providers)
│   ├── mobile/     # iOS/Android pages
│   └── desktop/    # macOS pages
└── l10n/           # Internationalization (en, zh)
```

## Security

- AES-256-GCM encryption
- Argon2id key derivation
- Zero plaintext logging
- Biometric authentication

## License

MIT
