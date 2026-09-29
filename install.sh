#!/usr/bin/env bash
# claude-workspace — one-command installer (macOS, zsh)
#
# Embeds claude-ws.zsh into ~/.zshrc between clearly marked lines.
# Safe to re-run: any previous copy is replaced, a backup is kept.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RC="$HOME/.zshrc"
BEGIN='# >>> claude-ws (claude-workspace) >>>'
END='# <<< claude-ws (claude-workspace) <<<'

echo "🪄  claude-workspace installer"

# 0. jq and fzf are required — refuse to continue without them.
if ! command -v jq >/dev/null 2>&1; then
  echo "❌  jq is required — claude-ws reads .code-workspace files with it:"
  echo "    brew install jq"
  exit 1
fi
if ! command -v fzf >/dev/null 2>&1; then
  echo "❌  fzf is required — the workspace picker is built on it:"
  echo "    brew install fzf"
  exit 1
fi

# 1. Check the block markers first (nothing is touched if they are broken).
HAS_BEGIN=0; HAS_END=0
grep -qF -- "$BEGIN" "$RC" 2>/dev/null && HAS_BEGIN=1
grep -qF -- "$END" "$RC" 2>/dev/null && HAS_END=1

# A lone BEGIN marker would make the removal below delete everything after it.
if (( HAS_BEGIN != HAS_END )); then
  echo "❌  $RC has only one of the claude-ws block markers — refusing to edit it."
  echo "    Remove the leftover marker line by hand (or restore the block), then re-run."
  exit 1
fi

# Backup: a new timestamped copy on every install, so none is ever overwritten.
BACKUP=""
if [[ -f "$RC" ]]; then
  BACKUP="$RC.bak-claude-ws-$(date +%Y%m%d-%H%M%S)"
  cp "$RC" "$BACKUP"
fi

# 2. Remove any previous copy (idempotent re-install).
if (( HAS_BEGIN )); then
  sed -i '' "/$BEGIN/,/$END/d" "$RC"
fi

# 3. Normalize the file end, then append the latest version —
#    so N re-installs always leave exactly one blank separator line.
[[ -f "$RC" ]] && sed -i '' -e :a -e '/^[[:space:]]*$/{$d;N;ba' -e '}' "$RC"
{
  [[ -s "$RC" ]] && echo
  echo "$BEGIN"
  cat "$HERE/claude-ws.zsh"
  echo "$END"
} >> "$RC"

# 4. Next steps.
echo "✅  Installed into $RC"
[[ -z "$BACKUP" ]] || echo "    Backup: $BACKUP"
echo
if ! grep -qE '^[[:space:]]*(export[[:space:]]+)?CLAUDE_WORKSPACE_DIRS=' "$RC"; then
  echo "👉  Set the folder holding your .code-workspace files (your own path) — add to $RC:"
  echo '      export CLAUDE_WORKSPACE_DIRS="/path/to/workspaces"'
  echo '    Several folders: separate them with ":".'
fi
echo "    Then open a new terminal (or: source ~/.zshrc) and run: claude-ws"
