---
Request for Comments: 6
Drafted At: 2026-03-04
Approved At: 2026-03-04
Authors:
  - Peter Evans
---

# 1. Preserving inline single-line block comments

Block comments using the `/* ... */` syntax can appear inline within a line of
Go code -- that is, with non-whitespace source text following the closing `*/`
on the same line. A common example is annotating a declaration:

```go
/* exported */ func Foo() {}
```

or marking a statement:

```go
/* #nosec */ x := dangerousFunc()
```

# 2. The problem with reformatting inline single-line block comments

When gocomments encounters a block comment at the start of a line, it
currently reformats it into the multi-line `/* ... */` style, which destroys
the inline structure of the source code:

```go
/* exported */ func Foo() {}
```

would become:

```go
/*
 * exported
 */
func Foo() {}
```

This transformation is incorrect -- it separates the comment from the
declaration it annotates and changes the meaning of the source.

# 3. Rule: preserve fitting inline single-line block comments

A block comment must not be reformatted when all of the following conditions
are met:

1. The comment is fully contained on a single line (it contains no newlines).
2. There is non-whitespace text on the same line after the closing `*/`.
3. The full source line does not exceed the configured line length limit
   (`llen`), after expanding tabs to their equivalent spaces.

When all three conditions are satisfied, gocomments leaves the comment and its
surrounding line exactly as written in the source file.

# 4. Examples

## 4.1. Inline comment within the limit -- preserved

```go
/* exported */ func Example() {}
```

With `llen=78`, the line is 32 characters, which is within the limit.
gocomments leaves this unchanged.

## 4.2. Standalone single-line block comment -- still reformatted

```go

/* Short block comment */
func example() {}
```

There is no non-whitespace text after the `*/`, so condition 2 is not met.
gocomments reformats this as before:

```go
/*
 * Short block comment
 */
func example() {}
```

## 4.3. Long single-line block comment -- still reformatted

```go
/* This is a very long block comment that would normally be wrapped if it was a line comment and should now be reformatted */
func example() {}
```

Even if text followed the `*/`, the line would exceed `llen=50`, so condition
3 is not met. gocomments reformats this as before:

```go
/*
 * This is a very long block comment that would
 * normally be wrapped if it was a line comment
 * and should now be reformatted
 */
func example() {}
```

# 5. Interaction with other rules

- The `gocomments:noformat` directive continues to take precedence over all
  other rules.
- Block comments with non-whitespace text before the `/*` on the same line are
  already excluded from processing by the general inline comment rule and are
  not affected by this RFC.
- Multi-line block comments (those containing newlines) are not affected by
  this rule and continue to be reformatted as before.
