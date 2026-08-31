# easy_mock_http

Transport-agnostic HTTP mocking for Flutter VM tests.

Instead of stubbing a transport package, `easy_mock_http` intercepts HTTP at the
lowest level — the `dart:io` `HttpClient` that every client sits on. Dio,
`package:http`, and any other VM transport create one under the hood, so a
single `HttpOverrides` swap covers them all: the code under test keeps its
real client and injects nothing. Refactor from one HTTP package to another
and your tests keep passing.

## Usage

Tests stay flat Arrange / Act / Assert:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_mock_http/easy_mock_http.dart';

test('ping replies pong', () async {
  // Arrange
  mockHttp.init();
  final result = mockHttp.when.get(
    'https://www.example.com/api/ping',
    response: {'pong': true},
  );

  // Act — production code, whatever transport it uses
  final response = await Dio().get('https://www.example.com/api/ping');

  // Assert
  expect(response.data, {'pong': true});
  result.calledOnce; // same matcher as the registration
  mockHttp.verify.get('/api/ping').calledOnce;
});
```

## Stubbing

Every verb (`get` / `post` / `put` / `delete` / `patch` / `head`) takes:

```dart
mockHttp.when.post(
  url,                       // String path, full URL, or RegExp
  body: {'user': any()},     // match request body (subset; values may be Matchers)
  headers: {'Authorization': any()},  // match request headers (case-insensitive)
  query: {'page': 2},        // match query parameters
  response: {'token': 'abc'},         // reply body (JSON-encoded)
  statusCode: 201,           // reply status, default 200
  responseHeaders: {...},    // reply headers
  delay: Duration(seconds: 1),        // postpone the reply
  error: SocketException('down'),     // throw instead of replying
  responder: (request) => MockHttpResponse(...), // dynamic reply
);
```

Unmatched requests get a loud 404, so a typo'd URL fails the test instead of
silently passing. `responder` cannot be combined with the canned reply
arguments. A dynamic reply looks like this:

```dart
mockHttp.when.get(
  '/v1/time',
  responder: (request) => MockHttpResponse.json({...}),
);
```

Every `when` verb returns a `MockResult`. It lazily verifies with the same
method, URL, body, headers, and query matcher as that registration:

```dart
final result = mockHttp.when.post('/v1/login', response: {'token': 'abc'});

await login();

result.calledOnce;
```

## Verifying

```dart
mockHttp.verify.post('/v1/login', body: {'user': 'sam'}).calledOnce;
mockHttp.verify.get('/v1/cities', query: {'page': 2}).called(2);
mockHttp.verify.delete('/v1/session').never;
mockHttp.requests;  // raw recording of everything sent
```

`mockHttp.verify` remains independent of `MockResult`: it searches all recorded
requests using the matcher supplied at verification time. Use it when the
verification matcher differs from the registered route.

## Notes

- VM tests only (`flutter test`); `dart:io` does not exist on
  `--platform chrome`.
- Inside `testWidgets`, run the request with `tester.runAsync(...)` — widget
  test time is fake, so a plain `await` on real I/O never completes.
- Construct clients after `mockHttp()` (inside the test body), which is the
  natural Arrange order anyway.
