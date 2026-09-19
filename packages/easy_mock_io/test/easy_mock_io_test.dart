import 'dart:io';

import 'package:easy_mock_io/easy_mock_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => IOOverrides.global = null);

  test('routes dart:io File through the in-memory filesystem', () {
    mockMemoryIO.init();

    File('/notes/todo.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('hi');

    expect(File('/notes/todo.txt').readAsStringSync(), 'hi');

    IOOverrides.global = null;
    expect(File('/notes/todo.txt').existsSync(), isFalse);
  });

  test('pre-creates /app_root', () {
    mockMemoryIO.init();

    expect(Directory('/app_root').existsSync(), isTrue);
  });

  test(
    'default application directories are ready for in-memory writes',
    () async {
      final fs = MemoryFileSystem();
      mockMemoryIO.init(fs);

      for (final relative in [
        'tmp',
        'support',
        'library',
        'documents',
        'cache',
        'downloads',
        'external/cache',
        'external/files',
        'external/files/music',
        'external/files/podcasts',
        'external/files/ringtones',
        'external/files/alarms',
        'external/files/notifications',
        'external/files/pictures',
        'external/files/movies',
        'external/files/downloads',
        'external/files/dcim',
        'external/files/documents',
      ]) {
        final directory = Directory('/app_root/$relative');
        expect(directory.existsSync(), isTrue, reason: directory.path);
        final file = File('${directory.path}/example.txt');
        await file.writeAsString(relative);
        expect(await file.readAsString(), relative);
        expect(fs.file(file.path).readAsStringSync(), relative);
      }
    },
  );

  test('application directories follow a custom root', () {
    mockMemoryIO.init(null, const MemoryIOConfig(rootDirPath: '/custom/app'));

    for (final relative in [
      'tmp',
      'support',
      'library',
      'documents',
      'cache',
      'downloads',
      'external/cache',
      'external/files',
      'external/files/downloads',
    ]) {
      final directory = Directory('/custom/app/$relative');
      expect(directory.existsSync(), isTrue, reason: directory.path);
      final file = File('${directory.path}/example.txt');
      file.writeAsStringSync('custom root');
      expect(file.readAsStringSync(), 'custom root');
    }
    expect(Directory('/app_root').existsSync(), isFalse);
  });

  test('creating the layout preserves pre-seeded application files', () {
    final fs = MemoryFileSystem();
    fs.file('/app_root/documents/notes.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('existing notes');

    mockMemoryIO.init(fs);

    expect(
      File('/app_root/documents/notes.txt').readAsStringSync(),
      'existing notes',
    );
    expect(Directory('/app_root/tmp').existsSync(), isTrue);
  });

  test('starts from a pre-seeded filesystem when one is passed', () {
    final fs = MemoryFileSystem();
    fs.file('/seed.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('from seed');

    mockMemoryIO.init(fs);

    expect(File('/seed.txt').readAsStringSync(), 'from seed');
  });

  test('file locks are no-ops instead of throwing or deadlocking', () async {
    mockMemoryIO.init();

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
