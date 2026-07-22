## 0.1.0

- Initial release.
- `mockChannel(name)` installs a mock handler for a `MethodChannel` (auto-removed on teardown).
- `when(method:, arguments:, returns:, throws:)` — stub a reply or error; optional deep-equality argument matching; later stubs win.
- `verify(method:)` and `calls` for assertions.
