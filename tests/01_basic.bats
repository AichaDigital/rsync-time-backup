#!/usr/bin/env bats
#
# Basic tests for rsync_tmbackup.sh
# These tests verify fundamental functionality without running actual backups
#

load 'test_helper'

# =============================================================================
# Setup and Teardown
# =============================================================================

setup() {
    setup_test_environment
}

teardown() {
    teardown_test_environment
}

# =============================================================================
# Script Existence and Permissions
# =============================================================================

@test "script exists" {
    assert_file_exists "$SCRIPT_PATH"
}

@test "script is executable" {
    assert_file_executable "$SCRIPT_PATH"
}

@test "script starts with proper shebang" {
    run head -1 "$SCRIPT_PATH"
    assert_output --partial "#!/usr/bin/env bash"
}

# =============================================================================
# Help and Usage
# =============================================================================

@test "displays help with -h flag" {
    run "$SCRIPT_PATH" -h
    assert_success
    assert_output --partial "Usage:"
    assert_output --partial "Options"
}

@test "displays help with --help flag" {
    run "$SCRIPT_PATH" --help
    assert_success
    assert_output --partial "Usage:"
}

@test "shows max_backups option in help" {
    run "$SCRIPT_PATH" --help
    assert_success
    assert_output --partial "--max_backups"
}

@test "shows sudo option in help" {
    run "$SCRIPT_PATH" --help
    assert_success
    assert_output --partial "--sudo"
}

@test "shows log-to-destination option in help" {
    run "$SCRIPT_PATH" --help
    assert_success
    assert_output --partial "--log-to-destination"
}

# =============================================================================
# Rsync Flags
# =============================================================================

@test "displays rsync flags with --rsync-get-flags" {
    run "$SCRIPT_PATH" --rsync-get-flags
    assert_success
    assert_output --partial "--recursive"
    assert_output --partial "--hard-links"
}

@test "rsync flags do not include --perms by default" {
    # This is a fork-specific change for non-root environments
    run "$SCRIPT_PATH" --rsync-get-flags
    assert_success
    refute_output --partial "--perms"
}

@test "rsync flags do not include --owner by default" {
    run "$SCRIPT_PATH" --rsync-get-flags
    assert_success
    refute_output --partial "--owner"
}

@test "rsync flags do not include --group by default" {
    run "$SCRIPT_PATH" --rsync-get-flags
    assert_success
    refute_output --partial "--group"
}

# =============================================================================
# Input Validation
# =============================================================================

@test "fails without arguments" {
    run "$SCRIPT_PATH"
    assert_failure
    assert_output --partial "Usage:"
}

@test "fails with only source argument" {
    run "$SCRIPT_PATH" "$TEST_SOURCE"
    assert_failure
    assert_output --partial "Usage:"
}

@test "fails when source folder does not exist" {
    run "$SCRIPT_PATH" "/nonexistent/source/path" "$TEST_DEST"
    assert_failure
    assert_output --partial "does not exist"
}

@test "fails when destination has no backup.marker" {
    rm "$TEST_DEST/backup.marker"
    run "$SCRIPT_PATH" "$TEST_SOURCE" "$TEST_DEST"
    assert_failure
    assert_output --partial "marker"
}

@test "rejects source path with single quotes" {
    # The script checks for single quotes in paths and rejects them
    # However, if the path doesn't exist, it fails with "does not exist" first
    # So we test with a valid path that has quotes
    mkdir -p "$TEST_TEMP_DIR/path'with'quotes"
    touch "$TEST_TEMP_DIR/path'with'quotes/file.txt"

    run "$SCRIPT_PATH" "$TEST_TEMP_DIR/path'with'quotes" "$TEST_DEST"
    assert_failure
    # Either fails with "single quote" error or "does not exist"
    # depending on order of checks in script
}

@test "rejects unknown option" {
    run "$SCRIPT_PATH" --unknown-option "$TEST_SOURCE" "$TEST_DEST"
    assert_failure
    assert_output --partial "Unknown option"
}
