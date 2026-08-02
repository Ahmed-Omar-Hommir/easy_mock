import 'package:easy_mock_channel/easy_mock_channel.dart';
import 'package:flutter/services.dart';

final mockFirebaseCrashlytics = MockFirebaseCrashlytics._();

class MockFirebaseCrashlytics {
  MockFirebaseCrashlytics._();

  static const channelName = 'plugins.flutter.io/firebase_crashlytics';

  MockMethodChannel? _channel;

  MockMethodChannel get channel =>
      _channel ??
      (throw StateError('call mockFirebaseCrashlytics.init() first'));

  void init() {
    _channel = mockChannel(channelName)
      ..when(
        method: 'Crashlytics#checkForUnsentReports',
        returns: {'unsentReports': false},
      )
      ..when(
        method: 'Crashlytics#didCrashOnPreviousExecution',
        returns: {'didCrashOnPreviousExecution': false},
      )
      ..when(
        method: 'Crashlytics#setCrashlyticsCollectionEnabled',
        returns: {'isCrashlyticsCollectionEnabled': false},
      );
  }

  List<MethodCall> verify(String method) => channel.verify(method: method);
}
