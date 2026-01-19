# Test: combined -l -d -w flags (all three together)

testfile="$TMPDIR/combined_ldw_test.go"

cat > "$testfile" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF

output=$("$BINARY" -l -d -w "$testfile" 2>&1 || true)

# Should list the file first
if ! echo "$output" | head -1 | grep -q "combined_ldw_test.go"; then
    fail "combined -l -d -w flags" "file not listed first"
else
    # Should show diff after the filename
    if ! echo "$output" | grep -q "^---"; then
        fail "combined -l -d -w flags" "diff not shown"
    else
        # File should be written
        content=$(cat "$testfile")
        if echo "$content" | grep -q "// characters and should be wrapped"; then
            pass "combined -l -d -w flags"
        else
            fail "combined -l -d -w flags" "file was not written"
        fi
    fi
fi
