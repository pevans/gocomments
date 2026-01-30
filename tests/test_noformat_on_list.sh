# Test: noformat directive on list
# RFC 5 Section 4

testfile="$TMPDIR/noformat_list.go"

cat > "$testfile" << 'EOF'
package main

// gocomments:noformat
// - This list should not be reformatted even though this line is very long and exceeds seventy-eight characters
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

if echo "$output" | grep -q "// - This list should not be reformatted even though this line is very long and exceeds seventy-eight characters"; then
    pass "noformat on list"
else
    fail "noformat on list" "noformat directive not respected for lists"
fi
