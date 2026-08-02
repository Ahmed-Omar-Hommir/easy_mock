part of '../easy_mock_http.dart';

/// Signature for a dynamic reply: computes a [MockHttpResponse] from the
/// matched [MockHttpRequest].
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
