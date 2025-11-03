#!/bin/bash
# ABOUTME: Comprehensive installation test suite for dotfiles
# Tests symlink creation, idempotency, backup functionality, and performance
#
# Usage:
#   ./tests/installation-test.sh [test_home_dir] [dotfiles_dir]
#
# Arguments:
#   test_home_dir  - Directory to use as $HOME for testing (default: temp dir)
#   dotfiles_dir   - Path to dotfiles repository (default: parent of script dir)
#
# Exit codes:
#   0 - All tests passed
#   1 - One or more tests failed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
TEST_HOME="${1:-$(mktemp -d)}"
DOTFILES_DIR="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DIAGNOSTICS_DIR="$TEST_HOME/diagnostics"
WORKSPACE="${GITHUB_WORKSPACE:-$DOTFILES_DIR}"

# Environment isolation: Unset variables that could affect installation behavior
# This prevents tests from inheriting parent environment settings
unset XDG_CONFIG_HOME
unset XDG_DATA_HOME
unset XDG_CACHE_HOME
unset ZDOTDIR

# Create diagnostics directory
mkdir -p "$DIAGNOSTICS_DIR"

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

# Test 1: First installation run
test_first_run() {
    print_test "First installation run"

    export HOME="$TEST_HOME"
    START_TIME=$(date +%s%3N)

    if bash "$DOTFILES_DIR/install.sh" 2>&1 | tee "$DIAGNOSTICS_DIR/install-first-run.log"; then
        END_TIME=$(date +%s%3N)
        FIRST_RUN_DURATION=$((END_TIME - START_TIME))
        echo "$FIRST_RUN_DURATION" > "$DIAGNOSTICS_DIR/first-run-duration.txt"
        pass "Installation completed in ${FIRST_RUN_DURATION}ms"
        return 0
    else
        fail "Installation failed"
        return 1
    fi
}

# Test 2: Verify critical symlinks
test_critical_symlinks() {
    print_test "Verify critical symlinks"

    local errors=0

    # Determine ZDOTDIR location (defaults to $HOME/.config/zsh per .zprofile)
    local zdotdir="${TEST_HOME}/.config/zsh"

    # Check .zshrc in ZDOTDIR location
    if [ ! -L "$zdotdir/.zshrc" ]; then
        fail ".zshrc not linked in ZDOTDIR ($zdotdir)"
        echo "ERROR: .zshrc not linked" >> "$DIAGNOSTICS_DIR/symlink-errors.log"
        errors=$((errors + 1))
    else
        pass ".zshrc (in ZDOTDIR)"
    fi

    # Check other critical symlinks
    local other_links=(".zprofile" ".aliases" ".config/nvim/init.vim" ".tmux.conf" ".config/starship.toml")
    for link in "${other_links[@]}"; do
        if [ ! -L "$TEST_HOME/$link" ]; then
            fail "$link not linked"
            echo "ERROR: $link not linked" >> "$DIAGNOSTICS_DIR/symlink-errors.log"
            errors=$((errors + 1))
        else
            pass "$link"
        fi
    done

    return $errors
}

# Test 3: Verify conditional symlinks
test_conditional_symlinks() {
    print_test "Verify conditional symlinks"

    local errors=0

    # Check .gitconfig
    if [ -f "$WORKSPACE/.gitconfig" ]; then
        if [ ! -L "$TEST_HOME/.gitconfig" ]; then
            fail ".gitconfig not linked (source exists)"
            echo "ERROR: .gitconfig not linked" >> "$DIAGNOSTICS_DIR/symlink-errors.log"
            errors=$((errors + 1))
        else
            pass ".gitconfig"
        fi
    else
        warn ".gitconfig source not found (skipped)"
    fi

    # Check inputrc
    if [ -f "$WORKSPACE/inputrc" ]; then
        if [ ! -L "$TEST_HOME/.config/shell/inputrc" ]; then
            fail "inputrc not linked (source exists)"
            echo "ERROR: inputrc not linked" >> "$DIAGNOSTICS_DIR/symlink-errors.log"
            errors=$((errors + 1))
        else
            pass "inputrc"
        fi
    else
        warn "inputrc source not found (skipped)"
    fi

    return $errors
}

# Test 4: Verify symlink targets
test_symlink_targets() {
    print_test "Verify symlink targets"

    local errors=0

    verify_target() {
        local symlink="$1"
        local expected_target="$2"

        if [ -L "$TEST_HOME/$symlink" ]; then
            local actual_target
            actual_target=$(readlink -f "$TEST_HOME/$symlink")
            if [ "$actual_target" != "$expected_target" ]; then
                fail "$symlink points to $actual_target, expected $expected_target"
                echo "ERROR: $symlink target mismatch" >> "$DIAGNOSTICS_DIR/target-errors.log"
                return 1
            else
                pass "$symlink -> $actual_target"
                return 0
            fi
        else
            fail "$symlink is not a symlink"
            return 1
        fi
    }

    verify_target ".zprofile" "$WORKSPACE/.zprofile" || errors=$((errors + 1))
    verify_target ".aliases" "$WORKSPACE/.aliases" || errors=$((errors + 1))
    verify_target ".config/nvim/init.vim" "$WORKSPACE/init.vim" || errors=$((errors + 1))
    verify_target ".tmux.conf" "$WORKSPACE/.tmux.conf" || errors=$((errors + 1))
    verify_target ".config/starship.toml" "$WORKSPACE/starship.toml" || errors=$((errors + 1))

    return $errors
}

