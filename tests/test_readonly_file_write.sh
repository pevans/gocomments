# Test: read-only files with -w flag
# RFC 2

testfile="$TMPDIR/readonly.go"

cat > "$testfile" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF

chmod 444 "$testfile"

output=$("$BINARY" -w "$testfile" 2>&1 || true)
exit_code=$?

# Restore permissions for cleanup
chmod 644 "$testfile"

# Should produce an error when trying to write to read-only file
if [[ $exit_code -ne 0 ]] || echo "$output" | grep -qi "permission\|denied\|read-only"; then
    pass "read-only file with -w flag"
else
    fail "read-only file with -w flag" "no error for read-only file"
fi
