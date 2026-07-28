# shellcheck shell=bash
# Shared helpers + package runner for the dotfiles orchestrator.

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Single logging seam. log()/log_error() are prefixed with [_LOG_PREFIX].
_LOG_PREFIX="dotfiles"
init_log() {
  _LOG_PREFIX="$1"
}
log() {
  echo "[${_LOG_PREFIX}] $*"
}
log_error() {
  echo "[${_LOG_PREFIX}] ERROR: $*" >&2
}

# Package management / config files — never stowed into targets.
STOW_IGNORE=(
  --ignore='package\.sh'
  --ignore='skill-targets\.sh'
  --ignore='README\.md'
  --ignore='link\.sh'
  --ignore='unlink\.sh'
)

stow_package() {
  local target="${1:-$HOME}"
  mkdir -p "$target"
  (cd "$DOTFILES_DIR" && stow --restow "${STOW_IGNORE[@]}" --target="$target" "$PACKAGE") || {
    log_error "failed to stow -> $target"
    return 1
  }
}

unstow_package() {
  local target="${1:-$HOME}"
  (cd "$DOTFILES_DIR" && stow -D "${STOW_IGNORE[@]}" --target="$target" "$PACKAGE") || {
    log_error "failed to unstow -> $target"
    return 1
  }
}

require_brew() {
  if ! command -v brew &>/dev/null; then
    log_error "homebrew required — install from https://brew.sh"
    return 1
  fi
}

brew_installed() {
  brew list "$1" &>/dev/null
}

brew_install() {
  require_brew || return 1
  local formula
  for formula in "$@"; do
    if brew_installed "$formula"; then
      log "$formula already installed, skipping"
    else
      log "installing $formula"
      if ! brew install "$formula"; then
        log_error "failed to install $formula"
        return 1
      fi
    fi
  done
}

brew_install_cask() {
  require_brew || return 1
  local cask
  for cask in "$@"; do
    if brew_installed "$cask"; then
      log "$cask already installed, skipping"
    else
      log "installing $cask (cask)"
      if ! brew install --cask "$cask"; then
        log_error "failed to install $cask"
        return 1
      fi
    fi
  done
}

# Tap each argument if not already tapped.
ensure_taps() {
  require_brew || return 1
  local tap
  for tap in "$@"; do
    if brew tap | grep -qx "$tap"; then
      log "tap $tap already present, skipping"
    else
      log "tapping $tap"
      if ! brew tap "$tap"; then
        log_error "failed to tap $tap"
        return 1
      fi
    fi
  done
}

# Deep runner: load a package manifest and apply it in the given direction.
#   run_package <link|unlink> <pkg>
run_package() {
  local direction="$1"
  local pkg="$2"
  local manifest="$DOTFILES_DIR/$pkg/package.sh"

  if [ ! -f "$manifest" ]; then
    log_error "missing manifest $pkg/package.sh"
    return 1
  fi

  # Reset manifest contract to defaults so packages don't inherit each
  # other's values when the orchestrator loops.
  local brew=()
  local casks=()
  local taps=()
  local stow_targets=("$HOME")
  post_link() { :; }
  post_unlink() { :; }

  # shellcheck source=/dev/null
  source "$manifest"

  PACKAGE="$pkg"
  init_log "$pkg"

  local t
  case "$direction" in
    link)
      if [ "$(uname -s)" = Darwin ]; then
        if [ ${#taps[@]} -gt 0 ]; then
          ensure_taps "${taps[@]}" || return 1
        fi
        if [ ${#casks[@]} -gt 0 ]; then
          brew_install_cask "${casks[@]}" || return 1
        fi
      else
        log "not macOS — skipping casks/taps"
      fi

      if [ ${#brew[@]} -gt 0 ]; then
        brew_install stow "${brew[@]}" || return 1
      else
        brew_install stow || return 1
      fi

      if [ ${#stow_targets[@]} -gt 0 ]; then
        for t in "${stow_targets[@]}"; do
          stow_package "$t" || return 1
        done
      fi

      post_link || return 1
      ;;
    unlink)
      post_unlink || return 1

      if [ ${#stow_targets[@]} -gt 0 ]; then
        for t in "${stow_targets[@]}"; do
          unstow_package "$t" || return 1
        done
      fi
      ;;
    *)
      log_error "unknown direction: $direction"
      return 1
      ;;
  esac
}
