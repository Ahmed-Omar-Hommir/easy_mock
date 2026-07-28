# easy_mock_local_notifications

A one-line fix for the `flutter_local_notifications` crash in Flutter widget
tests:

```
LateInitializationError: Field '_instance@…' has not been initialized.
  FlutterLocalNotificationsPlatform.instance
  FlutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation
  FlutterLocalNotificationsPlugin.initialize
```

## Why it happens

`FlutterLocalNotificationsPlatform.instance` is a `late static` field that's set
**only when the native plugin registers itself** (the `GeneratedPluginRegistrant`
at real app startup). `flutter test` never runs the registrant, and the
app-facing `FlutterLocalNotificationsPlugin()` constructor doesn't set it either.
Meanwhile `initialize()` still enters the `defaultTargetPlatform == android`
branch (android is the flutter-test default) and reads that unset field → crash.
A method-channel mock can't help — this throws **before** any channel call.

## Usage

```dart
import 'package:easy_mock_local_notifications/easy_mock_local_notifications.dart';

setUp(() => mockLocalNotifications.install());
```

`install()` sets `FlutterLocalNotificationsPlatform.instance` to a no-op. The
plugin's per-platform resolvers then return `null` (exactly as on an unsupported
platform), so your real code runs and `initialize()` / `show()` / … quietly do
nothing instead of crashing.
