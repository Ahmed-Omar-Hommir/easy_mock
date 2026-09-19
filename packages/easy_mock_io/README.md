# easy_mock_io

In-memory `dart:io` for Flutter tests. `mockMemoryIO.init()` replaces
`IOOverrides.global` with a [`MemoryFileSystem`], so every `File` / `Directory`
your code under test touches runs in memory instead of hitting the real disk —
no temp files to clean up, and tests stay isolated from each other.

## Usage

```dart
import 'dart:io';

import 'package:easy_mock_io/easy_mock_io.dart';
import 'package:flutter_test/flutter_test.dart';

setUp(() => mockMemoryIO.init());
tearDown(() => IOOverrides.global = null);

test('writes go to memory, not disk', () {
  File('/notes/todo.txt')
    ..createSync(recursive: true)
    ..writeAsStringSync('hi');

  expect(File('/notes/todo.txt').readAsStringSync(), 'hi');
});
```

- **`mockMemoryIO.init([MemoryFileSystem? fs, MemoryIOConfig config])`** installs
  the override. Pass a pre-seeded filesystem to start with files already present;
  omit it for a fresh one with the default directories. `config` controls the
  asset seeding and root path. Existing files in a supplied filesystem are kept
  when the directory layout is created.
- **File locks are no-ops.** `lock` / `unlock` (sync and async) return
  immediately, so tests that open the same path in parallel can't deadlock on an
  exclusive lock the memory filesystem wouldn't honour anyway.
- **Assets are seeded** from the folder named by the `UNIT_TEST_ASSETS`
  environment variable and from `MemoryIOConfig.testAssetsDirPath`
  (`test/assets` by default).

`init` sets `IOOverrides.global`; reset it with `IOOverrides.global = null`
in `tearDown` (or install a fresh one per test) so overrides don't leak.

## Default directories

`init()` pre-creates this application directory layout in memory:

| Purpose | Directory |
| --- | --- |
| Temporary files | `/app_root/tmp` |
| Application support | `/app_root/support` |
| Library | `/app_root/library` |
| Application documents | `/app_root/documents` |
| Application cache | `/app_root/cache` |
| Downloads | `/app_root/downloads` |
| External files | `/app_root/external/files` |
| External cache | `/app_root/external/cache` |

Under `external/files`, the `music`, `podcasts`, `ringtones`, `alarms`,
`notifications`, `pictures`, `movies`, `downloads`, `dcim`, and `documents`
subdirectories are also created for common external-storage categories.

Files can be written directly into these directories without creating parents:

```dart
mockMemoryIO.init();
File('/app_root/documents/settings.json').writeAsStringSync('{}');
```

Setting `MemoryIOConfig(rootDirPath: '/custom/app')` creates the same layout
under `/custom/app`. Custom directories outside the pre-created layout must be
created by your test or pre-seeded filesystem.

[`MemoryFileSystem`]: https://pub.dev/packages/file
