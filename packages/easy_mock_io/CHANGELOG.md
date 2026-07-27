## 0.1.0

- Initial release.
- `MockMemoryIO.install([MemoryFileSystem? fs])` swaps `IOOverrides.global` for a `MemoryFileSystem`, so all `dart:io` `File` / `Directory` access runs in memory and never touches disk.
- File locks (`lock` / `unlock`, sync and async) are no-ops, so tests opening the same file in parallel can't deadlock.
- Seeds the memory filesystem from the `UNIT_TEST_ASSETS` folder and pre-creates `/epay_root`.
- Exports `MemoryFileSystem` so callers can pre-seed a filesystem before installing.
