import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_platform_interface/test.dart';

/// Firebase core mock. Call [MockFirebaseCore.init] before
/// `Firebase.initializeApp()`.
final mockFirebaseCore = MockFirebaseCore._();

class MockFirebaseCore {
  MockFirebaseCore._();

  /// Drop-in for `setupFirebaseCoreMocks()` that also seeds the plugin constants
  /// some Firebase plugins read (and assert on) *before* their platform delegate
  /// is built — notably Crashlytics' `isCrashlyticsCollectionEnabled`, which the
  /// official mock leaves empty. Call it before `Firebase.initializeApp()` in
  /// place of `setupFirebaseCoreMocks()` when the boot touches Crashlytics.
  void init() {
    TestFirebaseCoreHostApi.setUp(_SeededFirebaseCore());
  }
}

class _SeededFirebaseCore implements TestFirebaseCoreHostApi {
  CoreFirebaseOptions get _options => CoreFirebaseOptions(
    apiKey: '123',
    projectId: '123',
    appId: '123',
    messagingSenderId: '123',
  );

  // Constants are nested per plugin, keyed by the plugin's method-channel name
  // (see FirebasePluginPlatform.pluginConstants).
  Map<String?, Object?> get _pluginConstants => {
    'plugins.flutter.io/firebase_crashlytics': {
      'isCrashlyticsCollectionEnabled': false,
    },
  };

  @override
  Future<CoreInitializeResponse> initializeApp(
    String appName,
    CoreFirebaseOptions initializeAppRequest,
  ) async => CoreInitializeResponse(
    name: appName,
    options: _options,
    pluginConstants: _pluginConstants,
  );

  @override
  Future<List<CoreInitializeResponse>> initializeCore() async => [
    CoreInitializeResponse(
      name: defaultFirebaseAppName,
      options: _options,
      pluginConstants: _pluginConstants,
    ),
  ];

  @override
  Future<CoreFirebaseOptions> optionsFromResource() async => _options;
}
