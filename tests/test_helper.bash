#!/usr/bin/env bash
#
# Common helper functions for bats tests
#

# Get the directory where this helper is located
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TESTS_DIR")"
SCRIPT_PATH="$PROJECT_ROOT/rsync_tmbackup.sh"

# Load bats helper libraries
load "${TESTS_DIR}/bats/bats-support/load"
load "${TESTS_DIR}/bats/bats-assert/load"
load "${TESTS_DIR}/bats/bats-file/load"

# Create a temporary test environment
setup_test_environment() {
    # Create unique temp directory for this test
    TEST_TEMP_DIR="$(mktemp -d)"
    TEST_SOURCE="$TEST_TEMP_DIR/source"
    TEST_DEST="$TEST_TEMP_DIR/dest"

    mkdir -p "$TEST_SOURCE"
    mkdir -p "$TEST_DEST"

    # Create backup.marker (required by the script)
    touch "$TEST_DEST/backup.marker"

    export TEST_TEMP_DIR TEST_SOURCE TEST_DEST
}

# Clean up temporary test environment
teardown_test_environment() {
    if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Create sample files in source directory
create_sample_files() {
    local dir="${1:-$TEST_SOURCE}"
    local count="${2:-5}"

    for i in $(seq 1 "$count"); do
        echo "Sample content $i - $(date +%s)" > "$dir/file_$i.txt"
    done
}

# Create sample directory structure
create_sample_structure() {
    local dir="${1:-$TEST_SOURCE}"

    mkdir -p "$dir/subdir1/nested"
    mkdir -p "$dir/subdir2"

    echo "root file" > "$dir/root.txt"
    echo "subdir1 file" > "$dir/subdir1/sub1.txt"
    echo "nested file" > "$dir/subdir1/nested/nested.txt"
    echo "subdir2 file" > "$dir/subdir2/sub2.txt"
}

# Create fake backup directories (for testing expiration/pruning)
create_fake_backups() {
    local dest="${1:-$TEST_DEST}"
    local count="${2:-5}"
    local days_ago="${3:-0}"

    for i in $(seq 1 "$count"); do
        local offset=$((days_ago + i))
        local backup_date=$(date -v-"${offset}"d +"%Y-%m-%d-%H%M%S" 2>/dev/null || \
                           date -d "-${offset} days" +"%Y-%m-%d-%H%M%S")
        mkdir -p "$dest/$backup_date"
        echo "backup $i" > "$dest/$backup_date/marker.txt"
    done
}

# Count backup directories
count_backups() {
    local dest="${1:-$TEST_DEST}"
    find "$dest" -maxdepth 1 -type d -name "????-??-??-??????" | wc -l | tr -d ' '
}

# Get the script name for running
get_script() {
    echo "$SCRIPT_PATH"
}

# Run the backup script with common options
run_backup() {
    run "$SCRIPT_PATH" "$@"
}

# Assert backup was created successfully
assert_backup_created() {
    local dest="${1:-$TEST_DEST}"
    local count
    count=$(count_backups "$dest")
    [ "$count" -gt 0 ] || fail "Expected at least one backup, found $count"
}

# Assert specific number of backups exist
assert_backup_count() {
    local expected="$1"
    local dest="${2:-$TEST_DEST}"
    local actual
    actual=$(count_backups "$dest")
    [ "$actual" -eq "$expected" ] || fail "Expected $expected backups, found $actual"
}
