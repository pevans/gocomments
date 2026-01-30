---
Request for Comments: 5
Drafted At: 2026-01-27
Approved At: 2026-01-29
Authors:
  - Peter Evans
---

# 1. Formatting bullet and list items

Comments in Go source code often contain bullet lists and numbered lists.
gocomments recognizes these list structures and applies special formatting
rules to preserve their readability when word-wrapping.

# 2. Recognizing list items

A list item is recognized by its prefix. The following patterns indicate a
list item:

- Bullet markers: `-`, `+`, `*`, or `o` followed by a space
- Numbered markers: one or more digits followed by `.` or `)` and a space

List item markers may be preceded by whitespace (spaces or tabs). This
whitespace is considered part of the list item's indentation level.

## 2.1. Examples of list items

The following are examples of recognized list items:

```go
// - This is a bullet item
// + This is also a bullet item
// * Another bullet style
// o Yet another bullet style
// 1. First numbered item
// 2. Second numbered item
// 3) Third numbered item (using parenthesis)
//   - Indented bullet item
//     10. Deeply indented numbered item
```

# 3. Word-wrapping list items

When a list item's text exceeds the line length limit (llen), the text is
wrapped to subsequent lines. The wrapped continuation lines must be indented
to align with the first character of the list item's text content, not with
the list marker itself.

## 3.1. Determining continuation indentation

The continuation indentation is calculated as follows:

1. Start with the indentation of the list item line (any leading whitespace)
2. Add the width of the comment marker (`//` plus any space after it)
3. Add the width of the list marker and its trailing space

All continuation lines of the list item should begin at this indentation level.

## 3.2. Example of wrapped list items

Before wrapping (line too long):

```go
// - This is a very long list item that exceeds the maximum line length and needs to be wrapped
```

After wrapping:

```go
// - This is a very long list item that exceeds the maximum line length and
//   needs to be wrapped
```

Note that "needs to be wrapped" is indented to align with "This" on the first
line.

# 4. Preserving list structure

When processing comments containing multiple list items, gocomments must
preserve the visual structure of the list. Each list item is treated as an
independent unit for wrapping purposes.

## 4.1. List items as paragraph boundaries

In addition to the paragraph boundaries defined in RFC 1 (blank comment lines),
list items also create paragraph boundaries. When a list item is encountered,
it starts a new paragraph. This means that:

- Each list item is wrapped independently
- Text before a list item is kept in a separate paragraph
- Each list item forms its own paragraph

A blank comment line or a non-list-item comment line terminates the list
context. Subsequent list items may start a new list.

## 4.2. Example with multiple items

Before wrapping:

```go
// Here are some items:
// - First item with some very long text that will need to wrap to the next line
// - Second item
// - Third item that is also quite long and will need special handling when it wraps
```

After wrapping:

```go
// Here are some items:
// - First item with some very long text that will need to wrap to the next
//   line
// - Second item
// - Third item that is also quite long and will need special handling when it
//   wraps
```
