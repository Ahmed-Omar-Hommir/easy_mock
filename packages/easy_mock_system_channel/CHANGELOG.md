## 0.1.0

- Initial release.
- `mockSystemChannel.init()` installs a default mock for every SystemChannels method channel (correct codec per channel; each method returns null and is recorded), auto-removed on teardown.
- Seeded defaults: `Clipboard.hasStrings` → `{'value': false}`, `getKeyboardState` → `{}`.
- `flutter/textinput` is left to the framework's `TestTextInput`, which owns it; `init()` relaxes the unmocked-channel guard on that channel so it can't fail while the handler is unregistered.
- Per-channel access via `mockSystemChannel.platform` / `.navigation` / `.mouseCursor` / … or `channel(name)` — override with `.when(...)`, assert with `.verify(...)`.
