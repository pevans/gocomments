# Test: list context termination
# RFC 5 Section 4.1

testfile="$TMPDIR/list_context_termination.go"

cat > "$testfile" << 'EOF'
package main

// - First item
// - Second item
//
// New paragraph terminates list context.
// - New list after blank line
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "// - First item" && \
   echo "$output" | grep -q "// - Second item" && \
   echo "$output" | grep -q "// New paragraph terminates list context\." && \
   echo "$output" | grep -q "// - New list after blank line"; then
    pass "list context termination"
else
    fail "list context termination" "list context not terminated correctly"
fi
