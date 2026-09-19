# easy_mock_channel

Fluent `MethodChannel` mocking for Flutter tests — the same `when` / `verify`
ergonomics as a request mock, but for platform channels. It stubs the channel at
the binary-messenger seam (`setMockMethodCallHandler`), so the real plugin Dart
code runs and only the native side is faked.

## Usage

```dart
import 'package:easy_mock_channel/easy_mock_channel.dart';

testWidgets('camera permission is denied', (tester) async {
  final channel = mockChannel('flutter.baseflow.com/permissions/methods')
    ..when(method: 'requestPermissions', returns: {1: 0}); // {camera: denied}

  // ... drive the code under test that calls Permission.camera.request() ...

  expect(channel.verify(method: 'requestPermissions').length, 1);
});
```

- **`mockChannel(name)`** installs the handler immediately and removes it on
  test teardown. Calling it again with the same name returns the existing mock,
  preserving its stubs and call history. Each test starts fresh.
- **`when({required method, arguments, returns, throws})`** — reply with
  `returns`, or throw `throws` (e.g. a `PlatformException`). Supply `arguments`
  to match only calls whose `arguments` deep-equal it; omit it to match any.
  Later stubs win.
- **`verify({required method})`** returns the recorded `MethodCall`s for that
  method; **`calls`** is the full ordered list.

> `return` is a reserved word in Dart, so the parameter is named `returns`.

You can configure and inspect the same channel from different helpers:

```dart
mockChannel('example/settings').when(method: 'theme', returns: 'dark');
mockChannel('example/settings').when(method: 'language', returns: 'en');

// Both stubs remain active. Looking up the channel does not reset it.
final channel = mockChannel('example/settings');
expect(channel.verify(method: 'theme').length, 0);
```

The first call selects the channel's codec. Later lookups retain that codec,
so a channel initially installed with `codec: const JSONMethodCodec()` can be
looked up again with just `mockChannel(name)`.

## Notes

- Requires the Flutter test binding (use inside `testWidgets`, or call
  `TestWidgetsFlutterBinding.ensureInitialized()` in a plain `test`).
- VM/widget tests only — it mocks the channel, it does not talk to a device.
