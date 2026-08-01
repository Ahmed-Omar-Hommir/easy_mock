# 0.1.0

- Initial release: `mockHttp()` with fluent `when` / `expect` / `verify` verbs.
- Intercepts `dart:io` `HttpClient` via `HttpOverrides` — covers Dio,
  `package:http`, and any other VM transport with zero injection.
- Request matching by method, URL (path, full URL, or RegExp), and subset
  matchers for `body`, `headers`, and `query` (values may be flutter_test
  matchers).
- Replies via `response` / `statusCode` / `responseHeaders`, plus `delay` for
  slow responses and `error` for transport failures; `replyWith` for dynamic
  replies.
- Records every request (`requests`) and verifies sends with
  `called` / `calledOnce` / `never`.
