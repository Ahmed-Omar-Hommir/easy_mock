# easy_mock_permission_handler

A readable test mock for the
[`permission_handler`](https://pub.dev/packages/permission_handler) **platform
channel**, built on [`easy_mock_channel`](../easy_mock_channel). It speaks the
channel's raw wire codes directly, so it has **no dependency on
permission_handler**. You narrate the story — "camera denied", "service
disabled" — and the real permission_handler Dart code (in your app) reads it
back. Scoped to **camera and notification** for now.

## Usage

```dart
import 'package:easy_mock_permission_handler/easy_mock_permission_handler.dart';

testWidgets('blocks the camera step when denied', (tester) async {
  mockPermissionHandler.init();          // harness usually does this
  mockPermissionHandler.camera.deny();

  // ... drive the code under test that calls Permission.camera.request() ...
});
```

`mockPermissionHandler` — defaults: camera & notification granted, service
enabled, app settings openable, no rationale.

- **per permission** — `mockPermissionHandler.camera` / `.notification`:
  `grant()` / `deny()` / `permanentlyDeny()` / `restrict()` / `limit()` /
  `provisional()`
- **service:** `serviceEnabled()` / `serviceDisabled()` / `serviceNotApplicable()`
- **app settings:** `openAppSetting()` / `doNotOpenAppSetting()`
- **rationale:** `showRequestPermissionRationale()` /
  `doNotShowRequestPermissionRationale()`
- **`install()`** — set up the channel and reset to defaults; call once per test
  (usually from the harness).

> Needs the Flutter test binding (inside `testWidgets`, or
> `TestWidgetsFlutterBinding.ensureInitialized()` in a plain `test`). Only camera
> and notification are supported for now.
