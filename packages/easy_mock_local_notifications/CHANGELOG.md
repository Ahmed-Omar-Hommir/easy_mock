## 0.1.0

- Initial release.
- `mockLocalNotifications.install()` sets `FlutterLocalNotificationsPlatform.instance` to a no-op so `flutter_local_notifications` doesn't throw a `LateInitializationError` under `flutter test`.
