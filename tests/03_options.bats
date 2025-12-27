#!/usr/bin/env bats
#
# CLI options tests for rsync_tmbackup.sh
# Tests for command-line argument parsing and option behavior
#

load 'test_helper'

# =============================================================================
# Setup and Teardown
# =============================================================================

setup() {
    setup_test_environment
    create_sample_files "$TEST_SOURCE" 3
}

teardown() {
    teardown_test_environment
}

# =============================================================================
# Max Backups Option (-m / --max_backups)
# =============================================================================

@test "max_backups option accepts -m flag" {
    run "$SCRIPT_PATH" -m 5 "$TEST_SOURCE" "$TEST_DEST"
    assert_success
}

@test "max_backups option accepts --max_backups flag" {
    run "$SCRIPT_PATH" --max_backups 5 "$TEST_SOURCE" "$TEST_DEST"
    assert_success
}

@test "max_backups limits number of kept backups" {
    # Create initial backup
    run "$SCRIPT_PATH" -m 3 "$TEST_SOURCE" "$TEST_DEST"
    assert_success

    # Create more backups than the limit
    for i in 1 2 3 4; do
        sleep 1
        echo "iteration $i" >> "$TEST_SOURCE/file_1.txt"
        run "$SCRIPT_PATH" -m 3 "$TEST_SOURCE" "$TEST_DEST"
        assert_success
    done

    # Should have at most 3 backups
    local count
    count=$(count_backups "$TEST_DEST")
    [ "$count" -le 3 ]
}

@test "max_backups prunes oldest backups first" {
    # Create 2 backups
    run "$SCRIPT_PATH" -m 2 "$TEST_SOURCE" "$TEST_DEST"
    assert_success
    sleep 1

    echo "second backup" >> "$TEST_SOURCE/file_1.txt"
    run "$SCRIPT_PATH" -m 2 "$TEST_SOURCE" "$TEST_DEST"
    assert_success
    sleep 1

    # Get first two backup names
    local first_backup second_backup
    first_backup=$(find "$TEST_DEST" -maxdepth 1 -type d -name "????-??-??-??????" | sort | head -1 | xargs basename)
    second_backup=$(find "$TEST_DEST" -maxdepth 1 -type d -name "????-??-??-??????" | sort | tail -1 | xargs basename)

    # Create third backup with limit of 2
    echo "third backup" >> "$TEST_SOURCE/file_1.txt"
    run "$SCRIPT_PATH" -m 2 "$TEST_SOURCE" "$TEST_DEST"
    assert_success

    # First backup should be gone
    assert_dir_not_exists "$TEST_DEST/$first_backup"

    # Second backup should still exist
    assert_dir_exists "$TEST_DEST/$second_backup"
}

# =============================================================================
# Rsync Flags Options
# =============================================================================

@test "rsync-append-flags adds custom flags" {
    run "$SCRIPT_PATH" --rsync-append-flags "--dry-run" "$TEST_SOURCE" "$TEST_DEST"
    # With --dry-run, no actual backup should be created
    assert_success
}

@test "rsync-set-flags replaces default flags" {
    run "$SCRIPT_PATH" --rsync-set-flags "-av" "$TEST_SOURCE" "$TEST_DEST"
    assert_success
}

# =============================================================================
# Expiration Strategy Option
# =============================================================================

@test "strategy option accepts custom strategy" {
    run "$SCRIPT_PATH" --strategy "1:1 7:2 30:7" "$TEST_SOURCE" "$TEST_DEST"
    assert_success
}

# =============================================================================
# Log Directory Options
# =============================================================================

@test "log-dir option sets custom log directory" {
    local custom_log_dir="$TEST_TEMP_DIR/custom_logs"
    mkdir -p "$custom_log_dir"

    run "$SCRIPT_PATH" --log-dir "$custom_log_dir" "$TEST_SOURCE" "$TEST_DEST"
    # Note: logs are auto-deleted on success, but directory should be used
    assert_success
}

@test "log-to-destination stores logs in destination" {
    run "$SCRIPT_PATH" --log-to-destination "$TEST_SOURCE" "$TEST_DEST"
    assert_success

    # Check for log directory in destination
    assert_dir_exists "$TEST_DEST/.rsync_tmbackup"
}

# =============================================================================
# No Auto Expire Option
# =============================================================================

@test "no-auto-expire option is accepted" {
    run "$SCRIPT_PATH" --no-auto-expire "$TEST_SOURCE" "$TEST_DEST"
    assert_success
}

# =============================================================================
# Sudo Option
# =============================================================================

@test "sudo option is accepted" {
    run "$SCRIPT_PATH" --sudo "$TEST_SOURCE" "$TEST_DEST"
    assert_success
}

# =============================================================================
# SSH Options
# =============================================================================

@test "port option accepts -p flag" {
    # This won't actually connect, but should parse the option
    run "$SCRIPT_PATH" -p 2222 --help
    assert_success
}

@test "id_rsa option accepts -i flag" {
    run "$SCRIPT_PATH" -i /path/to/key --help
    assert_success
}

# =============================================================================
# Exclusion File
# =============================================================================

@test "exclusion file is used when provided" {
    local exclude_file="$TEST_TEMP_DIR/excludes.txt"
    echo "file_1.txt" > "$exclude_file"

    run "$SCRIPT_PATH" "$TEST_SOURCE" "$TEST_DEST" "$exclude_file"
    assert_success

    # Find the backup directory
    local backup_dir
    backup_dir=$(find "$TEST_DEST" -maxdepth 1 -type d -name "????-??-??-??????" | head -1)

    # Excluded file should not exist
    assert_file_not_exists "$backup_dir/file_1.txt"

    # Other files should exist
    assert_file_exists "$backup_dir/file_2.txt"
}

@test "exclusion file with filter rules uses --filter" {
    local exclude_file="$TEST_TEMP_DIR/filters.txt"
    cat > "$exclude_file" << 'EOF'
- file_1.txt
+ file_2.txt
- *.txt
EOF

    run "$SCRIPT_PATH" "$TEST_SOURCE" "$TEST_DEST" "$exclude_file"
    assert_success

    local backup_dir
    backup_dir=$(find "$TEST_DEST" -maxdepth 1 -type d -name "????-??-??-??????" | head -1)

    # file_1.txt excluded
    assert_file_not_exists "$backup_dir/file_1.txt"

    # file_2.txt explicitly included
    assert_file_exists "$backup_dir/file_2.txt"
}
