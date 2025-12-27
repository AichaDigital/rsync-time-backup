#!/usr/bin/env bash
#
# Run all bats tests for rsync_tmbackup.sh
#
# Usage:
#   ./tests/run_tests.sh              # Run all tests
#   ./tests/run_tests.sh 01_basic     # Run specific test file
#   ./tests/run_tests.sh --verbose    # Run with verbose output
#

set -e

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATS_DIR="$TESTS_DIR/bats"
BATS_BIN="$BATS_DIR/bats-core/bin/bats"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if bats is installed
if [ ! -x "$BATS_BIN" ]; then
    echo -e "${YELLOW}Bats not found. Installing...${NC}"
    "$TESTS_DIR/setup_bats.sh"
    echo ""
fi

# Parse arguments
VERBOSE=""
TEST_FILES=()

for arg in "$@"; do
    case $arg in
        --verbose|-v)
            VERBOSE="--verbose-run"
            ;;
        --tap)
            VERBOSE="--tap"
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS] [TEST_FILES...]"
            echo ""
            echo "Options:"
            echo "  -v, --verbose    Show verbose test output"
            echo "  --tap            Output in TAP format"
            echo "  -h, --help       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                   Run all tests"
            echo "  $0 01_basic          Run only 01_basic.bats"
            echo "  $0 --verbose         Run all tests with verbose output"
            exit 0
            ;;
        *)
            # Check if it's a test file name
            if [ -f "$TESTS_DIR/${arg}.bats" ]; then
                TEST_FILES+=("$TESTS_DIR/${arg}.bats")
            elif [ -f "$TESTS_DIR/$arg" ]; then
                TEST_FILES+=("$TESTS_DIR/$arg")
            elif [ -f "$arg" ]; then
                TEST_FILES+=("$arg")
            else
                echo -e "${RED}Unknown option or test file: $arg${NC}"
                exit 1
            fi
            ;;
    esac
done

# If no test files specified, run all
if [ ${#TEST_FILES[@]} -eq 0 ]; then
    TEST_FILES=("$TESTS_DIR"/*.bats)
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  rsync_tmbackup.sh Test Suite${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Running tests: ${TEST_FILES[*]}"
echo ""

# Run bats
"$BATS_BIN" $VERBOSE "${TEST_FILES[@]}"

echo ""
echo -e "${GREEN}All tests completed!${NC}"
