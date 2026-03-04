#!/usr/bin/env bats
# Tests for CLI flags: -w, -l, -d, -llen, -tlen, and their combinations

load test_helper

setup_file() {
    setup_test_env
    build_gocomments
}

# ---------------------------------------------------------------------------
# -w flag
# ---------------------------------------------------------------------------

@test "-w flag: writes formatted content to file" {
    local testfile="$BATS_TEST_TMPDIR/write_test.go"
    cat > "$testfile" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    run "$BINARY" -w "$testfile"
    [ "$status" -eq 1 ]  # exits 1 when changes are written
    run grep -c "// characters and should be wrapped" "$testfile"
    assert_success
}

@test "-w flag: exits 0 when no changes needed" {
    local testfile="$BATS_TEST_TMPDIR/write_clean.go"
    cat > "$testfile" << 'EOF'
package main

// Short comment
func example() {}
EOF
    run "$BINARY" -w "$testfile"
    assert_success
}

# ---------------------------------------------------------------------------
# -l flag
# ---------------------------------------------------------------------------

@test "-l flag: lists files needing changes" {
    local needs_format="$BATS_TEST_TMPDIR/needs_format.go"
    local already_formatted="$BATS_TEST_TMPDIR/already_formatted.go"

    cat > "$needs_format" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    cat > "$already_formatted" << 'EOF'
package main

// Short comment
func example() {}
EOF

    run "$BINARY" -l "$needs_format" "$already_formatted"
    assert_output --partial "needs_format.go"
    refute_output --partial "already_formatted.go"
}

@test "-l flag: exits 1 when changes needed" {
    local testfile="$BATS_TEST_TMPDIR/needs_format.go"
    cat > "$testfile" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    run "$BINARY" -l "$testfile"
    [ "$status" -eq 1 ]
}

@test "-l flag: exits 0 when no changes needed" {
    local testfile="$BATS_TEST_TMPDIR/already_formatted.go"
    cat > "$testfile" << 'EOF'
package main

// Short comment
func example() {}
EOF
    run "$BINARY" -l "$testfile"
    assert_success
}

@test "-l flag: exits 1 when any file needs changes" {
    local needs="$BATS_TEST_TMPDIR/needs.go"
    local clean="$BATS_TEST_TMPDIR/clean.go"
    cat > "$needs" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    cat > "$clean" << 'EOF'
package main

// Short comment
func example() {}
EOF
    run "$BINARY" -l "$needs" "$clean"
    [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# -d flag
# ---------------------------------------------------------------------------

@test "-d flag: outputs unified diff" {
    local testfile="$BATS_TEST_TMPDIR/diff_test.go"
    cat > "$testfile" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    run "$BINARY" -d "$testfile"
    assert_output --partial "---"
    assert_output --partial "+++"
    assert_output --partial "@@"
    assert_output --partial "+// characters and should be wrapped"
}

# ---------------------------------------------------------------------------
# Combined flags
# ---------------------------------------------------------------------------

@test "combined -l -d flags: lists file then shows diff" {
    local testfile="$BATS_TEST_TMPDIR/combined_ld_test.go"
    cat > "$testfile" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    run "$BINARY" -l -d "$testfile"
    local first_line
    first_line=$(echo "$output" | head -1)
    [[ "$first_line" == *"combined_ld_test.go"* ]]
    assert_output --partial "---"
    assert_output --partial "+++"
    assert_output --partial "@@"
}

@test "combined -w -d flags: shows diff and writes file" {
    local testfile="$BATS_TEST_TMPDIR/combined_wd_test.go"
    cat > "$testfile" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    run "$BINARY" -w -d "$testfile"
    assert_output --partial "---"
    assert_output --partial "+++"
    assert_output --partial "@@"
    run grep -c "// characters and should be wrapped" "$testfile"
    assert_success
}

@test "combined -l -d -w flags: lists, diffs, and writes" {
    local testfile="$BATS_TEST_TMPDIR/combined_ldw_test.go"
    cat > "$testfile" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    run "$BINARY" -l -d -w "$testfile"
    local first_line
    first_line=$(echo "$output" | head -1)
    [[ "$first_line" == *"combined_ldw_test.go"* ]]
    assert_output --partial "---"
    run grep -c "// characters and should be wrapped" "$testfile"
    assert_success
}

# ---------------------------------------------------------------------------
# -llen flag
# ---------------------------------------------------------------------------

@test "-llen flag: negative value uses default (78)" {
    run "$BINARY" -llen -10 << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    assert_output --partial "// This is a very long comment"
    assert_output --partial "// characters and should be wrapped"
}

@test "-llen flag: zero value uses default (78)" {
    run "$BINARY" -llen 0 << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    assert_output --partial "// This is a very long comment"
    assert_output --partial "// characters and should be wrapped"
}

# ---------------------------------------------------------------------------
# -tlen flag
# ---------------------------------------------------------------------------

@test "-tlen flag: negative value uses default without panic" {
    run "$BINARY" -tlen -5 << 'EOF'
package main

// Short comment
func example() {}
EOF
    assert_success
    assert_output --partial "package main"
}

@test "-tlen flag: zero value uses default without panic" {
    run "$BINARY" -tlen 0 << 'EOF'
package main

// Short comment
func example() {}
EOF
    assert_success
    assert_output --partial "package main"
}

@test "-tlen flag: larger tab width produces more comment lines" {
    local input
    input=$(cat << 'EOF'
package main

func example() {
	// This comment is indented with a tab and is exactly seventy characters!
	println("test")
}
EOF
)
    local count4 count8
    count4=$(echo "$input" | "$BINARY" -tlen 4 | grep -c "//" || true)
    count8=$(echo "$input" | "$BINARY" -tlen 8 | grep -c "//" || true)
    [ "$count8" -gt "$count4" ]
}
