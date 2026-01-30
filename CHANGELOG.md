# Changelog

All notable changes to gocomments will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-01-29

### Added

- RFCs that define the expected behavior of gocomments (see `rfcs/` to read
  those). New functionality will be defined through subsequent RFCs.
- End-to-end (black box) tests that demonstrate the expectations of
  gocomments. You can run those with `just e2e-test` or together with unit
  tests with `just test`.
- Slash-star block comments (`/* ... */`) are now formatted, just as
  slash-slash (`// ...`) had been.

### Changed

- Alternative behaviors (like `-l`, list files, and `-w`, write changes) can
  be combined, similar to `gofmt`. If you list and show diffs (`-l -d`), the name
  of the file will be printed before the file's diff.

## [0.1.0] - 2026-01-27

This is the first release of gocomments, a tool for automatically reformatting comments in Go source files to respect preferred line and tab lengths.

[0.2.0]: https://github.com/pevans/gocomments/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/pevans/gocomments/releases/tag/v0.1.0
