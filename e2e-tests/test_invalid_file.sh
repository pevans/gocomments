# Test: invalid Go files
# RFC 1 Section 2.6

failed=0

# Test 1: Empty file (invalid Go)
empty_file="$TMPDIR/empty.go"
: > "$empty_file"
"$BINARY" "$empty_file" > /dev/null 2>&1 || exit_code=$?
if [[ ${exit_code:-0} -eq 0 ]]; then
    echo "FAIL: empty file should produce error"
    failed=1
fi

# Test 2: Non-Go file provided as file path
non_go_file="$TMPDIR/notgo.txt"
echo "This is not a Go file" > "$non_go_file"
"$BINARY" "$non_go_file" > /dev/null 2>&1 || exit_code=$?
if [[ ${exit_code:-0} -eq 0 ]]; then
    echo "FAIL: non-Go file should produce error"
    failed=1
fi

# Test 3: Invalid Go code piped to stdin
invalid_stdin=$("$BINARY" <<< "this is not valid Go code" 2>&1 || true)
exit_code=$?
if [[ $exit_code -eq 0 ]]; then
    echo "FAIL: invalid Go code to stdin should produce error"
    failed=1
fi

# Test 4: Directory containing .go file with invalid Go code
testdir="$TMPDIR/invalid_go_dir"
mkdir -p "$testdir"
cat > "$testdir/invalid.go" << 'EOF'
package main

func broken syntax here {
EOF

"$BINARY" "$testdir" > /dev/null 2>&1 || exit_code=$?
if [[ ${exit_code:-0} -eq 0 ]]; then
    echo "FAIL: directory with invalid .go file should produce error"
    failed=1
fi

if [[ $failed -eq 0 ]]; then
    pass "invalid Go files produce errors"
else
    fail "invalid Go files" "one or more invalid file checks failed"
fi
