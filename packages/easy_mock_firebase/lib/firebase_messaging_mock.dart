import 'package:easy_mock_channel/easy_mock_channel.dart';
import 'package:flutter/services.dart';

/// Mocks the `plugins.flutter.io/firebase_messaging` MethodChannel so the real
/// `firebase_messaging` Dart code runs against fake native replies — no device,
/// no APNs/FCM. Install it in a test (auto-removed on teardown); tweak the
/// replies with [grant] / [deny] / [token] / [initialMessage].
final mockFirebaseMessaging = MockFirebaseMessaging._();

class MockFirebaseMessaging {
  MockFirebaseMessaging._();

  static const channelName = 'plugins.flutter.io/firebase_messaging';

  MockMethodChannel? _channel;
  MockMethodChannel get _c =>
      _channel ?? (throw StateError('call mockFirebaseMessaging.install() first'));

  /// The underlying channel mock, for stubbing methods not covered here.
  MockMethodChannel get channel => _c;

  /// Installs the channel mock with default-happy replies: permission
  /// authorized, a fake FCM/APNs token, and no initial message.
  void install() {
    _channel = mockChannel(channelName);
    grant();
    token('fake-fcm-token');
    noInitialMessage();
    _c
      ..when(method: 'Messaging#getAPNSToken', returns: {'token': 'fake-apns-token'})
      ..when(
        method: 'Messaging#setForegroundNotificationPresentationOptions',
        returns: null,
      )
      ..when(method: 'Messaging#deleteToken', returns: null)
      ..when(method: 'Messaging#subscribeToTopic', returns: null)
      ..when(method: 'Messaging#unsubscribeFromTopic', returns: null);
  }

  /// `requestPermission()` and `getNotificationSettings()` report authorized.
  void grant() => _settings(_authorized);

  /// `requestPermission()` and `getNotificationSettings()` report denied.
  void deny() => _settings(_denied);

  /// `getToken()` returns [value].
  void token(String value) =>
      _c.when(method: 'Messaging#getToken', returns: {'token': value});

  /// `getInitialMessage()` returns [message] — a `RemoteMessage` wire map (as
  /// the platform would send), or `null` for none.
  void initialMessage(Map<String, dynamic>? message) =>
      _c.when(method: 'Messaging#getInitialMessage', returns: message);

  void noInitialMessage() => initialMessage(null);

  /// Recorded calls to [method], e.g. `verify('Messaging#requestPermission')`.
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
