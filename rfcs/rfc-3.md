---
Request for Comments: 3
Drafted At: 2026-01-27
Approved At: 2026-01-29
Authors:
  - Peter Evans
---

# 1. List files that would be changed

gocomments can list files that would be changed without actually changing
them. This feature is useful to discover where there may be formatting
inconsistencies in a code base, particularly within a CI/CD pipeline that
requires such consistency.

# 1.1. Difference in behavior

To list files that would change, users pass the `-l` command-line flag ti
gocomments. When this happens, the normal behavior of printing reformatted
source code to standard output will not occur. Instead, a list of files are
printed (one per line) that represent files where changes would occur.

# 1.2. Exit codes

The exit code behavior described in RFC 1 section 2.3 remains unchanged when
using the `-l` flag. gocomments will exit with code 1 if any files would be
changed (i.e., if any files are listed), and exit with code 0 if no files
required reformatting.

# 1.3. Combination with other flags

When gocomments is executed with both `-l` and `-w` flags (defined RFC 2),
files are both listed _and_ written in-place. That is, the behaviors of the
two flags are combined, rather than mutually exclusive.
