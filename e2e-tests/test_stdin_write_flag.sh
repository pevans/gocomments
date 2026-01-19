# Test: -w flag with stdin (should still output to stdout, not write)

output=$("$BINARY" -w << 'EOF' 2>&1 || true
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
)

# With stdin, -w should still output formatted code to stdout (can't write to stdin)
if echo "$output" | grep -q "// This is a very long comment that exceeds the default line length of 78"; then
    if echo "$output" | grep -q "// characters and should be wrapped"; then
        pass "-w flag with stdin"
    else
        fail "-w flag with stdin" "output not properly wrapped"
    fi
else
    fail "-w flag with stdin" "expected formatted output to stdout"
fi
