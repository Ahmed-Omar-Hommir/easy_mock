## 0.1.0

- Initial release.
- `mockLocalNotifications.install()` registers the real `AndroidFlutterLocalNotificationsPlugin` and stubs its `dexterous.com/flutter/local_notifications` MethodChannel via `easy_mock_channel`, so `flutter_local_notifications` runs its real Dart under `flutter test` without a `LateInitializationError` or any native call.
