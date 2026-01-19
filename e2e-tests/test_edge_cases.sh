# Test: empty file (should error)

empty_file="$TMPDIR/empty.go"
: > "$empty_file"
"$BINARY" "$empty_file" > /dev/null 2>&1 || exit_code=$?
if [[ ${exit_code:-0} -eq 0 ]]; then
    fail "empty file" "should produce error"
else
    pass "empty file produces error"
fi
