import 'package:easy_mock_channel/easy_mock_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const name = 'example/channel';
  const real = MethodChannel(name);

  test('replies with the stubbed value', () async {
    mockChannel(name).when(method: 'ping', returns: 'pong');

    expect(await real.invokeMethod<String>('ping'), 'pong');
  });

  test('matches arguments by deep equality and records calls', () async {
    final channel = mockChannel(name)
      ..when(method: 'echo', arguments: [1, 2], returns: 'match');

    expect(await real.invokeMethod('echo', [1, 2]), 'match');
    expect(await real.invokeMethod('echo', [9]), isNull); // no match -> null

    expect(channel.verify(method: 'echo').length, 2);
    expect(channel.verify(method: 'echo').first.arguments, [1, 2]);
  });

  test('later stubs win', () async {
    mockChannel(name)
      ..when(method: 'value', returns: 1)
      ..when(method: 'value', returns: 2);

    expect(await real.invokeMethod('value'), 2);
  });

  test('throws the configured error', () async {
    mockChannel(name).when(
      method: 'boom',
      throws: PlatformException(code: 'denied'),
    );

    expect(() => real.invokeMethod('boom'), throwsA(isA<PlatformException>()));
  });

  test('unstubbed calls return null', () async {
    mockChannel(name);

    expect(await real.invokeMethod('whatever'), isNull);
  });
}
