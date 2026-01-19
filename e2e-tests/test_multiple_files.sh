# Test: multiple files as arguments

file1="$TMPDIR/multi1.go"
file2="$TMPDIR/multi2.go"
file3="$TMPDIR/multi3.go"

cat > "$file1" << 'EOF'
package main

// First file has a very long comment that exceeds the default line length and should be wrapped
func first() {}
EOF

cat > "$file2" << 'EOF'
package main

// Second file also has a very long comment that exceeds the default line length and should be wrapped
func second() {}
EOF

cat > "$file3" << 'EOF'
package main

// Short comment
func third() {}
EOF

output=$("$BINARY" -l "$file1" "$file2" "$file3" 2>&1 || true)

# Should list file1 and file2 (need changes) but not file3
if echo "$output" | grep -q "multi1.go" && \
   echo "$output" | grep -q "multi2.go" && \
   ! echo "$output" | grep -q "multi3.go"; then
    pass "multiple files as arguments"
else
    fail "multiple files as arguments" "incorrect files listed: $output"
fi
