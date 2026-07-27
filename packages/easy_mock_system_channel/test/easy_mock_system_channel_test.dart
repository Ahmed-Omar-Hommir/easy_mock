import 'package:easy_mock_channel/easy_mock_channel.dart';
import 'package:easy_mock_system_channel/easy_mock_system_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('records a HapticFeedback call and returns without error', () async {
    mockSystemChannels.install();

    await HapticFeedback.vibrate();

    expect(
      mockSystemChannels.platform
          .verify(method: 'HapticFeedback.vibrate')
          .length,
      1,
    );
  });

  test('Clipboard.hasStrings defaults to false', () async {
    mockSystemChannels.install();

    expect(await Clipboard.hasStrings(), isFalse);
  });

  test('a platform method can be overridden (JSONMethodCodec path)', () async {
    mockSystemChannels.install();
    mockSystemChannels.platform.when(
      method: 'Clipboard.getData',
      returns: {'text': 'hello'},
    );

    final data = await Clipboard.getData(Clipboard.kTextPlain);

    expect(data?.text, 'hello');
  });

  test('records SystemChrome calls with their arguments', () async {
    mockSystemChannels.install();

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    final calls = mockSystemChannels.platform.verify(
      method: 'SystemChrome.setPreferredOrientations',
    );
    expect(calls.single.arguments, ['DeviceOrientation.portraitUp']);
  });

  test('a StandardMethodCodec channel returns null by default', () async {
    mockSystemChannels.install();

    const restoration = MethodChannel('flutter/restoration');
    expect(await restoration.invokeMethod<Object?>('get'), isNull);
    expect(mockSystemChannels.restoration.verify(method: 'get').length, 1);
  });

  test('flutter/textinput is not exposed as a mock channel', () {
    mockSystemChannels.install();

    expect(
      () => mockSystemChannels.channel('flutter/textinput'),
      throwsStateError,
    );
  });

  test(
    'a strict guard is not tripped by an unhandled flutter/textinput call',
    () async {
      installUnmockedChannelGuard();
      mockSystemChannels.install();
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
    mockSystemChannels.install();

    expect(
      mockSystemChannels.channel('flutter/platform'),
      isA<MockMethodChannel>(),
    );
    expect(
      () => mockSystemChannels.channel('flutter/does_not_exist'),
      throwsStateError,
    );
  });
}
