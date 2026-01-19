# Test: -l flag with stdin (outputs formatted code, not list)
# Note: -l flag is ignored with stdin, formatted output is produced instead

output=$("$BINARY" -l << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
)

# With stdin, -l flag is ignored; should output formatted code
if echo "$output" | grep -q "// This is a very long comment that exceeds the default line length of 78" && \
   echo "$output" | grep -q "// characters and should be wrapped"; then
    pass "-l flag with stdin (outputs formatted code)"
else
    fail "-l flag with stdin" "expected formatted output"
fi
