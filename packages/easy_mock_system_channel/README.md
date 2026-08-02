# easy_mock_system_channel

Default test mocks for Flutter's [`SystemChannels`](https://api.flutter.dev/flutter/services/SystemChannels-class.html),
built on `easy_mock_channel`. One `install()` and every framework method channel
(`flutter/platform`, `flutter/navigation`, `flutter/mousecursor`, …) answers with
a sensible default — each method returns `null` and is recorded — so app code
that calls `HapticFeedback.vibrate()`, `SystemChrome.setPreferredOrientations()`,
`Clipboard.getData()`, `SystemSound.play()` etc. runs without reaching the real
platform. Each channel is wired with the **same codec** the framework uses
(e.g. `flutter/platform` uses `JSONMethodCodec`).

## Usage

```dart
import 'package:easy_mock_system_channel/easy_mock_system_channel.dart';
import 'package:flutter/services.dart';

testWidgets('haptics + clipboard', (tester) async {
  mockSystemChannel.init();

  // ... drive code that calls HapticFeedback.vibrate() ...
  expect(mockSystemChannel.platform.verify(method: 'HapticFeedback.vibrate').length, 1);

  // Override a return value:
  mockSystemChannel.platform.when(
    method: 'Clipboard.getData',
    returns: {'text': 'hello'},
  );
  expect((await Clipboard.getData('text/plain'))?.text, 'hello');
});
```

- **`install({bool includeTextInput = false})`** installs the mocks immediately
  and removes them on teardown. Wire it into your test harness alongside the
  other `easy_mock_*` installers.
- **`mockSystemChannel.platform`** / `.navigation` / `.mouseCursor` /
  `.contextMenu` / `.restoration` — each is a `MockMethodChannel`, so use
  `.when(...)` to override and `.verify(...)` to assert. Reach any other channel
  by name with **`channel('flutter/status_bar')`**.
- Seeded non-null defaults: `Clipboard.hasStrings` → `{'value': false}`,
  `getKeyboardState` → `{}`.

## Notes

- **`flutter/textinput` is not mocked by default** — the test framework's
  `TestTextInput` owns it, and replacing it breaks `tester.enterText`. Pass
  `install(includeTextInput: true)` only if you intend to drive text input
  yourself.
- Requires the Flutter test binding (use inside `testWidgets`, or call
  `TestWidgetsFlutterBinding.ensureInitialized()` in a plain `test`).
- VM/widget tests only — it mocks the channels, it does not talk to a device.
