## 0.1.0

- Built on `easy_mock_channel` with no dependency on the real plugin.
- Initial release with `mockPathProvider.init()` and defaults for every directory.
- Override paths with `set(...)`, including external storage directory lists.
- Simulate delayed and failed lookups with `delay(...)` and `throwError(...)`.
- Remove the method-channel handler automatically after each test.
