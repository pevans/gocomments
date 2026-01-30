# Test: numbered list with parenthesis formatting
# RFC 5 Section 2

testfile="$TMPDIR/numbered_paren.go"

cat > "$testfile" << 'EOF'
package main

// 1) First item
// 2) Second item
// 10) Tenth item
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "// 1) First item" && \
   echo "$output" | grep -q "// 2) Second item" && \
   echo "$output" | grep -q "// 10) Tenth item"; then
    pass "numbered paren formatting"
else
    fail "numbered paren formatting" "numbered paren markers not preserved correctly"
fi
