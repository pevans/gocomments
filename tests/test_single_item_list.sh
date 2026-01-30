# Test: single item list
# RFC 5 Section 4

testfile="$TMPDIR/single_item.go"

cat > "$testfile" << 'EOF'
package main

// - Only one item in this list
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "// - Only one item in this list"; then
    pass "single item list"
else
    fail "single item list" "single list item not formatted correctly"
fi
