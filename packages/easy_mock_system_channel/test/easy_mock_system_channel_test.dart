import 'package:easy_mock_system_channel/easy_mock_system_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('records a HapticFeedback call and returns without error', () async {
    mockSystemChannel.init();

    await HapticFeedback.vibrate();

    expect(
      mockSystemChannel.platform
          .verify(method: 'HapticFeedback.vibrate')
          .length,
      1,
    );
  });

  test('Clipboard.hasStrings defaults to false', () async {
    mockSystemChannel.init();

    expect(await Clipboard.hasStrings(), isFalse);
  });

  test('a platform method can be overridden (JSONMethodCodec path)', () async {
    mockSystemChannel.init();
    mockSystemChannel.platform.when(
      method: 'Clipboard.getData',
      returns: {'text': 'hello'},
    );

    final data = await Clipboard.getData(Clipboard.kTextPlain);

    expect(data?.text, 'hello');
  });

  test('records SystemChrome calls with their arguments', () async {
    mockSystemChannel.init();

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    final calls = mockSystemChannel.platform.verify(
      method: 'SystemChrome.setPreferredOrientations',
    );
    expect(calls.single.arguments, ['DeviceOrientation.portraitUp']);
  });

  test('a StandardMethodCodec channel returns null by default', () async {
    mockSystemChannel.init();

    const restoration = MethodChannel('flutter/restoration');
    expect(await restoration.invokeMethod<Object?>('get'), isNull);
    expect(mockSystemChannel.restoration.verify(method: 'get').length, 1);
  });

  test('flutter/textinput is not exposed as a mock channel', () {
    mockSystemChannel.init();

    expect(
      () => mockSystemChannel.channel('flutter/textinput'),
      throwsStateError,
    );
  });

  test(
    'a strict guard is not tripped by an unhandled flutter/textinput call',
    () async {
      mockChannel.init();
      mockSystemChannel.init();
      // Simulate patrol having unregistered the framework's TestTextInput.
      TestWidgetsFlutterBinding.instance.testTextInput.unregister();

      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final reply = await messenger.send(
        'flutter/textinput',
        const JSONMethodCodec().encodeMethodCall(
          const MethodCall('TextInput.clearClient'),
        ),
      );

      // Relaxed to null rather than recorded — otherwise the guard's teardown
      // would fail this test.
      expect(reply, isNull);
    },
  );

  test('channel(name) reaches any installed channel', () async {
    mockSystemChannel.init();

    expect(
      mockSystemChannel.channel('flutter/platform'),
      isA<MockMethodChannel>(),
    );
    expect(
      () => mockSystemChannel.channel('flutter/does_not_exist'),
      throwsStateError,
    );
  });
}
