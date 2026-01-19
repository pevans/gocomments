# Test: combined -l -d flags (list first, then diff)

testfile="$TMPDIR/combined_ld_test.go"

cat > "$testfile" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF

output=$("$BINARY" -l -d "$testfile" 2>&1 || true)

# First line should be the filename (from -l)
first_line=$(echo "$output" | head -1)
if echo "$first_line" | grep -q "combined_ld_test.go"; then
    # Should also show diff output after the filename
    if echo "$output" | grep -q "^---" && \
       echo "$output" | grep -q "^+++" && \
       echo "$output" | grep -q "^@@"; then
        pass "combined -l -d flags (list then diff)"
    else
        fail "combined -l -d flags" "diff output missing after filename"
    fi
else
    fail "combined -l -d flags" "filename should be listed first, got: $first_line"
fi
