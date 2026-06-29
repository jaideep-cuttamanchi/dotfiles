stow nvim
stow tmux
stow aerospace
stow zsh

# cursor skills (productivity + engineering)
mkdir -p "$HOME/.cursor/skills"
stow --restow --dir=skills --target="$HOME/.cursor/skills" --ignore='README\.md' productivity engineering

# oh-my-zsh (skip if already installed; keep our stowed .zshrc)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# zsh-vi-mode
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-vi-mode" ]; then
  mkdir -p "$ZSH_CUSTOM/plugins"
  git clone https://github.com/jeffreytse/zsh-vi-mode "$ZSH_CUSTOM/plugins/zsh-vi-mode"
fi
