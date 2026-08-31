part of '../easy_mock_http.dart';

/// HTTP-verb entry points for [MockHttp.when].
///
/// Request matching: [body], [query], and [headers] are subset matchers
/// (extra keys on the real request are ignored; header names are
/// case-insensitive); any value may be exact or a [Matcher] like [any].
/// Reply: [response] / [statusCode] / [responseHeaders] build the canned
/// reply, [delay] postpones it, and [error] throws instead — simulating a
/// transport failure. Use [responder] to compute a reply from the matched
/// request. Every verb returns a [MockResult] that lazily verifies requests
/// using that exact registration matcher.
class StubVerbs {
  StubVerbs._(this._mock);

  final MockHttp _mock;

  MockResult _verb(
    String method,
    Object url,
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
    Object? response,
    int? statusCode,
    Map<String, String>? responseHeaders,
    Duration? delay,
    Object? error,
    MockHttpHandler? responder,
  ) {
    if (responder != null &&
        (response != null ||
            statusCode != null ||
            responseHeaders != null ||
            delay != null ||
            error != null)) {
      throw ArgumentError(
        'responder cannot be combined with response, statusCode, '
        'responseHeaders, delay, or error.',
      );
    }

    final matcher = _RequestMatcher(method, url, body, headers, query);
    final stub = _Stub(matcher)
      ..responder =
          responder ??
          (_) async {
            if (delay != null) await Future<void>.delayed(delay);
            if (error != null) throw error;
            return MockHttpResponse(
              statusCode: statusCode ?? 200,
              body: response,
              headers: responseHeaders,
            );
          };
    _mock._stubs.add(stub);

    return MockResult._(
      () => _Verification(
        _mock.requests.where(matcher.matches).toList(),
        '$matcher',
      ),
    );
  }

  MockResult get(
    Object url, {
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
    Object? response,
    int? statusCode,
    Map<String, String>? responseHeaders,
    Duration? delay,
    Object? error,
    MockHttpHandler? responder,
  }) => _verb(
    'GET',
    url,
    body,
    headers,
    query,
    response,
    statusCode,
    responseHeaders,
    delay,
    error,
    responder,
  );

  MockResult post(
    Object url, {
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
    Object? response,
    int? statusCode,
    Map<String, String>? responseHeaders,
    Duration? delay,
    Object? error,
    MockHttpHandler? responder,
  }) => _verb(
    'POST',
    url,
    body,
    headers,
    query,
    response,
    statusCode,
    responseHeaders,
    delay,
    error,
    responder,
  );

  MockResult put(
    Object url, {
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
    Object? response,
    int? statusCode,
    Map<String, String>? responseHeaders,
    Duration? delay,
    Object? error,
    MockHttpHandler? responder,
  }) => _verb(
    'PUT',
    url,
    body,
    headers,
    query,
    response,
    statusCode,
    responseHeaders,
    delay,
    error,
    responder,
  );

  MockResult delete(
    Object url, {
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
    Object? response,
    int? statusCode,
    Map<String, String>? responseHeaders,
    Duration? delay,
    Object? error,
    MockHttpHandler? responder,
  }) => _verb(
    'DELETE',
    url,
    body,
    headers,
    query,
    response,
    statusCode,
    responseHeaders,
    delay,
    error,
    responder,
  );

  MockResult patch(
    Object url, {
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
    Object? response,
    int? statusCode,
    Map<String, String>? responseHeaders,
    Duration? delay,
    Object? error,
    MockHttpHandler? responder,
  }) => _verb(
    'PATCH',
    url,
    body,
    headers,
    query,
    response,
    statusCode,
    responseHeaders,
    delay,
    error,
    responder,
  );

  MockResult head(
    Object url, {
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
    Object? response,
    int? statusCode,
    Map<String, String>? responseHeaders,
    Duration? delay,
    Object? error,
    MockHttpHandler? responder,
  }) => _verb(
    'HEAD',
    url,
    body,
    headers,
    query,
    response,
    statusCode,
    responseHeaders,
    delay,
    error,
    responder,
  );
}

/// The result of registering a canned HTTP interaction.
///
/// Verification is evaluated lazily using the method, URL, body, headers, and
/// query supplied to the registration. Use [MockHttp.verify] for an independent
/// matcher-based lookup.
final class MockResult extends LazyVerification {
  const MockResult._(super.verification);
}

class _Stub {
  _Stub(this.matcher);

  final _RequestMatcher matcher;
  MockHttpHandler responder = (_) => MockHttpResponse(statusCode: 200);
}
