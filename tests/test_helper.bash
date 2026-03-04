#!/bin/bash
# Common test helpers for bats-core tests
# Load with: load test_helper
#
# Requires bats-core >= 1.7 for bats_load_library, plus bats-support and
# bats-assert libraries installed (e.g. via Homebrew: bats-core bats-support
# bats-assert).

bats_load_library bats-support
bats_load_library bats-assert

# Set up test environment variables. Call from setup_file.
setup_test_env() {
    export BINARY="$BATS_FILE_TMPDIR/gocomments"
}

# Build the gocomments binary into BATS_FILE_TMPDIR. Call from setup_file.
build_gocomments() {
    (cd "${BATS_TEST_DIRNAME}/.." && go build -o "$BATS_FILE_TMPDIR/gocomments" .)
    if [ ! -f "$BATS_FILE_TMPDIR/gocomments" ]; then
        echo "Error: Failed to build gocomments binary" >&2
        return 1
    fi
}
