# Test: bullet list formatting
# RFC 5 Section 2

testfile="$TMPDIR/bullet_list.go"

cat > "$testfile" << 'EOF'
package main

// - Item with dash
// + Item with plus
// * Item with star
// o Item with lowercase o
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "// - Item with dash" && \
   echo "$output" | grep -q "// + Item with plus" && \
   echo "$output" | grep -q "// \* Item with star" && \
   echo "$output" | grep -q "// o Item with lowercase o"; then
    pass "bullet list formatting"
else
    fail "bullet list formatting" "bullet markers not preserved correctly"
fi
