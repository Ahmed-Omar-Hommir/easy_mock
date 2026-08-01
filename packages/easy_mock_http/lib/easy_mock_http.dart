import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Low-level HTTP mocking for tests, built on `dart:io` [HttpOverrides].
///
/// Goal: keep network tests easy to mock, easy to write, readable, and
/// maintainable. Instead of stubbing a transport package, this mocks HTTP at
/// the lowest level — the `dart:io` [HttpClient] that every client sits on.
/// Dio and `package:http` both create one under the hood, so a single
/// [HttpOverrides] swap covers both: the code under test keeps its real client
/// and injects nothing. Stub replies with [mockHttp]'s `when` and assert sends
/// with `verify`. Tests stay flat Arrange / Act / Assert:
///
/// ```dart
/// test('ping replies pong', () async {
///   // Arrange
///   final http = mockHttp();
///   http.when.get(
///     'https://www.example.com/api/ping',
///     response: {'pong': true},
///   );
///
///   // Act
///   final response = await Dio().get('https://www.example.com/api/ping');
///
///   // Assert
///   expect(response.data, {'pong': true});
///   http.verify.get('/api/ping').calledOnce;
/// });
/// ```
typedef MockHttpHandler =
    FutureOr<MockHttpResponse> Function(MockHttpRequest request);

/// A request as observed at the `dart:io` boundary, after the transport
/// package has serialized headers and body.
class MockHttpRequest {
  MockHttpRequest({
    required this.method,
    required this.uri,
    required this.headers,
    required this.bodyBytes,
  });

  final String method;
  final Uri uri;
  final Map<String, List<String>> headers;
  final List<int> bodyBytes;

  String get bodyString => utf8.decode(bodyBytes, allowMalformed: true);

  Object? get bodyJson => bodyBytes.isEmpty ? null : jsonDecode(bodyString);

  String? header(String name) {
    final values = headers[name.toLowerCase()];
    return (values == null || values.isEmpty) ? null : values.join(', ');
  }

  @override
  String toString() => '$method ${uri.path}';
}

/// The canned reply for a mocked request.
class MockHttpResponse {
  MockHttpResponse({
    this.statusCode = 200,
    Object? body,
    Map<String, String>? headers,
    String? reasonPhrase,
  }) : bodyBytes = _encodeBody(body),
       headers = {
         'content-type': 'application/json; charset=utf-8',
         if (headers != null)
           for (final e in headers.entries) e.key.toLowerCase(): e.value,
       },
       reasonPhrase = reasonPhrase ?? _reasonPhraseFor(statusCode);

  factory MockHttpResponse.json(
    Object? data, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) => MockHttpResponse(statusCode: statusCode, body: data, headers: headers);

  final int statusCode;
  final List<int> bodyBytes;
  final Map<String, String> headers;
  final String reasonPhrase;

