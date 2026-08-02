import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final mockFirebaseAppCheck = MockFirebaseAppCheck._();

class MockFirebaseAppCheck {
  MockFirebaseAppCheck._();

  static const _prefix =
      'dev.flutter.pigeon.firebase_app_check_platform_interface'
      '.FirebaseAppCheckHostApi.';

  void init() {
    _stub('activate', null);
    _stub('getToken', 'fake-app-check-token');
    _stub('getLimitedUseAppCheckToken', 'fake-app-check-token');
    _stub('setTokenAutoRefreshEnabled', null);
    _stub('registerTokenListener', null);
  }

  void _stub(String method, Object? result) {
    const codec = StandardMessageCodec();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final channel = '$_prefix$method';
    messenger.setMockMessageHandler(
      channel,
      (_) async => codec.encodeMessage(<Object?>[result]),
    );
    addTearDown(() => messenger.setMockMessageHandler(channel, null));
  }
}
