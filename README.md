# PhonePe Checkout (Flutter)

A minimal Flutter helper demo for taking payments with **PhonePe** using a WebView/deep-link style flow (`phone_pe` package).  
The example shows how to start a checkout, configure sandbox vs. production, and handle the resulting status.

> This package/example is not an official PhonePe SDK. Use **sandbox credentials** for development and never ship your **secret keys** in the client. For production, do signing/verification on your **backend** and use PhonePe webhooks.

---

## Features

- Start a PhonePe checkout from Flutter
- Sandbox and production configuration examples
- Return to app using a **deep link** (e.g., `myapp://payment-return`)
- Simple status handling with snackbars and UI state

---

## Getting started

### Installation

Add the dependency in your app `pubspec.yaml`:

```yaml
dependencies:
  phone_pe: ^1.0.0
```

Then run:

```bash
flutter pub get
```

> If you're developing the `phone_pe` package itself, the example app depends on it via a local `path: ../` in `example/pubspec.yaml` (see below).

---

## Deep links

Register your deep link on Android and iOS so `myapp://payment-return` opens your app.

- **Android:** add an intent filter in the main activity for your scheme/host.
- **iOS:** configure URL Types in `Info.plist` with the same scheme.

In this demo flow, the in-app WebView intercepts navigation to the `returnDeepLink` and the example handles the result in Dart.

---

## Example usage

```dart
final result = await PhonePeCheckout.startPayment(
  context: context,
  config: sandboxConfig,
  amountPaise: 10000, // ₹100.00 (paise)
  returnDeepLink: 'myapp://payment-return',
);

// result.status: "SUCCESS" | "PENDING" | "FAILED" | provider-specific
```

See the full example in [`example/lib/main.dart`](example/lib/main.dart).

---

## Security notes

- Do not embed production secrets in the app. Sign/verify requests on your **server**.
- For live traffic, confirm transactions via PhonePe webhooks / server-side verification.
- Keep `enableLogs` off in release builds.

---

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE).
