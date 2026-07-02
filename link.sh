#!/usr/bin/env bash
set -uo pipefail

fail_count=0

log() {
  echo "[link.sh] $*"
}

log_error() {
  echo "[link.sh] ERROR: $*" >&2
  fail_count=$((fail_count + 1))
}

log "stowing nvim"
stow nvim || log_error "failed to stow nvim"

log "stowing tmux"
stow tmux || log_error "failed to stow tmux"

log "stowing aerospace"
stow aerospace || log_error "failed to stow aerospace"

log "stowing zsh"
stow zsh || log_error "failed to stow zsh"

# skills: stow the whole skills/ folder into every agent's skills dir, so skills/* -> target/*
skill_targets=("$HOME/.cursor/skills" "$HOME/.claude/skills")

for target in "${skill_targets[@]}"; do
  log "preparing skills target: $target"
  mkdir -p "$target"

  log "stowing skills -> $target"
  if ! stow --restow --dir=. --target="$target" --ignore='README\.md' skills; then
    log_error "failed to stow skills -> $target"
  fi
done

# oh-my-zsh (skip if already installed; keep our stowed .zshrc)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "installing oh-my-zsh"
  if ! KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
    log_error "failed to install oh-my-zsh"
  fi
else
  log "oh-my-zsh already installed, skipping"
fi

# zsh-vi-mode
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-vi-mode" ]; then
  log "cloning zsh-vi-mode plugin"
  mkdir -p "$ZSH_CUSTOM/plugins"
  if ! git clone https://github.com/jeffreytse/zsh-vi-mode "$ZSH_CUSTOM/plugins/zsh-vi-mode"; then
    log_error "failed to clone zsh-vi-mode"
  fi
else
  log "zsh-vi-mode already present, skipping"
fi

if [ "$fail_count" -gt 0 ]; then
  log "done with $fail_count error(s)"
  exit 1
fi

log "done, all steps succeeded"
