# Test: list item with URL
# RFC 5 Section 3

testfile="$TMPDIR/url_in_list.go"

cat > "$testfile" << 'EOF'
package main

// - See https://github.com/anthropics/gocomments for more information about this tool
func example() {}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)

# URL should not be broken across lines
if echo "$output" | grep -q "https://github.com/anthropics/gocomments"; then
    pass "list with url"
else
    fail "list with url" "URL was broken across lines"
fi
