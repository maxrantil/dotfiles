#!/bin/bash
# ABOUTME: Behaviour and performance tests for the zsh config (safe_source, startup time)
# Usage: ./tests/zsh-config-test.sh [dotfiles_dir]   (requires zsh)

set -uo pipefail

DOTFILES_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# Startup budget in ms (README promises <100ms; CI runners are slower than laptops)
BUDGET_MS="${ZSH_STARTUP_BUDGET_MS:-100}"
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
check() {
    local desc="$1"
    shift
    if "$@"; then pass "$desc"; else fail "$desc"; fi
}

if ! command -v zsh > /dev/null 2>&1; then
    echo "zsh not installed; skipping" >&2
    exit 0
fi

HOME=$(mktemp -d)
export HOME
trap 'rm -rf "$HOME"' EXIT
bash "$DOTFILES_DIR/install.sh" > /dev/null 2>&1 || {
    echo "install.sh failed" >&2
    exit 1
}

zi() { zsh -i -c "$1" < /dev/null 2> "$HOME/stderr"; }
zl() { zsh -l -i -c "$1" < /dev/null 2> /dev/null; }

echo "Test 1: interactive shell starts cleanly"
zi 'exit' > /dev/null
check "no warnings on startup" test ! -s "$HOME/stderr"
[ -s "$HOME/stderr" ] && sed 's/^/    /' "$HOME/stderr"

echo "Test 2: aliases and bookmark shortcuts load through safe_source"
check "alias gs defined" test "$(zi 'alias gs')" = "gs='git status --short --branch'"
check "shortcut cf defined" test -n "$(zi 'alias cf')"

echo "Test 3: safe_source security checks"
mkdir -p "$HOME/t"
echo 'SOURCED=yes' > "$HOME/t/ok"
chmod 664 "$HOME/t/ok"
check "group-writable (664) file accepted" test "$(zi "safe_source $HOME/t/ok && echo \$SOURCED")" = "yes"
cp "$HOME/t/ok" "$HOME/t/ww" && chmod 666 "$HOME/t/ww"
check "world-writable file rejected" test -z "$(zi "safe_source $HOME/t/ww; echo \${SOURCED:-}")"
cp "$HOME/t/ok" "$HOME/t/suid" && chmod 4644 "$HOME/t/suid"
check "setuid file rejected" test -z "$(zi "safe_source $HOME/t/suid; echo \${SOURCED:-}")"
ln -s "$HOME/t/ww" "$HOME/t/link-to-ww"
check "symlink to unsafe file rejected" test -z "$(zi "safe_source $HOME/t/link-to-ww; echo \${SOURCED:-}")"
check "path with metacharacters rejected" test -z "$(zi "safe_source '$HOME/t/ok;x'; echo \${SOURCED:-}")"
check "missing file rejected" test "$(zi "safe_source $HOME/t/nope; echo \$?")" = "1"
if [ "$(id -u)" -eq 0 ]; then
    chown 65534 "$HOME/t/ok"
    check "file owned by another user rejected" test -z "$(zi "safe_source $HOME/t/ok 2>/dev/null; echo \${SOURCED:-}")"
fi

echo "Test 4: environment hygiene"
check "os-release variables don't leak" test -z "$(zi 'echo ${VERSION_ID:-}${PRETTY_NAME:-}')"
dup=$(zsh -i -c 'zsh -i -c "print -l \${(s/:/)PATH}"' < /dev/null 2> /dev/null | sort | uniq -d)
check "no duplicate PATH entries in nested shells" test -z "$dup"
check "man page colors contain a real escape byte" test "$(zl 'printf %s "$LESS_TERMCAP_mb"' | od -An -c | tr -d ' \n')" = '033[1;31m'

echo "Test 5: completion cache"
zi 'exit' > /dev/null
dump="$HOME/.config/zsh/.zcompdump"
check "zcompdump created in ZDOTDIR" test -s "$dump"
before=$(stat -c %Y "$dump")
sleep 1
zi 'exit' > /dev/null
check "fresh dump is not rebuilt on next start" test "$(stat -c %Y "$dump")" = "$before"

echo "Test 6: startup time (budget ${BUDGET_MS}ms)"
for _ in 1 2 3; do zi 'exit' > /dev/null; done
median=$(
    for _ in $(seq 15); do
        s=$(date +%s%N)
        zsh -i -c exit < /dev/null > /dev/null 2>&1
        e=$(date +%s%N)
        echo $(((e - s) / 1000000))
    done | sort -n | sed -n 8p
)
echo "  median startup: ${median}ms"
check "median startup under budget" test "$median" -lt "$BUDGET_MS"

echo ""
echo "Passed: $PASSED  Failed: $FAILED"
[ "$FAILED" -eq 0 ]
