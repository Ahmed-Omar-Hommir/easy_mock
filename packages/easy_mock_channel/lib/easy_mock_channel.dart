import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stack_trace/stack_trace.dart';

/// Fails the current test if the app sends a message on a platform channel that
/// has no registered mock, instead of hanging on the real platform or silently
/// returning null. The failure names the channel, the method, and the call site
/// that triggered it.
///
/// Flutter's own framework channels (`flutter/*` and `dev.flutter/channel-buffers`)
/// always pass through to the real test delegate. Pass [allow] to let extra
/// channels through by exact name or prefix. Any channel stubbed with
/// [mockChannel] (or another mock handler) is delegated to that mock as usual.
///
/// Install it once per test, alongside your other mock installers:
///
/// ```dart
/// installUnmockedChannelGuard();
/// ```
///
/// The guard removes itself on teardown.
void installUnmockedChannelGuard({Set<String> allow = const {}}) {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final hits = <String, String>{};

  bool isAllowed(String channel) =>
      channel.startsWith('flutter/') ||
      channel == 'dev.flutter/channel-buffers' ||
      allow.any((prefix) => channel == prefix || channel.startsWith(prefix));

  messenger.allMessagesHandler = (channel, handler, message) {
    if (handler != null) return handler(message);
    if (isAllowed(channel)) return messenger.delegate.send(channel, message);

    final method = _decodeMethod(message);
    hits.putIfAbsent(
      '$channel#$method',
      () => '$channel · $method\n${_callSite(Chain.current())}',
    );
    return Future<ByteData?>.error(
      StateError('MissingChannelMock: channel "$channel", method "$method".'),
    );
  };

  addTearDown(() {
    messenger.allMessagesHandler = null;
    if (hits.isEmpty) return;
    fail(
      'Unmocked platform channel(s) called during the test — register a mock '
      '(mockChannel(...)) or allow the channel:\n\n'
      '${hits.values.map((hit) => '  • $hit').join('\n\n')}',
    );
  });
}

const _guardCodec = StandardMethodCodec();

String _decodeMethod(ByteData? message) {
  if (message == null) return '<unknown>';
  try {
    return _guardCodec.decodeMethodCall(message).method;
  } catch (_) {
    return '<unknown>';
  }
}

bool _isNoiseFrame(Frame frame) {
  final uri = frame.uri.toString();
  return uri.startsWith('dart:') ||
      uri.startsWith('package:flutter/') ||
      uri.startsWith('package:flutter_test/') ||
      uri.startsWith('package:stack_trace/') ||
      uri.startsWith('package:easy_mock_channel/');
}

String _framePackage(Frame frame) =>
    frame.uri.scheme == 'package' ? frame.uri.pathSegments.first : frame.uri.path;

/// Renders the async chain as the caller's own frames, deepest first, collapsing
/// consecutive frames from the same package so a single library only shows once.
String _callSite(Chain chain, {int max = 6}) {
  final lines = <String>[];
  String? lastPackage;
  for (final frame in chain.terse.traces.expand((trace) => trace.frames)) {
    if (_isNoiseFrame(frame)) continue;
    final package = _framePackage(frame);
    if (package == lastPackage) continue;
    lastPackage = package;
    lines.add('      ${frame.member ?? '<fn>'}  (${frame.location})');
    if (lines.length == max) break;
  }
  return lines.isEmpty ? '      origin unknown' : lines.join('\n');
}

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
///
/// Pass [codec] for channels that don't use the default [StandardMethodCodec]
/// (e.g. `flutter/platform` uses [JSONMethodCodec]) — it must match the real
/// channel's codec or messages won't decode.
MockMethodChannel mockChannel(
  String name, {
  MethodCodec codec = const StandardMethodCodec(),
}) => MockMethodChannel(name, codec: codec);

const Object _anyArguments = Object();

/// A mock for the single [MethodChannel] named [name].
class MockMethodChannel {
  /// Installs the mock handler for the channel called [name]. Prefer the
  /// [mockChannel] shorthand. Pass [codec] when the channel uses something other
  /// than [StandardMethodCodec].
  MockMethodChannel(this.name, {MethodCodec codec = const StandardMethodCodec()}) {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final channel = MethodChannel(name, codec);
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
