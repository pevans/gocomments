# Test: -tlen affects wrapping
# With tlen=4: availableLength = 78 - 4 - 2 - 1 = 71 chars
# With tlen=8: availableLength = 78 - 8 - 2 - 1 = 67 chars
# Comment is 71 chars: fits with tlen=4, wraps with tlen=8

output4=$("$BINARY" -tlen 4 << 'EOF'
package main

func example() {
	// This comment is indented with a tab and is exactly seventy characters!
	println("test")
}
EOF
)
output8=$("$BINARY" -tlen 8 << 'EOF'
package main

func example() {
	// This comment is indented with a tab and is exactly seventy characters!
	println("test")
}
EOF
)

count4=$(echo "$output4" | grep -c "//" || true)
count8=$(echo "$output8" | grep -c "//" || true)

if [[ $count8 -gt $count4 ]]; then
    pass "-tlen effect"
else
    fail "-tlen effect" "tlen=8 should produce more comment lines than tlen=4 (got $count8 vs $count4)"
fi
