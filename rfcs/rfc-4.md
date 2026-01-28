---
Request for Comments: 4
Drafted At: 2026-01-27
Authors:
  - Peter Evans
---

# 1. Unified diffs of changes that would be made

gocomments can print unified diffs of changes (similar to what is produced
with `diff -u`) that would be made to files. Users of gocomments can use this
feature to quickly learn the inconsistencies in comments without having to
read the entirety of the source file.

# 1.1. Difference in behavior

To print unified diffs of changes, users of gocomments must run the program
with a `-d` command-line flag. When this happens, as files are processed,
their unified diffs are printed to standard output. The normal behavior of
printing the entire source file reformatted does not take place.

Below is an example unified diff:

```diff
--- wrap.go
+++ wrap.go
@@ -5,7 +5,8 @@
 	"strings"
 )

-//  fsldkjf klsdj fklsd fklsdf sdkl fjklsdf jklsdf jskdl fsdklf jksdl fksdl fksdl fsdkl fjsdk fjsdkl jfsdklj fsklfjs
+// fsldkjf klsdj fklsd fklsdf sdkl fjklsdf jklsdf jskdl fsdklf jksdl fksdl
+// fksdl fsdkl fjsdk fjsdkl jfsdklj fsklfjs
 var listItemPattern       = regexp.MustCompile(`^\s*[-+*o] |^\s*\d+[.)] `)

 // wrapText takes some given text and a length, and with that produces a set
```

# 1.2. Exit codes

The exit code behavior described in RFC 1 section 2.3 remains unchanged when
using the `-d` flag. gocomments will exit with code 1 if any files would be
changed (i.e., if any diffs are shown), and exit with code 0 if no files
required reformatting.

# 1.3. Combination with other flags

When gocomments is executed with other command-line flags, their behavior is
_combined_ rather than mutually exclusive.

If gocomments is executed with `-w` and `-d`, then both unified diffs are
printed and changes are written in-place (see RFC 2 for details on that).

If gocomments is executed with `-l` and `-d`, then both filenames _and_
unified diffs are printed to standard output. In such an event, the filename
from `-l` must be printed _before_ the unified diff for that file.

The content should be consistent: you should always see the file that would be
changed followed by the diff for that file; there should never be a mismatch
of filename and unified diff.

It is possible to run gocomments with `-l`, `-w`, and `-d`. In such an event,
the behaviors described in the above paragraphs must all hold true.
