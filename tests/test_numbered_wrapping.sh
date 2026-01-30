# Test: numbered list wrapping
# RFC 5 Section 3

testfile="$TMPDIR/numbered_wrapping.go"

cat > "$testfile" << 'EOF'
package main

// 1. This is a very long numbered item that exceeds the default line length of seventy-eight characters
// 10. This is another very long numbered item that exceeds the default line length of seventy-eight chars
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "// 1\. This is a very long numbered item that exceeds the default line length" && \
   echo "$output" | grep -q "//    of seventy-eight characters" && \
   echo "$output" | grep -q "// 10\. This is another very long numbered item that exceeds the default line" && \
   echo "$output" | grep -q "//     length of seventy-eight chars"; then
    pass "numbered wrapping"
else
    fail "numbered wrapping" "continuation indent not aligned correctly for numbered items"
fi
