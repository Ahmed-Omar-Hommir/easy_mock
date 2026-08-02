part of '../easy_mock_http.dart';

/// HTTP-verb entry points for [MockHttp.when] / [MockHttp.expect].
///
/// Request matching: [body], [query], and [headers] are subset matchers
/// (extra keys on the real request are ignored; header names are
/// case-insensitive); any value may be exact or a [Matcher] like [any].
/// Reply: [response] / [statusCode] / [responseHeaders] build the canned
/// reply, [delay] postpones it, and [error] throws instead — simulating a
/// transport failure. Omit all reply args to chain [StubBuilder.response] /
/// [StubBuilder.replyWith].
class StubVerbs {
  StubVerbs._(this._mock, {required this.expected});

  final MockHttp _mock;
  final bool expected;

  StubBuilder _verb(
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
  ) {
    final builder = StubBuilder._(
      _mock,
      _RequestMatcher(method, url, body, headers, query),
      expected,
    );
    final hasReply =
        response != null ||
        statusCode != null ||
        delay != null ||
        error != null;
    if (hasReply) {
      builder.replyWith((_) async {
        if (delay != null) await Future<void>.delayed(delay);
        if (error != null) throw error;
        return MockHttpResponse(
          statusCode: statusCode ?? 200,
          body: response,
          headers: responseHeaders,
        );
      });
    }
    return builder;
  }

  StubBuilder get(
    Object url, {
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
    Object? response,
    int? statusCode,
    Map<String, String>? responseHeaders,
    Duration? delay,
    Object? error,
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
  );

  StubBuilder post(
    Object url, {
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
    Object? response,
    int? statusCode,
    Map<String, String>? responseHeaders,
    Duration? delay,
    Object? error,
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
  );

  StubBuilder put(
    Object url, {
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
    Object? response,
    int? statusCode,
    Map<String, String>? responseHeaders,
    Duration? delay,
    Object? error,
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
  );

  StubBuilder delete(
    Object url, {
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
    Object? response,
    int? statusCode,
    Map<String, String>? responseHeaders,
    Duration? delay,
    Object? error,
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
  );

  StubBuilder patch(
    Object url, {
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
    Object? response,
    int? statusCode,
    Map<String, String>? responseHeaders,
    Duration? delay,
    Object? error,
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
  );

  StubBuilder head(
    Object url, {
    Object? body,
    Map<String, Object?>? headers,
    Map<String, Object?>? query,
    Object? response,
    int? statusCode,
    Map<String, String>? responseHeaders,
    Duration? delay,
    Object? error,
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
  );
}

/// Terminal of a `when`/`expect` chain: declares the canned reply.
class StubBuilder {
  StubBuilder._(this._mock, this._matcher, this._expected);

  final MockHttp _mock;
  final _RequestMatcher _matcher;
  final bool _expected;

  /// Reply with [body] (JSON-encoded) and [statusCode].
  void response(
    Object? body, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) => replyWith(
    (_) =>
        MockHttpResponse(statusCode: statusCode, body: body, headers: headers),
  );

  /// Alias for [response].
  void reply(
    Object? body, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) => response(body, statusCode: statusCode, headers: headers);

  /// Reply with an error [statusCode] and an optional [body].
  void fail(int statusCode, {Object? body}) =>
      response(body, statusCode: statusCode);

  /// Make the request throw [error] — simulates a socket/transport failure.
  void throwError(Object error) => replyWith((_) => throw error);

  /// Reply dynamically, computing the response from the matched request.
  void replyWith(MockHttpHandler responder) =>
      _mock._stubs.add(_Stub(_matcher, _expected)..responder = responder);
}

class _Stub {
  _Stub(this.matcher, this.expected);

  final _RequestMatcher matcher;
  final bool expected;
  final List<MockHttpRequest> calls = <MockHttpRequest>[];
  MockHttpHandler responder = (_) => MockHttpResponse(statusCode: 200);
}
