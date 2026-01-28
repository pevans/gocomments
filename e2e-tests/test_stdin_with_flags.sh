# Test: stdin with flags
# RFC 1 Sections 2.1, 5.1

output=$("$BINARY" -llen 40 << 'EOF'
package main

// This is a comment that will be wrapped at a shorter length
func example() {}
EOF
)
expected=$(cat << 'EOF'
package main

// This is a comment that will be
// wrapped at a shorter length
func example() {}
EOF
)
if [[ "$output" == "$expected" ]]; then
    pass "stdin with flags"
else
    fail "stdin with flags" "output did not match expected"
fi
