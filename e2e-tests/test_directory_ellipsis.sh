# Test: directory argument with /... ellipsis (recursive)

testdir="$TMPDIR/ellipsistest"
mkdir -p "$testdir/subdir/nested"

cat > "$testdir/root.go" << 'EOF'
package main

// Root file has a very long comment that exceeds the default line length and should be wrapped
func root() {}
EOF

cat > "$testdir/subdir/sub.go" << 'EOF'
package sub

// Subdir file has a very long comment that exceeds the default line length and should be wrapped
func sub() {}
EOF

cat > "$testdir/subdir/nested/deep.go" << 'EOF'
package nested

// Nested file has a very long comment that exceeds the default line length and should be wrapped
func deep() {}
EOF

output=$("$BINARY" -l "$testdir/..." 2>&1 || true)

# Should find all three files recursively
if echo "$output" | grep -q "root.go" && \
   echo "$output" | grep -q "sub.go" && \
   echo "$output" | grep -q "deep.go"; then
    pass "directory with /... ellipsis"
else
    fail "directory with /... ellipsis" "did not find all nested files: $output"
fi
