#!/usr/bin/env bash
# Ensure Taskwarrior + taskwarrior-tui are installed and initialised.
# Safe to run repeatedly; prints "ok" when everything is ready.
set -euo pipefail

missing=()
command -v task >/dev/null 2>&1 || missing+=(task)
command -v taskwarrior-tui >/dev/null 2>&1 || missing+=(taskwarrior-tui)

if ((${#missing[@]})); then
  if ! command -v brew >/dev/null 2>&1; then
    echo "missing: ${missing[*]} — install Homebrew or install these manually" >&2
    exit 1
  fi
  echo "installing: ${missing[*]}"
  brew install "${missing[@]}"
fi

# Taskwarrior prompts interactively on first run when ~/.taskrc is absent.
if [[ ! -f "$HOME/.taskrc" ]]; then
  cat >"$HOME/.taskrc" <<'EOF'
# Created by the todo skill
data.location=~/.task
confirmation=off
EOF
  echo "created ~/.taskrc"
fi

task rc.verbose=nothing count >/dev/null
echo "ok: $(task --version), taskwarrior-tui $(taskwarrior-tui --version 2>/dev/null | awk '{print $NF}')"
