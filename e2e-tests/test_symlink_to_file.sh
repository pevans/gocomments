# Test: symlinks to files

testdir="$TMPDIR/symlinktest"
mkdir -p "$testdir"

cat > "$testdir/real.go" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF

ln -sf "$testdir/real.go" "$testdir/link.go"

output=$("$BINARY" -l "$testdir/link.go" 2>&1 || true)

# Should process the symlinked file
if echo "$output" | grep -q "link.go"; then
    pass "symlink to file"
else
    fail "symlink to file" "symlinked file not processed"
fi
