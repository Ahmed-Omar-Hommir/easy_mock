import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file/file.dart' as f;
import 'package:file/memory.dart';

export 'package:file/memory.dart' show MemoryFileSystem;

const mockMemoryIO = MockMemoryIO._();

class MockMemoryIO {
  const MockMemoryIO._();

  void install([MemoryFileSystem? memoryFile]) {
    final mf = memoryFile ?? MemoryFileSystem();
    seedTestAssets(mf);

    mf.directory('/app_root').createSync(recursive: true);

    IOOverrides.global = MemoryIOOverrides(mf);
  }
}

void x() async {
  final file = File('./image.png');
  await file.exists();
  await file.readAsBytes();
}

base class MemoryIOOverrides extends IOOverrides {
  MemoryIOOverrides([MemoryFileSystem? fs]) : _fs = fs ?? MemoryFileSystem();

  final MemoryFileSystem _fs;

  @override
  File createFile(String path) => _NoLockFile(_fs.file(path));

  @override
  Directory createDirectory(String path) => _fs.directory(path);

  @override
  Link createLink(String path) => _fs.link(path);

  @override
  Directory getCurrentDirectory() => _fs.currentDirectory;

  @override
  void setCurrentDirectory(String path) => _fs.currentDirectory = path;

  @override
  Directory getSystemTempDirectory() => _fs.systemTempDirectory;

  @override
  Future<FileStat> stat(String path) => _fs.stat(path);

  @override
  FileStat statSync(String path) => _fs.statSync(path);

  @override
  Future<bool> fseIdentical(String path1, String path2) =>
      _fs.identical(path1, path2);

  @override
  bool fseIdenticalSync(String path1, String path2) =>
      _fs.identicalSync(path1, path2);

  @override
  Future<FileSystemEntityType> fseGetType(String path, bool followLinks) =>
      _fs.type(path, followLinks: followLinks);

  @override
  FileSystemEntityType fseGetTypeSync(String path, bool followLinks) =>
      _fs.typeSync(path, followLinks: followLinks);

  @override
  bool fsWatchIsSupported() => _fs.isWatchSupported;

  @override
  Stream<FileSystemEvent> fsWatch(String path, int events, bool recursive) =>
      throw UnsupportedError('watch is not supported by MemoryFileSystem');
}

class _NoLockRaf with f.ForwardingRandomAccessFile {
  _NoLockRaf(this.delegate);

  @override
  final RandomAccessFile delegate;

  @override
  Future<RandomAccessFile> lock([
    FileLock mode = FileLock.exclusive,
    int start = 0,
    int end = -1,
  ]) async {
    return this;
  }

  @override
  void lockSync([
    FileLock mode = FileLock.exclusive,
    int start = 0,
    int end = -1,
  ]) {}

  @override
  Future<RandomAccessFile> unlock([int start = 0, int end = -1]) async {
    return this;
  }

  @override
  void unlockSync([int start = 0, int end = -1]) {}
}

class _NoLockFile implements File {
  _NoLockFile(this.delegate);

  final f.File delegate;

  File _wrap(f.File file) => _NoLockFile(file);

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async =>
      _NoLockRaf(await delegate.open(mode: mode));

  @override
  RandomAccessFile openSync({FileMode mode = FileMode.read}) =>
      _NoLockRaf(delegate.openSync(mode: mode));

  @override
  String get path => delegate.path;

  @override
  Uri get uri => delegate.uri;

  @override
  bool get isAbsolute => delegate.isAbsolute;

  @override
  File get absolute => _wrap(delegate.absolute);

  @override
  Directory get parent => delegate.parent;

  @override
  Future<bool> exists() => delegate.exists();

