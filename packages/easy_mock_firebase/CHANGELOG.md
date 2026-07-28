## 0.1.0

- Initial release. Extracted from `easy_test_app` so Firebase test fakes are opt-in per app.
- `setUpFirebasePerformanceMock()` — stubs the Firebase Performance pigeon channel so metric calls settle on the fake clock.
- `injectFakeRemoteConfig()` + `featureFlag` — in-memory `FirebaseRemoteConfigPlatform` (setRemoteValues / pushUpdate) over the real Remote Config Dart logic.
- `mockFirebaseMessaging.install()` — stubs the `plugins.flutter.io/firebase_messaging` MethodChannel (permission / token / initial message; `grant` / `deny` / `token` / `initialMessage` / `verify`) via `easy_mock_channel`, keeping the real Dart logic.
- `mockFirebaseAppCheck.install()` — no-op `FirebaseAppCheckPlatform` fake; `activate()` no-ops and never starts the token-refresh timer (which hangs the fake clock).
- `mockFirebaseCrashlytics.install()` — stubs the `plugins.flutter.io/firebase_crashlytics` MethodChannel via `easy_mock_channel` (keeps the real Dart logic; needs no `Firebase.app()`).
- `setUpFirebaseCoreMock()` — drop-in for `setupFirebaseCoreMocks()` that seeds plugin constants (`isCrashlyticsCollectionEnabled`), required for the Crashlytics fake to take effect.
