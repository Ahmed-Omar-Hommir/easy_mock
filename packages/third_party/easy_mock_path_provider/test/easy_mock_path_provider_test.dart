import 'package:easy_mock_path_provider/easy_mock_path_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const channel = MethodChannel('plugins.flutter.io/path_provider');

Future<String?> readPath(String method) => channel.invokeMethod<String>(method);

Future<List<String>?> readPaths(String method, [Object? arguments]) =>
    channel.invokeListMethod<String>(method, arguments);

Future<Map<String, Object?>> directoryPaths() async => {
  'temporary': await readPath('getTemporaryDirectory'),
  'support': await readPath('getApplicationSupportDirectory'),
  'library': await readPath('getLibraryDirectory'),
  'documents': await readPath('getApplicationDocumentsDirectory'),
  'cache': await readPath('getApplicationCacheDirectory'),
  'external': await readPath('getStorageDirectory'),
  'externalCaches': await readPaths('getExternalCacheDirectories'),
  'externalStorage': await readPaths('getExternalStorageDirectories', {
    'type': null,
  }),
  'downloads': await readPath('getDownloadsDirectory'),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Registered first so this checks cleanup after Easy Mock's teardown.
    addTearDown(() {
      expect(
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .checkMockMessageHandler(channel.name, null),
        isTrue,
      );
    });
    mockPathProvider.init();
  });

  test('every directory channel method has a default', () async {
    expect(await directoryPaths(), {
      'temporary': '/mock/path_provider/temporary',
      'support': '/mock/path_provider/support',
      'library': '/mock/path_provider/library',
      'documents': '/mock/path_provider/documents',
      'cache': '/mock/path_provider/cache',
      'external': '/mock/path_provider/external',
      'externalCaches': ['/mock/path_provider/external_cache'],
      'externalStorage': ['/mock/path_provider/external'],
      'downloads': '/mock/path_provider/downloads',
    });
  });

  test('all paths can be overridden', () async {
    mockPathProvider.set(
      temporaryPath: '/test/temp',
      applicationSupportPath: '/test/support',
      libraryPath: '/test/library',
      applicationDocumentsPath: '/test/docs',
      applicationCachePath: '/test/cache',
      externalStoragePath: '/test/external',
      externalCachePaths: ['/test/cache1', '/test/cache2'],
      externalStoragePaths: ['/test/storage1', '/test/storage2'],
      downloadsPath: '/test/downloads',
    );

    expect(await directoryPaths(), {
      'temporary': '/test/temp',
      'support': '/test/support',
      'library': '/test/library',
      'documents': '/test/docs',
      'cache': '/test/cache',
      'external': '/test/external',
      'externalCaches': ['/test/cache1', '/test/cache2'],
      'externalStorage': ['/test/storage1', '/test/storage2'],
      'downloads': '/test/downloads',
    });
  });

  test('partial updates retain earlier overrides and other defaults', () async {
    mockPathProvider.set(temporaryPath: '/test/temp');
    mockPathProvider.set(applicationDocumentsPath: '/test/docs');

    expect(await readPath('getTemporaryDirectory'), '/test/temp');
    expect(await readPath('getApplicationDocumentsDirectory'), '/test/docs');
    expect(
      await readPath('getApplicationSupportDirectory'),
      '/mock/path_provider/support',
    );
  });

  test(
    'external storage wire types apply to every configured base path',
    () async {
      mockPathProvider.set(externalStoragePaths: ['/test/one/', '/test/two']);
      const types = [
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

      for (var index = 0; index < types.length; index++) {
        expect(
          await readPaths('getExternalStorageDirectories', {'type': index}),
          ['/test/one/${types[index]}', '/test/two/${types[index]}'],
        );
      }
    },
  );

  test('external paths are copied on input and output', () async {
    final paths = ['/test/external'];
    mockPathProvider.set(
      externalCachePaths: paths,
      externalStoragePaths: paths,
    );
    paths.clear();

    (await readPaths('getExternalCacheDirectories'))![0] = '/changed';
    (await readPaths('getExternalStorageDirectories'))![0] = '/changed';

    expect(await readPaths('getExternalCacheDirectories'), ['/test/external']);
    expect(await readPaths('getExternalStorageDirectories'), [
      '/test/external',
    ]);
  });

  test('empty external lists simulate no available directories', () async {
    mockPathProvider.set(externalCachePaths: [], externalStoragePaths: []);

    expect(await readPaths('getExternalCacheDirectories'), isEmpty);
    expect(await readPaths('getExternalStorageDirectories'), isEmpty);
    expect(
      await readPaths('getExternalStorageDirectories', {'type': 7}),
      isEmpty,
    );
  });

  test('lookup errors propagate through the method channel', () async {
    mockPathProvider.throwError(
      PlatformException(
        code: 'unavailable',
        message: 'storage unavailable',
        details: 'offline',
      ),
    );
    final matcher = throwsA(
      isA<PlatformException>()
          .having((error) => error.code, 'code', 'unavailable')
          .having((error) => error.message, 'message', 'storage unavailable')
          .having((error) => error.details, 'details', 'offline'),
    );

    await expectLater(readPath('getTemporaryDirectory'), matcher);
    await expectLater(
      readPaths('getExternalStorageDirectories', {'type': 7}),
      matcher,
    );
    await expectLater(readPath('getDownloadsDirectory'), matcher);
  });

  test('default error is encoded as a platform exception', () async {
    mockPathProvider.throwError();
    await expectLater(
      readPath('getTemporaryDirectory'),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.message,
          'message',
          contains('path provider unavailable'),
        ),
      ),
    );
  });

  testWidgets('directory lookups stay pending for the configured delay', (
    tester,
  ) async {
    mockPathProvider.delay(const Duration(milliseconds: 300));
    var completed = false;
    final lookup = readPath('getTemporaryDirectory').then((path) {
      completed = true;
      return path;
    });

    await tester.pump(const Duration(milliseconds: 299));
    expect(completed, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    expect(completed, isTrue);
    expect(await lookup, '/mock/path_provider/temporary');
  });

  testWidgets('repeated init resets paths, delay, and errors', (tester) async {
    final defaults = await directoryPaths();
    mockPathProvider.set(
      temporaryPath: '/changed',
      applicationSupportPath: '/changed',
      libraryPath: '/changed',
      applicationDocumentsPath: '/changed',
      applicationCachePath: '/changed',
      externalStoragePath: '/changed',
      externalCachePaths: [],
      externalStoragePaths: [],
      downloadsPath: '/changed',
    );
    mockPathProvider.delay(const Duration(days: 1));
    mockPathProvider.throwError();
    mockPathProvider.init();

    // No clock advance is needed after resetting the delay.
    expect(await directoryPaths(), defaults);
    expect(await readPaths('getExternalStorageDirectories', {'type': 7}), [
      '/mock/path_provider/external/downloads',
    ]);
  });
}
