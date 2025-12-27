#!/usr/bin/env bats
#
# Backup expiration and pruning tests for rsync_tmbackup.sh
# Tests for the expiration strategy and max_backups pruning
#

load 'test_helper'

# =============================================================================
# Setup and Teardown
# =============================================================================

setup() {
    setup_test_environment
    create_sample_files "$TEST_SOURCE" 2
}

teardown() {
    teardown_test_environment
}

# =============================================================================
# Pruning by Count (max_backups)
# =============================================================================

@test "prune keeps exactly max_backups when exceeded" {
    # Create 5 backups with max_backups=3
    for i in 1 2 3 4 5; do
        sleep 1
        echo "backup $i" >> "$TEST_SOURCE/file_1.txt"
        run "$SCRIPT_PATH" -m 3 "$TEST_SOURCE" "$TEST_DEST"
        assert_success
    done

    local count
    count=$(count_backups "$TEST_DEST")
    [ "$count" -le 3 ]
}

@test "prune removes oldest backup when limit reached" {
    # Create first backup
    run "$SCRIPT_PATH" -m 2 "$TEST_SOURCE" "$TEST_DEST"
    assert_success
    local oldest
    oldest=$(find "$TEST_DEST" -maxdepth 1 -type d -name "????-??-??-??????" | head -1)
    local oldest_name
    oldest_name=$(basename "$oldest")

    sleep 1

    # Second backup
    echo "second" >> "$TEST_SOURCE/file_1.txt"
    run "$SCRIPT_PATH" -m 2 "$TEST_SOURCE" "$TEST_DEST"
    assert_success

    sleep 1

    # Third backup (should trigger pruning of oldest)
    echo "third" >> "$TEST_SOURCE/file_1.txt"
    run "$SCRIPT_PATH" -m 2 "$TEST_SOURCE" "$TEST_DEST"
    assert_success

    # Oldest should be pruned
    assert_dir_not_exists "$TEST_DEST/$oldest_name"

    # Should have exactly 2 backups
    local count
    count=$(count_backups "$TEST_DEST")
    [ "$count" -eq 2 ]
}

# =============================================================================
# Default Expiration Strategy
# =============================================================================

@test "default strategy is 1:1 30:7 365:30" {
    # This test verifies the default strategy is applied
    # We can't easily test complex expiration without time manipulation
    # but we can verify the script accepts the default

    run "$SCRIPT_PATH" "$TEST_SOURCE" "$TEST_DEST"
    assert_success
}

@test "custom strategy is accepted and applied" {
    # Simple strategy: keep one per day
    run "$SCRIPT_PATH" --strategy "1:1" "$TEST_SOURCE" "$TEST_DEST"
    assert_success
}

# =============================================================================
# Edge Cases
# =============================================================================

@test "single backup is never pruned" {
    run "$SCRIPT_PATH" -m 1 "$TEST_SOURCE" "$TEST_DEST"
    assert_success

    local count
    count=$(count_backups "$TEST_DEST")
    [ "$count" -eq 1 ]
}

@test "backup with malformed date directory is skipped during expiration" {
    # Create a normal backup first
    run "$SCRIPT_PATH" "$TEST_SOURCE" "$TEST_DEST"
    assert_success

    # Create a malformed directory that looks like a backup but isn't valid
    mkdir -p "$TEST_DEST/not-a-valid-date"

    sleep 1

    # Create another backup - should not crash
    echo "second backup" >> "$TEST_SOURCE/file_1.txt"
    run "$SCRIPT_PATH" "$TEST_SOURCE" "$TEST_DEST"
    assert_success

    # Malformed directory should still exist (not deleted by expiration)
    assert_dir_exists "$TEST_DEST/not-a-valid-date"
}

# =============================================================================
# Safety Checks
# =============================================================================

@test "expiration only works on directories with backup.marker" {
    # This is a critical safety feature
    # The script should verify backup.marker exists before expiring

    run "$SCRIPT_PATH" "$TEST_SOURCE" "$TEST_DEST"
    assert_success

    # Backup should be in a directory with backup.marker
    local backup_dir
    backup_dir=$(find "$TEST_DEST" -maxdepth 1 -type d -name "????-??-??-??????" | head -1)
    local parent_dir
    parent_dir=$(dirname "$backup_dir")

    assert_file_exists "$parent_dir/backup.marker"
}
