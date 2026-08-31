part of '../easy_mock_http.dart';

/// HTTP-verb entry points for [MockHttp.verify]; returns a [Verification] over
/// the requests recorded so far.
class VerifyVerbs {
  VerifyVerbs._(this._mock);

  final MockHttp _mock;

  Verification _verb(
    String method,
    Object url,
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
  ) {
    final matcher = _RequestMatcher(method, url, body, headers, query);
    return _Verification(
      _mock.requests.where(matcher.matches).toList(),
      '$matcher',
    );
  }

  Verification get(
    Object url, {
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
  }) => _verb('GET', url, body, headers, query);
  Verification post(
    Object url, {
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
  }) => _verb('POST', url, body, headers, query);
  Verification put(
    Object url, {
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
  }) => _verb('PUT', url, body, headers, query);
  Verification delete(
    Object url, {
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
  }) => _verb('DELETE', url, body, headers, query);
  Verification patch(
    Object url, {
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
  }) => _verb('PATCH', url, body, headers, query);
  Verification head(
    Object url, {
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
  }) => _verb('HEAD', url, body, headers, query);
}

/// Verification of matching HTTP calls.
///
/// Assert on the count, or read [calls] for deeper checks on the captured
/// requests.
abstract interface class Verification {
  int get count;
  List<MockHttpRequest> get calls;
  MockHttpRequest get single;

  void called(int times);
  void get calledOnce;
  void get never;
  void calledAtLeast(int times);
  void calledAtMost(int times);
}

final class _Verification implements Verification {
  _Verification(this._matched, this._describe);

  final List<MockHttpRequest> _matched;
  final String _describe;

  @override
  int get count => _matched.length;

  @override
  List<MockHttpRequest> get calls => List.unmodifiable(_matched);

  @override
  MockHttpRequest get single => _matched.single;

  @override
  void called(int times) => expect(
    _matched.length,
    times,
    reason:
        'Expected $times request(s) matching $_describe, '
        'found ${_matched.length}.',
  );

  @override
  void get calledOnce => called(1);

  @override
  void get never => called(0);

  @override
  void calledAtLeast(int times) => expect(
    _matched.length,
    greaterThanOrEqualTo(times),
    reason:
        'Expected at least $times request(s) matching $_describe, '
        'found ${_matched.length}.',
  );

  @override
  void calledAtMost(int times) => expect(
    _matched.length,
    lessThanOrEqualTo(times),
    reason:
        'Expected at most $times request(s) matching $_describe, '
        'found ${_matched.length}.',
  );
}

/// A verification lookup that is resolved when an assertion or value is read.
///
/// This lets a verification handle be created while arranging a test and used
/// after the code under test has sent its requests.
class LazyVerification implements Verification {
  const LazyVerification(this._verification);

  final Verification Function() _verification;

  @override
  void called(int times) => _verification().called(times);

  @override
  void calledAtLeast(int times) => _verification().calledAtLeast(times);

  @override
  void calledAtMost(int times) => _verification().calledAtMost(times);

  @override
  void get calledOnce => _verification().calledOnce;

  @override
  List<MockHttpRequest> get calls => _verification().calls;

  @override
  int get count => _verification().count;

  @override
  void get never => _verification().never;

  @override
  MockHttpRequest get single => _verification().single;
}
