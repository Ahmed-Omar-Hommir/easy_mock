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
    return Verification._(
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

/// Result of a `verify` lookup. Assert on the count, or read [calls] for deeper
/// checks on the captured requests.
class Verification {
  Verification._(this._matched, this._describe);

  final List<MockHttpRequest> _matched;
  final String _describe;

  int get count => _matched.length;
  List<MockHttpRequest> get calls => List.unmodifiable(_matched);
  MockHttpRequest get single => _matched.single;

  void called(int times) => expect(
    _matched.length,
    times,
    reason:
        'Expected $times request(s) matching $_describe, '
        'found ${_matched.length}.',
  );

  void get calledOnce => called(1);
  void get never => called(0);

  void calledAtLeast(int times) => expect(
    _matched.length,
    greaterThanOrEqualTo(times),
    reason:
        'Expected at least $times request(s) matching $_describe, '
        'found ${_matched.length}.',
  );

  void calledAtMost(int times) => expect(
    _matched.length,
    lessThanOrEqualTo(times),
    reason:
        'Expected at most $times request(s) matching $_describe, '
        'found ${_matched.length}.',
  );
}
