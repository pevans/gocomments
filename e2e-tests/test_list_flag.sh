# Test: -l flag lists files needing changes

needs_format="$TMPDIR/needs_format.go"
already_formatted="$TMPDIR/already_formatted.go"

cat > "$needs_format" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF

cat > "$already_formatted" << 'EOF'
package main

// Short comment
func example() {}
EOF

output=$("$BINARY" -l "$needs_format" "$already_formatted" 2>&1 || true)

if echo "$output" | grep -q "needs_format.go"; then
    if ! echo "$output" | grep -q "already_formatted.go"; then
        pass "-l flag"
    else
        fail "-l flag" "should not list already formatted file"
    fi
else
    fail "-l flag" "should list file needing changes"
fi
