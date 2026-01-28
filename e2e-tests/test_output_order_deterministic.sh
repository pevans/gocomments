# Test: output order with multiple files is deterministic
# RFC 1 Section 2.2

testdir="$TMPDIR/ordertest"
mkdir -p "$testdir"

# Create files with names that would sort differently
for name in z_file a_file m_file; do
    cat > "$testdir/${name}.go" << EOF
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func ${name}() {}
EOF
done

# Run twice and compare output
output1=$("$BINARY" -l "$testdir" 2>&1 || true)
output2=$("$BINARY" -l "$testdir" 2>&1 || true)

if [[ "$output1" == "$output2" ]]; then
    pass "output order is deterministic"
else
    fail "output order is deterministic" "output differs between runs"
fi
