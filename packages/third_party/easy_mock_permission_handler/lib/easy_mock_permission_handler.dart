import 'package:easy_mock_channel/easy_mock_channel.dart';
import 'package:flutter_test/flutter_test.dart';

// Raw permission_handler channel codes (the plugin's own enum indices). Kept
// here so this package needs NO dependency on permission_handler — it just
// speaks the channel's wire format.
const _channelName = 'flutter.baseflow.com/permissions/methods';

const _statusDenied = 0;
const _statusGranted = 1;
const _statusRestricted = 2;
const _statusLimited = 3;
const _statusPermanentlyDenied = 4;
const _statusProvisional = 5;

const _serviceDisabled = 0;
const _serviceEnabled = 1;
const _serviceNotApplicable = 2;

const _cameraPermission = 1;
const _notificationPermission = 17;

/// Readable permission scenarios for tests — narrate the story, not the channel.
///
/// ```dart
/// mockPermissionHandler.camera.deny();
/// mockPermissionHandler.notification.grant();
/// mockPermissionHandler.serviceDisabled();
/// ```
final mockPermissionHandler = MockPermissionHandler._();

/// Drives a faked permission_handler channel. Defaults: camera and notification
/// granted, service enabled, app settings openable, no rationale.
class MockPermissionHandler {
  MockPermissionHandler._();

  MockMethodChannel? _channel;
  final Map<int, int> _statuses = {};
  int _serviceStatus = _serviceEnabled;
  bool _canOpenAppSettings = true;
  bool _showRationale = false;

  /// The camera permission scenario (`mockPermissionHandler.camera.deny()`).
  late final PermissionScenario camera = PermissionScenario._(
    this,
    _cameraPermission,
  );

  /// The notification permission scenario.
  late final PermissionScenario notification = PermissionScenario._(
    this,
    _notificationPermission,
  );

  /// Installs the channel mock and resets every scenario to its default. The
  /// harness calls this once per test.
  void init() {
    _statuses
      ..clear()
      ..[_cameraPermission] = _statusGranted
      ..[_notificationPermission] = _statusGranted;
    _serviceStatus = _serviceEnabled;
    _canOpenAppSettings = true;
    _showRationale = false;
    _channel = mockChannel(_channelName);
    _apply();
    addTearDown(() => _channel = null);
  }

  // --- service status ---
  void serviceEnabled() => _setService(_serviceEnabled);
  void serviceDisabled() => _setService(_serviceDisabled);
  void serviceNotApplicable() => _setService(_serviceNotApplicable);

  // --- open app settings ---
  void openAppSetting() => _setOpenAppSettings(true);
  void doNotOpenAppSetting() => _setOpenAppSettings(false);

  // --- request-permission rationale ---
  void showRequestPermissionRationale() => _setRationale(true);
  void doNotShowRequestPermissionRationale() => _setRationale(false);

  void _setStatus(int permission, int status) {
    _statuses[permission] = status;
    _apply();
  }

  void _setService(int status) {
    _serviceStatus = status;
    _apply();
  }

  void _setOpenAppSettings(bool value) {
    _canOpenAppSettings = value;
    _apply();
  }

  void _setRationale(bool value) {
    _showRationale = value;
    _apply();
  }

  void _apply() {
    final channel = _channel;
    if (channel == null) return;

    channel.when(method: 'checkPermissionStatus', returns: _statusGranted);
    _statuses.forEach((permission, status) {
      channel.when(
        method: 'checkPermissionStatus',
        arguments: permission,
        returns: status,
      );
    });

    channel.when(method: 'requestPermissions', returns: {..._statuses});
    channel.when(method: 'checkServiceStatus', returns: _serviceStatus);
    channel.when(method: 'openAppSettings', returns: _canOpenAppSettings);
    channel.when(
      method: 'shouldShowRequestPermissionRationale',
      returns: _showRationale,
    );
  }
}

/// One permission's scenario knobs, e.g. `mockPermissionHandler.camera`.
class PermissionScenario {
  PermissionScenario._(this._handler, this._permission);

  final MockPermissionHandler _handler;
  final int _permission;

  void grant() => _handler._setStatus(_permission, _statusGranted);
  void deny() => _handler._setStatus(_permission, _statusDenied);
  void permanentlyDeny() =>
      _handler._setStatus(_permission, _statusPermanentlyDenied);
  void restrict() => _handler._setStatus(_permission, _statusRestricted);
  void limit() => _handler._setStatus(_permission, _statusLimited);
  void provisional() => _handler._setStatus(_permission, _statusProvisional);
}