# Test 5: Check for broken symlinks
test_broken_symlinks() {
    print_test "Check for broken symlinks"

    cd "$TEST_HOME"
    if find . -type l ! -exec test -e {} \; -print | grep -q .; then
        fail "Found broken symlinks"
        find . -type l ! -exec test -e {} \; -print | tee "$DIAGNOSTICS_DIR/broken-symlinks.log"
        return 1
    else
        pass "No broken symlinks found"
        return 0
    fi
}

# Test 6: Idempotency (second run)
test_idempotency_run() {
    print_test "Idempotency (second run)"

    export HOME="$TEST_HOME"
    START_TIME=$(date +%s%3N)

    if bash "$DOTFILES_DIR/install.sh" 2>&1 | tee "$DIAGNOSTICS_DIR/install-second-run.log"; then
        END_TIME=$(date +%s%3N)
        SECOND_RUN_DURATION=$((END_TIME - START_TIME))
        echo "$SECOND_RUN_DURATION" > "$DIAGNOSTICS_DIR/second-run-duration.txt"
        pass "Second run completed in ${SECOND_RUN_DURATION}ms"
        return 0
    else
        fail "Second run failed"
        return 1
    fi
}

# Test 7: Verify idempotency (no duplicates)
test_no_duplicates() {
    print_test "Verify no duplicates after second run"

    local errors=0
    local zdotdir="${TEST_HOME}/.config/zsh"

    # Check symlinks still exist
    if [ ! -L "$zdotdir/.zshrc" ]; then
        fail ".zshrc removed during second run"
        errors=$((errors + 1))
    else
        pass ".zshrc still exists"
    fi

    if [ ! -L "$TEST_HOME/.aliases" ]; then
        fail ".aliases removed during second run"
        errors=$((errors + 1))
    else
        pass ".aliases still exists"
    fi

    # Check no duplicate directories
    local config_dirs
    config_dirs=$(find "$TEST_HOME/.config" -type d -name "nvim" 2> /dev/null | wc -l)
    if [ "$config_dirs" -ne 1 ]; then
        fail "Duplicate directories created (found $config_dirs nvim dirs)"
        echo "ERROR: Duplicate directories" >> "$DIAGNOSTICS_DIR/idempotency-errors.log"
        errors=$((errors + 1))
    else
        pass "No duplicate directories"
    fi

    return $errors
}

# Test 8: Backup functionality
test_backup_functionality() {
    print_test "Backup functionality"

    local errors=0
    local zdotdir="${TEST_HOME}/.config/zsh"

    # Create a real file that should be backed up
    echo "test content" > "$TEST_HOME/.test-backup-file"

    # Run install.sh with a file that conflicts
    export HOME="$TEST_HOME"
    bash "$DOTFILES_DIR/install.sh" 2>&1 | tee "$DIAGNOSTICS_DIR/install-backup-test.log" > /dev/null

    # Check if backup directory was created (might not be if no conflicts)
    local backup_dir
    backup_dir=$(find "$TEST_HOME" -maxdepth 1 -name ".dotfiles_backup_*" -type d 2> /dev/null | head -1)

    if [ -n "$backup_dir" ]; then
        pass "Backup directory created: $(basename "$backup_dir")"
    else
        warn "No backup directory created (no conflicts detected)"
    fi

    # Verify symlinks are not backed up (they should be replaced)
    if [ -L "$zdotdir/.zshrc" ]; then
        pass "Symlinks replaced correctly"
    else
        fail ".zshrc is not a symlink after re-installation"
        echo "ERROR: Symlink not replaced" >> "$DIAGNOSTICS_DIR/backup-errors.log"
        errors=$((errors + 1))
    fi

    return $errors
}

# Test 9: Performance regression check
test_performance() {
    print_test "Performance regression check"

    local first_run
    first_run=$(cat "$DIAGNOSTICS_DIR/first-run-duration.txt" 2> /dev/null || echo "0")
    local second_run
    second_run=$(cat "$DIAGNOSTICS_DIR/second-run-duration.txt" 2> /dev/null || echo "0")
    local threshold=30000 # 30 seconds

    echo "Performance metrics:"
    echo "  First run:  ${first_run}ms"
    echo "  Second run: ${second_run}ms"

    # Save metrics
    echo "first_run_ms=$first_run" > "$DIAGNOSTICS_DIR/performance-metrics.txt"
    echo "second_run_ms=$second_run" >> "$DIAGNOSTICS_DIR/performance-metrics.txt"

    if [ "$first_run" -gt "$threshold" ]; then
        warn "First run exceeded ${threshold}ms threshold"
        echo "WARNING: Performance threshold exceeded" >> "$DIAGNOSTICS_DIR/performance-warning.log"
    else
        pass "First run within threshold"
    fi

    if [ "$second_run" -gt "$threshold" ]; then
        warn "Second run exceeded ${threshold}ms threshold"
        echo "WARNING: Performance threshold exceeded" >> "$DIAGNOSTICS_DIR/performance-warning.log"
    else
        pass "Second run within threshold"
    fi

    return 0
}

# Main test execution
main() {
    print_header "Dotfiles Installation Test Suite"
    echo "Test home: $TEST_HOME"
    echo "Dotfiles:  $DOTFILES_DIR"
    echo "Workspace: $WORKSPACE"

    # Run tests
    test_first_run || true
    test_critical_symlinks || true
    test_conditional_symlinks || true
    test_symlink_targets || true
    test_broken_symlinks || true
    test_idempotency_run || true
    test_no_duplicates || true
    test_backup_functionality || true
    test_performance || true

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
        echo "Diagnostics saved to: $DIAGNOSTICS_DIR"
        return 1
    fi
}

# Run main function
main
exit $?
