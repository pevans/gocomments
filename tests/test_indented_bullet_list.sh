# Test: indented bullet list
# RFC 5 Section 2

testfile="$TMPDIR/indented_bullets.go"

cat > "$testfile" << 'EOF'
package main

//   - Two space indented bullet with text that should wrap when exceeding line length limit here
//     - Four space indented bullet with text that should wrap when exceeding line length limit
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "//   - Two space indented bullet with text that should wrap when exceeding" && \
   echo "$output" | grep -q "//     line length limit here" && \
   echo "$output" | grep -q "//     - Four space indented bullet with text that should wrap when" && \
   echo "$output" | grep -q "//       line length limit"; then
    pass "indented bullet list"
else
    fail "indented bullet list" "indented bullet continuation not aligned correctly"
fi
