# Test: inline block comment with trailing code is not reformatted
# RFC 6 Section 3

output=$("$BINARY" << 'EOF'
package main

/* exported */ func Example() {}
EOF
)
expected=$(cat << 'EOF'
package main

/* exported */ func Example() {}
EOF
)
if [[ "$output" == "$expected" ]]; then
    pass "inline block comment preserved"
else
    fail "inline block comment preserved" "inline block comment with trailing code should not be reformatted"
fi
