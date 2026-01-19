# Test: -w flag writes and exits

testfile="$TMPDIR/write_test.go"

cat > "$testfile" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF

if "$BINARY" -w "$testfile" > /dev/null 2>&1; then
    fail "-w flag" "should exit 1 when changes were written"
else
    code=$?
    if [[ $code -ne 1 ]]; then
        fail "-w flag" "expected exit code 1, got $code"
    else
        content=$(cat "$testfile")
        if echo "$content" | grep -q "// characters and should be wrapped"; then
            pass "-w flag"
        else
            fail "-w flag" "file was not properly modified"
        fi
    fi
fi
