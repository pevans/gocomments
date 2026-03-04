#!/usr/bin/env bats
# Tests for list formatting in comments

load test_helper

setup_file() {
    setup_test_env
    build_gocomments
}

# ---------------------------------------------------------------------------
# Bullet list markers
# ---------------------------------------------------------------------------

@test "lists: bullet markers (-, +, *, o) are preserved" {
    local testfile="$BATS_TEST_TMPDIR/bullet_markers.go"
    cat > "$testfile" << 'EOF'
package main

// - Item with dash
// + Item with plus
// * Item with star
// o Item with lowercase o
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial "// - Item with dash"
    assert_output --partial "// + Item with plus"
    assert_output --partial "// * Item with star"
    assert_output --partial "// o Item with lowercase o"
}

@test "lists: long bullet item wraps with continuation indent" {
    local testfile="$BATS_TEST_TMPDIR/bullet_wrap.go"
    cat > "$testfile" << 'EOF'
package main

// - This is a very long bullet item that exceeds the default line length of seventy-eight characters and should wrap
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_output --partial "// - This is a very long bullet item that exceeds the default line length of"
    assert_output --partial "//   seventy-eight characters and should wrap"
}

# ---------------------------------------------------------------------------
# Numbered lists
# ---------------------------------------------------------------------------

@test "lists: numbered list items (N.) are preserved" {
    local testfile="$BATS_TEST_TMPDIR/numbered_list.go"
    cat > "$testfile" << 'EOF'
package main

// 1. First item
// 2. Second item
// 10. Tenth item
// 99. Ninety-ninth item
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial "// 1. First item"
    assert_output --partial "// 2. Second item"
    assert_output --partial "// 10. Tenth item"
    assert_output --partial "// 99. Ninety-ninth item"
}

@test "lists: numbered list items with parenthesis (N)) are preserved" {
    local testfile="$BATS_TEST_TMPDIR/numbered_paren.go"
    cat > "$testfile" << 'EOF'
package main

// 1) First item
// 2) Second item
// 10) Tenth item
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial "// 1) First item"
    assert_output --partial "// 2) Second item"
    assert_output --partial "// 10) Tenth item"
}

@test "lists: numbered items wrap with aligned continuation indent" {
    local testfile="$BATS_TEST_TMPDIR/numbered_wrap.go"
    cat > "$testfile" << 'EOF'
package main

// 1. This is a very long numbered item that exceeds the default line length of seventy-eight characters
// 10. This is another very long numbered item that exceeds the default line length of seventy-eight chars
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_output --partial "// 1. This is a very long numbered item that exceeds the default line length"
    assert_output --partial "//    of seventy-eight characters"
    assert_output --partial "// 10. This is another very long numbered item that exceeds the default line"
    assert_output --partial "//     length of seventy-eight chars"
}

# ---------------------------------------------------------------------------
# Indented lists
# ---------------------------------------------------------------------------

@test "lists: indented bullet items wrap with correct continuation indent" {
    local testfile="$BATS_TEST_TMPDIR/indented_bullets.go"
    cat > "$testfile" << 'EOF'
package main

//   - Two space indented bullet with text that should wrap when exceeding line length limit here
//     - Four space indented bullet with text that should wrap when exceeding line length limit
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_output --partial "//   - Two space indented bullet with text that should wrap when exceeding"
    assert_output --partial "//     line length limit here"
    assert_output --partial "//     - Four space indented bullet with text that should wrap when"
    assert_output --partial "//       line length limit"
}

@test "lists: indented numbered items wrap with correct continuation indent" {
    local testfile="$BATS_TEST_TMPDIR/indented_numbered.go"
    cat > "$testfile" << 'EOF'
package main

//   1. Indented numbered item with some text that should wrap when exceeding line length limit here
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_output --partial "//   1. Indented numbered item with some text that should wrap when"
    assert_output --partial "//      line length limit here"
}

@test "lists: tab-indented bullet items are handled without error" {
    local testfile="$BATS_TEST_TMPDIR/tab_indented.go"
    cat > "$testfile" << 'EOF'
package main

//	- Tab indented bullet with text that should wrap when exceeding line length limit here
func example() {}
EOF
    run "$BINARY" -tlen 4 "$testfile"
    assert_output --partial "// - Tab indented bullet with text that should wrap when exceeding"
    assert_output --partial "//   limit here"
}

