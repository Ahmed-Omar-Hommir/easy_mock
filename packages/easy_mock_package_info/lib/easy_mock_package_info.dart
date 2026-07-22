import 'package:package_info_plus/package_info_plus.dart';

/// Readable test mock for package_info_plus.
///
/// package_info_plus caches `PackageInfo.fromPlatform()` and ships its own
/// `setMockInitialValues` seam, so a raw channel mock would be shadowed by the
/// cache. This is the one easy_mock that depends on the real package — it just
/// drives that seam.
///
/// ```dart
/// mockPackageInfo.set(version: '2.3.4', buildNumber: '42');
/// ```
final mockPackageInfo = MockPackageInfo._();

/// Drives a faked [PackageInfo]. Defaults: epay / ly.anis.epay / 1.0.0 / 1.
class MockPackageInfo {
  MockPackageInfo._();

  String _appName = 'epay';
  String _packageName = 'ly.anis.epay';
  String _version = '1.0.0';
  String _buildNumber = '1';

  /// Resets [PackageInfo] to the defaults. The harness calls this once per test.
  void install() {
    _appName = 'epay';
    _packageName = 'ly.anis.epay';
    _version = '1.0.0';
    _buildNumber = '1';
    _apply();
  }

  void set({
    String? appName,
    String? packageName,
    String? version,
    String? buildNumber,
  }) {
    if (appName != null) _appName = appName;
    if (packageName != null) _packageName = packageName;
    if (version != null) _version = version;
    if (buildNumber != null) _buildNumber = buildNumber;
    _apply();
  }

  void _apply() {
    // ignore: invalid_use_of_visible_for_testing_member
    PackageInfo.setMockInitialValues(
      appName: _appName,
      packageName: _packageName,
      version: _version,
      buildNumber: _buildNumber,
      buildSignature: '',
    );
  }
}
