##### Project shortcuts
# This file is for generic project discovery logic.
# Put specific project shortcuts in ~/.zshrc.d/ or ~/.zshrc.local

project_cd() {
  local project_name="${1:-}"
  if [[ -z "$project_name" ]]; then
    echo "Usage: project_cd <project-name>"
    return 1
  fi
  cd "$HOME/Projects/$project_name" || return 1
}
