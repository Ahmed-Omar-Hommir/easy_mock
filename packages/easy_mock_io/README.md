# easy_mock_io

In-memory `dart:io` for Flutter tests. `MockMemoryIO.install()` replaces
`IOOverrides.global` with a [`MemoryFileSystem`], so every `File` / `Directory`
your code under test touches runs in memory instead of hitting the real disk —
no temp files to clean up, and tests stay isolated from each other.

## Usage

```dart
import 'package:easy_mock_io/easy_mock_io.dart';

setUp(() => MockMemoryIO.install());
tearDown(() => IOOverrides.global = null);

test('writes go to memory, not disk', () {
  File('/notes/todo.txt')
    ..createSync(recursive: true)
    ..writeAsStringSync('hi');

  expect(File('/notes/todo.txt').readAsStringSync(), 'hi');
});
```

- **`MockMemoryIO.install([MemoryFileSystem? fs])`** installs the override. Pass
  a pre-seeded filesystem to start with files already present; omit it for an
  empty one.
- **File locks are no-ops.** `lock` / `unlock` (sync and async) return
  immediately, so tests that open the same path in parallel can't deadlock on an
  exclusive lock the memory filesystem wouldn't honour anyway.
- **Assets are seeded** from the folder named by the `UNIT_TEST_ASSETS`
  environment variable, and `/app_root` is created up front.

`install` sets `IOOverrides.global`; reset it with `IOOverrides.global = null`
in `tearDown` (or install a fresh one per test) so overrides don't leak.

[`MemoryFileSystem`]: https://pub.dev/packages/file
