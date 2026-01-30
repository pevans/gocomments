# Test: list paragraph separation
# RFC 5 Section 4.1

testfile="$TMPDIR/lists_and_paragraphs.go"

cat > "$testfile" << 'EOF'
package main

// This is regular text before the list.
//
// - First list item
// - Second list item
//
// This is regular text after the list.
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "// This is regular text before the list\." && \
   echo "$output" | grep -q "// - First list item" && \
   echo "$output" | grep -q "// - Second list item" && \
   echo "$output" | grep -q "// This is regular text after the list\."; then
    pass "list paragraph separation"
else
    fail "list paragraph separation" "list items not separated as paragraphs"
fi
