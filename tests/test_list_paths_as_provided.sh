# Test: -l output uses paths as provided (relative vs absolute)
# RFC 3

testfile="$TMPDIR/pathtest.go"

cat > "$testfile" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF

# Test with absolute path
output_abs=$("$BINARY" -l "$testfile" 2>&1 || true)

# Test with relative path (from TMPDIR)
cd "$TMPDIR"
output_rel=$("$BINARY" -l "pathtest.go" 2>&1 || true)
cd - > /dev/null

# Absolute path output should contain full path
if echo "$output_abs" | grep -q "$TMPDIR"; then
    # Relative path output should not contain TMPDIR
    if echo "$output_rel" | grep -q "^pathtest.go$"; then
        pass "-l output uses paths as provided"
    else
        fail "-l output uses paths as provided" "relative path not preserved: $output_rel"
    fi
else
    fail "-l output uses paths as provided" "absolute path not preserved: $output_abs"
fi
