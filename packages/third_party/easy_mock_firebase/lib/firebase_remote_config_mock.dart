import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config_platform_interface/firebase_remote_config_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

/// Installs an in-memory `FirebaseRemoteConfigPlatform` (keeping the real Remote
/// Config Dart, only the native side is faked). Drive flag values with
/// [setRemoteValues] before launching the app, or [pushUpdate] to emit an
/// `onConfigUpdated` event.
final mockFirebaseRemoteConfig = MockRemoteConfig._();

class MockRemoteConfig {
  MockRemoteConfig._();

  Map<String, dynamic> _value = {};
  final Map<String, dynamic> _updatedValue = {};
  StreamController<RemoteConfigUpdate>? _streamController;

  /// Sets the values a `fetch()` will activate. Call before launching the app.
  void setRemoteValues(Map<String, dynamic> value) {
    _value = value;
  }

  /// Emits an `onConfigUpdated` event carrying [value]'s keys.
  void pushUpdate(Map<String, dynamic> value) {
    _updatedValue.addAll(value);
    _streamController!.add(RemoteConfigUpdate(value.keys.toSet()));
  }

  void init() {
    _streamController = StreamController<RemoteConfigUpdate>.broadcast();
    addTearDown(() {
      _value = {};
      _updatedValue.clear();
      _streamController!.close();
      _streamController = null;
    });
    FirebaseRemoteConfigPlatform.instance = _FakeRemoteConfig(this);
  }
}

class _FakeRemoteConfig extends FirebaseRemoteConfigPlatform {
  _FakeRemoteConfig(this._owner);

  final MockRemoteConfig _owner;

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
    _values = _owner._value;
    _owner._value = {};

    _values.addAll(_owner._updatedValue);
    _owner._updatedValue.clear();
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
  Stream<RemoteConfigUpdate> get onConfigUpdated =>
      _owner._streamController!.stream;
}
