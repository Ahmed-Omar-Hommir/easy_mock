import 'package:easy_mock_permission_handler/easy_mock_permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Asserts against the raw channel directly (no permission_handler), since the
// whole point is that this package speaks the channel's wire codes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');

  setUp(mockPermissionHandler.install);

  test('camera and notification default to granted', () async {
    expect(await channel.invokeMethod('checkPermissionStatus', 1), 1);
    expect(await channel.invokeMethod('checkPermissionStatus', 17), 1);
    expect(await channel.invokeMethod('requestPermissions', [1]), {
      1: 1,
      17: 1,
    });
  });

  test('camera.deny()', () async {
    mockPermissionHandler.camera.deny();

    expect(await channel.invokeMethod('checkPermissionStatus', 1), 0);
    expect(await channel.invokeMethod('requestPermissions', [1]), {
      1: 0,
      17: 1,
    });
  });

  test('notification.permanentlyDeny()', () async {
    mockPermissionHandler.notification.permanentlyDeny();

    expect(await channel.invokeMethod('checkPermissionStatus', 17), 4);
  });

  test('service status', () async {
    expect(await channel.invokeMethod('checkServiceStatus', 1), 1);

    mockPermissionHandler.serviceDisabled();
    expect(await channel.invokeMethod('checkServiceStatus', 1), 0);

    mockPermissionHandler.serviceNotApplicable();
    expect(await channel.invokeMethod('checkServiceStatus', 1), 2);
  });

  test('open app settings', () async {
    expect(await channel.invokeMethod('openAppSettings'), true);

    mockPermissionHandler.doNotOpenAppSetting();
    expect(await channel.invokeMethod('openAppSettings'), false);
  });

  test('request-permission rationale', () async {
    expect(
      await channel.invokeMethod('shouldShowRequestPermissionRationale', 1),
      false,
    );

    mockPermissionHandler.showRequestPermissionRationale();
    expect(
      await channel.invokeMethod('shouldShowRequestPermissionRationale', 1),
      true,
    );
  });
}
