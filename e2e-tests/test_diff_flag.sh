# Test: -d flag outputs diff

testfile="$TMPDIR/diff_test.go"

cat > "$testfile" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF

output=$("$BINARY" -d "$testfile" 2>&1 || true)

if echo "$output" | grep -q "^---" && \
   echo "$output" | grep -q "^+++" && \
   echo "$output" | grep -q "^@@"; then
    pass "-d flag"
else
    fail "-d flag" "diff output missing expected markers"
fi
