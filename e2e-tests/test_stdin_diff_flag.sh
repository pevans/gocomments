# Test: -d flag with stdin (outputs formatted code, not diff)
# RFC 4
# Note: -d flag is ignored with stdin, formatted output is produced instead

output=$("$BINARY" -d << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
)

# With stdin, -d flag is ignored; it should output formatted code
if echo "$output" | grep -q "// This is a very long comment that exceeds the default line length of 78" && \
   echo "$output" | grep -q "// characters and should be wrapped"; then
    pass "-d flag with stdin (outputs formatted code)"
else
    fail "-d flag with stdin" "expected formatted output"
fi
