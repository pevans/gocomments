# Test: mixed files and directories as arguments

testdir="$TMPDIR/mixedtest"
mkdir -p "$testdir/subdir"

# File in root
cat > "$testdir/root.go" << 'EOF'
package main

// Root file has a very long comment that exceeds the default line length and should be wrapped
func root() {}
EOF

# File in subdir
cat > "$testdir/subdir/sub.go" << 'EOF'
package sub

// Subdir file has a very long comment that exceeds the default line length and should be wrapped
func sub() {}
EOF

# Standalone file outside directory
standalone="$TMPDIR/standalone.go"
cat > "$standalone" << 'EOF'
package standalone

// Standalone file has a very long comment that exceeds the default line length and should be wrapped
func standalone() {}
EOF

output=$("$BINARY" -l "$standalone" "$testdir/subdir" 2>&1 || true)

# Should find standalone file and subdir file
if echo "$output" | grep -q "standalone.go" && echo "$output" | grep -q "sub.go"; then
    pass "mixed files and directories"
else
    fail "mixed files and directories" "did not find expected files: $output"
fi
