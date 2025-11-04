#!/bin/bash
# ABOUTME: Comprehensive test suite for rollback.sh script
# Tests backup discovery, file restoration, symlink removal, and error handling

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
TEST_HOME="${1:-$(mktemp -d)}"
DOTFILES_DIR="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ROLLBACK_SCRIPT="$DOTFILES_DIR/rollback.sh"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Helper functions
print_header() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

print_test() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo ""
    echo "Test $TESTS_TOTAL: $1"
}

pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Setup test environment
setup_test_env() {
    export HOME="$TEST_HOME"
    mkdir -p "$TEST_HOME"

    # Create a backup directory with test files
    local backup_dir="$TEST_HOME/.dotfiles_backup_20250101_120000"
    mkdir -p "$backup_dir"
    echo "original content" > "$backup_dir/.zshrc"
    echo "original aliases" > "$backup_dir/.aliases"
    echo "original config" > "$backup_dir/.gitconfig"

    # Create current symlinks that should be removed during rollback
    mkdir -p "$TEST_HOME/.config/zsh"
    ln -sf "$DOTFILES_DIR/.zshrc" "$TEST_HOME/.config/zsh/.zshrc"
    ln -sf "$DOTFILES_DIR/.aliases" "$TEST_HOME/.aliases"
    ln -sf "$DOTFILES_DIR/.gitconfig" "$TEST_HOME/.gitconfig"
}

# Test 1: Rollback script exists
test_script_exists() {
    print_test "Rollback script exists"

    if [ -f "$ROLLBACK_SCRIPT" ]; then
        pass "rollback.sh exists at $ROLLBACK_SCRIPT"
        return 0
    else
        fail "rollback.sh not found at $ROLLBACK_SCRIPT"
        return 1
    fi
}

# Test 2: Script is executable
test_script_executable() {
    print_test "Script is executable"

    if [ -x "$ROLLBACK_SCRIPT" ]; then
        pass "rollback.sh is executable"
        return 0
    else
        fail "rollback.sh is not executable"
        return 1
    fi
}

# Test 3: Find latest backup
test_find_latest_backup() {
    print_test "Find latest backup directory"

    setup_test_env

    # Create multiple backup directories
    mkdir -p "$TEST_HOME/.dotfiles_backup_20250101_100000"
    mkdir -p "$TEST_HOME/.dotfiles_backup_20250101_120000"
    mkdir -p "$TEST_HOME/.dotfiles_backup_20250101_110000"

    # Expected latest backup
    local expected="$TEST_HOME/.dotfiles_backup_20250101_120000"

    # Test script's ability to find latest backup
    # This will fail until we implement the script
    if HOME="$TEST_HOME" bash -c "source '$ROLLBACK_SCRIPT' 2>/dev/null && echo \$LATEST_BACKUP" | grep -q "20250101_120000"; then
        pass "Found latest backup: $(basename "$expected")"
        return 0
    else
        fail "Failed to find latest backup"
        return 1
    fi
}

# Test 4: Error when no backup exists
test_no_backup_error() {
    print_test "Error handling when no backup exists"

    # Create clean environment with no backups
    local clean_home
    clean_home=$(mktemp -d)

    # Run rollback script and expect failure
    if HOME="$clean_home" bash "$ROLLBACK_SCRIPT" 2>&1 | grep -q "No backup found"; then
        pass "Correctly reports no backup found"
        rm -rf "$clean_home"
        return 0
    else
        fail "Did not report missing backup"
        rm -rf "$clean_home"
        return 1
    fi
}

# Test 5: Non-interactive rollback (auto-yes)
test_noninteractive_rollback() {
    print_test "Non-interactive rollback with -y flag"

    setup_test_env
    local backup_dir="$TEST_HOME/.dotfiles_backup_20250101_120000"

    # Run rollback with -y flag (should skip confirmation)
    if HOME="$TEST_HOME" bash "$ROLLBACK_SCRIPT" -y 2>&1 | tee /tmp/rollback-output.log; then
        # Verify files were restored
        if [ -f "$TEST_HOME/.zshrc" ] && [ ! -L "$TEST_HOME/.zshrc" ]; then
            pass "File restored from backup"
        else
            fail "File not restored properly"
            return 1
        fi

        # Verify backup directory was removed (if empty)
        if [ ! -d "$backup_dir" ]; then
            pass "Empty backup directory cleaned up"
        else
            warn "Backup directory still exists"
        fi

        return 0
    else
        fail "Non-interactive rollback failed"
        return 1
    fi
}

