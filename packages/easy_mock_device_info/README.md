# easy_mock_device_info

A readable test mock for
[`device_info_plus`](https://pub.dev/packages/device_info_plus), built on
[`easy_mock_channel`](../easy_mock_channel). It scripts the single
`getDeviceInfo` channel call, so it has **no dependency on device_info_plus**.

## Usage

```dart
import 'package:easy_mock_device_info/easy_mock_device_info.dart';

mockDeviceInfo.install();                                   // harness usually does this
mockDeviceInfo.set(name: 'Pixel 7', manufacturer: 'Google', model: 'Pixel 7', id: 'd1');
```

`set({name, manufacturer, model, id, extra})` — the named fields are the ones the
app reads; `extra` adds any other key. `device_info_plus` decodes the same map
differently per platform (Android/iOS/macOS …).

> **Heads-up:** if your code branches on `dart:io Platform.isAndroid/isIOS`, that
> is fixed to the host OS in VM tests and isn't overridable — so the
> Android/iOS-specific paths may not run, and only the generic
> `DeviceInfoPlugin().deviceInfo` call reaches this mock.
>
> Needs the Flutter test binding (inside `testWidgets`, or
> `TestWidgetsFlutterBinding.ensureInitialized()` in a plain `test`).
