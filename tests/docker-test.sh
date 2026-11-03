#!/bin/bash
# ABOUTME: Docker-based fresh-machine test: build, install, then run the test suites inside
# Usage: ./tests/docker-test.sh [--distro ubuntu|arch] [--interactive]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DISTRO="ubuntu"
INTERACTIVE=false

while [ $# -gt 0 ]; do
    case "$1" in
        --distro)
            DISTRO="${2:-}"
            shift
            ;;
        --interactive) INTERACTIVE=true ;;
        -h | --help)
            echo "Usage: $0 [--distro ubuntu|arch] [--interactive]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
    shift
done

case "$DISTRO" in
    ubuntu) DOCKERFILE="$SCRIPT_DIR/Dockerfile" ;;
    arch) DOCKERFILE="$SCRIPT_DIR/Dockerfile.arch" ;;
    *)
        echo "Unsupported distro: $DISTRO (use ubuntu or arch)" >&2
        exit 2
        ;;
esac
IMAGE_NAME="dotfiles-test-$DISTRO"

ok() { echo -e "${GREEN}✓ $1${NC}"; }
die() {
    echo -e "${RED}✗ $1${NC}" >&2
    exit 1
}
in_container() { docker run --rm "$IMAGE_NAME" "$@"; }

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Dotfiles Docker Test Suite ($DISTRO)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}Building image (includes ./install.sh as a normal user)...${NC}"
docker build -t "$IMAGE_NAME" -f "$DOCKERFILE" "$DOTFILES_DIR"
ok "Image built and install.sh succeeded"

echo -e "${YELLOW}Test 1: interactive shell starts without errors${NC}"
errors=$(in_container zsh -i -c 'exit' 2>&1 > /dev/null || true)
[ -z "$errors" ] || die "Shell printed errors on startup: $errors"
ok "Shell starts cleanly"

echo -e "${YELLOW}Test 2: zsh files live in ZDOTDIR and are linked${NC}"
in_container zsh -c '[[ -L $ZDOTDIR/.zshrc && -L $ZDOTDIR/.zprofile && -L ~/.zshenv && -L ~/.tmux.conf ]]' ||
    die "Expected symlinks missing"
ok "Symlinks in place"

echo -e "${YELLOW}Test 3: login shell loads .zprofile${NC}"
[ -n "$(in_container zsh -l -c 'print -r -- $FZF_DEFAULT_OPTS')" ] || die ".zprofile not loaded"
ok ".zprofile loaded"

echo -e "${YELLOW}Test 4: starship prompt is cached${NC}"
in_container zsh -i -c '[[ -s ${XDG_CACHE_HOME:-$HOME/.cache}/starship/init.zsh ]]' ||
    die "Starship cache was not created"
ok "Starship cache created"

echo -e "${YELLOW}Test 5: tmux starts with the config${NC}"
in_container sh -c 'tmux -f ~/.tmux.conf new-session -d -s t "sleep 1" && tmux kill-server' ||
    die "tmux failed to start"
ok "tmux starts"

echo -e "${YELLOW}Test 6: test suites as a non-root user${NC}"
in_container bash -c '
    set -e
    cd ~/.dotfiles
    ./tests/zsh-config-test.sh
    ./tests/roundtrip-test.sh
    ./tests/rollback-test.sh < /dev/null
' || die "Test suites failed inside the container"
ok "All suites pass inside the container"

if [ "$INTERACTIVE" = true ]; then
    echo ""
    echo -e "${BLUE}Launching interactive shell (exit with Ctrl+D)...${NC}"
    docker run --rm -it "$IMAGE_NAME" zsh -i
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  All Docker tests passed ($DISTRO) ✓${NC}"
echo -e "${GREEN}========================================${NC}"
