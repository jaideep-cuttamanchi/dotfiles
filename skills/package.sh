# shellcheck shell=bash
# shellcheck disable=SC2034  # consumed by run_package in lib/dotfiles.sh
# shellcheck source=skill-targets.sh
source "$DOTFILES_DIR/skills/skill-targets.sh"

# Split targets by kind: "stow" targets go through the generic stow loop in
# run_package as before; "flatten" targets are handled below via post_link/
# post_unlink, symlinking each individual skill dir directly instead of the
# category folder that contains it.
stow_targets=()
flatten_targets=()
for _entry in "${skill_targets[@]}"; do
  case "$_entry" in
    *:flatten) flatten_targets+=("${_entry%:flatten}") ;;
    *:stow) stow_targets+=("${_entry%:stow}") ;;
    *) log_error "skills: unknown target kind in '$_entry'" ;;
  esac
done
unset _entry

_skill_dirs() {
  find "$DOTFILES_DIR/skills" -mindepth 3 -maxdepth 3 -name SKILL.md -exec dirname {} \;
}

post_link() {
  [ ${#flatten_targets[@]} -eq 0 ] && return 0
  local dir name target
  while IFS= read -r dir; do
    name="$(basename "$dir")"
    for target in "${flatten_targets[@]}"; do
      mkdir -p "$target"
      ln -sfn "$dir" "$target/$name"
    done
  done < <(_skill_dirs)
}

post_unlink() {
  [ ${#flatten_targets[@]} -eq 0 ] && return 0
  local dir name target
  while IFS= read -r dir; do
    name="$(basename "$dir")"
    for target in "${flatten_targets[@]}"; do
      [ -L "$target/$name" ] && rm "$target/$name"
    done
  done < <(_skill_dirs)
}
