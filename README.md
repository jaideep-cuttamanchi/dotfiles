# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). A single `dotfiles.sh` orchestrator reads a declarative `package.sh` manifest from each package directory, installs Homebrew dependencies, stows config into `$HOME` (or other targets), and runs any package-specific setup hooks.

## Prerequisites

- macOS (aerospace is macOS-only; other packages work on Linux with minor tweaks)
- [Homebrew](https://brew.sh)
- **Windows:** go fuck yourself

## Quick start

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./dotfiles.sh link
```

That links everything. To link specific packages:

```bash
./dotfiles.sh link tmux zsh
./dotfiles.sh link tmux          # a single package
```

To remove symlinks:

```bash
./dotfiles.sh unlink             # all packages
./dotfiles.sh unlink nvim        # one package
```

## Packages

| Package | Stow target | Brew deps | Extra setup |
|---------|-------------|-----------|-------------|
| `nvim` | `~/.config/nvim` | stow, neovim, ripgrep, fd, git, cmake | Lazy.nvim installs plugins on first launch |
| `tmux` | `~/.config/tmux` | stow, tmux, git, JetBrains Mono Nerd Font | TPM + plugins (Dracula) |
| `wezterm` | `~/.config/wezterm` | stow, wezterm, JetBrains Mono Nerd Font | — |
| `zsh` | `~/.zshrc`, `~/*.zsh` | stow, git, fzf | oh-my-zsh, zsh-vi-mode |
| `aerospace` | `~/.config/aerospace` | stow, `nikitabobko/tap/aerospace` (cask) | — |
| `skills` | agent skill dirs (see below) | stow, task, taskwarrior-tui | stows into multiple targets |

See per-package READMEs (`aerospace/`, `nvim/`, `tmux/`, `wezterm/`, `zsh/`, `skills/`, `lib/`).

## Layout

```
dotfiles/
├── dotfiles.sh               # directional orchestrator (link|unlink)
├── lib/dotfiles.sh           # package runner + stow/brew helpers
├── nvim/       package.sh    # per-package manifest (brew/casks/taps/hooks)
├── tmux/       package.sh
├── wezterm/    package.sh
├── zsh/        package.sh
├── aerospace/  package.sh
└── skills/
    ├── package.sh            # manifest (sets stow_targets from skill-targets.sh)
    ├── skill-targets.sh      # where skills get stowed
    └── engineering/ …        # skill content
```

Each `package.sh` is a small data file declaring `brew`, `casks`, `taps`,
`stow_targets`, and optional `post_link` / `post_unlink` hooks. The runner in
`lib/dotfiles.sh` adds `stow` automatically and applies the manifest.

## Skills

Agent skills are stowed from `skills/` into every path listed in `skills/skill-targets.sh`:

```bash
# skills/skill-targets.sh
skill_targets=(
  "$HOME/.cursor/skills"
  "$HOME/.claude/skills"
  "$HOME/skills"
)
```

Edit that file to add or remove targets, then re-run `./dotfiles.sh link skills`. The `skills/package.sh` manifest sources `skill-targets.sh` and sets `stow_targets`, so the multi-target stow flows through the shared runner.

## Secrets

Zsh agent/MCP credentials live in `zsh/agent-env.local.zsh` (gitignored). Copy from `zsh/agent-env.local.zsh.example` after linking.

## Notes

- **tmux prefix:** `Ctrl-s` (not the default `Ctrl-b`). Install plugins with `prefix + I`.
- **unlink** removes stow symlinks only; it does not uninstall Homebrew packages, oh-my-zsh, TPM, or cloned plugins.
- **tmux plugins** are gitignored under `tmux/.config/tmux/plugins/`; TPM installs them to `~/.config/tmux/plugins/` at link time.
