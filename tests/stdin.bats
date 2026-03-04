#!/usr/bin/env bats
# Tests for stdin input processing

load test_helper

setup_file() {
    setup_test_env
    build_gocomments
}

@test "stdin: basic comment wrapping" {
    run "$BINARY" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    assert_success
    assert_output --partial "// This is a very long comment that exceeds the default line length of 78"
    assert_output --partial "// characters and should be wrapped"
}

@test "stdin: exact output matches expected" {
    local expected
    expected=$(cat << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78
// characters and should be wrapped
func example() {}
EOF
)
    run "$BINARY" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    assert_success
    [ "$output" = "$expected" ]
}

@test "stdin: -llen flag controls wrapping width" {
    run "$BINARY" -llen 40 << 'EOF'
package main

// This is a comment that will be wrapped at a shorter length
func example() {}
EOF
    assert_success
    assert_output --partial "// This is a comment that will be"
    assert_output --partial "// wrapped at a shorter length"
}

@test "stdin: -l flag outputs formatted code (flag ignored for stdin)" {
    run "$BINARY" -l << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    assert_success
    assert_output --partial "// This is a very long comment that exceeds the default line length of 78"
    assert_output --partial "// characters and should be wrapped"
}

@test "stdin: -d flag outputs formatted code (flag ignored for stdin)" {
    run "$BINARY" -d << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    assert_success
    assert_output --partial "// This is a very long comment that exceeds the default line length of 78"
    assert_output --partial "// characters and should be wrapped"
}

@test "stdin: -w flag outputs formatted code to stdout" {
    run "$BINARY" -w << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
    assert_success
    assert_output --partial "// This is a very long comment that exceeds the default line length of 78"
    assert_output --partial "// characters and should be wrapped"
}

@test "stdin: invalid Go code produces error" {
    run "$BINARY" << 'EOF'
this is not valid Go code
EOF
    assert_failure
}
