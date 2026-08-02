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
  mockHttp.when.get(
    'https://www.example.com/api/ping',
    response: {'pong': true},
  );

  // Act — production code, whatever transport it uses
  final response = await Dio().get('https://www.example.com/api/ping');

  // Assert
  expect(response.data, {'pong': true});
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
);
```

Unmatched requests get a loud 404, so a typo'd URL fails the test instead of
silently passing. For dynamic replies, chain instead:

```dart
mockHttp.when.get('/v1/time').replyWith((request) => MockHttpResponse.json({...}));
```

`mockHttp.expect.get(...)` works like `when` but also fails the test on teardown
if the request never arrives.

## Verifying

```dart
mockHttp.verify.post('/v1/login', body: {'user': 'sam'}).calledOnce;
mockHttp.verify.get('/v1/cities', query: {'page': 2}).called(2);
mockHttp.verify.delete('/v1/session').never;
mockHttp.requests;  // raw recording of everything sent
```

## Notes

- VM tests only (`flutter test`); `dart:io` does not exist on
  `--platform chrome`.
- Inside `testWidgets`, run the request with `tester.runAsync(...)` — widget
  test time is fake, so a plain `await` on real I/O never completes.
- Construct clients after `mockHttp()` (inside the test body), which is the
  natural Arrange order anyway.
