import 'package:easy_mock_channel/easy_mock_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final mockLocalNotifications = MockLocalNotifications._();

class MockLocalNotifications {
  MockLocalNotifications._();

  static const channelName = 'dexterous.com/flutter/local_notifications';

  MockMethodChannel? _channel;

  MockMethodChannel get channel =>
      _channel ??
      (throw StateError('call mockLocalNotifications.install() first'));

  void install() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();

    _channel = mockChannel(channelName)
      ..when(method: 'initialize', returns: true)
      ..when(method: 'getNotificationAppLaunchDetails', returns: null)
      ..when(method: 'pendingNotificationRequests', returns: <dynamic>[])
      ..when(method: 'getActiveNotifications', returns: <dynamic>[])
      ..when(method: 'areNotificationsEnabled', returns: true);
  }

  List<MethodCall> verify(String method) => channel.verify(method: method);
}
