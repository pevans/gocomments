#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMPDIR=$(mktemp -d)
BINARY="$TMPDIR/gocomments"
PASSED=0
FAILED=0

cleanup() {
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

echo "Building gocomments..."
go build -o "$BINARY" "$SCRIPT_DIR"

pass() {
    echo "PASS: $1"
    PASSED=$((PASSED + 1))
}

fail() {
    echo "FAIL: $1"
    echo "  $2"
    FAILED=$((FAILED + 1))
}

echo
echo "Running tests..."
echo

for test_file in "$SCRIPT_DIR/e2e-tests"/test_*.sh; do
    source "$test_file"
done

echo
echo "Results: $PASSED passed, $FAILED failed"

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi
