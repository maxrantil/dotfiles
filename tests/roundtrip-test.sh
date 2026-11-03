#!/bin/bash
# ABOUTME: End-to-end install -> rollback tests (backup paths, dry-run, idempotency)
# Usage: ./tests/roundtrip-test.sh [dotfiles_dir]

set -uo pipefail

DOTFILES_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PASSED=0
FAILED=0

pass() {
    PASSED=$((PASSED + 1))
    echo "  PASS: $1"
}
fail() {
    FAILED=$((FAILED + 1))
    echo "  FAIL: $1" >&2
}
check() { # check <description> <command...>
    local desc="$1"
    shift
    if "$@"; then pass "$desc"; else fail "$desc"; fi
}

new_home() {
    TEST_HOME=$(mktemp -d)
    export HOME="$TEST_HOME"
}
cleanup() { rm -rf "$TEST_HOME"; }

install_q() { bash "$DOTFILES_DIR/install.sh" "$@" > /dev/null 2>&1; }
rollback_q() { bash "$DOTFILES_DIR/rollback.sh" "$@" > /dev/null 2>&1; }
backup_count() { find "$HOME" -maxdepth 1 -name '.dotfiles_backup_*' -type d | wc -l; }

echo "Test 1: dry run changes nothing"
new_home
echo "mine" > "$HOME/.aliases"
install_q --dry-run
check "dry run exits 0" test $? -eq 0
check "existing file untouched" test "$(cat "$HOME/.aliases")" = "mine"
check "no symlinks created" test ! -L "$HOME/.zshenv"
check "no backup dir created" test "$(backup_count)" -eq 0
cleanup

echo "Test 2: nested files are backed up and restored to their original paths"
new_home
mkdir -p "$HOME/.config/nvim" "$HOME/.config/zsh"
echo "my vim" > "$HOME/.config/nvim/init.vim"
echo "my zshrc" > "$HOME/.config/zsh/.zshrc"
echo "my env" > "$HOME/.zshenv"
install_q
check "init.vim is now a symlink" test -L "$HOME/.config/nvim/init.vim"
backup=$(find "$HOME" -maxdepth 1 -name '.dotfiles_backup_*' -type d | head -1)
check "backup keeps nested path" test -f "$backup/.config/nvim/init.vim"
rollback_q -y
check "init.vim restored in place" test "$(cat "$HOME/.config/nvim/init.vim" 2> /dev/null)" = "my vim"
check "ZDOTDIR .zshrc restored in place" test "$(cat "$HOME/.config/zsh/.zshrc" 2> /dev/null)" = "my zshrc"
check ".zshenv restored" test "$(cat "$HOME/.zshenv" 2> /dev/null)" = "my env"
check "no stray ~/init.vim" test ! -e "$HOME/init.vim"
check "starship symlink removed" test ! -L "$HOME/.config/starship.toml"
check "backup dir removed" test "$(backup_count)" -eq 0
cleanup

echo "Test 3: re-running install is a no-op"
new_home
install_q
install_q
check "second run creates no backup" test "$(backup_count)" -eq 0
check "links still correct" test "$(readlink "$HOME/.aliases")" = "$DOTFILES_DIR/.aliases"
cleanup

echo "Test 4: a foreign symlink is backed up, not deleted"
new_home
echo "elsewhere" > "$HOME/other-aliases"
ln -s "$HOME/other-aliases" "$HOME/.aliases"
install_q
backup=$(find "$HOME" -maxdepth 1 -name '.dotfiles_backup_*' -type d | head -1)
check "foreign symlink kept in backup" test -L "$backup/.aliases"
rollback_q -y
check "foreign symlink restored" test "$(readlink "$HOME/.aliases")" = "$HOME/other-aliases"
cleanup

echo "Test 5: old flat backups restore to the managed location"
new_home
install_q
mkdir -p "$HOME/.dotfiles_backup_20250101_120000"
echo "old vim" > "$HOME/.dotfiles_backup_20250101_120000/init.vim"
rollback_q -y
check "flat init.vim goes to ~/.config/nvim" test "$(cat "$HOME/.config/nvim/init.vim" 2> /dev/null)" = "old vim"
cleanup

echo "Test 6: rollback never overwrites a real file"
new_home
echo "first" > "$HOME/.aliases"
install_q
rm "$HOME/.aliases"
echo "newer" > "$HOME/.aliases"
rollback_q -y
check "newer file kept" test "$(cat "$HOME/.aliases")" = "newer"
check "backup kept because item was skipped" test "$(backup_count)" -eq 1
cleanup

echo "Test 7: unknown option is rejected"
new_home
install_q --bogus
check "install rejects unknown flag" test $? -ne 0
cleanup

echo "Test 8: obsolete ~/.zprofile link from older installs is removed"
new_home
ln -s "$DOTFILES_DIR/.zprofile" "$HOME/.zprofile"
install_q
check "legacy ~/.zprofile link removed" test ! -e "$HOME/.zprofile"
check ".zprofile linked in ZDOTDIR" test -L "$HOME/.config/zsh/.zprofile"
# Never write through a leftover link: that would modify the repo's own file
rm -f "$HOME/.zprofile"
echo "keep" > "$HOME/.zprofile"
install_q
check "a real ~/.zprofile is never removed" test "$(cat "$HOME/.zprofile")" = "keep"
cleanup

echo "Test 9: an XDG_CONFIG_HOME outside \$HOME does not break install"
new_home
XDG_CONFIG_HOME=/nonexistent/.config install_q
check "install succeeds" test $? -eq 0
check ".zshrc linked in \$HOME/.config/zsh (what .zshenv sets)" test -L "$HOME/.config/zsh/.zshrc"
cleanup

echo ""
echo "Passed: $PASSED  Failed: $FAILED"
[ "$FAILED" -eq 0 ]
