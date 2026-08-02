## 0.1.0

- Initial release. Extracted from `easy_test_app` so Firebase test fakes are opt-in per app.
- `mockFirebasePerformance.init()` — stubs the Firebase Performance pigeon channel so metric calls settle on the fake clock.
- `mockFirebaseRemoteConfig.init()` — in-memory `FirebaseRemoteConfigPlatform` (`setRemoteValues` / `pushUpdate`) over the real Remote Config Dart logic.
- `mockFirebaseMessaging.init()` — stubs the `plugins.flutter.io/firebase_messaging` MethodChannel (permission / token / initial message; `grant` / `deny` / `token` / `initialMessage` / `verify`) via `easy_mock_channel`, keeping the real Dart logic.
- `mockFirebaseAppCheck.init()` — stubs the App Check pigeon channel (`FirebaseAppCheckHostApi`), keeping the real Dart; `activate()` no longer hangs on the unmocked channel.
- `mockFirebaseCrashlytics.init()` — stubs the `plugins.flutter.io/firebase_crashlytics` MethodChannel via `easy_mock_channel` (keeps the real Dart logic; needs no `Firebase.app()`).
- `mockFirebaseCore.init()` — drop-in for `setupFirebaseCoreMocks()` that seeds plugin constants (`isCrashlyticsCollectionEnabled`), required for the Crashlytics fake to take effect.
