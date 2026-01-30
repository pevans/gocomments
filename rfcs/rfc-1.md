---
Request for Comments: 1
Drafted At: 2026-01-27
Approved At: 2026-01-29
Authors:
  - Peter Evans
---

# 1. gocomments: Essential structure and operation

_gocomments_ is a CLI application that reformats comments in Go source files.
It is designed to word-wrap comments to fit a prescribed length, thus making
them more readable to humans working with a code base. Only comments are
modified in the source files.

# 2. Methods of input

_gocomments_ supports several forms of input:

- Stdin: data is provided by stdin
- Command line arguments: file paths are provided as arguments and processed
  sequentially.

## 2.1. Stdin

When data is provided via stdin, the reformatted version is printed to stdout.
If the provided data is not valid Go code, an error code of 1 is returned with
an error message.

## 2.2. File paths

File paths provided as command line arguments can include files and
directories.

- If a file is provided, then that file is reformatted and printed to stdout.
- If a directory is provided, then the files within that directory are
  reformatted and printed to stdout. Files are processed in alphabetical
  ascending order.
- If an argument is provided in the form of `foo/...`, and if `foo` is a
  directory, then gocomments will recurse through foo and all subdirectories
  and process all files discovered therein.

Regardless of whether files, directories, or recursive directories are passed
to gocomments, only Go source files (which end in `.go`) will be processed.

When multiple files are processed in this manner, their output is _not_
delineated in any way.

### 2.2.1. Symbolic links

gocomments follows symbolic links when processing files and directories:

- If a symbolic link points to a file, gocomments will process the target file
  as if it were provided directly.
- If a symbolic link points to a directory, gocomments will process all Go
  source files within the target directory (and recursively if using the `...`
  notation).

The behavior is identical to processing the target file or directory directly.

## 2.3. Exit codes

When processing files from command line arguments, gocomments will exit with
code 1 if any files would be changed by reformatting. This behavior is useful
in CI/CD pipelines to detect formatting inconsistencies. If no files would be
changed, gocomments exits with code 0.

When processing stdin, gocomments exits with code 1 only if the input is not
valid Go code. Successfully reformatted stdin (regardless of whether changes
were made) exits with code 0.

## 2.4. Error handling for non-existent paths

When a file or directory provided as a command-line argument does not exist,
gocomments will produce an error message and exit with a non-zero exit code.

- If a file path does not exist, an error message is printed indicating the
  file cannot be found.
- If a directory path does not exist (including those specified with the `...`
  notation), an error message is printed indicating the directory cannot be
  found.

This behavior ensures that typos or incorrect paths are caught early and
reported to the user.

## 2.5. Line ending handling

gocomments correctly handles files with different line ending conventions:

- Files with Unix line endings (LF, `\n`) are processed normally.
- Files with Windows line endings (CRLF, `\r\n`) are also processed correctly.
- Files with mixed line endings are handled appropriately.

The output from gocomments will use the line ending convention appropriate for
the context (stdout typically uses LF, while files written in-place preserve
their original line ending style when feasible).

## 2.6. Invalid Go files

If a file is not valid Go code, then gocomments will return an exit code of 1
and print an error message. This can happen if:

- A user provides a non-Go file as a file path
- A user pipes data that is not valid Go code into stdin
- A user scans a directory which contains files that end in `.go` but do not
  contain valid Go code

# 3. Comment types and behaviors

Go supports several types of comments -- chiefly, end-of-line comments (`//
...`) and block comments (`/* ... */`).

In all cases:

- gocomments preserves indentation up until the beginning of the comment, and
  new comment indicators that may be added will use the same indentation as
  the existing comment that it extends.
- Only comments that occupy one or more entire lines of code will be
  considered. Inline comments (such as those that follow other code, or in the
  case of block comments that come in the middle of other code) will not be
  modified.
- Spacing after the comment indicator is preserved. If there is no space, then
  there will be no space on subsequent comment lines.

## 3.1. End-of-line comments

- If the comment indicator contains more `/` characters than is required (for
  example, `/// ...`), then those additional slash characters are preserved on
  subsequent lines.

## 3.2. Block comments

- Block comments don't have a required comment indicator for each of their
  lines. Whatever spacing and/or punctuation characters (e.g., `*`) will be
  preserved on subsequent lines that are wrapped.
