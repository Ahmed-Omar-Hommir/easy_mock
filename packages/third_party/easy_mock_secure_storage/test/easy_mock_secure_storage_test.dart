import 'dart:async';

import 'package:easy_mock_secure_storage/easy_mock_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  Future<Object?> invoke(String method, [Map<String, Object?>? args]) =>
      channel.invokeMethod<Object?>(method, args);

  setUp(mockSecureStorage.install);

  test('starts empty', () async {
    expect(await invoke('read', {'key': 'k'}), isNull);
    expect(mockSecureStorage.stored, isEmpty);
  });

  test('a write is read back through the channel and via read()', () async {
    await invoke('write', {'key': 'k', 'value': 'v'});

    expect(await invoke('read', {'key': 'k'}), 'v');
    expect(mockSecureStorage.read('k'), 'v');
  });

  test('seed primes what the channel returns', () async {
    mockSecureStorage.seed({'unique_device_id': 'abc'});

    expect(await invoke('read', {'key': 'unique_device_id'}), 'abc');
  });

  test('delete removes a key; containsKey reflects it', () async {
    mockSecureStorage.seed({'k': 'v'});

    expect(await invoke('containsKey', {'key': 'k'}), isTrue);
    await invoke('delete', {'key': 'k'});
    expect(await invoke('containsKey', {'key': 'k'}), isFalse);
  });

  test('install resets the store between tests', () async {
    expect(mockSecureStorage.stored, isEmpty);
  });

  test('delay keeps the response pending without changing the value', () async {
    mockSecureStorage.seed({'k': 'v'});
    mockSecureStorage.delay(const Duration(milliseconds: 50));

    var resolved = false;
    final future = invoke('read', {'key': 'k'});
    unawaited(future.then((_) => resolved = true));

    // A zero-delay turn fires before the 50ms response.
    await Future<void>.delayed(Duration.zero);
    expect(resolved, isFalse, reason: 'read should still be pending');

    expect(await future, 'v');
  });
}
