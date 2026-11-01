<div align="center">

# 🪄 Claude Workspace

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Built for Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-D97757)](https://claude.com/claude-code)
[![Platform: macOS](https://img.shields.io/badge/platform-macOS-black?logo=apple)](#)
[![VS Code workspace format](https://img.shields.io/badge/uses-VS%20Code%20workspace%20format-007ACC?logo=visualstudiocode&logoColor=white)](#)

**Pick a workspace, and the Claude Code CLI opens with all its folders and context attached.**
<br>
**No workspace yet?** Browse your folders, mark a few, name it — saved for next time.
<br>
**Full context:** loads the `CLAUDE.md` of every folder.
<br>
**VS Code–friendly:** uses plain `.code-workspace` files — reuse the ones you have, no new format to learn.

<br>

</div>

---

## 💡 What is this

`claude-ws` is a single zsh script that sits next to `claude`. Run it, pick a workspace from a menu, and `claude` boots up in the right folder with every other folder already attached via `--add-dir`. No manual `--add-dir` typing, no touching `claude` itself.

Don't have a workspace for what you're about to do? Pick **`+ New workspace…`**, mark the folders in a built-in browser, give it a name — it's saved and launched, and it's in the menu next time.

Workspaces are the exact `.code-workspace` JSON files VS Code uses for multi-root projects, so if you already organize work that way, `claude-ws` just plugs in. VS Code itself is not required.

## ⚙️ How it works

1. Lists the `*.code-workspace` files in your workspace folder, newest first, with **`+ New workspace…`** on top.
2. Shows an arrow-key picker (fzf) with search.
3. Reads the folder list from the chosen file with `jq`.
4. Starts `claude` in the first folder and adds the rest with `--add-dir`.

**The first folder is the "home" of the session.** Claude works there by default, and the session itself — its history and memory (auto memory, `/resume`) — belongs to that folder. The other folders are attached as extra context: Claude can read and edit them, but nothing session-related is stored there. When you create a workspace with `claude-ws`, you pick the home folder at the end; in a file you wrote yourself, it's the first entry in the `folders` list.

## 📋 Requirements

- macOS + zsh
- [`jq`](https://stedolan.github.io/jq/)
- [`fzf`](https://github.com/junegunn/fzf) 0.36 or newer
- The official `claude` CLI

## 📦 Install

```bash
brew install jq fzf

git clone https://github.com/paulmorphic/claude-workspace.git
cd claude-workspace
./install.sh
```

The installer links `bin/claude-ws` into `~/.local/bin` and tells you if that folder isn't in your `PATH` yet. It's a link, not a copy: to update, just `git pull` in the cloned folder. Safe to re-run (it also removes the `~/.zshrc` block older versions used, keeping a backup).

Then pick a folder to keep your workspace files in — or use the one that already holds your VS Code workspaces — and point `claude-ws` at it in `~/.zshrc`:

```bash
mkdir -p ~/workspaces
```

```bash
export CLAUDE_WORKSPACE_DIRS="$HOME/workspaces"
```

Reload with `source ~/.zshrc` or open a new terminal. More options in [Configuration](#-configuration).

## 🚀 Usage

```bash
claude-ws
```

Type to filter, Enter to launch. Extra arguments pass straight through to `claude`:

```bash
claude-ws --model haiku
```

### ➕ Create a workspace

Pick **`+ New workspace…`** at the top of the menu (it opens on its own when you have no workspaces yet). A folder browser starts in your home folder, or in `CLAUDE_WORKSPACE_BROWSE_ROOT` if set:

| Key | Action |
| --- | --- |
| `→` / `Enter` | open folder |
| `←` | go up |
| `Tab` | mark / unmark the highlighted folder |
| `Ctrl-S` | done |
| `Esc` | cancel |

To mark the folder you're in, use the `this folder: …` line at the top (`Tab` or `Enter`). Marks stay while you move around.

After `Ctrl-S`, with two or more folders marked, pick the **home folder** (the first one you marked is preselected — Enter keeps it). Then type a name: the workspace is saved as `<name>.code-workspace` in the first folder of `CLAUDE_WORKSPACE_DIRS` (an existing file is never overwritten), and `claude` starts right away.

### 📄 The workspace file

A workspace is a plain JSON file, e.g. `~/workspaces/my-app.code-workspace`:

```json
{
  "folders": [
    { "name": "project-a", "path": "~/code/project-a" },
    { "name": "project-b", "path": "/Users/me/work/project-b" }
  ]
}
```

Paths can be absolute, `~/…`, or relative to the file (like in VS Code). The optional `name` is the label VS Code shows for the folder; `claude-ws` only reads `path`. Edit it by hand, create one in VS Code (**File → Save Workspace As…**), or let `claude-ws` write it for you.

## 🔧 Configuration

Set these in `~/.zshrc`. Keep the `export` (`claude-ws` is a separate program and only sees exported variables), and use `$HOME` rather than `~` inside quotes — a quoted `~` is not expanded.

| Variable | Default | What it does |
| --- | --- | --- |
| `CLAUDE_WORKSPACE_DIRS` | — (required) | Folder(s) holding your `.code-workspace` files, separated by `:`. Subfolders are not searched. New workspaces are saved to the first one, which must exist. |
| `CLAUDE_WORKSPACE_BROWSE_ROOT` | `$HOME` | Where the `+ New workspace…` folder browser starts, e.g. `"$HOME/Projects"`. |
| `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` | `1` | Load `CLAUDE.md` from every folder, not just the first (see below). Set to `0` to turn off. |

## 📝 Good to know

- `CLAUDE.md` and `.claude/rules` of every folder in the workspace are loaded, not just the first (`claude-ws` sets `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`; plain `--add-dir` doesn't).
- ⚠️ Loading all those files adds to the context of every session, so **token usage can go up** — noticeably with many folders or large `CLAUDE.md` files. To turn it off, set `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=0` ([Configuration](#-configuration)).
- This is Claude Code behavior defined by Anthropic, so it may change independently of this tool. See the docs: [Memory → Load from additional directories](https://code.claude.com/docs/en/memory#load-from-additional-directories) and [Environment variables](https://code.claude.com/docs/en/env-vars).
- Workspace files are trusted: their folders are added without a prompt. Keep only files you trust in `CLAUDE_WORKSPACE_DIRS`; the added folders are printed before launch.

## 🧹 Uninstall

```bash
rm ~/.local/bin/claude-ws
```

Then delete the cloned folder and the `CLAUDE_WORKSPACE_*` export lines you added. Your workspace files stay where they are.

## 📄 License

[MIT](LICENSE) — do whatever you want with it, just keep the notice.
