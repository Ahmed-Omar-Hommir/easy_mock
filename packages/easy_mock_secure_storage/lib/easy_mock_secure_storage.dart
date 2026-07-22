import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// flutter_secure_storage's method channel. This package speaks its raw method
// codes (read/write/delete/...), so it needs NO dependency on the plugin.
const _channelName = 'plugins.it_nomads.com/flutter_secure_storage';

/// Backs `flutter_secure_storage` with an in-memory store in tests. Seed what
/// the app should read, then read back what it wrote:
///
/// ```dart
/// mockSecureStorage.seed({'unique_device_id': 'abc'}); // app reads this
/// // ... run the flow ...
/// expect(mockSecureStorage.read('unique_device_id'), isNotNull);
/// ```
final mockSecureStorage = MockSecureStorage._();

/// Drives a faked `flutter_secure_storage` channel: a real `write` is read back
/// by a later `read`, and the store is seedable/inspectable from the test.
class MockSecureStorage {
  MockSecureStorage._();

  final Map<String, String> _store = <String, String>{};
  Duration? _delay;

  /// Wires the channel mock and clears the store. The harness calls this once
  /// per test.
  void install() {
    _store.clear();
    _delay = null;
    const channel = MethodChannel(_channelName);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, _handle);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  }

  /// Replaces the store with [data] — the keys the app will read.
  void seed(Map<String, String> data) {
    _store
      ..clear()
      ..addAll(data);
  }

  /// Delays every channel response by [duration] so a read/write stays pending
  /// — lets a test observe a loading state before secure storage resolves.
  void delay(Duration duration) => _delay = duration;

  /// A read-only view of everything currently stored.
  Map<String, String> get stored => Map.unmodifiable(_store);

  /// The value the app wrote under [key], or null.
  String? read(String key) => _store[key];

  Future<Object?> _handle(MethodCall call) async {
    final delay = _delay;
    if (delay != null) await Future<void>.delayed(delay);
    final args = (call.arguments as Map?)?.cast<String, Object?>() ?? const {};
    final key = args['key'] as String?;
    switch (call.method) {
      case 'read':
        return _store[key];
      case 'write':
        _store[key!] = args['value'] as String;
        return null;
      case 'delete':
        _store.remove(key);
        return null;
      case 'deleteAll':
        _store.clear();
        return null;
      case 'containsKey':
        return _store.containsKey(key);
      case 'readAll':
        return Map<String, String>.from(_store);
      default:
        return null;
    }
  }
}
