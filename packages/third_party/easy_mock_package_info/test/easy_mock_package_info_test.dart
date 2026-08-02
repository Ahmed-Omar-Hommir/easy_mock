import 'package:easy_mock_package_info/easy_mock_package_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(mockPackageInfo.init);

  test('defaults', () async {
    final info = await PackageInfo.fromPlatform();
    expect(info.appName, 'epay');
    expect(info.packageName, 'ly.anis.epay');
    expect(info.version, '1.0.0');
    expect(info.buildNumber, '1');
  });

  test('set overrides version and build', () async {
    mockPackageInfo.set(version: '2.3.4', buildNumber: '42');

    final info = await PackageInfo.fromPlatform();
    expect(info.version, '2.3.4');
    expect(info.buildNumber, '42');
  });
}
