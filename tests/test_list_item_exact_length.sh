# Test: list item at exact line length
# RFC 5 Section 3

testfile="$TMPDIR/exact_length.go"

cat > "$testfile" << 'EOF'
package main

// - This item is seventy-eight characters long including the comment marker
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

# Should not wrap since it fits exactly
if echo "$output" | grep -q "// - This item is seventy-eight characters long including the comment marker" && \
   ! echo "$output" | grep -q "//   "; then
    pass "list item exact length"
else
    fail "list item exact length" "item at exact length wrapped incorrectly"
fi
