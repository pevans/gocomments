# Test: invalid value for -tlen (negative or zero uses default)

# Test negative value
output=$("$BINARY" -tlen -5 << 'EOF'
package main

// Short comment
func example() {}
EOF
)

# Negative tlen should use default (4) and not panic
if echo "$output" | grep -q "package main"; then
    # Test zero value
    output2=$("$BINARY" -tlen 0 << 'EOF'
package main

// Short comment
func example() {}
EOF
)
    if echo "$output2" | grep -q "package main"; then
        pass "invalid -tlen value (uses default)"
    else
        fail "invalid -tlen value" "zero tlen did not use default"
    fi
else
    fail "invalid -tlen value" "negative tlen did not use default"
fi
