# easy_mock_path_provider

A readable test mock for [`path_provider`](https://pub.dev/packages/path_provider)
with default values for every directory lookup.

Built on `easy_mock_channel`, like the other channel-based Easy Mock helpers.
Mocks `plugins.flutter.io/path_provider` directly, with no dependency on the real
plugin.

This covers the method-channel implementation. Platform implementations using
Pigeon, FFI, or other channel names are outside its scope. It does not change
which implementation the plugin selects or bypass the plugin's platform checks.

## Usage

Add `easy_mock_path_provider` to your app's `dev_dependencies`.

```dart
import 'package:easy_mock_path_provider/easy_mock_path_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(mockPathProvider.init);

  test('uses default paths', () async {
    final directory = await getApplicationDocumentsDirectory();
    expect(directory.path, '/mock/path_provider/documents');
  });

  test('overrides paths', () async {
    mockPathProvider.set(
      temporaryPath: '/test/temp',
      applicationDocumentsPath: '/test/documents',
    );

    expect((await getTemporaryDirectory()).path, '/test/temp');
    expect((await getApplicationDocumentsDirectory()).path, '/test/documents');
  });
}
```

`init()` resets all values and uses Easy Mock to remove the channel handler at
teardown. Call it from `setUp` or inside a test.

## Default values

Every path can be overridden with the corresponding named argument to `set`.
Omitted or null arguments retain the current value.

| `set` argument | Default value |
| --- | --- |
| `temporaryPath` | `/mock/path_provider/temporary` |
| `applicationSupportPath` | `/mock/path_provider/support` |
| `libraryPath` | `/mock/path_provider/library` |
| `applicationDocumentsPath` | `/mock/path_provider/documents` |
| `applicationCachePath` | `/mock/path_provider/cache` |
| `externalStoragePath` | `/mock/path_provider/external` |
| `externalCachePaths` | `['/mock/path_provider/external_cache']` |
| `externalStoragePaths` | `['/mock/path_provider/external']` |
| `downloadsPath` | `/mock/path_provider/downloads` |

`getExternalStorageDirectories(type: StorageDirectory.downloads)` appends
`/downloads` to each configured `externalStoragePaths` base path. Other storage
types append their enum name. Passing an empty list returns no directories.

The mock supplies paths only; it does not create directories. For tests that
write files, use temporary directories you create yourself or pair this helper
with `easy_mock_io` and create the directories in its in-memory filesystem.

## Loading and failure states

```dart
mockPathProvider.delay(const Duration(milliseconds: 300));
mockPathProvider.throwError(Exception('storage unavailable'));
```

These apply to all mocked channel methods and reset on `init()`. Errors reach the
caller as `PlatformException`s. In widget tests, pump the configured duration to
advance delayed lookups.
