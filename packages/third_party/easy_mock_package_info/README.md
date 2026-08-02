# easy_mock_package_info

A readable test mock for
[`package_info_plus`](https://pub.dev/packages/package_info_plus).

Unlike the other `easy_mock_*` packages, this one **depends on
package_info_plus** on purpose: the plugin caches `PackageInfo.fromPlatform()`
and exposes its own `setMockInitialValues` test seam, so a raw channel mock would
be shadowed by that cache. This package just drives the official seam with a
readable API and per-test reset.

## Usage

```dart
import 'package:easy_mock_package_info/easy_mock_package_info.dart';

mockPackageInfo.init();                          // harness usually does this
mockPackageInfo.set(version: '2.3.4', buildNumber: '42');

// app code: (await PackageInfo.fromPlatform()).version == '2.3.4'
```

`set({appName, packageName, version, buildNumber})`; defaults are
`epay` / `ly.anis.epay` / `1.0.0` / `1`. `install()` resets to those.
