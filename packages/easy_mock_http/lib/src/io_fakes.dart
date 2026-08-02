part of '../easy_mock_http.dart';

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
