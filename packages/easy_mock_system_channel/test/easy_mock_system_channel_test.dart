import 'package:easy_mock_system_channel/easy_mock_system_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('records a HapticFeedback call and returns without error', () async {
    mockSystemChannels.install();

    await HapticFeedback.vibrate();

    expect(
      mockSystemChannels.platform.verify(method: 'HapticFeedback.vibrate').length,
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

  test('flutter/textinput is not mocked unless opted in', () {
    mockSystemChannels.install();

    expect(() => mockSystemChannels.textInput, throwsStateError);
  });

  test('install(includeTextInput: true) exposes the textinput mock', () async {
    mockSystemChannels.install(includeTextInput: true);
    mockSystemChannels.textInput.when(method: 'TextInput.clearClient', returns: null);

    const textInput = MethodChannel('flutter/textinput', JSONMethodCodec());
    await textInput.invokeMethod<void>('TextInput.clearClient');

    expect(
      mockSystemChannels.textInput.verify(method: 'TextInput.clearClient').length,
      1,
    );
  });

  test('channel(name) reaches any installed channel', () async {
    mockSystemChannels.install();

    expect(mockSystemChannels.channel('flutter/platform'), isA<MockMethodChannel>());
    expect(
      () => mockSystemChannels.channel('flutter/does_not_exist'),
      throwsStateError,
    );
  });
}
