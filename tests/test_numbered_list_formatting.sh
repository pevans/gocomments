# Test: numbered list formatting
# RFC 5 Section 2

testfile="$TMPDIR/numbered_list.go"

cat > "$testfile" << 'EOF'
package main

// 1. First item
// 2. Second item
// 10. Tenth item
// 99. Ninety-ninth item
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "// 1\. First item" && \
   echo "$output" | grep -q "// 2\. Second item" && \
   echo "$output" | grep -q "// 10\. Tenth item" && \
   echo "$output" | grep -q "// 99\. Ninety-ninth item"; then
    pass "numbered list formatting"
else
    fail "numbered list formatting" "numbered markers not preserved correctly"
fi
