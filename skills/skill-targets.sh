# shellcheck shell=bash
# Agent skill targets for skills/link.sh and skills/unlink.sh.
# Each entry is "<target>:<kind>":
#   stow    - plain GNU stow of the package as-is (category folders stay
#             nested, e.g. <target>/engineering -> dotfiles/skills/engineering)
#   flatten - symlink each individual skill dir directly into <target>, for
#             loaders that only scan one level deep (e.g. Claude Code, which
#             expects <skills-dir>/<skill>/SKILL.md, not <skills-dir>/<category>/<skill>/SKILL.md)
skill_targets=(
  "$HOME/.cursor/skills:stow"
  "$HOME/.claude/skills:flatten"
  "$HOME/skills:stow"
  "$HOME/.agents/skills/:stow"
)
