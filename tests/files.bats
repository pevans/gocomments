#!/usr/bin/env bats
# Tests for file and directory argument handling

load test_helper

setup_file() {
    setup_test_env
    build_gocomments
}

# ---------------------------------------------------------------------------
# Error handling
# ---------------------------------------------------------------------------

@test "files: non-existent file produces error message" {
    run "$BINARY" "/nonexistent/path/to/file.go"
    assert_failure
    [[ "$output" =~ [Nn]o\ such\ file|not\ exist|[Cc]annot|[Ee]rror ]]
}

@test "files: non-existent directory produces error message" {
    run "$BINARY" "/nonexistent/directory/..."
    assert_failure
    [[ "$output" =~ [Nn]o\ such\ file|not\ exist|[Cc]annot|[Ee]rror ]]
}

@test "files: empty .go file produces error" {
    local empty_file="$BATS_TEST_TMPDIR/empty.go"
    : > "$empty_file"
    run "$BINARY" "$empty_file"
    assert_failure
}

@test "files: non-.go file argument produces error" {
    local non_go="$BATS_TEST_TMPDIR/notgo.txt"
    echo "This is not a Go file" > "$non_go"
    run "$BINARY" "$non_go"
    assert_failure
}

@test "files: directory with invalid Go code produces error" {
    local testdir="$BATS_TEST_TMPDIR/invalid_go_dir"
    mkdir -p "$testdir"
    cat > "$testdir/invalid.go" << 'EOF'
package main

func broken syntax here {
EOF
    run "$BINARY" "$testdir"
    assert_failure
}

@test "files: syntax error file produces error" {
    local testfile="$BATS_TEST_TMPDIR/syntax_error.go"
    cat > "$testfile" << 'EOF'
package main

// This comment is fine
func example( {
    // missing closing paren
}
EOF
    run "$BINARY" "$testfile"
    assert_failure
}

@test "files: read-only file with -w produces error" {
    local testfile="$BATS_TEST_TMPDIR/readonly.go"
    cat > "$testfile" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    chmod 444 "$testfile"
    run "$BINARY" -w "$testfile"
    chmod 644 "$testfile"
    assert_failure
    [[ "$output" =~ [Pp]ermission|[Dd]enied|read-only ]]
}

# ---------------------------------------------------------------------------
# Multiple files and directories
# ---------------------------------------------------------------------------

@test "files: multiple file arguments" {
    local file1="$BATS_TEST_TMPDIR/multi1.go"
    local file2="$BATS_TEST_TMPDIR/multi2.go"
    local file3="$BATS_TEST_TMPDIR/multi3.go"

    cat > "$file1" << 'EOF'
package main

// First file has a very long comment that exceeds the default line length and should be wrapped
func first() {}
EOF
    cat > "$file2" << 'EOF'
package main

// Second file also has a very long comment that exceeds the default line length and should be wrapped
func second() {}
EOF
    cat > "$file3" << 'EOF'
package main

// Short comment
func third() {}
EOF

    run "$BINARY" -l "$file1" "$file2" "$file3"
    assert_output --partial "multi1.go"
    assert_output --partial "multi2.go"
    refute_output --partial "multi3.go"
}

@test "files: directory argument processes only .go files" {
    local testdir="$BATS_TEST_TMPDIR/dirtest"
    mkdir -p "$testdir"

    cat > "$testdir/a.go" << 'EOF'
package main

// File A has a very long comment that exceeds the default line length and should be wrapped
func a() {}
EOF
    cat > "$testdir/b.go" << 'EOF'
package main

// File B has a very long comment that exceeds the default line length and should be wrapped
func b() {}
EOF
    echo "not a go file" > "$testdir/readme.txt"

    run "$BINARY" -l "$testdir"
    assert_output --partial "a.go"
    assert_output --partial "b.go"
    refute_output --partial "readme.txt"
}

@test "files: directory with /... ellipsis recurses into subdirectories" {
    local testdir="$BATS_TEST_TMPDIR/ellipsistest"
    mkdir -p "$testdir/subdir/nested"

    cat > "$testdir/root.go" << 'EOF'
package main

// Root file has a very long comment that exceeds the default line length and should be wrapped
func root() {}
EOF
    cat > "$testdir/subdir/sub.go" << 'EOF'
package sub

// Subdir file has a very long comment that exceeds the default line length and should be wrapped
func sub() {}
EOF
    cat > "$testdir/subdir/nested/deep.go" << 'EOF'
package nested

// Nested file has a very long comment that exceeds the default line length and should be wrapped
func deep() {}
EOF

    run "$BINARY" -l "$testdir/..."
    assert_output --partial "root.go"
    assert_output --partial "sub.go"
    assert_output --partial "deep.go"
}

@test "files: mixed file and directory arguments" {
    local testdir="$BATS_TEST_TMPDIR/mixedtest"
    mkdir -p "$testdir/subdir"
    local standalone="$BATS_TEST_TMPDIR/standalone.go"

    cat > "$testdir/subdir/sub.go" << 'EOF'
package sub

// Subdir file has a very long comment that exceeds the default line length and should be wrapped
func sub() {}
EOF
    cat > "$standalone" << 'EOF'
package standalone

// Standalone file has a very long comment that exceeds the default line length and should be wrapped
func standalone() {}
EOF

    run "$BINARY" -l "$standalone" "$testdir/subdir"
    assert_output --partial "standalone.go"
    assert_output --partial "sub.go"
}

# ---------------------------------------------------------------------------
# Symlinks
# ---------------------------------------------------------------------------

@test "files: symlink to file is processed" {
    local testdir="$BATS_TEST_TMPDIR/symlinktest"
    mkdir -p "$testdir"

    cat > "$testdir/real.go" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    ln -sf "$testdir/real.go" "$testdir/link.go"

    run "$BINARY" -l "$testdir/link.go"
    assert_output --partial "link.go"
}

@test "files: symlink to directory is processed" {
    local testdir="$BATS_TEST_TMPDIR/symlinkdirtest"
    mkdir -p "$testdir/realdir"

    cat > "$testdir/realdir/file.go" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    ln -sf "$testdir/realdir" "$testdir/linkdir"

    run "$BINARY" -l "$testdir/linkdir"
    assert_output --partial "file.go"
}

# ---------------------------------------------------------------------------
# Path and output behavior
# ---------------------------------------------------------------------------

@test "files: -l output preserves absolute paths as provided" {
    local testfile="$BATS_TEST_TMPDIR/pathtest.go"
    cat > "$testfile" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    run "$BINARY" -l "$testfile"
    assert_output --partial "$BATS_TEST_TMPDIR"
}

@test "files: -l output preserves relative paths as provided" {
    local testfile="$BATS_TEST_TMPDIR/pathtest.go"
    cat > "$testfile" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    local orig_dir="$PWD"
    cd "$BATS_TEST_TMPDIR"
    run "$BINARY" -l "pathtest.go"
    cd "$orig_dir"
    [ "$output" = "pathtest.go" ]
}

@test "files: output order is deterministic across runs" {
    local testdir="$BATS_TEST_TMPDIR/ordertest"
    mkdir -p "$testdir"

    for name in z_file a_file m_file; do
        cat > "$testdir/${name}.go" << EOF
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func ${name}() {}
EOF
    done

    local output1 output2
    output1=$("$BINARY" -l "$testdir" 2>&1 || true)
    output2=$("$BINARY" -l "$testdir" 2>&1 || true)
    [ "$output1" = "$output2" ]
}

# ---------------------------------------------------------------------------
# Special file content
# ---------------------------------------------------------------------------

@test "files: Windows line endings (CRLF) handled correctly" {
    local testfile="$BATS_TEST_TMPDIR/crlf.go"
    printf 'package main\r\n\r\n// Short comment\r\nfunc example() {}\r\n' > "$testfile"

    run "$BINARY" "$testfile"
    assert_output --partial "package main"
    assert_output --partial "// Short comment"
    assert_output --partial "func example"
}
