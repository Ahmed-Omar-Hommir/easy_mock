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
  test teardown.
- **`when({required method, arguments, returns, throws})`** — reply with
  `returns`, or throw `throws` (e.g. a `PlatformException`). Supply `arguments`
  to match only calls whose `arguments` deep-equal it; omit it to match any.
  Later stubs win.
- **`verify({required method})`** returns the recorded `MethodCall`s for that
  method; **`calls`** is the full ordered list.

> `return` is a reserved word in Dart, so the parameter is named `returns`.

## Notes

- Requires the Flutter test binding (use inside `testWidgets`, or call
  `TestWidgetsFlutterBinding.ensureInitialized()` in a plain `test`).
- VM/widget tests only — it mocks the channel, it does not talk to a device.
