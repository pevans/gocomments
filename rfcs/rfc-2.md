---
Request for Comments: 2
Drafted At: 2026-01-27
Approved At: 2026-01-29
Authors:
  - Peter Evans
---

# 1. In-place writes

gocomments has the capability of writing changes to files in-place. Users of
gocomments may use this capability to automatically update all files that have
some inconsistency in their formatting.

# 1.1. Difference in behavior

When gocomments is with the `-w` flag, the normal behavior of printing the
reformatted Go source code is not taken. After execution, each file that was
read by gocomments will be written back with reformatted comments.

# 1.2. Exit codes

The exit code behavior described in RFC 1 section 2.3 remains unchanged when
using the `-w` flag. gocomments will exit with code 1 if any files would be
changed (or were changed, when using `-w`), and exit with code 0 if no files
required reformatting.
