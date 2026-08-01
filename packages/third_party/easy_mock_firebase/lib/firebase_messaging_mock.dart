import 'package:easy_mock_channel/easy_mock_channel.dart';
import 'package:flutter/services.dart';

final mockFirebaseMessaging = MockFirebaseMessaging._();

class MockFirebaseMessaging {
  MockFirebaseMessaging._();

  static const channelName = 'plugins.flutter.io/firebase_messaging';

  MockMethodChannel? _channel;
  MockMethodChannel get _c =>
      _channel ??
      (throw StateError('call mockFirebaseMessaging.install() first'));

  MockMethodChannel get channel => _c;

  void install() {
    _channel = mockChannel(channelName);
    grant();
    token('fake-fcm-token');
    noInitialMessage();
    _c
      ..when(
        method: 'Messaging#getAPNSToken',
        returns: {'token': 'fake-apns-token'},
      )
      ..when(
        method: 'Messaging#setForegroundNotificationPresentationOptions',
        returns: null,
      )
      ..when(method: 'Messaging#deleteToken', returns: null)
      ..when(method: 'Messaging#subscribeToTopic', returns: null)
      ..when(method: 'Messaging#unsubscribeFromTopic', returns: null);
  }

  void grant() => _settings(_authorized);

  void deny() => _settings(_denied);

  void token(String value) =>
      _c.when(method: 'Messaging#getToken', returns: {'token': value});

  void initialMessage(Map<String, dynamic>? message) =>
      _c.when(method: 'Messaging#getInitialMessage', returns: message);

  void noInitialMessage() => initialMessage(null);

  List<MethodCall> verify(String method) => _c.verify(method: method);

  void _settings(Map<String, int> settings) {
    _c
      ..when(method: 'Messaging#requestPermission', returns: settings)
      ..when(method: 'Messaging#getNotificationSettings', returns: settings);
  }

  static const _authorized = <String, int>{
    'authorizationStatus': 1,
    'alert': 1,
    'badge': 1,
    'sound': 1,
    'announcement': 0,
    'carPlay': 0,
    'lockScreen': 1,
    'notificationCenter': 1,
    'showPreviews': 1,
    'timeSensitive': 0,
    'criticalAlert': 0,
    'providesAppNotificationSettings': 0,
  };

  static const _denied = <String, int>{
    'authorizationStatus': 0,
    'alert': 0,
    'badge': 0,
    'sound': 0,
    'announcement': 0,
    'carPlay': 0,
    'lockScreen': 0,
    'notificationCenter': 0,
    'showPreviews': 0,
    'timeSensitive': 0,
    'criticalAlert': 0,
    'providesAppNotificationSettings': 0,
  };
}
