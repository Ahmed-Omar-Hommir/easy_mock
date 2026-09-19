import 'package:easy_mock_channel/easy_mock_channel.dart';
import 'package:flutter_test/flutter_test.dart';

const _channelName = 'plugins.flutter.io/path_provider';

const _defaults = <String, Object>{
  'getTemporaryDirectory': '/mock/path_provider/temporary',
  'getApplicationSupportDirectory': '/mock/path_provider/support',
  'getLibraryDirectory': '/mock/path_provider/library',
  'getApplicationDocumentsDirectory': '/mock/path_provider/documents',
  'getApplicationCacheDirectory': '/mock/path_provider/cache',
  'getStorageDirectory': '/mock/path_provider/external',
  'getExternalCacheDirectories': ['/mock/path_provider/external_cache'],
  'getExternalStorageDirectories': ['/mock/path_provider/external'],
  'getDownloadsDirectory': '/mock/path_provider/downloads',
};

// StorageDirectory's wire indices, so no path_provider dependency is needed.
const _storageTypes = [
  'music',
  'podcasts',
  'ringtones',
  'alarms',
  'notifications',
  'pictures',
  'movies',
  'downloads',
  'dcim',
  'documents',
];

/// Scripts paths returned by path_provider's method channel in tests.
///
/// ```dart
/// setUp(mockPathProvider.init);
/// // In a test:
/// mockPathProvider.set(applicationDocumentsPath: '/test/documents');
/// ```
final mockPathProvider = MockPathProvider._();

/// Mocks `plugins.flutter.io/path_provider` through easy_mock_channel.
///
/// Defaults to paths under `/mock/path_provider`. Supplies paths without
/// creating directories. Implementations using other channels, Pigeon, or FFI
/// are outside the scope of this method-channel mock.
class MockPathProvider {
  MockPathProvider._();

  MockMethodChannel? _channel;
  Map<String, Object> _paths = _defaults;
  Duration? _delay;
  Object? _throws;

  /// Installs the channel mock and resets paths, delays, and errors to defaults.
  ///
  /// Call in `setUp` or inside a test. The handler is removed at teardown.
  void init() {
    _paths = _defaults;
    _delay = null;
    _throws = null;
    _channel = mockChannel(_channelName);
    _apply();
    addTearDown(() => _channel = null);
  }

  /// Overrides supplied paths, retaining all other values.
  ///
  /// External storage paths are base directories. Typed storage requests append
  /// the type's name (for example, `/downloads`). Empty external path lists
  /// simulate having no external directories.
  void set({
    String? temporaryPath,
    String? applicationSupportPath,
    String? libraryPath,
    String? applicationDocumentsPath,
    String? applicationCachePath,
    String? externalStoragePath,
    List<String>? externalCachePaths,
    List<String>? externalStoragePaths,
    String? downloadsPath,
  }) {
    _paths = {
      ..._paths,
      'getTemporaryDirectory': ?temporaryPath,
      'getApplicationSupportDirectory': ?applicationSupportPath,
      'getLibraryDirectory': ?libraryPath,
      'getApplicationDocumentsDirectory': ?applicationDocumentsPath,
      'getApplicationCacheDirectory': ?applicationCachePath,
      'getStorageDirectory': ?externalStoragePath,
      if (externalCachePaths != null)
        'getExternalCacheDirectories': List<String>.of(externalCachePaths),
      if (externalStoragePaths != null)
        'getExternalStorageDirectories': List<String>.of(externalStoragePaths),
      'getDownloadsDirectory': ?downloadsPath,
    };
    _apply();
  }

  /// Delays every channel response to exercise loading states.
  void delay(Duration duration) {
    _delay = duration;
    _apply();
  }

  /// Makes every directory lookup fail until the next [init].
  ///
  /// Errors are encoded by the method channel as platform exceptions.
  void throwError([Object? error]) {
    _throws = error ?? Exception('path provider unavailable');
    _apply();
  }

  void _apply() {
    final channel = _channel;
    if (channel == null) return;

    for (final entry in _paths.entries) {
      channel.when(
        method: entry.key,
        returns: entry.value,
        throws: _throws,
        delay: _delay,
      );
    }

    final externalPaths =
        _paths['getExternalStorageDirectories'] as List<String>;
    for (var index = 0; index < _storageTypes.length; index++) {
      channel.when(
        method: 'getExternalStorageDirectories',
        arguments: {'type': index},
        returns: [
          for (final path in externalPaths)
            '${path.replaceFirst(RegExp(r'[/\\]+$'), '')}/${_storageTypes[index]}',
        ],
        throws: _throws,
        delay: _delay,
      );
    }
  }
}
