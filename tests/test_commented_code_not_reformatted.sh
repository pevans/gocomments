# Test: commented code not reformatted as lists
# RFC 5 Section 4

testfile="$TMPDIR/commented_code.go"

cat > "$testfile" << 'EOF'
package main

// func old() {
//     x := 1
//     y := 2
//     return x + y
// }
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "// func old() {" && \
   echo "$output" | grep -q "//     x := 1" && \
   echo "$output" | grep -q "//     y := 2"; then
    pass "commented code not reformatted"
else
    fail "commented code not reformatted" "commented code structure not preserved"
fi
