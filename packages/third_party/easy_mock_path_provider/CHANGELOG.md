## 0.1.1

- Move default paths under `/app_root`.
  Temporary storage uses `/app_root/tmp`; external storage and cache use
  `/app_root/external/files` and `/app_root/external/cache`.
- Custom path overrides still require caller-created directories.

## 0.1.0

- Built on `easy_mock_channel` with no dependency on the real plugin.
- Initial release with `mockPathProvider.init()` and defaults for every directory.
- Override paths with `set(...)`, including external storage directory lists.
- Simulate delayed and failed lookups with `delay(...)` and `throwError(...)`.
- Remove the method-channel handler automatically after each test.
