# Dittox

> Document printing, simplified. Upload your files, find nearby print shops on a map, place an order, and track it to pickup — all from your phone.

---

## Features

### Customer App

- **File Upload** — Upload PDFs, images, and documents directly from your device or cloud storage
- **Nearby Shop Discovery** — Browse a live map of print shops sorted by distance and ratings
- **Order Placement** — Configure print settings (pages, copies, color/B&W, binding) and place orders in seconds
- **Real-Time Tracking** — Follow your order status from submitted → printing → ready for pickup
- **Order History** — View past orders, reorder, and download receipts

### Store Mode (Print Shop Owners)

- **Live Order Dashboard** — See incoming orders the instant they arrive
- **Fast Actions** — Accept, reject, or mark orders complete with a single tap
- **Bulk Updates** — Update multiple order statuses simultaneously
- **Print-to-Pickup Workflow** — Guided queue management from print start to customer collection
- **Revenue Tracking** — Daily and weekly order summaries

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Dart) |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| File Storage | Firebase Cloud Storage |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| Maps & Location | Google Maps API |
| State Management | Provider / Riverpod |
| CI/CD | GitHub Actions |

---

## Getting Started

### Prerequisites

- Flutter 3.x+
- Dart 3.x+
- Firebase project configured for Android & iOS
- Google Maps API key

### Setup

```bash
git clone https://github.com/mohith2309/dittox.git
cd dittox
flutter pub get
```

Add your Firebase config files to the respective platform folders:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Create a `.env` file at the project root:

```env
GOOGLE_MAPS_API_KEY=your_key_here
```

### Run

```bash
flutter run
```

### Build APK

```bash
flutter build apk --release
```

---

## Project Structure

```
lib/
├── main.dart
├── models/           # Order, Shop, User data models
├── screens/
│   ├── customer/     # File upload, map, order flow screens
│   └── store/        # Owner dashboard and order management
├── services/         # Firebase, Maps, file handling services
└── widgets/          # Shared UI components
```

---

## Screenshots

_Coming soon_

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.

## License

[MIT](LICENSE)
