import 'package:easy_mock_local_notifications/easy_mock_local_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockLocalNotifications.install();
  });

  test('initialize() no longer throws LateInitializationError', () async {
    final plugin = FlutterLocalNotificationsPlugin();

    final result = await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // The android impl isn't registered, so the resolver returns null → no-op.
    expect(result, isNull);
  });

  test('query methods are no-ops instead of throwing', () async {
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
