# Test: non-existent file handling

output=$("$BINARY" "/nonexistent/path/to/file.go" 2>&1 || true)
exit_code=$?

# Should produce an error message
if echo "$output" | grep -qi "no such file\|not exist\|cannot\|error"; then
    pass "non-existent file handling"
else
    fail "non-existent file handling" "expected error message, got: $output"
fi
