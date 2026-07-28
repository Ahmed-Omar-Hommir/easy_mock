import 'dart:io';

import 'package:easy_mock_io/easy_mock_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => IOOverrides.global = null);

  test('routes dart:io File through the in-memory filesystem', () {
    mockMemoryIO.install();

    File('/notes/todo.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('hi');

    expect(File('/notes/todo.txt').readAsStringSync(), 'hi');

    IOOverrides.global = null;
    expect(File('/notes/todo.txt').existsSync(), isFalse);
  });

  test('pre-creates /app_root', () {
    mockMemoryIO.install();

    expect(Directory('/app_root').existsSync(), isTrue);
  });

  test('starts from a pre-seeded filesystem when one is passed', () {
    final fs = MemoryFileSystem();
    fs.file('/seed.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('from seed');

    mockMemoryIO.install(fs);

    expect(File('/seed.txt').readAsStringSync(), 'from seed');
  });

  test('file locks are no-ops instead of throwing or deadlocking', () async {
    mockMemoryIO.install();

    final file = File('/data.bin')..writeAsBytesSync([1, 2, 3]);
    final raf = file.openSync(mode: FileMode.append);

    raf.lockSync();
    await raf.lock();
    raf.unlockSync();
    await raf.unlock();
    raf.closeSync();

    expect(File('/data.bin').readAsBytesSync(), [1, 2, 3]);
  });
}
