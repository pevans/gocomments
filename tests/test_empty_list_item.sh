# Test: empty list item
# RFC 5 Section 2

testfile="$TMPDIR/empty_item.go"

cat > "$testfile" << 'EOF'
package main

// -
// - Item with text
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)
exit_code=0
"$BINARY" "$testfile" > /dev/null 2>&1 || exit_code=$?

if [[ $exit_code -eq 0 ]]; then
    pass "empty list item"
else
    fail "empty list item" "empty list item caused error"
fi
