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

`FlutterLocalNotificationsPlatform.instance` is a `late static` field set **only
when the native plugin registers itself** (the `GeneratedPluginRegistrant` at
real app startup). `flutter test` never runs the registrant, and the app-facing
`FlutterLocalNotificationsPlugin()` constructor doesn't set it either. Meanwhile
`initialize()` still enters the `defaultTargetPlatform == android` branch
(android is the flutter-test default) and reads that unset field → crash, before
any channel call.

## Usage

```dart
import 'package:easy_mock_local_notifications/easy_mock_local_notifications.dart';

setUp(() => mockLocalNotifications.init());
```

`install()` registers the **real** `AndroidFlutterLocalNotificationsPlugin` (via
its `registerWith()`) so `.instance` is set, and stubs the
`dexterous.com/flutter/local_notifications` MethodChannel with `easy_mock_channel`.
The real plugin Dart runs — serializing settings, mapping notification details —
but every native call is intercepted (`initialize` → `true`, queries → empty,
`show`/`cancel`/… → no-op). Use `mockLocalNotifications.channel` to override or
`verify('show')` to assert.
