import 'package:firebase_app_check_platform_interface/firebase_app_check_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';

/// Replaces `FirebaseAppCheckPlatform` with a fake so `FirebaseAppCheck` works
/// under `flutter test`.
///
/// The real App Check does device attestation and starts a token auto-refresh
/// timer on `activate()` — neither completes on the fake test clock, so it hangs.
/// This fake makes `activate()` a no-op, hands back a dummy token, and never
/// starts the timer. Install it after `Firebase.initializeApp()`.
final mockFirebaseAppCheck = MockFirebaseAppCheck._();

class MockFirebaseAppCheck {
  MockFirebaseAppCheck._();

  void install() {
    FirebaseAppCheckPlatform.instance = _FakeAppCheck();
  }
}

class _FakeAppCheck extends FirebaseAppCheckPlatform {
  @override
  FirebaseAppCheckPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAppCheckPlatform setInitialValues() => this;

  @override
  Future<void> activate({
    WebProvider? webProvider,
    AndroidProvider? androidProvider,
    AppleProvider? appleProvider,
    AndroidAppCheckProvider? providerAndroid,
    AppleAppCheckProvider? providerApple,
    WindowsAppCheckProvider? providerWindows,
  }) async {}

  @override
  Future<String?> getToken(bool forceRefresh) async => 'fake-app-check-token';

  @override
  Future<String> getLimitedUseToken() async => 'fake-app-check-token';

  @override
  Future<void> setTokenAutoRefreshEnabled(
    bool isTokenAutoRefreshEnabled,
  ) async {}

  @override
  Stream<String?> get onTokenChange => const Stream<String?>.empty();
}
