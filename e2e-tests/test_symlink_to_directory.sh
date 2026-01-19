# Test: symlinks to directories

testdir="$TMPDIR/symlinkdirtest"
mkdir -p "$testdir/realdir"

cat > "$testdir/realdir/file.go" << 'EOF'
package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func example() {}
EOF

ln -sf "$testdir/realdir" "$testdir/linkdir"

output=$("$BINARY" -l "$testdir/linkdir" 2>&1 || true)

# Should process files in the symlinked directory
if echo "$output" | grep -q "file.go"; then
    pass "symlink to directory"
else
    fail "symlink to directory" "files in symlinked directory not processed"
fi
