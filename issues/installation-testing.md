## Problem

`install.sh` changes are not tested until VM provisioning (5+ minutes feedback loop). Broken installation script affects all new VMs.

**Current Testing**:
- Manual: Run `install.sh` locally
- VM: Provision test VM with vm-infra
- Docker: Test in container (exists but not automated)

**Gap**: No automated CI testing of installation

## Solution

Add installation testing job to CI that runs `install.sh` in isolated environment.

## Workflow Addition

**File**: `.github/workflows/shell-quality.yml` (ADD JOB)

Add new job to existing workflow:

```yaml
name: Shell Quality Checks
on:
  pull_request:
    branches: [master]

jobs:
  shellcheck:
    # Existing shellcheck job
    uses: maxrantil/.github/.github/workflows/shell-quality-reusable.yml@main
    with:
      shellcheck-severity: 'warning'
      shfmt-options: '-d -i 4 -ci -sr'

  installation-test:
    name: Test Installation Script
    runs-on: ubuntu-latest
    permissions:
      contents: read

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Create temporary home directory
        run: |
          TEMP_HOME=$(mktemp -d)
          echo "TEMP_HOME=$TEMP_HOME" >> $GITHUB_ENV

      - name: Run install.sh in test home
        run: |
          export HOME=$TEMP_HOME
          bash install.sh
        env:
          CI: true

      - name: Verify key symlinks created
        run: |
          # Check critical symlinks exist
          test -L "$TEMP_HOME/.zshrc" || (echo "ERROR: .zshrc not linked" && exit 1)
          test -L "$TEMP_HOME/.aliases" || (echo "ERROR: .aliases not linked" && exit 1)
          test -L "$TEMP_HOME/.config/nvim" || (echo "ERROR: nvim config not linked" && exit 1)
          test -L "$TEMP_HOME/.config/tmux" || (echo "ERROR: tmux config not linked" && exit 1)

      - name: Verify no errors in installation
        run: |
          # If install.sh created error log, fail
          if [ -f "$TEMP_HOME/.dotfiles-install-errors" ]; then
            cat "$TEMP_HOME/.dotfiles-install-errors"
            exit 1
          fi

      - name: Check for broken symlinks
        run: |
          # Find and report broken symlinks
          cd $TEMP_HOME
          find . -type l ! -exec test -e {} \; -print | while read -r broken; do
            echo "ERROR: Broken symlink: $broken"
            exit 1
          done
```

## Installation Script Enhancement

**File**: `install.sh` (OPTIONAL ENHANCEMENT)

Add CI detection and error logging:

```bash
#!/bin/bash

# Detect CI environment
CI_MODE=${CI:-false}

# Error logging
ERROR_LOG="$HOME/.dotfiles-install-errors"
rm -f "$ERROR_LOG"

# Wrapper for critical operations
log_error() {
  echo "[ERROR] $1" | tee -a "$ERROR_LOG" >&2
  if [ "$CI_MODE" = "true" ]; then
    exit 1  # Fail fast in CI
  fi
}

# Example usage in install.sh
ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc" || log_error "Failed to link .zshrc"
```

## Testing Scope

### What to Test
- ✅ install.sh executes without errors
- ✅ Key symlinks created (.zshrc, .aliases, config files)
- ✅ No broken symlinks
- ✅ Directory structure correct (~/.config/*, etc.)

### What NOT to Test (out of scope)
- ❌ Full shell functionality (needs interactive shell)
- ❌ Neovim plugin installation (too slow)
- ❌ Tmux session creation (needs tmux server)
- ❌ ZSH initialization (needs actual zsh)

**Rationale**: CI tests basic installation, VM tests full functionality

## Implementation Checklist

- [ ] Add `installation-test` job to `shell-quality.yml`
- [ ] Test workflow with clean repository
- [ ] Verify symlinks checked correctly
- [ ] Verify broken symlinks detected
- [ ] (Optional) Enhance install.sh with error logging
- [ ] (Optional) Add CI_MODE detection
- [ ] Update README with testing info

## Testing Plan

1. Add installation test job
2. Create test PR
3. Verify installation runs successfully
4. Introduce intentional error:
   - Comment out symlink creation
   - Break path to config file
5. Verify workflow fails appropriately
6. Fix error
7. Verify workflow passes
8. Merge to master

## Benefits

- **Fast Feedback**: Installation errors caught in ~30 seconds vs 5+ minutes
- **Pre-VM Validation**: Know install.sh works before provisioning VM
- **Regression Prevention**: Changes won't break installation
- **CI/CD Best Practice**: Test what you deploy

## Performance

**Expected Duration**:
- Checkout: ~5s
- Create temp home: ~1s
- Run install.sh: ~10s
- Verify symlinks: ~5s
- **Total**: ~20-30 seconds

**Impact on Total CI Time**:
- Before: ~1 minute (shellcheck only)
- After: ~1.5 minutes (shellcheck + installation test)

## Alternative: Docker-based Testing

More comprehensive but slower:

```yaml
installation-test-docker:
  name: Test Installation (Docker)
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Build test container
      run: docker build -t dotfiles-test tests/
    - name: Run installation test
      run: docker run dotfiles-test
```

**Trade-off**: More realistic but ~2-3x slower

**Recommendation**: Start with simple test, add Docker if needed

## Files to Update

- `.github/workflows/shell-quality.yml` (add job)
- `install.sh` (optional: add error logging)
- `README.md` (optional: document testing)

## Acceptance Criteria

- [ ] Installation test job added
- [ ] install.sh runs in temporary home
- [ ] Key symlinks verified
- [ ] Broken symlinks detected
- [ ] Workflow passes on clean install
- [ ] Workflow fails on broken install
- [ ] CI time <2 minutes total

## Priority

**LOW** - Complete in Month 2 (nice-to-have, not critical)

**Rationale**:
- Docker tests already exist (manual)
- vm-infra provides comprehensive integration testing
- Low ROI vs effort for CI automation
