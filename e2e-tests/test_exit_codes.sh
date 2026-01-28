# Test: various exit code behaviors
# RFC 1 Section 2.3

failed=0

# Test: exit code 1 when file doesn't exist
"$BINARY" "/nonexistent/file.go" > /dev/null 2>&1 || exit_code=$?
if [[ ${exit_code:-0} -eq 0 ]]; then
    echo "FAIL: should exit non-zero for non-existent file"
    failed=1
fi

# Test: exit code 1 when parse error occurs
parse_error_file="$TMPDIR/parse_error.go"
cat > "$parse_error_file" << 'EOF'
package main
func broken( {
EOF
"$BINARY" "$parse_error_file" > /dev/null 2>&1 || exit_code=$?
if [[ ${exit_code:-0} -eq 0 ]]; then
    echo "FAIL: should exit non-zero for parse error"
    failed=1
fi

# Test: exit code 1 when -l finds changes needed
needs_change="$TMPDIR/needs_change.go"
cat > "$needs_change" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF
"$BINARY" -l "$needs_change" > /dev/null 2>&1 || exit_code=$?
if [[ ${exit_code:-0} -ne 1 ]]; then
    echo "FAIL: -l should exit 1 when changes needed"
    failed=1
fi

# Test: exit code 0 when -l finds no changes needed
no_change="$TMPDIR/no_change.go"
cat > "$no_change" << 'EOF'
package main

// Short comment
func example() {}
EOF
"$BINARY" -l "$no_change" > /dev/null 2>&1
exit_code=$?
if [[ $exit_code -ne 0 ]]; then
    echo "FAIL: -l should exit 0 when no changes needed"
    failed=1
fi

# Test: exit code 1 when multiple files and at least one needs changes
"$BINARY" -l "$needs_change" "$no_change" > /dev/null 2>&1 || exit_code=$?
if [[ ${exit_code:-0} -ne 1 ]]; then
    echo "FAIL: should exit 1 when any file needs changes"
    failed=1
fi

if [[ $failed -eq 0 ]]; then
    pass "exit codes"
else
    fail "exit codes" "one or more exit code checks failed"
fi
