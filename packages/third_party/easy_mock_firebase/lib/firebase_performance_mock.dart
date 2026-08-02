import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stubs the Firebase Performance pigeon channel.
///
/// Without a mock handler, its `HttpMetric#start`/`stop` calls (awaited by the
/// Dio performance interceptor on every request) are routed to the real
/// platform messenger and only complete on the real event loop — which forces
/// tests to drive the request with `runAsync` instead of `pump`. Stubbing the
/// channel makes those calls resolve on the fake clock, so the whole HTTP flow
/// settles under `pump`/`pumpAndSettle`.
final mockFirebasePerformance = MockFirebasePerformance._();

class MockFirebasePerformance {
  MockFirebasePerformance._();

  void init() {
    const codec = StandardMessageCodec();
    const prefix =
        'dev.flutter.pigeon.firebase_performance_platform_interface.'
        'FirebasePerformanceHostApi.';
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    // Pigeon wraps a successful host reply as a single-element list `[result]`.
    void stub(String method, Object? result) {
      final channel = '$prefix$method';
      messenger.setMockMessageHandler(
        channel,
        (_) async => codec.encodeMessage(<Object?>[result]),
      );
      addTearDown(() => messenger.setMockMessageHandler(channel, null));
    }

    stub('startHttpMetric', 1);
    stub('stopHttpMetric', null);
    stub('startTrace', 1);
    stub('stopTrace', null);
    stub('setPerformanceCollectionEnabled', null);
    stub('isPerformanceCollectionEnabled', false);
  }
}
