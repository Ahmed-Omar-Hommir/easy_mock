import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stubs a platform [MethodChannel] in tests with a fluent `when` API and
/// records every call for verification. The mock handler is installed
/// immediately and removed automatically on test teardown.
///
/// ```dart
/// final channel = mockChannel('flutter.baseflow.com/permissions/methods');
/// channel.when(method: 'checkPermissionStatus', arguments: 1, returns: 0);
/// channel.when(method: 'requestPermissions', returns: {1: 0});
///
/// expect(channel.verify(method: 'requestPermissions').length, 1);
/// ```
MockMethodChannel mockChannel(String name) => MockMethodChannel(name);

const Object _anyArguments = Object();

/// A mock for the single [MethodChannel] named [name].
class MockMethodChannel {
  /// Installs the mock handler for the channel called [name]. Prefer the
  /// [mockChannel] shorthand.
  MockMethodChannel(this.name) {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final channel = MethodChannel(name);
    messenger.setMockMethodCallHandler(channel, _onCall);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  }

  /// The platform channel name this mock intercepts.
  final String name;

  final List<_Stub> _stubs = [];

  /// Every call the channel received, in invocation order.
  final List<MethodCall> calls = [];

  /// Replies to [method] with [returns], or throws [throws] (typically a
  /// [PlatformException]) when supplied.
  ///
  /// When [arguments] is given the stub only matches calls whose `arguments`
  /// deep-equal it (lists and maps included); otherwise it matches any. Later
  /// stubs take precedence over earlier ones.
  ///
  /// (`return` is a reserved word in Dart, so the parameter is named `returns`.)
  void when({
    required String method,
    Object? arguments = _anyArguments,
    Object? returns,
    Object? throws,
    Duration? delay,
  }) {
    _stubs.add(_Stub(method, arguments, returns, throws, delay));
  }

  /// The recorded calls to [method] — assert on `.length`, `.single.arguments`, …
  List<MethodCall> verify({required String method}) =>
      calls.where((call) => call.method == method).toList();

  Future<Object?> _onCall(MethodCall call) async {
    calls.add(call);
    for (final stub in _stubs.reversed) {
      if (stub.matches(call)) {
        if (stub.delay != null) await Future<void>.delayed(stub.delay!);
        final throws = stub.throws;
        if (throws != null) throw throws;
        return stub.returns;
      }
    }
    return null;
  }
}

class _Stub {
  _Stub(this.method, this.arguments, this.returns, this.throws, this.delay);

  final String method;
  final Object? arguments;
  final Object? returns;
  final Object? throws;
  final Duration? delay;

  bool matches(MethodCall call) {
    if (call.method != method) return false;
    if (identical(arguments, _anyArguments)) return true;
    return _deepEquals(call.arguments, arguments);
  }
}

bool _deepEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  return a == b;
}
