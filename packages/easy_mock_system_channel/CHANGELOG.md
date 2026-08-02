## 0.1.0

- Initial release.
- `mockSystemChannel.install()` installs a default mock for every SystemChannels method channel (correct codec per channel; each method returns null and is recorded), auto-removed on teardown.
- Seeded defaults: `Clipboard.hasStrings` → `{'value': false}`, `getKeyboardState` → `{}`.
- `flutter/textinput` is excluded by default (the test framework's `TestTextInput` owns it); opt in with `install(includeTextInput: true)`.
- Per-channel access via `mockSystemChannel.platform` / `.navigation` / `.mouseCursor` / … or `channel(name)` — override with `.when(...)`, assert with `.verify(...)`.
