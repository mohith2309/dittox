# Dittox

Flutter print-ordering app backed by Firebase Auth, Firestore, and Firebase Storage on the Firebase Spark/free plan.

## Run Locally

```bash
flutter pub get
flutter run
```

The app is configured for Firebase project `dittoc-5a839` on Android and iOS. Orders are cached locally for offline resilience, then synced to Firestore when a Firebase user is signed in.

## Cloud Data Flow

- User orders: `users/{uid}/orders/{orderId}`
- Active order cache: `users/{uid}/orders_sync/ongoing/items/{orderId}`
- History cache: `users/{uid}/orders_sync/history/items/{orderId}`
- Store-facing operational data: `operational_orders`, `operational_events`, `printer_queue`
- Store profiles shown to customers: `shop_profiles`
- Payment records: `payment_confirmations`, `payment_retry_queue`

Local fallback orders use `LOCAL-*` IDs. Signed-in cloud orders use `ORD-*` IDs.

## Verify

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build web --release
```

The `functions/` directory is optional Blaze-only code. It is not part of the default Firebase deploy because Cloud Functions require pay-as-you-go billing.

## Deploy Firebase On Free Plan

Build and deploy Firestore plus the Flutter web app:

```bash
flutter build web --release
firebase deploy --only firestore:rules,firestore:indexes,hosting
```

The default `firebase deploy` is also Spark-safe because `firebase.json` includes only Firestore and Hosting targets.

Use release dart defines for production payment values, for example:

```bash
flutter build apk --release \
  --dart-define=DITTOX_RAZORPAY_KEY_ID=your_key \
  --dart-define=DITTOX_RAZORPAY_CREATE_ORDER_URL=your_create_order_url \
  --dart-define=DITTOX_RAZORPAY_VERIFY_URL=your_verify_url
```
