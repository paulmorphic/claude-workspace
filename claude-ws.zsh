# claude-ws.zsh — interactive workspace picker for the `claude` CLI
#
# `claude-ws` lists the *.code-workspace files in your workspace folder
# (one level only, no recursive search),
# lets you pick one from an arrow-key menu with substring search (fzf),
# then starts `claude` in the first folder of that workspace with every
# other folder passed as --add-dir. The `claude` command itself is never
# touched.
#
# Workspace files stay plain VS Code files — nothing is injected into them.
#
# Requires zsh + jq + fzf. Designed for macOS.
# Requires CLAUDE_WORKSPACE_DIRS: the folder(s) holding your workspace files
# (colon-separated, e.g. "/path/to/workspaces:/another/folder").

claude-ws() {
  [[ -n "$CLAUDE_WORKSPACE_DIRS" ]] || {
    echo "claude-ws: CLAUDE_WORKSPACE_DIRS is not set" >&2
    echo "  add to ~/.zshrc: export CLAUDE_WORKSPACE_DIRS=\"/path/to/workspaces\"" >&2
    return 1
  }

  command -v fzf >/dev/null 2>&1 || {
    echo "claude-ws: fzf is not installed — brew install fzf" >&2
    return 1
  }
  command -v jq >/dev/null 2>&1 || {
    echo "claude-ws: jq is not installed — brew install jq" >&2
    return 1
  }

  # Folders holding the *.code-workspace files (colon-separated). Only these
  # folders themselves are listed — subfolders are never searched.
  local ws_dirs=("${(@s/:/)CLAUDE_WORKSPACE_DIRS}")

  local found files choice
  found=("${(f)$(find "${ws_dirs[@]}" -maxdepth 1 -type f -name '*.code-workspace' 2>/dev/null)}")

  (( ${#found} )) && [[ -n "${found[1]}" ]] || {
    echo "claude-ws: no .code-workspace files found in ${ws_dirs[*]}" >&2
    echo "  create one in VS Code (File → Save Workspace As…), or point CLAUDE_WORKSPACE_DIRS elsewhere" >&2
    return 1
  }

  # Newest first, duplicates removed. ANSI color codes are stripped —
  # ls emits them even into pipes when CLICOLOR_FORCE is set, and they
  # would leak into the menu as raw text.
  files=("${(f)$(command ls -1dt -- "${found[@]}" 2>/dev/null | sed $'s/\e\[[0-9;]*m//g' | awk '!seen[$0]++')}")

  choice=$(print -l -- "${files[@]}" | fzf --layout=reverse --exact \
    --height ~50% --border \
    --prompt 'Search › ' \
    --header 'Enter to pick, Esc to quit' \
    --delimiter / --with-nth=-2..)
  [[ -n "$choice" ]] || return 0

  # First folder becomes the working directory, the rest become --add-dir.
  # Every path is resolved to an absolute, normalized form: relative paths
  # (e.g. ../api) are taken relative to the workspace file, as VS Code does,
  # and a leading ~ is expanded.
  local base dirs first d i args=()
  base="${choice:A:h}"

  if ! dirs=("${(f)$(jq -r '.folders[]?.path // empty' "$choice" 2>/dev/null)}"); then
    echo "claude-ws: cannot read $choice" >&2
    return 1
  fi
  (( ${#dirs} )) && [[ -n "${dirs[1]}" ]] || {
    echo "claude-ws: $choice has no folders" >&2
    return 1
  }

  for i in {1..${#dirs}}; do
    d="${dirs[i]}"
    [[ "$d" == "~" || "$d" == "~/"* ]] && d="$HOME${d#\~}"
    [[ "$d" != /* ]] && d="$base/$d"
    dirs[i]="${d:A}"
  done

  first="${dirs[1]}"
  [[ -d "$first" ]] || {
    echo "claude-ws: $first does not exist" >&2
    return 1
  }

  for d in "${dirs[@]:1}"; do
    [[ -d "$d" ]] || {
      echo "claude-ws: $d does not exist" >&2
      return 1
    }
    args+=(--add-dir "$d")
  done

  # Workspace files are trusted input: every folder listed gets access
  # without a prompt, so show exactly what is being granted.
  echo "→ workspace: $choice"
  echo "→ starting claude in $first"
  for d in "${dirs[@]:1}"; do
    echo "→ add-dir: $d"
  done
  ( cd "$first" && command claude "${args[@]}" "$@" )
}
