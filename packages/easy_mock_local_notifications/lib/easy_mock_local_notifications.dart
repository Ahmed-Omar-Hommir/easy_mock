import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';

/// Registers a no-op `FlutterLocalNotificationsPlatform` so
/// `flutter_local_notifications` works under `flutter test`.
///
/// The plugin's platform impl is set only by the native plugin registrant,
/// which tests never run — so `FlutterLocalNotificationsPlatform.instance` (a
/// `late` static) is unset and `initialize()` throws a
/// `LateInitializationError`. Installing this no-op fills that field; the
/// per-platform resolvers then return `null` (as on an unsupported platform),
/// so the real plugin Dart runs and quietly does nothing.
final mockLocalNotifications = MockLocalNotifications._();

class MockLocalNotifications {
  MockLocalNotifications._();

  void install() {
    FlutterLocalNotificationsPlatform.instance = _NoopLocalNotifications();
  }
}

class _NoopLocalNotifications extends FlutterLocalNotificationsPlatform {
  @override
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async => null;

  @override
  Future<void> cancel({required int id}) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelAllPendingNotifications() async {}

  @override
  Future<List<PendingNotificationRequest>>
  pendingNotificationRequests() async => const <PendingNotificationRequest>[];

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async =>
      const <ActiveNotification>[];
}
