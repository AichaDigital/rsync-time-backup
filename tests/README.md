# Testing rsync_tmbackup.sh

This directory contains automated tests for `rsync_tmbackup.sh` using the [bats-core](https://github.com/bats-core/bats-core) testing framework.

## Quick Start

```bash
# Install bats (first time only)
./tests/setup_bats.sh

# Run all tests
./tests/run_tests.sh

# Run specific test file
./tests/run_tests.sh 01_basic

# Run with verbose output
./tests/run_tests.sh --verbose
```

## Test Files

| File | Description | Tests |
|------|-------------|-------|
| `01_basic.bats` | Script existence, help, flags, input validation | 18 |
| `02_backup.bats` | Backup creation, incremental backups, symlinks | 9 |
| `03_options.bats` | CLI options: max_backups, rsync flags, exclusions | 15 |
| `04_expiration.bats` | Backup expiration and pruning logic | 7 |
| `05_resume.bats` | Interrupted backup handling and recovery | 5 |

**Total: 54 tests**

## What is Bats?

Bats (Bash Automated Testing System) is a TAP-compliant testing framework for Bash. Each test is a function that runs in isolation:

```bash
@test "displays help with -h flag" {
    run ./rsync_tmbackup.sh -h
    assert_success
    assert_output --partial "Usage:"
}
```

Key concepts:

- `@test "description"` - Defines a test case
- `run` - Executes a command and captures output/status
- `assert_success` - Verifies exit code is 0
- `assert_failure` - Verifies exit code is non-zero
- `assert_output --partial "text"` - Checks output contains text
- `assert_file_exists` - Verifies file exists

## Test Structure

```
tests/
├── setup_bats.sh       # Installs bats-core and helpers
├── run_tests.sh        # Test runner script
├── test_helper.bash    # Common functions for all tests
├── 01_basic.bats       # Basic functionality tests
├── 02_backup.bats      # Backup operation tests
├── 03_options.bats     # CLI options tests
├── 04_expiration.bats  # Expiration/pruning tests
├── 05_resume.bats      # Resume/recovery tests
├── bats/               # (gitignored) bats-core installation
│   ├── bats-core/
│   ├── bats-assert/
│   ├── bats-support/
│   └── bats-file/
└── README.md           # This file
```

## Writing New Tests

1. Create a new `.bats` file or add to existing one
2. Load the test helper at the top:

```bash
#!/usr/bin/env bats
load 'test_helper'
```

3. Use setup/teardown for test isolation:

```bash
setup() {
    setup_test_environment
}

teardown() {
    teardown_test_environment
}
```

4. Write tests using the `@test` syntax:

```bash
@test "my new test" {
    run "$SCRIPT_PATH" --my-option "$TEST_SOURCE" "$TEST_DEST"
    assert_success
}
```

## Helper Functions

The `test_helper.bash` provides:

| Function | Description |
|----------|-------------|
| `setup_test_environment` | Creates temp source/dest with backup.marker |
| `teardown_test_environment` | Cleans up temp directories |
| `create_sample_files` | Creates N sample files in a directory |
| `create_sample_structure` | Creates a nested directory structure |
| `create_fake_backups` | Creates fake backup directories for testing |
| `count_backups` | Counts backup directories in destination |
| `run_backup` | Runs the backup script |

## CI Integration

To run tests in CI (GitHub Actions, GitLab CI, etc.):

```yaml
# GitHub Actions example
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Setup bats
      run: ./tests/setup_bats.sh
    - name: Run tests
      run: ./tests/run_tests.sh
```

## Troubleshooting

### Tests fail with "bats not found"

Run `./tests/setup_bats.sh` to install bats-core locally.

### Tests are slow

Some tests create actual backups. Use `--verbose` to see which tests are running:

```bash
./tests/run_tests.sh --verbose
```

### Test cleanup issues

If temp directories aren't cleaned up, check the `teardown` function is being called. You can manually clean with:

```bash
rm -rf /tmp/tmp.*  # Be careful with this!
```

## Resources

- [bats-core documentation](https://bats-core.readthedocs.io/)
- [bats-assert](https://github.com/bats-core/bats-assert) - Assertion library
- [bats-file](https://github.com/bats-core/bats-file) - File assertions
- [Writing tests guide](https://bats-core.readthedocs.io/en/stable/writing-tests.html)
