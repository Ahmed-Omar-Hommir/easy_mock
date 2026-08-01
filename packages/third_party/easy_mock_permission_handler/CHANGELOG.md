## 0.1.0

- Initial release.
- `mockPermissionHandler` — a readable scenario API over the permission_handler
  platform channel, built on `easy_mock_channel`. **No dependency on
  permission_handler**; speaks the channel's raw wire codes.
- Per-permission scenarios `mockPermissionHandler.camera` / `.notification`:
  `grant` / `deny` / `permanentlyDeny` / `restrict` / `limit` / `provisional`.
- Service: `serviceEnabled` / `serviceDisabled` / `serviceNotApplicable`.
- App settings: `openAppSetting` / `doNotOpenAppSetting`.
- Rationale: `showRequestPermissionRationale` /
  `doNotShowRequestPermissionRationale`.
- `install()` sets up the channel and resets to defaults.
- Supports camera and notification for now.
