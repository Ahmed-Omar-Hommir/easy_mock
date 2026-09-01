# 0.4.0

- Make the `MockHttpOverrides` instance private; recorded requests remain
  available through `mockHttp.requests`.
- Rename `Verification.calls` to `Verification.requests` for consistency with
  `mockHttp.requests`.

# 0.3.0

- Remove `mockHttp.expect`; use the `MockResult` returned by `mockHttp.when`
  for explicit verification.

# 0.2.3

- Remove the deprecated `MockResult.verification` compatibility alias.

# 0.2.2

- Make `MockResult` extend `LazyVerification`, allowing direct assertions such
  as `result.calledOnce`, `result.never`, and `result.calls`.
- Keep `MockResult.verification` as a deprecated compatibility alias.

# 0.2.1

- Make `MockResult.verification` count every recorded request matching the
  registration's method, URL, body, headers, and query, including requests
  served by another registration with the same matcher.

# 0.2.0

- Replace `StubBuilder` with `MockResult`, returned directly by every
  `when` / `expect` verb. `MockResult.verification` lazily verifies calls handled
  by that exact registration.
- Preserve dynamic replies through the new `responder` named argument.
- Keep `mockHttp.verify` as the independent matcher-based verification API.

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
