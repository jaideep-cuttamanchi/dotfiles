#!/usr/bin/env bash
set -uo pipefail

fail_count=0

log() {
  echo "[unlink.sh] $*"
}

log_error() {
  echo "[unlink.sh] ERROR: $*" >&2
  fail_count=$((fail_count + 1))
}

log "unstowing nvim"
stow -D nvim || log_error "failed to unstow nvim"

log "unstowing tmux"
stow -D tmux || log_error "failed to unstow tmux"

log "unstowing aerospace"
stow -D aerospace || log_error "failed to unstow aerospace"

log "unstowing zsh"
stow -D zsh || log_error "failed to unstow zsh"

# skills: unstow the whole skills/ folder from every agent's skills dir
skill_targets=("$HOME/.cursor/skills" "$HOME/.claude/skills")

for target in "${skill_targets[@]}"; do
  log "unstowing skills -> $target"
  if ! stow -D --dir=. --target="$target" --ignore='README\.md' skills; then
    log_error "failed to unstow skills -> $target"
  fi
done

if [ "$fail_count" -gt 0 ]; then
  log "done with $fail_count error(s)"
  exit 1
fi

log "done, all steps succeeded"
