import 'package:easy_mock_firebase/easy_mock_firebase.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    mockFirebaseMessaging.init();
    await Firebase.initializeApp();
  });

  test('requestPermission reports authorized by default', () async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    expect(settings.authorizationStatus, AuthorizationStatus.authorized);
  });

  test('deny() flips requestPermission to denied', () async {
    mockFirebaseMessaging.deny();

    final settings = await FirebaseMessaging.instance.requestPermission();

    expect(settings.authorizationStatus, AuthorizationStatus.denied);
  });

  test('getToken returns the stubbed token', () async {
    mockFirebaseMessaging.token('tok-123');

    expect(await FirebaseMessaging.instance.getToken(), 'tok-123');
  });

  test('getInitialMessage is null by default', () async {
    expect(await FirebaseMessaging.instance.getInitialMessage(), isNull);
  });

  test('records channel calls for verification', () async {
    await FirebaseMessaging.instance.requestPermission();

    expect(
      mockFirebaseMessaging.verify('Messaging#requestPermission'),
      hasLength(1),
    );
  });
}
