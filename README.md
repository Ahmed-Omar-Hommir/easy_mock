# easy_mock

Readable test mocks for Flutter plugins — a small family of packages that let you
narrate platform behavior in tests ("camera denied", "app version 2.3.4") instead
of wiring up raw method channels by hand.

Most of these speak a plugin's method channel **directly**, so they carry no
dependency on the plugin they mock. Your app's real plugin Dart code runs; only
the native side is faked.

## Packages

| Package | What it mocks | Depends on the real plugin? |
| --- | --- | --- |
| [`easy_mock_channel`](packages/easy_mock_channel) | Any `MethodChannel` — fluent `when` / `verify` at the binary-messenger seam | — (foundation for the others) |
| [`easy_mock_secure_storage`](packages/easy_mock_secure_storage) | [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) via an in-memory store | No |
| [`easy_mock_permission_handler`](packages/easy_mock_permission_handler) | [`permission_handler`](https://pub.dev/packages/permission_handler) channel (camera & notification) | No |
| [`easy_mock_device_info`](packages/easy_mock_device_info) | [`device_info_plus`](https://pub.dev/packages/device_info_plus) `getDeviceInfo` | No |
| [`easy_mock_package_info`](packages/easy_mock_package_info) | [`package_info_plus`](https://pub.dev/packages/package_info_plus) via its `setMockInitialValues` seam | Yes (by design) |

`easy_mock_permission_handler` and `easy_mock_device_info` build on
`easy_mock_channel` through a relative path dependency, so the whole set lives in
one repo.

## Layout

```
packages/
  easy_mock_channel/
  easy_mock_secure_storage/
  easy_mock_permission_handler/
  easy_mock_device_info/
  easy_mock_package_info/
```

Each package has its own `README.md` with usage examples. All are Flutter
VM/widget test helpers — they require the Flutter test binding and do not talk to
a device.
