# Test: indented numbered list
# RFC 5 Section 2

testfile="$TMPDIR/indented_numbered.go"

cat > "$testfile" << 'EOF'
package main

//   1. Indented numbered item with some text that should wrap when exceeding line length limit here
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "//   1\. Indented numbered item with some text that should wrap when" && \
   echo "$output" | grep -q "//      line length limit here"; then
    pass "indented numbered list"
else
    fail "indented numbered list" "indented numbered continuation not aligned correctly"
fi
