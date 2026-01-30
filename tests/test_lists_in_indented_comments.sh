# Test: lists in indented comments
# RFC 5 Section 2

testfile="$TMPDIR/lists_in_function.go"

cat > "$testfile" << 'EOF'
package main

func example() {
	// - First item in function comment
	// - Second item in function comment
	doSomething()
}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "	// - First item in function comment" && \
   echo "$output" | grep -q "	// - Second item in function comment"; then
    pass "lists in indented comments"
else
    fail "lists in indented comments" "indented comment lists not formatted correctly"
fi
