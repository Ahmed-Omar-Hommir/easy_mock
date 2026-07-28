import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics_platform_interface/firebase_crashlytics_platform_interface.dart';

/// Replaces `FirebaseCrashlyticsPlatform` with a no-op fake so Crashlytics calls
/// don't reach the native channel under `flutter test`.
///
/// `bootFirebase` only tears off `recordFlutterFatalError`, so the boot itself
/// never touches Crashlytics — but this keeps any error routed to Crashlytics
/// during a test from hitting the real platform. Install after
/// `Firebase.initializeApp()`.
final mockFirebaseCrashlytics = MockFirebaseCrashlytics._();

class MockFirebaseCrashlytics {
  MockFirebaseCrashlytics._();

  void install() {
    FirebaseCrashlyticsPlatform.instance = _FakeCrashlytics(
      appInstance: Firebase.app(),
    );
  }
}

class _FakeCrashlytics extends FirebaseCrashlyticsPlatform {
  _FakeCrashlytics({required super.appInstance});

  @override
  bool get isCrashlyticsCollectionEnabled => false;

  @override
  Future<bool> checkForUnsentReports() async => false;

  @override
  void crash() {}

  @override
  Future<void> deleteUnsentReports() async {}

  @override
  Future<bool> didCrashOnPreviousExecution() async => false;

  @override
  Future<void> recordError({
    required String exception,
    required String information,
    required String? reason,
    bool fatal = false,
    String? buildId,
    List<String> loadingUnits = const [],
    List<Map<String, String>>? stackTraceElements,
  }) async {}

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> sendUnsentReports() async {}

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setUserIdentifier(String identifier) async {}

  @override
  Future<void> setCustomKey(String key, String value) async {}

  @override
  FirebaseCrashlyticsPlatform setInitialValues({
    required bool isCrashlyticsCollectionEnabled,
  }) => this;
}
