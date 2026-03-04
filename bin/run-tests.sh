#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Help bats_load_library find bats-support and bats-assert. Append common
# Homebrew locations so CI systems can override by setting BATS_LIB_PATH
# themselves before invoking this script.
BATS_LIB_PATH="${BATS_LIB_PATH:+${BATS_LIB_PATH}:}/opt/homebrew/lib:/usr/local/lib"
export BATS_LIB_PATH

exec bats "$BASE_DIR/tests/"*.bats "$@"
