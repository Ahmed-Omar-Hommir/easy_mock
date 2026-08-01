import 'package:easy_mock_channel/easy_mock_channel.dart';
import 'package:flutter_test/flutter_test.dart';

// device_info_plus' single channel: getDeviceInfo returns one map that
// DeviceInfoPlugin decodes per platform. This package speaks that raw map, so it
// needs NO dependency on device_info_plus.
const _channelName = 'dev.fluttercommunity.plus/device_info';

// A COMPLETE union map valid for the three decoders that read the channel map:
// MacOsDeviceInfo / AndroidDeviceInfo / IosDeviceInfo (each reads only its own
// keys). They demand many non-null fields, so a sparse map crashes
// `deviceInfo` / `androidInfo` / `iosInfo`; override keys via the platform sets.
// Linux/Windows/Web cast from a typed object, not this map, so they're out of scope.
const _defaults = <String, dynamic>{
  // macOS
  'name': 'Test Device',
  'computerName': 'Test Device',
  'hostName': 'test.local',
  'arch': 'arm64',
  'model': 'TestDevice',
  'modelName': 'Test Device',
  'kernelVersion': 'test',
  'osRelease': '14.0',
  'majorVersion': 14,
  'minorVersion': 0,
  'patchVersion': 0,
  'activeCPUs': 8,
  'memorySize': 0,
  'cpuFrequency': 0,
  'systemGUID': 'test-guid',
  // Android
  'version': {
    'codename': 'REL',
    'incremental': '0',
    'release': '14',
    'sdkInt': 34,
    'previewSdkInt': 0,
    'baseOS': '',
    'securityPatch': '',
  },
  'board': 'test',
  'bootloader': 'test',
  'brand': 'Google',
  'device': 'test',
  'display': 'test',
  'fingerprint': 'test',
  'hardware': 'test',
  'host': 'test',
  'id': 'test-id',
  'manufacturer': 'Google',
  'product': 'test',
  'tags': 'release-keys',
  'type': 'user',
  'isPhysicalDevice': true,
  'isLowRamDevice': false,
  'systemFeatures': <String>[],
  'supported32BitAbis': <String>[],
  'supported64BitAbis': <String>[],
  'supportedAbis': <String>[],
  'freeDiskSize': 0,
  'totalDiskSize': 0,
  'physicalRamSize': 0,
  'availableRamSize': 0,
  // iOS
  'systemName': 'iOS',
  'systemVersion': '17.0',
  'localizedModel': 'iPhone',
  'identifierForVendor': 'test-vendor-id',
  'isiOSAppOnMac': false,
  'isiOSAppOnVision': false,
  'utsname': {
    'sysname': 'Darwin',
    'nodename': 'test',
    'release': '23.0.0',
    'version': 'test',
    'machine': 'arm64',
  },
};

/// Scripts what `DeviceInfoPlugin().deviceInfo` (and `androidInfo` / `iosInfo`)
/// return in tests. Pick the platform you're faking:
///
/// ```dart
/// mockDeviceInfo.android.set(manufacturer: 'Google', model: 'Pixel 8', id: '0000');
/// mockDeviceInfo.mac.set(name: 'Ahmed Mac');
/// mockDeviceInfo.iOS.set(systemVersion: '18.0');
/// ```
final mockDeviceInfo = MockDeviceInfo._();

/// Drives a faked `device_info_plus` channel. Defaults to a complete
/// cross-platform map (macOS/Android/iOS); override fields through the platform
/// sets [mac] / [android] / [iOS].
class MockDeviceInfo {
  MockDeviceInfo._();

  MockMethodChannel? _channel;
  Map<String, dynamic> _data = _defaults;
  Duration? _delay;
  Object? _throws;

  late final mac = MockMacDeviceInfo._(this);
  late final android = MockAndroidDeviceInfo._(this);
  late final iOS = MockIosDeviceInfo._(this);

  /// Installs the channel mock and resets to the default info. The harness calls
  /// this once per test.
  void install() {
    _data = _defaults;
    _delay = null;
    _throws = null;
    _channel = mockChannel(_channelName);
    _apply();
    addTearDown(() => _channel = null);
  }

  /// Escape hatch for keys the platform sets don't cover.
  void set({Map<String, dynamic> extra = const {}}) => _merge(extra);

  /// Delays the channel response by [duration] so `DeviceInfoPlugin().deviceInfo`
  /// (and `androidInfo` / `iosInfo`) stay pending — lets a test observe the
  /// device-info loading state before it resolves.
  void delay(Duration duration) {
    _delay = duration;
    _apply();
  }

  /// Makes the channel throw [error] (default: a generic exception) instead of
  /// returning device info — lets a test exercise the lookup-failure path.
  void throwError([Object? error]) {
    _throws = error ?? Exception('device info unavailable');
    _apply();
  }

  void _merge(Map<String, dynamic> fields) {
    _data = {..._data, ...fields};
    _apply();
  }

