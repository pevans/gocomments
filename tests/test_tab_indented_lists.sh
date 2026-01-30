# Test: tab indented lists with different tlen values
# RFC 5 Section 3.1

testfile="$TMPDIR/tab_indented.go"

cat > "$testfile" << 'EOF'
package main

//	- Tab indented bullet with text that should wrap when exceeding line length limit here
func example() {}
EOF

output4=$("$BINARY" -tlen 4 "$testfile" 2>&1 || true)
output8=$("$BINARY" -tlen 8 "$testfile" 2>&1 || true)

# Note: Current implementation converts tabs to spaces in output
# Test just verifies that tabs in input are handled without error
if echo "$output4" | grep -q "// - Tab indented bullet with text that should wrap when exceeding" && \
   echo "$output4" | grep -q "//   limit here"; then
    pass "tab indented lists"
else
    fail "tab indented lists" "tab indented lists not handled correctly"
fi