# ---------------------------------------------------------------------------
# Lists in different comment styles
# ---------------------------------------------------------------------------

@test "lists: lists in line comments (//) are formatted" {
    local testfile="$BATS_TEST_TMPDIR/lists_line.go"
    cat > "$testfile" << 'EOF'
package main

// - First item in line comment
// - Second item in line comment
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial "// - First item in line comment"
    assert_output --partial "// - Second item in line comment"
}

@test "lists: lists in block comments (/* */) are formatted" {
    local testfile="$BATS_TEST_TMPDIR/lists_block.go"
    cat > "$testfile" << 'EOF'
package main

/*
 * - First item in block comment
 * - Second item in block comment
 */
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial " * - First item in block comment"
    assert_output --partial " * - Second item in block comment"
}

@test "lists: lists in doc comments (///) are formatted" {
    local testfile="$BATS_TEST_TMPDIR/lists_doc.go"
    cat > "$testfile" << 'EOF'
package main

/// - First item in doc comment
/// - Second item in doc comment
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial "/// - First item in doc comment"
    assert_output --partial "/// - Second item in doc comment"
}

@test "lists: lists in indented (function-body) comments are formatted" {
    local testfile="$BATS_TEST_TMPDIR/lists_indented.go"
    cat > "$testfile" << 'EOF'
package main

func example() {
	// - First item in function comment
	// - Second item in function comment
	doSomething()
}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial "	// - First item in function comment"
    assert_output --partial "	// - Second item in function comment"
}

# ---------------------------------------------------------------------------
# List structure and context
# ---------------------------------------------------------------------------

@test "lists: blank line terminates list context" {
    local testfile="$BATS_TEST_TMPDIR/list_termination.go"
    cat > "$testfile" << 'EOF'
package main

// - First item
// - Second item
//
// New paragraph terminates list context.
// - New list after blank line
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial "// - First item"
    assert_output --partial "// - Second item"
    assert_output --partial "// New paragraph terminates list context."
    assert_output --partial "// - New list after blank line"
}

@test "lists: text before list items is kept separate" {
    local testfile="$BATS_TEST_TMPDIR/text_before_list.go"
    cat > "$testfile" << 'EOF'
package main

// Here are the items:
// - First item
// - Second item
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial "// Here are the items:"
    assert_output --partial "// - First item"
    assert_output --partial "// - Second item"
}

@test "lists: text before and after list is preserved" {
    local testfile="$BATS_TEST_TMPDIR/list_paragraphs.go"
    cat > "$testfile" << 'EOF'
package main

// This is regular text before the list.
//
// - First list item
// - Second list item
//
// This is regular text after the list.
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial "// This is regular text before the list."
    assert_output --partial "// - First list item"
    assert_output --partial "// - Second list item"
    assert_output --partial "// This is regular text after the list."
}

@test "lists: multiple list blocks are formatted independently" {
    local testfile="$BATS_TEST_TMPDIR/multiple_lists.go"
    cat > "$testfile" << 'EOF'
package main

// First list:
// - Item one
// - Item two
//
// Second list:
// 1. Numbered one
// 2. Numbered two
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial "// - Item one"
    assert_output --partial "// - Item two"
    assert_output --partial "// 1. Numbered one"
    assert_output --partial "// 2. Numbered two"
}

@test "lists: mixed bullet and numbered markers in separate lists" {
    local testfile="$BATS_TEST_TMPDIR/mixed_markers.go"
    cat > "$testfile" << 'EOF'
package main

// First list:
// - Bullet item
// - Another bullet
//
// Second list:
// 1. Numbered item
// 2. Another number
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial "// - Bullet item"
    assert_output --partial "// - Another bullet"
    assert_output --partial "// 1. Numbered item"
    assert_output --partial "// 2. Another number"
}

@test "lists: nested list indentation is preserved" {
    local testfile="$BATS_TEST_TMPDIR/nested_lists.go"
    cat > "$testfile" << 'EOF'
package main

// - First level item
//   - Second level nested item
//     - Third level deeply nested item
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial "// - First level item"
    assert_output --partial "//   - Second level nested item"
    assert_output --partial "//     - Third level deeply nested item"
}

