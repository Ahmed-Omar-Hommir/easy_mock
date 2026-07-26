import 'package:easy_mock_channel/easy_mock_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

export 'package:easy_mock_channel/easy_mock_channel.dart'
    show MockMethodChannel, mockChannel;

const _json = JSONMethodCodec();
const _standard = StandardMethodCodec();

class _ChannelSpec {
  const _ChannelSpec(this.name, this.codec, [this.defaults = const {}]);

  final String name;
  final MethodCodec codec;
  final Map<String, Object?> defaults;
}

// Every SystemChannels method channel, with the SAME codec the framework uses
// (most are StandardMethodCodec; the JSON ones are called out). Each unstubbed
// method returns null — the [defaults] only cover the few methods whose callers
// would choke on a null reply.
//
// flutter/textinput is deliberately absent: it is handled by the framework's
// TestTextInput (see [install]), not by a plain mock.
const _specs = <_ChannelSpec>[
  _ChannelSpec('flutter/platform', _json, {
    'Clipboard.hasStrings': {'value': false},
  }),
  _ChannelSpec('flutter/navigation', _json),
  _ChannelSpec('flutter/status_bar', _json),
  _ChannelSpec('flutter/mousecursor', _standard),
  _ChannelSpec('flutter/contextmenu', _json),
  _ChannelSpec('flutter/undomanager', _json),
  _ChannelSpec('flutter/processtext', _standard),
  _ChannelSpec('flutter/spellcheck', _standard),
  _ChannelSpec('flutter/scribe', _json),
  _ChannelSpec('flutter/menu', _standard),
  _ChannelSpec('flutter/keyboard', _standard, {
    'getKeyboardState': <int, int>{},
  }),
  _ChannelSpec('flutter/restoration', _standard),
  _ChannelSpec('flutter/platform_views', _standard),
  _ChannelSpec('flutter/platform_views_2', _standard),
  _ChannelSpec('flutter/deferredcomponent', _standard),
  _ChannelSpec('flutter/localization', _json),
  _ChannelSpec('flutter/sensitivecontent', _standard),
  _ChannelSpec('flutter/backgesture', _standard),
  _ChannelSpec('flutter/skia', _json),
];

/// Default mocks for Flutter's [SystemChannels]. Install once per test:
///
/// ```dart
/// mockSystemChannels.install();
/// ```
final mockSystemChannels = MockSystemChannels._();

/// Installs a [MockMethodChannel] for every SystemChannels method channel so
/// calls like `HapticFeedback.vibrate()` are answered (default: `null`) and
/// recorded instead of reaching the real platform. Override or assert on any of
/// them through [channel] or the named getters.
class MockSystemChannels {
  MockSystemChannels._();

  final Map<String, MockMethodChannel> _channels = {};

  /// Installs the default mocks and records every call. The harness calls this
  /// once per test; mocks are removed on teardown.
  ///
  /// `flutter/textinput` is not mocked with a canned reply — that channel is owned
  /// by the framework's `TestTextInput`, which patrol registers only during
  /// `enterText` and unregisters afterwards. A null reply on it is harmless, so
  /// [_relaxTextInput] keeps a strict unmocked-channel guard from failing on the
  /// windows where it has no handler (see [installUnmockedChannelGuard]). Install
  /// this AFTER the guard so it can wrap it.
  void install() {
    _channels.clear();
    for (final spec in _specs) {
      final mock = mockChannel(spec.name, codec: spec.codec);
      spec.defaults.forEach(
        (method, value) => mock.when(method: method, returns: value),
      );
      _channels[spec.name] = mock;
    }
    _relaxTextInput();
    addTearDown(_channels.clear);
  }

  void _relaxTextInput() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final inner = messenger.allMessagesHandler;
    if (inner == null) return;
    messenger.allMessagesHandler = (channel, handler, message) {
      if (channel == 'flutter/textinput' && handler == null) return null;
      return inner(channel, handler, message);
    };
  }

  /// The mock for the channel called [name] (e.g. `'flutter/platform'`) —
  /// override with `.when(...)` or assert with `.verify(...)`.
  MockMethodChannel channel(String name) {
    final mock = _channels[name];
    if (mock == null) {
      throw StateError(
        'No SystemChannels mock for "$name". Call mockSystemChannels.install() '
        'first. (flutter/textinput is handled by TestTextInput, not mocked here.)',
      );
    }
    return mock;
  }

  /// `flutter/platform` — HapticFeedback, SystemChrome, SystemSound, Clipboard,
  /// SystemNavigator.
  MockMethodChannel get platform => channel('flutter/platform');

  /// `flutter/navigation` — Router route updates.
  MockMethodChannel get navigation => channel('flutter/navigation');

  /// `flutter/mousecursor` — `activateSystemCursor`.
  MockMethodChannel get mouseCursor => channel('flutter/mousecursor');

  /// `flutter/contextmenu` — show/hide the system context menu.
  MockMethodChannel get contextMenu => channel('flutter/contextmenu');

  /// `flutter/restoration` — state restoration `get` / `put`.
  MockMethodChannel get restoration => channel('flutter/restoration');
}
