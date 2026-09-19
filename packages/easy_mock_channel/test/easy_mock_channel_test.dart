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

  test('reopening a channel preserves its stubs and recorded calls', () async {
    final first = mockChannel(name)..when(method: 'ping', returns: 'pong');
    expect(await real.invokeMethod<String>('ping'), 'pong');

    final reopened = mockChannel(name);

    expect(reopened, same(first));
    expect(reopened.verify(method: 'ping'), hasLength(1));
    expect(await real.invokeMethod<String>('ping'), 'pong');
    expect(first.verify(method: 'ping'), hasLength(2));
  });

  test('separate lookups add stubs without dropping earlier methods', () async {
    mockChannel(name).when(method: 'first', returns: 1);
    mockChannel(name).when(method: 'second', returns: 2);

    expect(await real.invokeMethod<int>('first'), 1);
    expect(await real.invokeMethod<int>('second'), 2);
    expect(mockChannel(name).calls, hasLength(2));
  });

  test(
    'later stubs through another lookup override only matching calls',
    () async {
      mockChannel(name).when(method: 'value', returns: 'default');
      mockChannel(
        name,
      ).when(method: 'value', arguments: 1, returns: 'override');

      expect(await real.invokeMethod<String>('value', 1), 'override');
      expect(await real.invokeMethod<String>('value', 2), 'default');
    },
  );

  test(
    'reopening a custom-codec channel retains the installed codec',
    () async {
      const jsonChannel = MethodChannel('example/json', JSONMethodCodec());
      final first = mockChannel(
        jsonChannel.name,
        codec: const JSONMethodCodec(),
      )..when(method: 'ping', returns: 'pong');

      final reopened = mockChannel(jsonChannel.name);

      expect(reopened, same(first));
      expect(await jsonChannel.invokeMethod<String>('ping'), 'pong');
      expect(reopened.verify(method: 'ping'), hasLength(1));
    },
  );

  test(
    'different channel names keep independent stubs and call histories',
    () async {
      const otherReal = MethodChannel('example/other');
      final first = mockChannel(name)..when(method: 'ping', returns: 'first');
      final other = mockChannel(otherReal.name)
        ..when(method: 'ping', returns: 'other');

      expect(await real.invokeMethod<String>('ping'), 'first');
      expect(other.calls, isEmpty);
      expect(await otherReal.invokeMethod<String>('ping'), 'other');
      expect(first.calls, hasLength(1));
      expect(other.calls, hasLength(1));
    },
  );

  for (var iteration = 1; iteration <= 2; iteration++) {
    test('channel state is isolated between tests ($iteration)', () async {
      const isolatedName = 'example/isolated';
      const isolatedReal = MethodChannel(isolatedName);
      // Run after the mock's teardown to verify handler removal as well.
      addTearDown(() {
        expect(
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .checkMockMessageHandler(isolatedName, null),
          isTrue,
        );
      });
      final channel = mockChannel(isolatedName);
      expect(channel.calls, isEmpty);
      expect(await isolatedReal.invokeMethod('ping'), isNull);
      channel.when(method: 'ping', returns: 'pong');
      expect(await isolatedReal.invokeMethod<String>('ping'), 'pong');
    });
  }

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
