## 0.1.0

- Initial release.
- `mockSecureStorage` — backs flutter_secure_storage's method channel
  (`plugins.it_nomads.com/flutter_secure_storage`) with an in-memory store.
  **No dependency on flutter_secure_storage**; speaks the channel's raw method
  codes (read/write/delete/deleteAll/containsKey/readAll).
- `seed({...})` / `read(key)` / `stored`; `install()` clears the store and wires
  the channel.
- `delay(duration)` — holds every channel response pending for [duration], so a
  test can observe a loading state before secure storage resolves.