  static List<int> _encodeBody(Object? body) {
    if (body == null) return const <int>[];
    if (body is List<int>) return body;
    if (body is String) return utf8.encode(body);
    return utf8.encode(jsonEncode(body));
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

// ─── Fluent API: stub with `when`, assert with `verify` ──────────────────────
//
// Same HttpOverrides interception as above, but instead of one up-front handler
// you stub imperatively and each line reads like the request it mocks:
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

/// Installs a fresh [MockHttp] as `HttpOverrides.global` and removes it on
/// teardown. Build transport clients (Dio, `http.Client`, repositories) AFTER
/// this call so they pick up the override.
MockHttp? _http;
MockHttp get http {
  if (_http == null) {
    throw Exception("You are missing setUpMockHttp.");
  }
  return _http!;
}

void setUpMockHttp() {
  _http = MockHttp();
  final http = _http!;
  HttpOverrides.global = http.overrides;
  addTearDown(() {
    HttpOverrides.global = null;
    http._verifyExpectations();
  });
}

/// Matches any value in a body matcher, e.g. `{'id': any(), 'name': 'Sam'}`.
Matcher any() => anything;

/// Stub registry and request recorder behind [mockHttp]. Reuses
/// [MockHttpOverrides] for the actual `dart:io` interception.
class MockHttp {
  late final MockHttpOverrides overrides = MockHttpOverrides(_handle);
  final List<_Stub> _stubs = <_Stub>[];

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

class _Stub {
  _Stub(this.matcher, this.expected);

  final _RequestMatcher matcher;
  final bool expected;
  final List<MockHttpRequest> calls = <MockHttpRequest>[];
  MockHttpHandler responder = (_) => MockHttpResponse(statusCode: 200);
}

/// Matches a recorded request by method, URL, and optional body / header /
/// query subsets.
class _RequestMatcher {
  _RequestMatcher(String method, this.url, this.body, this.headers, this.query)
    : method = method.toUpperCase();

  final String method;
  final Object url;
  final Object? body;
  final Map<String, Object?>? headers;
  final Map<String, Object?>? query;

  bool matches(MockHttpRequest request) {
    if (request.method.toUpperCase() != method) return false;
    if (!_matchUrl(request.uri)) return false;
    if (body != null && !_matchBody(request)) return false;
    if (headers != null && !_matchHeaders(request)) return false;
    if (query != null && !_matchQuery(request)) return false;
    return true;
  }

  bool _matchHeaders(MockHttpRequest request) {
    for (final entry in headers!.entries) {
      if (!_valueMatches(entry.value, request.header(entry.key))) return false;
    }
    return true;
  }

  bool _matchQuery(MockHttpRequest request) {
    final params = request.uri.queryParameters;
    for (final entry in query!.entries) {
      final expected = entry.value;
      final actual = params[entry.key];
      final ok = expected is Matcher
          ? expected.matches(actual, <dynamic, dynamic>{})
          : actual == '$expected';
      if (!ok) return false;
    }
    return true;
  }

  bool _matchUrl(Uri uri) {
    final full = uri.toString();
    final pattern = url;
    if (pattern is RegExp) {
      return pattern.hasMatch(full) || pattern.hasMatch(uri.path);
    }
    if (pattern is Matcher) return pattern.matches(full, <dynamic, dynamic>{});
    final s = '$pattern';
    if (s.startsWith('http')) return full == s || full.startsWith(s);
    return uri.path == s || uri.path.endsWith(s) || full.contains(s);
  }

  bool _matchBody(MockHttpRequest request) {
    final expected = body;
    if (expected is String) return request.bodyString == expected;
    return _valueMatches(expected, _safeJson(request));
  }

  @override
  String toString() => [
    method,
    url,
    if (body != null) body,
    if (headers != null) headers,
    if (query != null) 'query=$query',
  ].join(' ');
}

Object? _safeJson(MockHttpRequest request) {
  if (request.bodyBytes.isEmpty) return null;
  // Form bodies aren't JSON; decode to a map so map matchers work on them.
  final contentType = request.header('content-type') ?? '';
  if (contentType.contains('application/x-www-form-urlencoded')) {
    return Uri.splitQueryString(request.bodyString);
  }
  try {
    return request.bodyJson;
  } catch (_) {
    return request.bodyString;
  }
}

bool _valueMatches(Object? expected, Object? actual) {
  if (expected is Matcher) {
    return expected.matches(actual, <dynamic, dynamic>{});
  }
  if (expected is Map) {
    if (actual is! Map) return false;
    for (final entry in expected.entries) {
      if (!actual.containsKey(entry.key)) return false;
      if (!_valueMatches(entry.value, actual[entry.key])) return false;
    }
    return true;
  }
  if (expected is List) {
    if (actual is! List || actual.length != expected.length) return false;
    for (var i = 0; i < expected.length; i++) {
      if (!_valueMatches(expected[i], actual[i])) return false;
    }
    return true;
  }
  return expected == actual;
}

String _reasonPhraseFor(int statusCode) => switch (statusCode) {
  200 => 'OK',
  201 => 'Created',
  202 => 'Accepted',
  204 => 'No Content',
  400 => 'Bad Request',
  401 => 'Unauthorized',
  403 => 'Forbidden',
  404 => 'Not Found',
  409 => 'Conflict',
  413 => 'Payload Too Large',
  422 => 'Unprocessable Entity',
  429 => 'Too Many Requests',
  500 => 'Internal Server Error',
  _ => 'Status $statusCode',
};

// ─── dart:io fakes ─────────────────────────────────────────────────────────
// Only the members Dio's IOHttpClientAdapter and the http package's IOClient
// actually touch are implemented; noSuchMethod absorbs the rest of the wide
// dart:io surface (config setters etc.).

class _MockHttpClient implements HttpClient {
  _MockHttpClient(this._overrides);

  final MockHttpOverrides _overrides;

  Future<HttpClientResponse> _finish(_MockHttpClientRequest request) async {
    final captured = MockHttpRequest(
      method: request.method,
      uri: request.uri,
      headers: request._headers.snapshot(),
      bodyBytes: request._body.toBytes(),
    );
    _overrides.requests.add(captured);
    final response = await _overrides.handler(captured);
    return _MockHttpClientResponse(response);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _MockHttpClientRequest(method, url, _finish);

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) => openUrl(method, Uri(scheme: 'http', host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);
  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);
  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('DELETE', url);
  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('PATCH', url);
  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('HEAD', url);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientRequest implements HttpClientRequest {
  _MockHttpClientRequest(this.method, this.uri, this._finish);

  final Future<HttpClientResponse> Function(_MockHttpClientRequest) _finish;

  final BytesBuilder _body = BytesBuilder(copy: false);
  final MockHttpHeaders _headers = MockHttpHeaders();
  Future<HttpClientResponse>? _response;

  @override
  final String method;
  @override
  final Uri uri;

  @override
  HttpHeaders get headers => _headers;

  @override
  Encoding encoding = utf8;
  @override
  int contentLength = -1;
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = true;
  @override
  bool bufferOutput = true;

  @override
  void add(List<int> data) => _body.add(data);

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      _body.add(chunk);
    }
  }

  @override
  void write(Object? object) => _body.add(encoding.encode('$object'));

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) =>
      write(objects.join(separator));

  @override
  void writeln([Object? object = '']) => write('$object\n');

  @override
  void writeCharCode(int charCode) => write(String.fromCharCode(charCode));

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> flush() async {}

  @override
  Future<HttpClientResponse> close() => _response ??= _finish(this);

  @override
  Future<HttpClientResponse> get done => _response ??= _finish(this);

  @override
  List<Cookie> get cookies => <Cookie>[];

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _MockHttpClientResponse(this._response);

  final MockHttpResponse _response;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(<List<int>>[
      Uint8List.fromList(_response.bodyBytes),
    ]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  int get statusCode => _response.statusCode;
  @override
  String get reasonPhrase => _response.reasonPhrase;
  @override
  int get contentLength => _response.bodyBytes.length;
  @override
  HttpHeaders get headers => MockHttpHeaders.fromMap(_response.headers);
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => false;
  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];
  @override
  List<Cookie> get cookies => <Cookie>[];
  @override
  X509Certificate? get certificate => null;
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  Future<Socket> detachSocket() =>
      Future<Socket>.error(UnsupportedError('detachSocket is not mocked'));

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) => Future<HttpClientResponse>.error(
    UnsupportedError('redirect is not mocked'),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpHeaders implements HttpHeaders {
  MockHttpHeaders();

  MockHttpHeaders.fromMap(Map<String, String> map) {
    map.forEach((key, value) => _store[key.toLowerCase()] = <String>[value]);
  }

  final Map<String, List<String>> _store = <String, List<String>>{};

  Map<String, List<String>> snapshot() => <String, List<String>>{
    for (final e in _store.entries) e.key: List<String>.from(e.value),
  };

  @override
  List<String>? operator [](String name) => _store[name.toLowerCase()];

  @override
  String? value(String name) {
    final values = _store[name.toLowerCase()];
    return (values == null || values.isEmpty) ? null : values.first;
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _store.putIfAbsent(name.toLowerCase(), () => <String>[]).add('$value');
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _store[name.toLowerCase()] = <String>['$value'];
  }

  @override
  void remove(String name, Object value) =>
      _store[name.toLowerCase()]?.remove('$value');

  @override
  void removeAll(String name) => _store.remove(name.toLowerCase());

  @override
  void forEach(void Function(String name, List<String> values) action) =>
      _store.forEach(action);

  @override
  void clear() => _store.clear();

  @override
  ContentType? get contentType {
    final raw = value('content-type');
    return raw == null ? null : ContentType.parse(raw);
  }

  @override
  set contentType(ContentType? value) {
    if (value == null) {
      removeAll('content-type');
    } else {
      set('content-type', value.toString());
    }
  }

  @override
  int get contentLength {
    final raw = value('content-length');
    return raw == null ? -1 : int.tryParse(raw) ?? -1;
  }

  @override
  set contentLength(int value) => set('content-length', '$value');

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
