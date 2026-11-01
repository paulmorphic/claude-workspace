#!/usr/bin/env bash
# claude-workspace — one-command installer (macOS, zsh)
#
# Links bin/claude-ws into ~/.local/bin, so a `git pull` here updates it.
# Also removes the block older versions pasted into ~/.zshrc (a backup is kept).
# Safe to re-run.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
RC="$HOME/.zshrc"
BEGIN='# >>> claude-ws (claude-workspace) >>>'
END='# <<< claude-ws (claude-workspace) <<<'

echo "🪄  claude-workspace installer"

# 0. jq and fzf (0.36+) are required — refuse to continue without them.
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
FZF_VERSION="$(fzf --version | awk '{print $1}')"
IFS=. read -r FZF_MAJOR FZF_MINOR _ <<< "$FZF_VERSION"
if (( FZF_MAJOR == 0 && FZF_MINOR < 36 )); then
  echo "❌  fzf 0.36 or newer is required (found $FZF_VERSION):"
  echo "    brew upgrade fzf"
  exit 1
fi

# 1. Remove the block older versions pasted into ~/.zshrc — left in place,
#    that old function would shadow the new command.
HAS_BEGIN=0; HAS_END=0
grep -qF -- "$BEGIN" "$RC" 2>/dev/null && HAS_BEGIN=1
grep -qF -- "$END" "$RC" 2>/dev/null && HAS_END=1

# A lone BEGIN marker would make the removal below delete everything after it.
if (( HAS_BEGIN != HAS_END )); then
  echo "❌  $RC has only one of the old claude-ws block markers — refusing to edit it."
  echo "    Remove the leftover marker line (or the whole old block) by hand, then re-run."
  exit 1
fi

MIGRATED=0
if (( HAS_BEGIN )); then
  BACKUP="$RC.bak-claude-ws-$(date +%Y%m%d-%H%M%S)"
  cp "$RC" "$BACKUP"
  sed -i '' "/$BEGIN/,/$END/d" "$RC"
  # Trim the blank lines the removal may leave at the end of the file.
  sed -i '' -e :a -e '/^[[:space:]]*$/{$d;N;ba' -e '}' "$RC"
  MIGRATED=1
  echo "🧹  Removed the old claude-ws block from $RC"
  echo "    Backup: $BACKUP"
fi

# 2. Link the command.
chmod +x "$HERE/bin/claude-ws"
mkdir -p "$BIN_DIR"
ln -sfn "$HERE/bin/claude-ws" "$BIN_DIR/claude-ws"
echo "✅  Linked $BIN_DIR/claude-ws → $HERE/bin/claude-ws"
echo "    Updates: git pull in $HERE — no need to re-run this installer."

# 3. Next steps.
echo
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    echo "👉  $BIN_DIR is not in your PATH — add to $RC:"
    echo '      export PATH="$HOME/.local/bin:$PATH"'
    ;;
esac
if ! grep -qE '^[[:space:]]*export[[:space:]]+CLAUDE_WORKSPACE_DIRS=' "$RC" 2>/dev/null; then
  echo "👉  Set the folder holding your .code-workspace files (your own path) — add to $RC:"
  echo '      export CLAUDE_WORKSPACE_DIRS="$HOME/path/to/workspaces"'
  echo '    Several folders: separate them with ":". Keep the "export" — claude-ws is a'
  echo '    separate program now and only sees exported variables.'
fi
if ! grep -qE '^[[:space:]]*export[[:space:]]+CLAUDE_WORKSPACE_BROWSE_ROOT=' "$RC" 2>/dev/null; then
  echo "    Optional: where \"+ New workspace…\" starts browsing (default: \$HOME):"
  echo '      export CLAUDE_WORKSPACE_BROWSE_ROOT="$HOME/Projects"'
fi
if (( MIGRATED )); then
  echo "    Then open a new terminal (or: exec zsh) — the old claude-ws function"
  echo "    stays loaded in already open shells until then. Run: claude-ws"
else
  echo "    Then run: claude-ws"
fi
