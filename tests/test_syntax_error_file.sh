# Test: Go files with syntax/parse errors
# RFC 1 Section 2.1

testfile="$TMPDIR/syntax_error.go"

cat > "$testfile" << 'EOF'
package main

// This comment is fine
func example( {
    // missing closing paren
}
EOF

output=$("$BINARY" "$testfile" 2>&1 || true)
exit_code=$?

# Should produce an error for syntax errors
if [[ $exit_code -ne 0 ]] || echo "$output" | grep -qi "error\|expected"; then
    pass "syntax error file handled"
else
    fail "syntax error file" "no error reported for invalid Go file"
fi
