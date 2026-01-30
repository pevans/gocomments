# Test: text before list
# RFC 5 Section 4.1

testfile="$TMPDIR/text_before_list.go"

cat > "$testfile" << 'EOF'
package main

// Here are the items:
// - First item
// - Second item
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "// Here are the items:" && \
   echo "$output" | grep -q "// - First item" && \
   echo "$output" | grep -q "// - Second item"; then
    pass "text before list"
else
    fail "text before list" "text before list not kept separate"
fi
