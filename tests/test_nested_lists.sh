# Test: nested lists
# RFC 5 Section 4

testfile="$TMPDIR/nested_lists.go"

cat > "$testfile" << 'EOF'
package main

// - First level item
//   - Second level nested item
//     - Third level deeply nested item
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "// - First level item" && \
   echo "$output" | grep -q "//   - Second level nested item" && \
   echo "$output" | grep -q "//     - Third level deeply nested item"; then
    pass "nested lists"
else
    fail "nested lists" "nested list indentation not preserved correctly"
fi
