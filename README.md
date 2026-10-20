# Kreen Gate (Flutter)

Flutter port of the **KreenGate** Android app — a gate / check-in app for Kreen events. Staff log in to an event, scan or manually enter participant tickets, view participant details, and print receipts on a Bluetooth thermal printer.

- Package: `id.kreen.android.kreengate`
- Version: `1.9.0+1`
- Platform: Android (no iOS target yet)

## Features

- **Event login** — sign in to an event by event ID
- **Ticket scan** — scan QR codes with the camera (`qr_code_dart_scan`), or type the ticket code manually
- **Redeem / check-in** — validates tickets against the Kreen API (plus JI Premium QR check)
- **Participant details** — shows participant data and order-form answers
- **Thermal printing** — ESC/POS and Printama printers through a native `MethodChannel` (`id.kreen.android.kreengate/printer`)
- **Multi-language** — Indonesian and English (`assets/lang/in.json`, `assets/lang/en.json`)
- **Crash reporting & analytics** — Firebase Crashlytics + Analytics

## Requirements

- Flutter SDK with Dart `^3.13.2`
- Android SDK / Android Studio
- `android/app/google-services.json` (Firebase config)

## Getting started

```bash
flutter pub get
flutter run
```

Release build:

```bash
flutter build apk --release
```

## Project structure

```
lib/
├── main.dart                 # Entry point: Firebase, storage, and language init
├── helper/                   # Global vars (API base URLs), shared functions and widgets, loading page
├── services/
│   ├── api_services.dart     # HTTP calls to the Kreen / JI Premium APIs
│   ├── lang_service.dart     # Loads translations from assets/lang
│   ├── printer_service.dart  # MethodChannel bridge to the native printer code
│   └── storage_services.dart # flutter_secure_storage wrapper
└── pages/
    ├── splash_screen_page.dart
    ├── main_page.dart
    ├── auth/                 # Event login
    ├── home_content/         # Home and settings tabs
    ├── scan/                 # QR scanner and manual ticket input
    ├── participant/          # Participant detail screens
    ├── setting/              # Language and printer settings
    └── printer_test/         # Printer test pages (ESC/POS, Printama)

assets/
├── certs/                    # SSL intermediate certificate
├── fonts/                    # Poppins
├── icons/  images/
└── lang/                     # en.json, in.json

android/app/src/main/kotlin/  # Native printer implementation (MethodChannel)
```

## Configuration

API base URLs are in [lib/helper/global_var.dart](lib/helper/global_var.dart):

| Constant           | Value                                    |
| ------------------ | ---------------------------------------- |
| `baseUrl`          | `https://kreenconnect.com/kreenapi/event/` |
| `baseUrlJipremium` | `https://jipremium.com/api/`             |
