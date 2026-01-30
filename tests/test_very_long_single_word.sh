# Test: very long single word in list item
# RFC 5 Section 3

testfile="$TMPDIR/long_word.go"

cat > "$testfile" << 'EOF'
package main

// - ThisIsAnExtremelyLongSingleWordThatExceedsTheLineLength
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

# Long word should stay on one line, not broken
if echo "$output" | grep -q "// - ThisIsAnExtremelyLongSingleWordThatExceedsTheLineLength"; then
    pass "very long single word"
else
    fail "very long single word" "long word was broken incorrectly"
fi
