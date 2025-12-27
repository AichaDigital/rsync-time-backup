#!/usr/bin/env bash
#
# Script to install bats-core and helper libraries for testing rsync_tmbackup.sh
#
# Usage: ./tests/setup_bats.sh
#

set -e

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATS_DIR="$TESTS_DIR/bats"

echo "Setting up bats-core testing framework..."

# Create bats directory
mkdir -p "$BATS_DIR"

# Clone bats-core if not exists
if [ ! -d "$BATS_DIR/bats-core" ]; then
    echo "Cloning bats-core..."
    git clone --depth 1 https://github.com/bats-core/bats-core.git "$BATS_DIR/bats-core"
else
    echo "bats-core already exists, skipping..."
fi

# Clone bats-support (helper library)
if [ ! -d "$BATS_DIR/bats-support" ]; then
    echo "Cloning bats-support..."
    git clone --depth 1 https://github.com/bats-core/bats-support.git "$BATS_DIR/bats-support"
else
    echo "bats-support already exists, skipping..."
fi

# Clone bats-assert (assertion library)
if [ ! -d "$BATS_DIR/bats-assert" ]; then
    echo "Cloning bats-assert..."
    git clone --depth 1 https://github.com/bats-core/bats-assert.git "$BATS_DIR/bats-assert"
else
    echo "bats-assert already exists, skipping..."
fi

# Clone bats-file (file assertions)
if [ ! -d "$BATS_DIR/bats-file" ]; then
    echo "Cloning bats-file..."
    git clone --depth 1 https://github.com/bats-core/bats-file.git "$BATS_DIR/bats-file"
else
    echo "bats-file already exists, skipping..."
fi

echo ""
echo "Setup complete!"
echo ""
echo "To run tests:"
echo "  $BATS_DIR/bats-core/bin/bats $TESTS_DIR/*.bats"
echo ""
echo "Or add an alias:"
echo "  alias bats='$BATS_DIR/bats-core/bin/bats'"
