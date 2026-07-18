# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`vimro.nvim` — a pure-Lua Neovim plugin for drilling Vim keybindings. It shows a `start` text and a `goal` text; the user edits the practice buffer until it matches. Only the final buffer state is checked, never the keys used.

There is no build step, no package manager, and no test framework. The repo is the plugin: `plugin/vimro.lua` defines `:Vimro`, `lua/vimro/*` is the implementation, `problems/<category>/*.json` is the content.

## Commands

Run the plugin from the repo without installing it:

```sh
nvim --cmd "set rtp+=$PWD" +Vimro
```

Verify a problem's solutions actually transform `start` into `goal` (headless, no config):

```sh
nvim --headless -u NONE -l verify.lua   # see .claude/skills/add-problem/SKILL.md for the script
```

That headless-replay pattern is the only automated check in the repo — use it whenever problem JSON changes.

## Architecture

Five modules, each with one job. `ui.lua` is the only one that knows about the others.

- **`engine.lua`** — no UI, no state beyond the progress file. Loads/sorts problems (difficulty, then id), decides clearing, persists progress. `root()` derives the plugin directory from `debug.getinfo`, so `problems/` is always found relative to the installed plugin, not the cwd.
- **`ui.lua`** — session state (`S`), the two-window tab layout, keymaps, rendering, startup flow. Everything user-visible lives here.
- **`config.lua`** — `M.defaults` is the single source of truth for options; `setup()` deep-extends into `M.options`. `ui.lua` reads `config.options` live, so runtime mutation (e.g. the language picker setting `config.options.lang`) takes effect immediately.
- **`i18n/`** — `t(key, ...)` for UI strings, `resolve_problem()` for per-problem text. Both fall back `lang` → `fallback_lang`; `t()` finally falls back to the key itself, so a missing string degrades rather than errors.
- **`keys.lua`** — keystroke counter via a single `vim.on_key` handler, counting only while the practice buffer is current.

### Things that will bite you

- **Clear matching is deliberately loose in one axis only**: `engine.normalize` strips trailing whitespace per line and drops trailing blank lines. Line contents and line count are otherwise strict. Problems whose answer depends on trailing whitespace cannot be expressed.
- **Keymaps in the practice buffer must stay behind `buffer_prefix`.** Binding plain `n` / `r` there would shadow the exact Vim motions being trained. The problem pane is where bare keys are safe.
- **Categories are hardcoded in `ui.lua`** (`local categories = { "plain" }`) even though `engine.load_problems` accepts any directory name. Adding a new `problems/<category>/` requires editing that list too.
- **`quit()` has two exit paths**: started from an empty Neovim (`is_fresh_nvim`) it runs `qa` and exits the editor; otherwise it tears down the tab/split and wipes buffers. Both must leave `S` clean, since `M.start()` guards re-entry on `S.active`.
- Both buffers are `nofile` + `bufhidden=wipe`, and a `BufWipeout` autocmd on the practice buffer ends the session — wiping it from anywhere is a supported way to quit.

## Problem JSON

One problem per file at `problems/<category>/NNN-<slug>.json`, `id` = `<category>-NNN`. Language-independent fields (`start`, `goal`, `cursor` as 1-based `[row, col]`, `solutions[].keys` in Vim notation, `tags`) plus both `i18n.ja` and `i18n.en`. `notes[i]` describes `solutions[i]` and must match in length; exactly one solution carries `"optimal": true`.

`problems/plain/001-delete-word.json` is the reference example. Full authoring workflow, including verification and PR conventions, lives in `.claude/skills/add-problem/SKILL.md` — follow it rather than hand-rolling when adding problems.

## Docs

`README.md` and `README.ja.md` are parallel structures, not translations of each other's layout drift. Any user-visible change (options, keymaps, workflow) needs both updated.