  Map<String, dynamic>? _overlay(String key, Map<String, dynamic>? override) {
    if (override == null) return null;
    final base = (_data[key] as Map?)?.cast<String, dynamic>() ?? const {};
    return {...base, ...override};
  }

  void _apply() {
    _channel?.when(
      method: 'getDeviceInfo',
      returns: _data,
      throws: _throws,
      delay: _delay,
    );
  }
}

/// macOS fields, as decoded by `MacOsDeviceInfo`.
class MockMacDeviceInfo {
  MockMacDeviceInfo._(this._owner);
  final MockDeviceInfo _owner;

  void set({
    String? name,
    String? computerName,
    String? hostName,
    String? arch,
    String? model,
    String? modelName,
    String? kernelVersion,
    String? osRelease,
    int? majorVersion,
    int? minorVersion,
    int? patchVersion,
    int? activeCPUs,
    int? memorySize,
    int? cpuFrequency,
    String? systemGUID,
  }) {
    _owner._merge({
      'name': ?name,
      'computerName': ?computerName,
      'hostName': ?hostName,
      'arch': ?arch,
      'model': ?model,
      'modelName': ?modelName,
      'kernelVersion': ?kernelVersion,
      'osRelease': ?osRelease,
      'majorVersion': ?majorVersion,
      'minorVersion': ?minorVersion,
      'patchVersion': ?patchVersion,
      'activeCPUs': ?activeCPUs,
      'memorySize': ?memorySize,
      'cpuFrequency': ?cpuFrequency,
      'systemGUID': ?systemGUID,
    });
  }
}

/// Android fields, as decoded by `AndroidDeviceInfo`. [version] merges onto the
/// default `AndroidBuildVersion` sub-map (e.g. `{'sdkInt': 30, 'release': '11'}`).
class MockAndroidDeviceInfo {
  MockAndroidDeviceInfo._(this._owner);
  final MockDeviceInfo _owner;

  void set({
    String? name,
    String? model,
    String? manufacturer,
    String? brand,
    String? id,
    String? board,
    String? bootloader,
    String? device,
    String? display,
    String? fingerprint,
    String? hardware,
    String? host,
    String? product,
    String? tags,
    String? type,
    bool? isPhysicalDevice,
    bool? isLowRamDevice,
    List<String>? systemFeatures,
    List<String>? supported32BitAbis,
    List<String>? supported64BitAbis,
    List<String>? supportedAbis,
    int? freeDiskSize,
    int? totalDiskSize,
    int? physicalRamSize,
    int? availableRamSize,
    Map<String, dynamic>? version,
  }) {
    _owner._merge({
      'name': ?name,
      'model': ?model,
      'manufacturer': ?manufacturer,
      'brand': ?brand,
      'id': ?id,
      'board': ?board,
      'bootloader': ?bootloader,
      'device': ?device,
      'display': ?display,
      'fingerprint': ?fingerprint,
      'hardware': ?hardware,
      'host': ?host,
      'product': ?product,
      'tags': ?tags,
      'type': ?type,
      'isPhysicalDevice': ?isPhysicalDevice,
      'isLowRamDevice': ?isLowRamDevice,
      'systemFeatures': ?systemFeatures,
      'supported32BitAbis': ?supported32BitAbis,
      'supported64BitAbis': ?supported64BitAbis,
      'supportedAbis': ?supportedAbis,
      'freeDiskSize': ?freeDiskSize,
      'totalDiskSize': ?totalDiskSize,
      'physicalRamSize': ?physicalRamSize,
      'availableRamSize': ?availableRamSize,
      'version': ?_owner._overlay('version', version),
    });
  }
}

/// iOS fields, as decoded by `IosDeviceInfo`. [utsname] merges onto the default
/// `IosUtsname` sub-map (e.g. `{'machine': 'iPhone16,2'}`).
class MockIosDeviceInfo {
  MockIosDeviceInfo._(this._owner);
  final MockDeviceInfo _owner;

  void set({
    String? name,
    String? systemName,
    String? systemVersion,
    String? model,
    String? modelName,
    String? localizedModel,
    String? identifierForVendor,
    bool? isPhysicalDevice,
    bool? isiOSAppOnMac,
    bool? isiOSAppOnVision,
    int? freeDiskSize,
    int? totalDiskSize,
    int? physicalRamSize,
    int? availableRamSize,
    Map<String, dynamic>? utsname,
  }) {
    _owner._merge({
      'name': ?name,
      'systemName': ?systemName,
      'systemVersion': ?systemVersion,
      'model': ?model,
      'modelName': ?modelName,
      'localizedModel': ?localizedModel,
      'identifierForVendor': ?identifierForVendor,
      'isPhysicalDevice': ?isPhysicalDevice,
      'isiOSAppOnMac': ?isiOSAppOnMac,
      'isiOSAppOnVision': ?isiOSAppOnVision,
      'freeDiskSize': ?freeDiskSize,
      'totalDiskSize': ?totalDiskSize,
      'physicalRamSize': ?physicalRamSize,
      'availableRamSize': ?availableRamSize,
      'utsname': ?_owner._overlay('utsname', utsname),
    });
  }
}
