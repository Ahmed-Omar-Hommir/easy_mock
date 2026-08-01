# easy_mock_secure_storage

A readable test mock for
[`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage). It
backs the plugin's method channel
(`plugins.it_nomads.com/flutter_secure_storage`) with an in-memory store, so it
has **no dependency on flutter_secure_storage** — it speaks the channel's raw
method codes directly.

## Usage

```dart
import 'package:easy_mock_secure_storage/easy_mock_secure_storage.dart';

mockSecureStorage.install();                       // harness usually does this

// Seed what the app will read:
mockSecureStorage.seed({'unique_device_id': 'abc'});

// ... run the flow that touches secure storage ...

// Inspect what the app wrote:
expect(mockSecureStorage.read('unique_device_id'), isNotNull);
```

- `install()` — wires the channel and clears the store (call once per test).
- `seed({...})` — replace the store with the keys the app should read.
- `read(key)` / `stored` — read back what the app wrote.
- `delay(duration)` — hold every channel response pending for `duration`, to
  observe a loading state (e.g. the device-id lookup in flight).

A real read/write round-trips through the in-memory store, so `read` returns the
last `write`.

> Needs the Flutter test binding (inside `testWidgets`, or
> `TestWidgetsFlutterBinding.ensureInitialized()` in a plain `test`).
