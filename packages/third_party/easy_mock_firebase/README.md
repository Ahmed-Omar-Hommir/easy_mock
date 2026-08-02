# easy_mock_firebase

Firebase test fakes for Flutter widget tests. Independent helpers, each
installed inside a test (they register their own teardown):

```dart
import 'package:easy_mock_firebase/easy_mock_firebase.dart';
```

## `mockFirebaseCore.init()`

A drop-in for the official `setupFirebaseCoreMocks()` that *also* seeds the
plugin constants some Firebase plugins read before their platform delegate is
built. Notably, Crashlytics asserts `isCrashlyticsCollectionEnabled != null` in
`instanceFor` — the official mock leaves that empty, so any Crashlytics call
throws an assertion error a platform fake can't intercept. Use this instead of
`setupFirebaseCoreMocks()` (before `Firebase.initializeApp()`) whenever the boot
touches Crashlytics:

```dart
mockFirebaseCore.init();          // in place of setupFirebaseCoreMocks()
await Firebase.initializeApp();
mockFirebaseCrashlytics.init();
mockFirebaseAppCheck.init();
```

## `mockFirebaseAppCheck.init()`

Stubs the Firebase App Check **pigeon** channel (`FirebaseAppCheckHostApi`),
keeping the real `MethodChannelFirebaseAppCheck` Dart. Without it, `activate()`
awaits an unmocked pigeon channel that only settles on the real event loop, so
the fake test clock hangs (same failure as Firebase Performance). `activate` /
`setTokenAutoRefreshEnabled` resolve to void; `getToken` returns a dummy token;
`registerTokenListener` replies null, which the plugin swallows, so no live
token EventChannel is opened.

## `mockFirebaseCrashlytics.init()`

Stubs the `plugins.flutter.io/firebase_crashlytics` MethodChannel via
`easy_mock_channel`, so the real `MethodChannelFirebaseCrashlytics` Dart runs but
`log` / `recordError` / … never reach the native side. Needs no `Firebase.app()`,
so it installs with the other mocks before the boot. Still requires
`mockFirebaseCore.init()` (above) — the platform interface asserts
`isCrashlyticsCollectionEnabled` in `instanceFor`, before any channel call. The
boot itself only tears off `recordFlutterFatalError`, so it never touches
Crashlytics; this covers the case where an error is actually routed to it.

## `mockFirebasePerformance.init()`

Stubs the Firebase Performance **pigeon** channel (`HttpMetric` /`Trace`
start/stop). Without it, the Dio performance interceptor's `await metric.start()`
is routed to the real platform messenger and only completes on the real event
loop — forcing tests to use `runAsync`. With it, those calls resolve on the fake
clock, so the whole HTTP flow settles under `pump` / `pumpAndSettle`.

## `mockFirebaseRemoteConfig.init()`

Installs an in-memory `FirebaseRemoteConfigPlatform`, keeping the real
`firebase_remote_config` Dart logic. Drive values through `mockFirebaseRemoteConfig`:

```dart
mockFirebaseRemoteConfig.setRemoteValues({'show_wallet': true}); // before launching the app
mockFirebaseRemoteConfig.pushUpdate({'show_wallet': false});     // emit an onConfigUpdated event
```

The app must still run its own Remote Config init (`setDefaults` /
`fetchAndActivate`) so the active cache the generated getters read is populated.

## `mockFirebaseMessaging.init()`

Stubs the `plugins.flutter.io/firebase_messaging` **MethodChannel** (a plain
channel, unlike Performance/Remote Config which are pigeon) via
`easy_mock_channel`, keeping the real `firebase_messaging` Dart logic. Installs
default-happy replies — permission authorized, a fake FCM/APNs token, no initial
message — and lets you tweak them:

```dart
mockFirebaseMessaging.init();

mockFirebaseMessaging.deny();                 // requestPermission → denied
mockFirebaseMessaging.token('tok-123');       // getToken() → 'tok-123'
mockFirebaseMessaging.initialMessage({...});  // getInitialMessage() → a RemoteMessage

// assert the app asked for permission:
expect(mockFirebaseMessaging.verify('Messaging#requestPermission'), hasLength(1));
```

Covers the methods the app hits during boot/init (`requestPermission`,
`getToken`, `getInitialMessage`, `setForegroundNotificationPresentationOptions`,
`getAPNSToken`, …). Use `mockFirebaseMessaging.channel` to stub anything else.
