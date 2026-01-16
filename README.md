# gocomments

gocomments is a tool that reformats your Go comments to respect your preferred
line and tab lengths. Its broad intention is to automate what might happen if
you used your editor's autoformat command on each of your comments. It is an
add-on tool for projects that are already using
[gofmt](https://pkg.go.dev/cmd/gofmt) or
[gofumpt](https://github.com/mvdan/gofumpt), which themselves do not alter the
contents of comments.

gocomments is designed to look and act similarly to gofmt; it accepts many of
gofmt's command-line arguments, both their form and intent. Below you will
find the help summary that explains what is supported:

```
usage: gocomments [flags] [paths...]
  gocomments reformat's comment blocks in Go files. By default, it only
  prints the reformatted contents of each file.

flags:
  -d	display unified diffs of changes rather than whole files
  -l	list files whose formatting would change
  -llen int
      maximum line length for comments (default 78)
  -tlen int
      number of spaces that tabs count for (default 4)
  -w	write changes back to source files instead of stdout
```

## How to use gocomments

gocomments can be deployed in any number of environments to keep your comments
well-formatted. Below are some examples:

- As part of your editor's formatting. For example, with conform.nvim you can
  chain several format programs together in sequence.
- As a git hook (pre-commit, pre-push, etc.)
- As a hook to an AI agent
- As part of a CI/CD pipeline (e.g. to test for correctness)

## Preservation of intent in comments

gocomments tries to maintain certain formatting choices within comments. Those
include:

- Additional slashes in the comment leader. Like using `///` for certain
  comments? gocomments will make sure that those are used correctly throughout
  any comment block they are found.
- Multi-paragraph comments. If you have several paragraphs within comments
  that are separated by blank comment lines, gocomments will separately format
  each block.
- Bullet list and numbered list items. gocomments will independently format
  each list item as if it were its own paragraph block, and will maintain list
  item indentation -- including for sublist items.
- Comments without any spacing to begin with (for example, `//go:embed ...`)
  may be formatted, but the lack of spacing between the comment leader and
  the text will be preserved.
- Any lines of code that are commented out are left alone.
- Slash-star inline comment blocks (`/* ... */`) are left alone.

If there's a comment block that you would prefer remain unformatted, you can
do so by adding `gocomments:noformat` to the end of the first (or only!) line
in the block.

## Why not use golines instead?

An existing formatter that can format comments is
[golines](https://github.com/segmentio/golines). It has been archived by their
org-owner, Segmentio, although [a fork has been created by the maintainers of
golangci-lint](https://github.com/golangci/golines/).

Golines is intended to shorten long lines in several contexts. It does not
reformat comments by default. To replicate the behavior of gocomments, you
would need to disable its other default functionality and enable the shortened
comment functionality. Selfishly, I found that procedure to be cumbersome, and
so wrote my own tool.

To put it another way, I'm personally ok with gofmt's behavior of leaving
long lines of code alone, but I prefer that comments be formatted according to
my editor's `textwidth` setting.
