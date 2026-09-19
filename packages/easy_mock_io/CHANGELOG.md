## 0.1.1

- Pre-create application directories under `/app_root`, including common
  external-storage categories.
- Create the same layout under `MemoryIOConfig.rootDirPath` for custom roots,
  preserving files in a supplied filesystem.

## 0.1.0

- Initial release.
- `MockMemoryIO.init([MemoryFileSystem? fs])` swaps `IOOverrides.global` for a `MemoryFileSystem`, so all `dart:io` `File` / `Directory` access runs in memory and never touches disk.
- File locks (`lock` / `unlock`, sync and async) are no-ops, so tests opening the same file in parallel can't deadlock.
- Seeds the memory filesystem from the `UNIT_TEST_ASSETS` folder and pre-creates `/app_root`.
- Exports `MemoryFileSystem` so callers can pre-seed a filesystem before installing.
