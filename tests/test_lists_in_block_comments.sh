# Test: lists in block comments
# RFC 5 Section 2

testfile="$TMPDIR/lists_in_block.go"

cat > "$testfile" << 'EOF'
package main

/*
 * - First item in block comment
 * - Second item in block comment
 */
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q " \* - First item in block comment" && \
   echo "$output" | grep -q " \* - Second item in block comment"; then
    pass "lists in block comments"
else
    fail "lists in block comments" "block comment lists not formatted correctly"
fi