@test "lists: single item list is formatted correctly" {
    local testfile="$BATS_TEST_TMPDIR/single_item.go"
    cat > "$testfile" << 'EOF'
package main

// - Only one item in this list
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial "// - Only one item in this list"
}

@test "lists: empty list item (bare marker) does not error" {
    local testfile="$BATS_TEST_TMPDIR/empty_item.go"
    cat > "$testfile" << 'EOF'
package main

// -
// - Item with text
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
}

# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

@test "lists: very long single word is not broken" {
    local testfile="$BATS_TEST_TMPDIR/long_word.go"
    cat > "$testfile" << 'EOF'
package main

// - ThisIsAnExtremelyLongSingleWordThatExceedsTheLineLength
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial "// - ThisIsAnExtremelyLongSingleWordThatExceedsTheLineLength"
}

@test "lists: item at exact line length is not wrapped" {
    local testfile="$BATS_TEST_TMPDIR/exact_length.go"
    cat > "$testfile" << 'EOF'
package main

// - This item is seventy-eight characters long including the comment marker
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial "// - This item is seventy-eight characters long including the comment marker"
    refute_output --partial "//   "
}

@test "lists: item one character over limit is handled" {
    local testfile="$BATS_TEST_TMPDIR/one_over.go"
    cat > "$testfile" << 'EOF'
package main

// - This item is seventy-nine characters long including the comment marker x
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial "// - This item is seventy-nine characters long including the comment marker x"
}

@test "lists: URL in list item is not split across lines" {
    local testfile="$BATS_TEST_TMPDIR/url_in_list.go"
    cat > "$testfile" << 'EOF'
package main

// - See https://github.com/anthropics/gocomments for more information about this tool
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_output --partial "https://github.com/anthropics/gocomments"
}

@test "lists: -llen 50 wraps list items at shorter width" {
    local testfile="$BATS_TEST_TMPDIR/llen_variations.go"
    cat > "$testfile" << 'EOF'
package main

// - This is a moderately long list item that may or may not wrap depending on line length
func example() {}
EOF
    run "$BINARY" -llen 50 "$testfile"
    assert_output --partial "//   or may not wrap depending on line length"
}

@test "lists: -llen 100 keeps list items on one line" {
    local testfile="$BATS_TEST_TMPDIR/llen_variations.go"
    cat > "$testfile" << 'EOF'
package main

// - This is a moderately long list item that may or may not wrap depending on line length
func example() {}
EOF
    run "$BINARY" -llen 100 "$testfile"
    assert_success
    assert_output --partial "// - This is a moderately long list item that may or may not wrap depending on line length"
}

@test "lists: formatting is idempotent (second run produces same output)" {
    local testfile="$BATS_TEST_TMPDIR/idempotent.go"
    cat > "$testfile" << 'EOF'
package main

// - This is a very long list item that exceeds the default line length and should wrap consistently
func example() {}
EOF
    local output1 output2
    output1=$("$BINARY" "$testfile" 2>&1 || true)
    output2=$(echo "$output1" | "$BINARY")
    [ "$output1" = "$output2" ]
}

# ---------------------------------------------------------------------------
# Directives and special comments
# ---------------------------------------------------------------------------

@test "lists: gocomments:noformat directive prevents list reformatting" {
    local testfile="$BATS_TEST_TMPDIR/noformat_list.go"
    cat > "$testfile" << 'EOF'
package main

// gocomments:noformat
// - This list should not be reformatted even though this line is very long and exceeds seventy-eight characters
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial "// - This list should not be reformatted even though this line is very long and exceeds seventy-eight characters"
}

@test "lists: commented-out code is not treated as list" {
    local testfile="$BATS_TEST_TMPDIR/commented_code.go"
    cat > "$testfile" << 'EOF'
package main

// func old() {
//     x := 1
//     y := 2
//     return x + y
// }
func example() {}
EOF
    run "$BINARY" "$testfile"
    assert_success
    assert_output --partial "// func old() {"
    assert_output --partial "//     x := 1"
    assert_output --partial "//     y := 2"
}

@test "lists: inline block comment with trailing code is not reformatted" {
    run "$BINARY" << 'EOF'
package main

/* exported */ func Example() {}
EOF
    assert_success
    assert_output --partial "/* exported */ func Example() {}"
}
