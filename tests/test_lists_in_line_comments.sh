# Test: lists in line comments
# RFC 5 Section 2

testfile="$TMPDIR/lists_in_line.go"

cat > "$testfile" << 'EOF'
package main

// - First item in line comment
// - Second item in line comment
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "// - First item in line comment" && \
   echo "$output" | grep -q "// - Second item in line comment"; then
    pass "lists in line comments"
else
    fail "lists in line comments" "line comment lists not formatted correctly"
fi
