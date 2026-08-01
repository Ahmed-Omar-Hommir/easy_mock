# easy_mock

Readable test mocks for Flutter plugins — a small family of packages that let you
narrate platform behavior in tests ("camera denied", "app version 2.3.4") instead
of wiring up raw method channels by hand.

Most of these speak a plugin's method channel **directly**, so they carry no
dependency on the plugin they mock. Your app's real plugin Dart code runs; only
the native side is faked.

## Core

Generic mocks for a platform or language seam — not tied to any specific pub.dev
package. The third-party mocks build on these.

| Package | What it mocks |
| --- | --- |
| [`easy_mock_channel`](packages/easy_mock_channel) | Any `MethodChannel` — fluent `when` / `verify` at the binary-messenger seam (foundation for the others) |
| [`easy_mock_system_channel`](packages/easy_mock_system_channel) | Flutter's built-in `SystemChannels` |
| [`easy_mock_http`](packages/easy_mock_http) | `dart:io` `HttpClient` via `HttpOverrides` — covers Dio, `package:http`, any VM transport with zero injection |
| [`easy_mock_io`](packages/easy_mock_io) | `dart:io` filesystem via an in-memory `MemoryFileSystem` (`IOOverrides`) |

## Third-party

Each mocks one specific pub.dev package. They live under `packages/third_party/`.

| Package | What it mocks | Depends on the real plugin? |
| --- | --- | --- |
| [`easy_mock_secure_storage`](packages/third_party/easy_mock_secure_storage) | [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) via an in-memory store | No |
| [`easy_mock_permission_handler`](packages/third_party/easy_mock_permission_handler) | [`permission_handler`](https://pub.dev/packages/permission_handler) channel (camera & notification) | No |
| [`easy_mock_device_info`](packages/third_party/easy_mock_device_info) | [`device_info_plus`](https://pub.dev/packages/device_info_plus) `getDeviceInfo` | No |
| [`easy_mock_package_info`](packages/third_party/easy_mock_package_info) | [`package_info_plus`](https://pub.dev/packages/package_info_plus) via its `setMockInitialValues` seam | Yes (by design) |
| [`easy_mock_firebase`](packages/third_party/easy_mock_firebase) | Firebase core / performance / remote config / messaging / app check / crashlytics channels | Partially (platform interfaces) |
| [`easy_mock_local_notifications`](packages/third_party/easy_mock_local_notifications) | [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) channel | Yes (registers the real Android plugin) |

The third-party mocks that build on `easy_mock_channel` reference it through a
relative path dependency (`../../easy_mock_channel`), so the whole set lives in
one repo.

## Layout

```
packages/
  easy_mock_channel/
  easy_mock_system_channel/
  easy_mock_http/
  easy_mock_io/
  third_party/
    easy_mock_secure_storage/
    easy_mock_permission_handler/
    easy_mock_device_info/
    easy_mock_package_info/
    easy_mock_firebase/
    easy_mock_local_notifications/
```

Each package has its own `README.md` with usage examples. All are Flutter
VM/widget test helpers — they require the Flutter test binding and do not talk to
a device.
