#!/bin/bash
# ABOUTME: Docker-based automated testing for dotfiles

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE_NAME="dotfiles-test"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Dotfiles Docker Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Build Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
docker build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile" "$DOTFILES_DIR"

echo ""
echo -e "${GREEN}✓ Docker image built successfully${NC}"
echo ""

# Test 1: Verify shell startup works
echo -e "${YELLOW}Test 1: Shell startup verification${NC}"
if docker run --rm "$IMAGE_NAME" zsh -i -c 'echo "Shell initialized successfully"' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Shell startup works${NC}"
else
    echo -e "${RED}✗ Shell startup failed${NC}"
    exit 1
fi

# Test 2: Verify Starship is available
echo -e "${YELLOW}Test 2: Starship availability${NC}"
if docker run --rm "$IMAGE_NAME" zsh -i -c 'command -v starship' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Starship is available${NC}"
else
    echo -e "${RED}✗ Starship not found${NC}"
    exit 1
fi

# Test 3: Verify Starship cache creation (Issue #7)
echo -e "${YELLOW}Test 3: Starship cache creation (Issue #7)${NC}"
CACHE_TEST=$(docker run --rm "$IMAGE_NAME" zsh -i -c '
    # Check if cache file exists
    if [[ -f "${XDG_CACHE_HOME:-$HOME/.cache}/starship/init.zsh" ]]; then
        echo "CACHE_EXISTS"
    else
        echo "CACHE_MISSING"
    fi
' 2> /dev/null)

if [[ "$CACHE_TEST" =~ "CACHE_EXISTS" ]]; then
    echo -e "${GREEN}✓ Starship cache created successfully${NC}"
else
    echo -e "${RED}✗ Starship cache was not created${NC}"
    echo -e "${YELLOW}  Debug: CACHE_TEST='$CACHE_TEST'${NC}"
    exit 1
fi

# Test 4: Measure shell startup time
echo -e "${YELLOW}Test 4: Shell startup performance${NC}"
STARTUP_TIME=$(docker run --rm "$IMAGE_NAME" bash -c 'time zsh -i -c exit' 2>&1 | grep real | awk "{print \$2}")
echo -e "${BLUE}  Startup time: ${STARTUP_TIME}${NC}"

# Test 5: Verify symlinks were created
echo -e "${YELLOW}Test 5: Dotfiles symlinks${NC}"
SYMLINK_TEST=$(docker run --rm "$IMAGE_NAME" zsh -c '
    if [[ -L ~/.zshrc && -L ~/.tmux.conf ]]; then
        echo "SYMLINKS_OK"
    else
        echo "SYMLINKS_MISSING"
    fi
' 2> /dev/null)

if [[ "$SYMLINK_TEST" =~ "SYMLINKS_OK" ]]; then
    echo -e "${GREEN}✓ Dotfiles symlinks created${NC}"
else
    echo -e "${RED}✗ Dotfiles symlinks missing${NC}"
    echo -e "${YELLOW}  Debug: SYMLINK_TEST='$SYMLINK_TEST'${NC}"
    exit 1
fi

# Test 6: Interactive shell test (optional)
if [[ "${1:-}" == "--interactive" ]]; then
    echo ""
    echo -e "${BLUE}Launching interactive shell for manual testing...${NC}"
    echo -e "${YELLOW}Exit with 'exit' or Ctrl+D${NC}"
    echo ""
    docker run --rm -it "$IMAGE_NAME" zsh -i
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  All tests passed! ✓${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Usage:${NC}"
echo -e "  ${YELLOW}./tests/docker-test.sh${NC}              # Run automated tests"
echo -e "  ${YELLOW}./tests/docker-test.sh --interactive${NC} # Run tests + interactive shell"
echo ""
