## 0.1.0

- Initial release.
- `mockDeviceInfo` — scripts `device_info_plus`' `getDeviceInfo` channel result
  (built on `easy_mock_channel`). **No dependency on device_info_plus**; speaks
  the channel's raw map.
- `set({name, manufacturer, model, id, extra})`; `install()` resets to an empty
  map.