- If a block comment would be wrapped that previously fit upon on one line,
  and we have no indication of the how the user intended each subsequent line
  to appear, then we will assume they want a `*` character to be aligned below
  the asterisk of the starting `/*` comment indicator. Additionally, we will
  also assume the ending comment indicator should be aligned to the asterisk
  above it. For example:

```
/* a comment like this that could be wrapped by gocomments */
...
/*
 * a comment like this that could be wrapped by
 * gocomments
 */
```

## 3.3. Comment directives

In Go, some software make use of comment directives which conventionally look
like `//foo:bar` with no spacing between the comment indicator and `foo:bar`.
In such cases, gocomments will leave those directives alone.

# 4. File and comment exclusions

Certain files and comment blocks are excluded from reformatting to preserve
their intended structure or to avoid modifying machine-generated content.

## 4.1. Generated files

Files that are machine-generated should not be reformatted, as they may be
regenerated in the future and any formatting changes would be lost. gocomments
detects generated files by searching for comments containing both "Code
generated" and "DO NOT EDIT" text. If such a comment is found anywhere in the
file, the entire file is skipped and returned unchanged.

## 4.2. Commented-out code

Comment blocks that contain valid Go source code are not reformatted. This
preserves the structure of code that has been temporarily commented out,
maintaining its readability as code rather than as prose.

To detect commented-out code, gocomments attempts to parse the text content of
a comment block as Go code in several ways:

- As a complete Go source file
- As statements within a function body
- As top-level declarations within a package

If any of these parsing attempts succeed, the comment block is considered to
contain code and is left unmodified.

## 4.3. Manual formatting preservation

Users can prevent gocomments from reformatting specific comment blocks by
adding the directive `gocomments:noformat` at the end of the first line of the
comment block. When this directive is detected, the entire comment block is
preserved with its original formatting.

Example:

```go
// This comment block will not be reformatted. gocomments:noformat
// Even though this line could be wrapped differently,
//    or has unusual spacing,
// it will be preserved exactly as written.
```

The directive must appear at the end of the first comment line in the block,
after any other text. Leading and trailing whitespace around the directive is
ignored when detecting it.

# 5. Word wrapping comments

Comments are word wrapped to a length defined as llen, which is an
abbreviation of "line length". By default, llen is 78 characters wide. This
length is exclusive; if a line is 78 characters long exactly, then it must be
wrapped.

Each character normally counts as 1 for the purposes of word wrapping. An
exception to this rule are horizontal tab characters, which are treated as
though they occupied a number of characters defined as tlen -- an abbreviation
for "tab length". By default, tlen is 4 characters wide.

For example, in the following code:

```
	// hello world
```

The length of the line would be equal to 15 characters (the length of `//
hello world`) plus 4 (the length of one tab character) for a total of 19.

## 5.1. Configuring line and tab length

From the command line, the user of gocomments may configure both line and tab
length with command-line arguments.

- `-llen n` changes the line length from its default to be `n` characters
  wide. If `n` is a number below 40, we will instead operate as though the
  line length was 40.
- `-tlen n` changes the tab length from its default to be `n` characters wide.

## 5.2. Wrapping at word boundaries

It is important that word wraps must happen at word boundaries; words may not
be cut off in the middle, as that would break the intent of the comment's
author.

A word boundary is considered to be some whitespace character.

If a word would exceed the length of a single line, it should be the only word
on the line that it would occupy.

## 5.3. Paragraph grouping

Within a comment block, gocomments groups consecutive comment lines into
paragraphs and wraps each paragraph independently. This preserves the logical
structure of multi-paragraph comments.

A paragraph boundary is created by a blank comment line (a line containing only
the comment indicator with no text). Each paragraph is wrapped independently,
preserving blank lines between paragraphs.

Example of paragraph grouping:

```go
// This is the first paragraph. It contains multiple sentences that will be
// wrapped together as a single unit.
//
// This is the second paragraph, separated by a blank comment line above. It
// will be wrapped independently from the first paragraph.
```

When a paragraph is wrapped, all text within that paragraph is joined together
with spaces, then re-wrapped according to the line length constraints. This
means that any manual line breaks within a paragraph will be removed during
reformatting.
