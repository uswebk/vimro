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

Verify every problem — schema plus a real headless replay of each solution against `goal`:

```sh
nvim --headless -u NONE -l scripts/verify_problems.lua
```

Check that every module still loads:

```sh
nvim --headless -u NONE -l scripts/load_check.lua
```

Both run in CI (`.github/workflows/ci.yml`) on every PR and push to main. Run `verify_problems.lua` locally whenever problem JSON changes — a failure prints the offending `id` and the buffer it actually produced.

## Release automation

Merging to `main` releases automatically (`.github/workflows/release.yml`): it re-runs both checks, reads the merged PR's labels to pick the bump (`breaking` → major, `enhancement` → minor, anything else including `problems` → patch), tags `vX.Y.Z` off the latest `v*` tag, and publishes a GitHub release. Notes are GitHub's generated ones plus a problem-count delta from `scripts/problem_delta.sh`. A commit that already carries a `v*` tag is skipped, so re-runs are safe. Tags without the `v` prefix (`1.0.0`, `1.1.0`) are legacy and ignored by the version lookup.

## Architecture

Four modules, each with one job. `ui.lua` is the only one that knows about the others.

- **`engine.lua`** — no UI, no state beyond the progress file. Loads/sorts problems (difficulty, then id), decides clearing, persists progress. `root()` derives the plugin directory from `debug.getinfo`, so `problems/` is always found relative to the installed plugin, not the cwd.
- **`ui.lua`** — session state (`S`), the two-window tab layout, keymaps, rendering, startup flow. Everything user-visible lives here.
- **`config.lua`** — `M.defaults` is the single source of truth for options; `setup()` deep-extends into `M.options`. `ui.lua` reads `config.options` live, so runtime mutation (e.g. the language picker setting `config.options.lang`) takes effect immediately.
- **`i18n/`** — `t(key, ...)` for UI strings, `resolve_problem()` for per-problem text. Both fall back `lang` → `fallback_lang`; `t()` finally falls back to the key itself, so a missing string degrades rather than errors.

### Things that will bite you

- **Clear matching is deliberately loose in one axis only**: `engine.normalize` strips trailing whitespace per line and drops trailing blank lines. Line contents and line count are otherwise strict. Problems whose answer depends on trailing whitespace cannot be expressed.
- **Keymaps in the practice buffer must stay behind `buffer_prefix`.** Binding plain `n` / `r` there would shadow the exact Vim motions being trained. The problem pane is where bare keys are safe.
- **Categories are auto-detected** by `engine.list_categories()` from the subdirectories of `problems/`, so a new category needs no code change.
- **Every problem starts at `[1, 1]`.** There is no per-problem start position: getting to the spot you edit is part of the drill, and a mid-line start reads as a leftover cursor from the previous problem. Solutions must therefore include whatever motion they need.
- **`quit()` has two exit paths**: started from an empty Neovim (`is_fresh_nvim`) it runs `qa` and exits the editor; otherwise it tears down the tab/split and wipes buffers. Both must leave `S` clean, since `M.start()` guards re-entry on `S.active`.
- Both buffers are `nofile` + `bufhidden=wipe`, and a `BufWipeout` autocmd on the practice buffer ends the session — wiping it from anywhere is a supported way to quit.

## Problem JSON

One problem per file at `problems/<category>/NNN-<slug>.json`, `id` = `<category>-NNN`. Language-independent fields (`start`, `goal`, `solutions[].keys` in Vim notation, `tags`) plus both `i18n.ja` and `i18n.en`. `notes[i]` describes `solutions[i]` and must match in length; exactly one solution carries `"optimal": true`.

`problems/plain/001-delete-word.json` is the reference example. Full authoring workflow, including verification and PR conventions, lives in `.claude/skills/add-problem/SKILL.md` — follow it rather than hand-rolling when adding problems.

## Docs

`README.md` and `README.ja.md` are parallel structures, not translations of each other's layout drift. Any user-visible change (options, keymaps, workflow) needs both updated.
