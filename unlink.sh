stow -D nvim
stow -D tmux
stow -D aerospace
stow -D zsh

# cursor skills (productivity + engineering)
stow -D --dir=skills --target="$HOME/.cursor/skills" --ignore='README\.md' productivity engineering
