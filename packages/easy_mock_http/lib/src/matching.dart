part of '../easy_mock_http.dart';

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
