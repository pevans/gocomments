# Test: directory argument (processes all .go files)
# RFC 1 Section 2.2

testdir="$TMPDIR/dirtest"
mkdir -p "$testdir"

cat > "$testdir/a.go" << 'EOF'
package main

// File A has a very long comment that exceeds the default line length and should be wrapped
func a() {}
EOF

cat > "$testdir/b.go" << 'EOF'
package main

// File B has a very long comment that exceeds the default line length and should be wrapped
func b() {}
EOF

# Also create a non-go file that should be ignored
echo "not a go file" > "$testdir/readme.txt"

output=$("$BINARY" -l "$testdir" 2>&1 || true)

# Should list both .go files
if echo "$output" | grep -q "a.go" && echo "$output" | grep -q "b.go"; then
    # Should not mention the txt file
    if ! echo "$output" | grep -q "readme.txt"; then
        pass "directory argument"
    else
        fail "directory argument" "should not process non-go files"
    fi
else
    fail "directory argument" "did not find go files in directory: $output"
fi
