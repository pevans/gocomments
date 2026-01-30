# Test: bullet list wrapping
# RFC 5 Section 3

testfile="$TMPDIR/bullet_wrapping.go"

cat > "$testfile" << 'EOF'
package main

// - This is a very long bullet item that exceeds the default line length of seventy-eight characters and should wrap
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "// - This is a very long bullet item that exceeds the default line length of" && \
   echo "$output" | grep -q "//   seventy-eight characters and should wrap"; then
    pass "bullet wrapping"
else
    fail "bullet wrapping" "continuation indent not aligned correctly"
fi
