import 'package:easy_mock_device_info/easy_mock_device_info.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.fluttercommunity.plus/device_info');

  Future<Map<dynamic, dynamic>?> getDeviceInfo() =>
      channel.invokeMapMethod<dynamic, dynamic>('getDeviceInfo');

  setUp(mockDeviceInfo.init);

  test('a complete default map', () async {
    final info = (await getDeviceInfo())!;
    expect(info['name'], 'Test Device');
    expect(info['systemGUID'], isNotNull); // full map, not sparse
  });

  test('set overrides the named fields, keeps the rest', () async {
    mockDeviceInfo.android.set(
      name: 'Pixel 7',
      manufacturer: 'Google',
      model: 'Pixel 7',
    );

    final info = (await getDeviceInfo())!;
    expect(info['name'], 'Pixel 7');
    expect(info['manufacturer'], 'Google');
    expect(info['model'], 'Pixel 7');
    expect(info['systemGUID'], isNotNull); // default retained
  });

  test('extra sets arbitrary keys', () async {
    mockDeviceInfo.set(extra: {'id': 'device-123'});

    expect((await getDeviceInfo())!['id'], 'device-123');
  });

  test('platform sets each write their own fields', () async {
    mockDeviceInfo.android.set(brand: 'Acme', totalDiskSize: 512);
    mockDeviceInfo.iOS.set(systemVersion: '18.0');

    final info = (await getDeviceInfo())!;
    expect(info['brand'], 'Acme');
    expect(info['totalDiskSize'], 512);
    expect(info['systemVersion'], '18.0');
  });

  test('version merges onto the default sub-map', () async {
    mockDeviceInfo.android.set(version: {'release': '15'});

    final version = (await getDeviceInfo())!['version'] as Map;
    expect(version['release'], '15'); // overridden
    expect(version['codename'], isNotNull); // default retained, decoder-safe
  });
}
