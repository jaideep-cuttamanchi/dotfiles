# ============================================================================
# Zsh Configuration - Modular Setup
# ============================================================================
# Configuration is split into multiple files for better organization:
#   - path.zsh       : PATH configuration
#   - agent-env.zsh  : MCP / Cursor harness / skill credentials (local secrets)
#   - oh-my-zsh.zsh  : Oh My Zsh framework and plugins
#   - plugins.zsh    : Post-load plugin configuration (fzf, etc.)
#   - options.zsh    : Shell options, history, and prompt
#   - aliases.zsh    : Command aliases
#   - tools.zsh      : External development tools (pyenv, jenv, docker, etc.)
#
# To edit configuration, modify the relevant file in ~/.config/zsh/
# or use: zshconfig

# Get the directory where this .zshrc is located
ZDOTDIR="${HOME}/.config/zsh"

# If config files are in the same directory as .zshrc (for dotfiles setup)
if [[ -f "${HOME}/.zshrc" ]]; then
  ZCONFIG_DIR="$(dirname $(readlink -f ${HOME}/.zshrc 2>/dev/null || echo ${HOME}/.zshrc))"
else
  ZCONFIG_DIR="${ZDOTDIR}"
fi

# Source configuration files in order
source "${ZCONFIG_DIR}/path.zsh"
source "${ZCONFIG_DIR}/agent-env.zsh"
source "${ZCONFIG_DIR}/oh-my-zsh.zsh"
source "${ZCONFIG_DIR}/plugins.zsh"
source "${ZCONFIG_DIR}/options.zsh"
source "${ZCONFIG_DIR}/aliases.zsh"
source "${ZCONFIG_DIR}/tools.zsh"

# Added by Asato-in-a-Box installer
export PATH="$HOME/bin:$PATH"

# AiB completions (must be before compinit)
fpath=("/opt/homebrew/share/zsh/site-functions" $fpath)
autoload -U compinit && compinit
