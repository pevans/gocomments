# Test: files with Windows line endings (CRLF)
# RFC 1 Section 2.5

testfile="$TMPDIR/crlf.go"

# Create file with CRLF line endings
printf 'package main\r\n\r\n// Short comment\r\nfunc example() {}\r\n' > "$testfile"

output=$("$BINARY" "$testfile" 2>&1 || true)

failed_crlf=0
# Verify output contains expected elements
if ! echo "$output" | grep -q "package main"; then
    echo "FAIL: CRLF -- package declaration missing"
    failed_crlf=1
fi
if ! echo "$output" | grep -q "// Short comment"; then
    echo "FAIL: CRLF -- comment not preserved"
    failed_crlf=1
fi
if ! echo "$output" | grep -q "func example"; then
    echo "FAIL: CRLF -- function declaration missing"
    failed_crlf=1
fi

if [[ $failed_crlf -eq 0 ]]; then
    pass "Windows line endings handled"
else
    fail "Windows line endings" "failed to process CRLF file correctly"
fi
