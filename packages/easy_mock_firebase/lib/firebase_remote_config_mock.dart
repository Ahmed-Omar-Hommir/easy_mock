import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config_platform_interface/firebase_remote_config_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class MockFeatureFlags {
  MockFeatureFlags._();

  Map<String, dynamic> _value = {};
  final Map<String, dynamic> _updatedValue = {};

  void setRemoteValues(Map<String, dynamic> value) {
    _value = value;
  }

  void pushUpdate(Map<String, dynamic> value) {
    _updatedValue.addAll(value);
    _streamController!.add(RemoteConfigUpdate(value.keys.toSet()));
  }
}

late StreamController<RemoteConfigUpdate>? _streamController;

final featureFlag = MockFeatureFlags._();

/// Installs the in-memory Remote Config platform. Wired into `_bootFirebaseMocks`
/// (core.dart), so Firebase core is already booted by the time it runs.
void injectFakeRemoteConfig() {
  _streamController = StreamController<RemoteConfigUpdate>.broadcast();
  addTearDown(() {
    featureFlag._value = {};
    _streamController!.close();
    _streamController = null;
  });
  FirebaseRemoteConfigPlatform.instance = _FakeRemoteConfig();
}

class _FakeRemoteConfig extends FirebaseRemoteConfigPlatform {
  Map<String, dynamic> _values = {};
  Map<String, dynamic> _defaultValues = {};
  RemoteConfigSettings _settings = RemoteConfigSettings(
    fetchTimeout: const Duration(minutes: 1),
    minimumFetchInterval: const Duration(hours: 1),
  );

  @override
  FirebaseRemoteConfigPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseRemoteConfigPlatform setInitialValues({
    required Map<dynamic, dynamic> remoteConfigValues,
  }) => this;

  @override
  bool getBool(String key) {
    if (_values[key] is bool) return _values[key];

    if (_defaultValues[key] is bool) return _defaultValues[key];

    return RemoteConfigValue.defaultValueForBool;
  }

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<void> fetch() async {
    _values = featureFlag._value;
    featureFlag._value = {};

    _values.addAll(featureFlag._updatedValue);
    featureFlag._updatedValue.clear();
  }

  @override
  Future<bool> activate() async => true;

  @override
  Future<bool> fetchAndActivate() async {
    await fetch();
    return await activate();
  }

  @override
  Future<void> setConfigSettings(RemoteConfigSettings settings) async =>
      _settings = settings;

  @override
  Future<void> setDefaults(Map<String, dynamic> defaultParameters) async =>
      _defaultValues = defaultParameters;

  @override
  DateTime get lastFetchTime => DateTime.fromMillisecondsSinceEpoch(0);

  @override
  RemoteConfigFetchStatus get lastFetchStatus =>
      RemoteConfigFetchStatus.success;

  @override
  RemoteConfigSettings get settings => _settings;

  @override
  Stream<RemoteConfigUpdate> get onConfigUpdated => _streamController!.stream;
}