# Test 6: Symlink removal
test_symlink_removal() {
    print_test "Symlink removal during rollback"

    setup_test_env

    # Verify symlinks exist before rollback
    if [ -L "$TEST_HOME/.aliases" ]; then
        pass "Symlink exists before rollback"
    else
        fail "Test setup error: symlink not created"
        return 1
    fi

    # Run rollback (non-interactive)
    HOME="$TEST_HOME" bash "$ROLLBACK_SCRIPT" -y > /dev/null 2>&1 || true

    # Verify symlink was removed and replaced with real file
    if [ -f "$TEST_HOME/.aliases" ] && [ ! -L "$TEST_HOME/.aliases" ]; then
        pass "Symlink removed and file restored"
        return 0
    else
        fail "Symlink not properly replaced"
        return 1
    fi
}

# Test 7: File content preservation
test_file_content_preservation() {
    print_test "File content preservation during rollback"

    setup_test_env
    local backup_dir="$TEST_HOME/.dotfiles_backup_20250101_120000"

    # Create backup with specific content
    echo "preserved content 12345" > "$backup_dir/.test-file"

    # Run rollback
    HOME="$TEST_HOME" bash "$ROLLBACK_SCRIPT" -y > /dev/null 2>&1 || true

    # Verify content was preserved
    if [ -f "$TEST_HOME/.test-file" ] && grep -q "preserved content 12345" "$TEST_HOME/.test-file"; then
        pass "File content preserved correctly"
        return 0
    else
        fail "File content not preserved"
        return 1
    fi
}

# Test 8: Permission preservation
test_permission_preservation() {
    print_test "Permission preservation during rollback"

    setup_test_env
    local backup_dir="$TEST_HOME/.dotfiles_backup_20250101_120000"

    # Create file with specific permissions in backup
    echo "executable script" > "$backup_dir/.test-script"
    chmod 755 "$backup_dir/.test-script"

    # Run rollback
    HOME="$TEST_HOME" bash "$ROLLBACK_SCRIPT" -y > /dev/null 2>&1 || true

    # Verify permissions were preserved
    if [ -x "$TEST_HOME/.test-script" ]; then
        pass "Permissions preserved correctly"
        return 0
    else
        fail "Permissions not preserved"
        return 1
    fi
}

# Test 9: Dry-run mode
test_dry_run() {
    print_test "Dry-run mode (--dry-run flag)"

    setup_test_env

    # Run in dry-run mode
    if HOME="$TEST_HOME" bash "$ROLLBACK_SCRIPT" --dry-run 2>&1 | grep -q "DRY RUN"; then
        # Verify no changes were made
        if [ -L "$TEST_HOME/.aliases" ]; then
            pass "Dry-run mode: no changes made"
            return 0
        else
            fail "Dry-run mode made changes"
            return 1
        fi
    else
        fail "Dry-run mode not implemented"
        return 1
    fi
}

# Main test execution
main() {
    print_header "Rollback Script Test Suite"
    echo "Test home:      $TEST_HOME"
    echo "Dotfiles:       $DOTFILES_DIR"
    echo "Rollback script: $ROLLBACK_SCRIPT"

    # Run tests
    test_script_exists || true
    test_script_executable || true
    test_find_latest_backup || true
    test_no_backup_error || true
    test_noninteractive_rollback || true
    test_symlink_removal || true
    test_file_content_preservation || true
    test_permission_preservation || true
    test_dry_run || true

    # Print summary
    print_header "Test Summary"
    echo "Total tests:  $TESTS_TOTAL"
    echo -e "Passed:       ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed:       ${RED}$TESTS_FAILED${NC}"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ All tests passed!${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}✗ Some tests failed${NC}"
        return 1
    fi
}

# Run main function
main
exit $?
