import 'package:easy_mock_firebase/easy_mock_firebase.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockFirebaseCore.install();
    await Firebase.initializeApp();
    mockFirebaseAppCheck.install();
    mockFirebaseCrashlytics.install();
  });

  group('FirebaseAppCheck', () {
    test('activate() completes without hanging', () async {
      await FirebaseAppCheck.instance.activate();
    });

    test('getToken() returns the fake token', () async {
      expect(
        await FirebaseAppCheck.instance.getToken(),
        'fake-app-check-token',
      );
    });
  });

  group('FirebaseCrashlytics', () {
    test('recordFlutterFatalError tear-off (the boot pattern) does not throw', () {
      expect(
        () => FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError,
        returnsNormally,
      );
    });

    test('log() / recordError() no-op', () async {
      await FirebaseCrashlytics.instance.log('hi');
      await FirebaseCrashlytics.instance.recordError('boom', StackTrace.empty);
    });
  });
}
