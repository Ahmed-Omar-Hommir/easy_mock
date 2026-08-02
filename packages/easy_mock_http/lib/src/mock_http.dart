part of '../easy_mock_http.dart';

// ─── Fluent API: stub with `when`, assert with `verify` ──────────────────────
//
// Same HttpOverrides interception as [MockHttpOverrides], but instead of one
// up-front handler you stub imperatively and each line reads like the request
// it mocks:
//
// ```dart
// final http = mockHttp();                       // installed + auto torn down
//
// http.when.post(
//   '/v1/login',
//   body: {'user': any()},                       // match method + path + body
//   headers: {'Authorization': any()},           // match request headers too
//   response: {'token': 'abc'},                  // canned 200 JSON reply
// );
//
// await Dio().post('https://api.test/v1/login', data: {'user': 'sam'});
//
// http.verify.post('/v1/login').calledOnce;      // assert it was sent once
// ```
//
// Body maps match as a *subset* (extra keys are ignored); request headers
// match the same way, with case-insensitive names. Any value may be a
// [Matcher] — [any] for "don't care", or a flutter_test matcher like
// `greaterThan(3)` / `contains('x')` for finer checks.

/// The HTTP mock. Call [MockHttp.init] to route `dart:io` traffic through
/// it, then stub with [MockHttp.when] / [MockHttp.expect] and assert with
/// [MockHttp.verify].
final mockHttp = MockHttp._();

/// Matches any value in a body matcher, e.g. `{'id': any(), 'name': 'Sam'}`.
Matcher any() => anything;

/// Stub registry and request recorder behind [mockHttp]. Reuses
/// [MockHttpOverrides] for the actual `dart:io` interception.
class MockHttp {
  MockHttp._();

  late final MockHttpOverrides overrides = MockHttpOverrides(_handle);
  final List<_Stub> _stubs = <_Stub>[];

  /// Installs this mock as `HttpOverrides.global`, resetting stubs and recorded
  /// requests, and removes it on teardown. Build transport clients (Dio,
  /// `http.Client`, repositories) AFTER this call so they pick up the override.
  void init() {
    _stubs.clear();
    overrides.requests.clear();
    HttpOverrides.global = overrides;
    addTearDown(() {
      HttpOverrides.global = null;
      _verifyExpectations();
    });
  }

  /// Every request seen, in order — the raw recording for ad-hoc assertions.
  List<MockHttpRequest> get requests => overrides.requests;

  /// Stub a reply: `when.get(url, response: {...})`.
  StubVerbs get when => StubVerbs._(this, expected: false);

  /// Like [when], but also asserts the request actually arrives — verified on
  /// teardown: `expect.get(url, response: {...})`.
  StubVerbs get expect => StubVerbs._(this, expected: true);

  /// Assert what was sent: `verify.post(url, body: {...}).called(1)`.
  VerifyVerbs get verify => VerifyVerbs._(this);

  FutureOr<MockHttpResponse> _handle(MockHttpRequest request) {
    for (final stub in _stubs.reversed) {
      if (stub.matcher.matches(request)) {
        stub.calls.add(request);
        return stub.responder(request);
      }
    }
    return MockHttpResponse(
      statusCode: 404,
      body: {'error': 'no mock route for $request'},
    );
  }

  void _verifyExpectations() {
    for (final stub in _stubs) {
      if (stub.expected && stub.calls.isEmpty) {
        fail('Expected a request matching ${stub.matcher}, but none was sent.');
      }
    }
  }
}

/// [HttpOverrides] implementation that routes every request through [handler]
/// and records what was sent in [requests].
class MockHttpOverrides extends HttpOverrides {
  MockHttpOverrides(this.handler);

  final MockHttpHandler handler;
  final List<MockHttpRequest> requests = <MockHttpRequest>[];

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _MockHttpClient(this);
}
