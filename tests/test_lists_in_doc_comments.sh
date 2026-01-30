# Test: lists in doc comments
# RFC 5 Section 2

testfile="$TMPDIR/lists_in_doc.go"

cat > "$testfile" << 'EOF'
package main

/// - First item in doc comment
/// - Second item in doc comment
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "/// - First item in doc comment" && \
   echo "$output" | grep -q "/// - Second item in doc comment"; then
    pass "lists in doc comments"
else
    fail "lists in doc comments" "doc comment lists not formatted correctly"
fi
