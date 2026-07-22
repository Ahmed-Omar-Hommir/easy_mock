## 0.1.0

- Initial release.
- `mockPackageInfo` — sets `PackageInfo` via package_info_plus'
  `setMockInitialValues` seam (it caches `fromPlatform`, so a channel mock would
  be unreliable — hence this depends on the real package).
- `set({appName, packageName, version, buildNumber})`; `install()` resets to
  defaults.
