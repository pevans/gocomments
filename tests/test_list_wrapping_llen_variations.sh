# Test: list wrapping with different llen values
# RFC 5 Section 3

testfile="$TMPDIR/llen_variations.go"

cat > "$testfile" << 'EOF'
package main

// - This is a moderately long list item that may or may not wrap depending on line length
func example() {}
EOF

output50=$("$BINARY" -llen 50 "$testfile" 2>&1 || true)
output100=$("$BINARY" -llen 100 "$testfile" 2>&1 || true)

if echo "$output50" | grep -q "//   or may not wrap depending on line length" && \
   echo "$output100" | grep -q "// - This is a moderately long list item that may or may not wrap depending on line length"; then
    pass "list wrapping llen variations"
else
    fail "list wrapping llen variations" "list not wrapping correctly at different line lengths"
fi
