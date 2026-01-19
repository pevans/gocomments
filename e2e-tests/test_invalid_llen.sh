# Test: invalid value for -llen (negative or zero uses default)

# Test negative value
output=$("$BINARY" -llen -10 << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
)

# Negative llen should use default (78); comment should be wrapped
if echo "$output" | grep -q "// This is a very long comment" && \
   echo "$output" | grep -q "// characters and should be wrapped"; then
    # Test zero value
    output2=$("$BINARY" -llen 0 << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
)
    if echo "$output2" | grep -q "// This is a very long comment" && \
       echo "$output2" | grep -q "// characters and should be wrapped"; then
        pass "invalid -llen value (uses default)"
    else
        fail "invalid -llen value" "zero llen did not use default"
    fi
else
    fail "invalid -llen value" "negative llen did not use default"
fi