  @override
  bool existsSync() => delegate.existsSync();

  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) =>
      delegate.create(recursive: recursive, exclusive: exclusive).then(_wrap);

  @override
  void createSync({bool recursive = false, bool exclusive = false}) =>
      delegate.createSync(recursive: recursive, exclusive: exclusive);

  @override
  Future<File> rename(String newPath) => delegate.rename(newPath).then(_wrap);

  @override
  File renameSync(String newPath) => _wrap(delegate.renameSync(newPath));

  @override
  Future<File> copy(String newPath) => delegate.copy(newPath).then(_wrap);

  @override
  File copySync(String newPath) => _wrap(delegate.copySync(newPath));

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      delegate.delete(recursive: recursive);

  @override
  void deleteSync({bool recursive = false}) =>
      delegate.deleteSync(recursive: recursive);

  @override
  Future<int> length() => delegate.length();

  @override
  int lengthSync() => delegate.lengthSync();

  @override
  Future<DateTime> lastAccessed() => delegate.lastAccessed();

  @override
  DateTime lastAccessedSync() => delegate.lastAccessedSync();

  @override
  Future<void> setLastAccessed(DateTime time) => delegate.setLastAccessed(time);

  @override
  void setLastAccessedSync(DateTime time) => delegate.setLastAccessedSync(time);

  @override
  Future<DateTime> lastModified() => delegate.lastModified();

  @override
  DateTime lastModifiedSync() => delegate.lastModifiedSync();

  @override
  Future<void> setLastModified(DateTime time) => delegate.setLastModified(time);

  @override
  void setLastModifiedSync(DateTime time) => delegate.setLastModifiedSync(time);

  @override
  Stream<List<int>> openRead([int? start, int? end]) =>
      delegate.openRead(start, end);

  @override
  IOSink openWrite({
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
  }) => delegate.openWrite(mode: mode, encoding: encoding);

  @override
  Future<Uint8List> readAsBytes() => delegate.readAsBytes();

  @override
  Uint8List readAsBytesSync() => delegate.readAsBytesSync();

  @override
  Future<String> readAsString({Encoding encoding = utf8}) =>
      delegate.readAsString(encoding: encoding);

  @override
  String readAsStringSync({Encoding encoding = utf8}) =>
      delegate.readAsStringSync(encoding: encoding);

  @override
  Future<List<String>> readAsLines({Encoding encoding = utf8}) =>
      delegate.readAsLines(encoding: encoding);

  @override
  List<String> readAsLinesSync({Encoding encoding = utf8}) =>
      delegate.readAsLinesSync(encoding: encoding);

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) => delegate.writeAsBytes(bytes, mode: mode, flush: flush).then(_wrap);

  @override
  void writeAsBytesSync(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) => delegate.writeAsBytesSync(bytes, mode: mode, flush: flush);

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) => delegate
      .writeAsString(contents, mode: mode, encoding: encoding, flush: flush)
      .then(_wrap);

  @override
  void writeAsStringSync(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) => delegate.writeAsStringSync(
    contents,
    mode: mode,
    encoding: encoding,
    flush: flush,
  );

  @override
  Future<FileStat> stat() => delegate.stat();

  @override
  FileStat statSync() => delegate.statSync();

  @override
  Stream<FileSystemEvent> watch({
    int events = FileSystemEvent.all,
    bool recursive = false,
  }) => delegate.watch(events: events, recursive: recursive);

  @override
  Future<String> resolveSymbolicLinks() => delegate.resolveSymbolicLinks();

  @override
  String resolveSymbolicLinksSync() => delegate.resolveSymbolicLinksSync();
}

void seedTestAssets(MemoryFileSystem fs) {
  final cache = _loadAssetsFromDisk();
  cache.forEach((path, bytes) {
    fs.file(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
  });
}

Map<String, Uint8List> _loadAssetsFromDisk() {
  final out = <String, Uint8List>{};
  final folder = Platform.environment['UNIT_TEST_ASSETS'];
  if (folder == null) return out;
  final dir = Directory(folder);
  if (!dir.existsSync()) return out;
  for (final e in dir.listSync(recursive: true)) {
    if (e is File) out[e.path] = e.readAsBytesSync();
  }
  return out;
}
