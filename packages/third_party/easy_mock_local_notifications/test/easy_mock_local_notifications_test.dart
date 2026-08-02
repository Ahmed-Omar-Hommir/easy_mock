import 'package:easy_mock_local_notifications/easy_mock_local_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockLocalNotifications.init();
  });

  test('initialize() runs the real impl against the mocked channel', () async {
    final plugin = FlutterLocalNotificationsPlugin();

    final result = await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    expect(result, isTrue);
    expect(mockLocalNotifications.verify('initialize'), hasLength(1));
  });

  test('query methods return empty instead of throwing', () async {
    expect(
      await FlutterLocalNotificationsPlatform.instance.getActiveNotifications(),
      isEmpty,
    );
    expect(
      await FlutterLocalNotificationsPlatform.instance
          .pendingNotificationRequests(),
      isEmpty,
    );
  });
}
