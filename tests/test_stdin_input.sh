# Test: stdin input
# RFC 1 Section 2.1

output=$("$BINARY" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
)
expected=$(cat << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78
// characters and should be wrapped
func example() {}
EOF
)
if [[ "$output" == "$expected" ]]; then
    pass "stdin input"
else
    fail "stdin input" "output did not match expected"
fi
