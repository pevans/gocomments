# Test: non-existent directory handling
# RFC 1 Section 2.4

output=$("$BINARY" "/nonexistent/directory/..." 2>&1 || true)
exit_code=$?

# Should produce an error message
if echo "$output" | grep -qi "no such file\|not exist\|cannot\|error"; then
    pass "non-existent directory handling"
else
    fail "non-existent directory handling" "expected error message, got: $output"
fi
