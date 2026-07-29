# shellcheck shell=bash
# shellcheck disable=SC2034  # consumed by run_package in lib/dotfiles.sh
# tree-sitter-cli: parser generator required by nvim-treesitter's `main`
# branch to compile parsers (the `master` branch did not need it).
brew=(neovim ripgrep fd git cmake markdownlint-cli2 tree-sitter-cli)
