# Test: list formatting is idempotent
# RFC 5 Section 3

testfile="$TMPDIR/idempotent.go"

cat > "$testfile" << 'EOF'
package main

// - This is a very long list item that exceeds the default line length and should wrap consistently
func example() {}
EOF

output1=$("$BINARY" "$testfile" 2>&1 || true)
output2=$(echo "$output1" | "$BINARY")

if [[ "$output1" == "$output2" ]]; then
    pass "list idempotent"
else
    fail "list idempotent" "second run produced different output"
fi
