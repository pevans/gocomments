# Test: combined -w -d flags (diff shown, then file written)
# RFC 2 Section 1.2, RFC 4 Section 1.3

testfile="$TMPDIR/combined_wd_test.go"

cat > "$testfile" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF

output=$("$BINARY" -w -d "$testfile" 2>&1 || true)

# Should show diff output
if echo "$output" | grep -q "^---" && \
   echo "$output" | grep -q "^+++" && \
   echo "$output" | grep -q "^@@"; then
    # File should also be written
    content=$(cat "$testfile")
    if echo "$content" | grep -q "// characters and should be wrapped"; then
        pass "combined -w -d flags (diff shown and file written)"
    else
        fail "combined -w -d flags" "file was not written"
    fi
else
    fail "combined -w -d flags" "diff output missing"
fi
