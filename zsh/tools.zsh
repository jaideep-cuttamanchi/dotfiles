# External tools integration
# This file handles initialization and configuration for development tools

# =============================================================================
# Homebrew completions (covers most CLIs automatically: gh, helm, kubectl,
# docker, atlas, terraform, etc. - anything that ships a static zsh
# completion via its homebrew formula)
# =============================================================================
if command -v brew &> /dev/null; then
  fpath=($(brew --prefix)/share/zsh/site-functions $fpath)
fi

# =============================================================================
# Docker
# =============================================================================
# Docker Desktop CLI completions
if [[ -d "$HOME/.docker/completions" ]]; then
  fpath=($HOME/.docker/completions $fpath)
fi

# =============================================================================
# Generic "completion zsh" tools (for CLIs not covered by homebrew's
# site-functions, e.g. installed via go install / curl script / npm).
# Cached to disk so we don't shell out to every binary on every startup.
# Add new tool names to the array below.
# =============================================================================
ZSH_DYNAMIC_COMPLETION_TOOLS=(gh kubectl helm terraform aws flux argocd k3d kind)
ZSH_COMPLETION_CACHE_DIR="${ZDOTDIR:-$HOME/.config/zsh}/.completions"

if [[ ! -d "$ZSH_COMPLETION_CACHE_DIR" ]]; then
  mkdir -p "$ZSH_COMPLETION_CACHE_DIR"
fi

for tool in "${ZSH_DYNAMIC_COMPLETION_TOOLS[@]}"; do
  if command -v "$tool" &> /dev/null; then
    cache_file="$ZSH_COMPLETION_CACHE_DIR/_$tool"
    tool_path="$(command -v "$tool")"
    # Regenerate if missing or the binary is newer than the cached completion
    if [[ ! -f "$cache_file" || "$tool_path" -nt "$cache_file" ]]; then
      tmp_file="$(mktemp "$ZSH_COMPLETION_CACHE_DIR/.${tool}.XXXXXX")"
      if "$tool" completion zsh > "$tmp_file" 2>/dev/null && [[ -s "$tmp_file" ]]; then
        mv "$tmp_file" "$cache_file"
      else
        rm -f "$tmp_file"
      fi
    fi
  fi
done
fpath=($ZSH_COMPLETION_CACHE_DIR $fpath)
unset tool cache_file tool_path tmp_file

# =============================================================================
# Python - pyenv
# =============================================================================
# Python version manager
if command -v pyenv &> /dev/null; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  pyenv() {
    unfunction pyenv
    eval "$(command pyenv init -)"
    pyenv "$@"
  }
fi

# =============================================================================
# Java - jenv
# =============================================================================
# Java version manager
if command -v jenv &> /dev/null; then
  eval "$(jenv init -)"
  [[ ! -e "$HOME/.jenv/plugins/maven" ]] && jenv enable-plugin maven
fi

# =============================================================================
# Kubernetes - kubebuilder
# =============================================================================
# kubebuilder autocompletion
if command -v kubebuilder &> /dev/null; then
  source <(kubebuilder completion zsh)
fi

# =============================================================================
# zoxide - smarter cd
# =============================================================================
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

# =============================================================================
# Completion System
# =============================================================================
# Initialize completion system (must be done after modifying fpath).
# Only rebuild the dump file once every 24h; otherwise use it as-is (-C skips
# the security check + fpath rescan, which is the slow part).
autoload -Uz compinit
zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -n "$zcompdump"(#qN.mh+24) ]]; then
  compinit -d "$zcompdump"
else
  compinit -C -d "$zcompdump"
fi
unset zcompdump
