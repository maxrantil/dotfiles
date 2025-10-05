# Dotfiles

Minimal dotfiles for Ubuntu servers. Managed via git + symlinks.

## Quick Install

```bash
git clone https://github.com/maxrantil/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## What's Included

- `.zshrc` - Vi mode, starship prompt, fzf integration
- `.aliases` - Universal aliases + distro-specific (auto-detected)
- `init.vim` - Gruvbox, NERDTree, Git integration, FZF, ALE
- `.gitconfig` - Delta pager, useful git aliases
- `starship.toml` - Clean prompt config

## Dependencies

Installed via ansible playbook or manually:

```bash
sudo apt install zsh neovim git curl bat fzf ripgrep
curl -sS https://starship.rs/install.sh | sh
chsh -s $(which zsh)
```

## Usage

Edit configs in repo, push changes:

```bash
cd ~/.dotfiles
vim .aliases
git add . && git commit -m "update" && git push
```

Pull on other machines to sync:

```bash
cd ~/.dotfiles && git pull
```

Symlinks keep everything in sync automatically.
