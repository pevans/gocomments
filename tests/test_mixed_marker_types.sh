# Test: mixed marker types in separate lists
# RFC 5 Section 2

testfile="$TMPDIR/mixed_markers.go"

cat > "$testfile" << 'EOF'
package main

// First list:
// - Bullet item
// - Another bullet
//
// Second list:
// 1. Numbered item
// 2. Another number
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "// - Bullet item" && \
   echo "$output" | grep -q "// - Another bullet" && \
   echo "$output" | grep -q "// 1\. Numbered item" && \
   echo "$output" | grep -q "// 2\. Another number"; then
    pass "mixed marker types"
else
    fail "mixed marker types" "different list types not handled correctly"
fi
