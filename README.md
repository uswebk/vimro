# vimro.nvim

Learn Vim keybindings hands-on, inside Neovim.

vimro shows you a start text and a goal text. Edit the buffer until it matches the goal — any sequence of keys that gets you there counts. Hints and solutions stay hidden until you ask for them.

[日本語版 README はこちら / Japanese README](README.ja.md)

## Features

- Drill-style problems: transform `start` into `goal`, cleared automatically on match
- Any key sequence counts — only the final buffer state is checked
- Hints and solutions on demand (`?` / `s`), never shown by default
- Problem pane on the left, right, or bottom (`pane_position`)
- Japanese / English UI, per-problem translations with fallback
- Progress saved locally
- Problems are plain JSON files — easy to contribute

<div align="center">
<img width="800" alt="Screenshot 2026-07-18 at 0 33 59" src="https://github.com/user-attachments/assets/a5d7a523-a58f-4090-93b9-e141a8fce1f5" />
</div>


## Requirements

- Neovim 0.9+

## Installation

vimro is installed with [lazy.nvim](https://github.com/folke/lazy.nvim). If you don't have it yet, follow the [lazy.nvim installation guide](https://lazy.folke.io/installation) first (Neovim distributions such as LazyVim and kickstart.nvim already include it).

Add this spec wherever your plugins are declared:

- **Using a distribution like LazyVim / kickstart.nvim** (your `init.lua` contains something like `require("config.lazy")` or `require("lazy").setup("plugins")`) — create a new file `lua/plugins/vimro.lua` in your config directory (`~/.config/nvim`, or `~\AppData\Local\nvim` on Windows):

  ```lua
  -- ~/.config/nvim/lua/plugins/vimro.lua
  return {
    "uswebk/vimro.nvim",
    cmd = "Vimro",
    opts = {},
  }
  ```

- **Plugins listed directly in `init.lua`** — add it inside the table passed to `require("lazy").setup({ ... })`:

  ```lua
  require("lazy").setup({
    -- ...your other plugins...
    {
      "uswebk/vimro.nvim",
      cmd = "Vimro",
      opts = {},
    },
  })
  ```

Restart Neovim (or run `:Lazy sync`) to install. Then run `:Vimro` to start.

Notes:

- `cmd = "Vimro"` lazy-loads the plugin the first time you run `:Vimro`.
- `opts = {}` uses the default settings. For a Japanese UI, use `opts = { lang = "ja" }`. See [Configuration](#configuration) for all options.

## Getting started

1. Run `:Vimro` (in normal mode, press `:`, type `Vimro`, then hit Enter). Or launch it straight from your terminal with `nvim +Vimro` — add `alias vimro='nvim +Vimro'` to your shell config to start drilling with a single word.
2. Pick a UI language (`ja` / `en`) and a category (`plain` or `python`).
3. The screen splits into a **problem pane** and the buffer you edit: edit it until it matches the goal described in the problem pane. The pane sits on the left by default — put it on the right or along the bottom with `pane_position`.
4. Clearing is detected automatically; press `n` in the problem pane for the next problem.

Keys in the problem pane:

| Key | Action |
|-----|--------|
| `n` | next problem |
| `p` | previous problem |
| `r` | reset the buffer |
| `?` | toggle hints |
| `s` | toggle solutions |
| `g` | pick a problem from the list (jump to any problem) |
| `q` | quit |

The same actions are also available **from the buffer** with a prefix, so you don't have to switch panes: `<leader>n` for next, `<leader>r` for reset, and so on. `<leader>` depends on your config — Space in LazyVim, `\` by default — and the problem pane shows the resolved key (e.g. "Press Space before each key"). Plain `n` / `r` etc. keep their normal Vim meaning there — that's what you are here to train. The prefix is configurable via `buffer_prefix` (set it to `false` to disable).

Matching ignores trailing whitespace on each line and trailing blank lines; line contents and line count are otherwise strict. How you get there — which keys, how many — is up to you.

Progress (solved problem ids) is saved to `stdpath("data")/vimro/progress.json` (e.g. `~/.local/share/nvim/vimro/progress.json`).

## Configuration

Defaults shown; every field is optional.

```lua
require("vimro").setup({
  lang = "en",          -- default UI language: "ja" | "en"
  fallback_lang = "en", -- used when a translation is missing
  keys = {              -- problem-pane keymaps
    next = "n",
    prev = "p",
    reset = "r",
    hint = "?",
    solution = "s",
    list = "g",
    quit = "q",
  },
  buffer_prefix = "<leader>",   -- prefix for the same actions outside the problem pane
                                -- (e.g. <leader>n = next); set to false to disable
  pane_position = "left", -- where the problem pane sits: "left" | "right" | "bottom"
  pane_width = 42,      -- width of the problem pane (columns), when left or right
  pane_height = 14,     -- height of the problem pane (lines), when bottom
})
```

## Contributing problems

Problems live in `problems/<category>/NNN-<slug>.json`, one file per problem:

- Fill the language-independent fields: `id`, `category`, `difficulty`, `start`, `goal`, `cursor` (1-based `[row, col]`), `solutions` (`keys` in Vim notation like `<Esc>`, mark the shortest with `"optimal": true`), `tags`.
- Fill both `i18n.ja` and `i18n.en` (`title`, `description`, `hints`, `notes`). `notes[i]` describes `solutions[i]`.
- Verify in Neovim that each `solutions[].keys` really transforms `start` into `goal`.
- Aim for one target operation per problem, and keep `description` consistent with `goal`.

See `problems/plain/001-delete-word.json` for a complete example.

## License

[MIT](LICENSE)
