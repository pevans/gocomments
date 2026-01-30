# Test: multiple list blocks
# RFC 5 Section 4.1

testfile="$TMPDIR/multiple_lists.go"

cat > "$testfile" << 'EOF'
package main

// First list:
// - Item one
// - Item two
//
// Second list:
// 1. Numbered one
// 2. Numbered two
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "// - Item one" && \
   echo "$output" | grep -q "// - Item two" && \
   echo "$output" | grep -q "// 1\. Numbered one" && \
   echo "$output" | grep -q "// 2\. Numbered two"; then
    pass "multiple list blocks"
else
    fail "multiple list blocks" "multiple lists not formatted independently"
fi
