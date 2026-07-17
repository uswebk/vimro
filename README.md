# vimro.nvim

Learn Vim keybindings hands-on, inside Neovim.

vimro shows you a start text and a goal text. Edit the buffer until it matches the goal — any sequence of keys that gets you there counts. Hints and solutions stay hidden until you ask for them.

[日本語の説明はこちら](#日本語)

## Features

- Drill-style problems: transform `start` into `goal`, cleared automatically on match
- Any key sequence counts — only the final buffer state is checked
- Hints and solutions on demand (`?` / `s`), never shown by default
- Japanese / English UI, per-problem translations with fallback
- Progress saved locally; keystroke count shown on clear
- Problems are plain JSON files — easy to contribute

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
2. Pick a UI language (`ja` / `en`) and a category (MVP ships `plain`).
3. The screen splits: edit the **left** buffer until it matches the goal described in the **right** pane.
4. Clearing is detected automatically; press `n` in the right pane for the next problem.

Keys in the problem pane (right side):

| Key | Action |
|-----|--------|
| `n` | next problem |
| `p` | previous problem |
| `r` | reset the practice buffer |
| `?` | toggle hints |
| `s` | toggle solutions |
| `g` | pick a problem from the list (jump to any problem) |
| `q` | quit |

The same actions are also available **from the practice buffer** with a prefix, so you don't have to switch panes: `<leader>n` for next, `<leader>r` for reset, and so on. `<leader>` depends on your config — Space in LazyVim, `\` by default — and the problem pane shows the resolved key (e.g. "Press Space before each key"). Plain `n` / `r` etc. keep their normal Vim meaning in the practice buffer — that's what you are here to train. The prefix is configurable via `practice_prefix` (set it to `false` to disable).

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
  practice_prefix = "<leader>", -- prefix for the same actions in the practice buffer
                                -- (e.g. <leader>n = next); set to false to disable
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

---

## 日本語

vim のキーバインディングを、Neovim の中でハンズオンで学ぶプラグインです。お題テキスト（start）を目標の形（goal）に編集するとクリア。到達方法（キー操作列）は問いません。ヒントと解法は要求したときだけ表示されます。

### インストール

プラグインマネージャ [lazy.nvim](https://github.com/folke/lazy.nvim) を使ってインストールします。lazy.nvim がまだ無い場合は先に[公式のインストール手順](https://lazy.folke.io/installation)に従ってください（LazyVim や kickstart.nvim を使っている場合は最初から入っています）。

プラグインを宣言している場所に次のスペックを追加します:

- **LazyVim / kickstart.nvim などのディストリビューションを使っている場合**（`init.lua` に `require("config.lazy")` や `require("lazy").setup("plugins")` のような行がある場合）— 設定ディレクトリ（`~/.config/nvim`、Windows は `~\AppData\Local\nvim`）の `lua/plugins/` に新しいファイルを作成:

  ```lua
  -- ~/.config/nvim/lua/plugins/vimro.lua
  return {
    "uswebk/vimro.nvim",
    cmd = "Vimro",
    opts = { lang = "ja" },
  }
  ```

- **`init.lua` に直接プラグインを列挙している場合** — `require("lazy").setup({ ... })` のテーブルの中に追加:

  ```lua
  require("lazy").setup({
    -- ...既存のプラグイン...
    {
      "uswebk/vimro.nvim",
      cmd = "Vimro",
      opts = { lang = "ja" },
    },
  })
  ```

Neovim を再起動（または `:Lazy sync` を実行）するとインストールされ、`:Vimro` で起動できます。

補足:

- `cmd = "Vimro"` は「`:Vimro` を初めて実行したときに読み込む」遅延読み込みの指定です
- `opts = { lang = "ja" }` で日本語 UI になります。`opts = {}` なら英語です。他のオプションは「設定」を参照

### 起動方法

1. `:Vimro` を実行（Neovim を開き、ノーマルモードで `:` を押してから `Vimro` と入力して Enter。挿入モード中なら先に Esc を押す）。ターミナルから `nvim +Vimro` で直接起動することもできます。`alias vimro='nvim +Vimro'` をシェル設定に足せば `vimro` 一語で起動できます
2. 表示言語（`ja` / `en`）とカテゴリを選択
3. 画面が左右に分割されるので、**左**の練習バッファを右ペインのお題どおりに編集
4. goal に一致すると自動でクリア判定。右ペインで `n` を押すと次の問題へ

右ペインの操作キー: `n`（次へ）/ `p`（前へ）/ `r`（リセット）/ `?`（ヒント）/ `s`（解法）/ `g`（問題一覧から選んでジャンプ）/ `q`（終了）

同じ操作は**左の練習バッファからも**プレフィックス付きで実行できます（ペイン移動不要）: `<leader>n` で次へ、`<leader>r` でリセットなど。`<leader>` の実キーは環境によって異なり（LazyVim なら Space、未設定なら `\`）、右ペインの案内には実際のキー名（例:「各キーの前に Space を押してください」）が表示されます。素の `n` や `r` は vim 本来の動きのまま残しています（それを練習するためのプラグインなので）。プレフィックスは `practice_prefix` オプションで変更でき、`false` で無効化できます。

### 設定

```lua
require("vimro").setup({
  lang = "ja",          -- 表示言語 "ja" | "en"（既定 "en"）
  fallback_lang = "en", -- 翻訳欠損時のフォールバック
  keys = {              -- 右ペインのキーマップ（上書き可）
    next = "n", prev = "p", reset = "r",
    hint = "?", solution = "s", list = "g", quit = "q",
  },
  practice_prefix = "<leader>", -- 練習バッファで同じ操作を使うときの前置キー
                                -- （例: <leader>n で次へ）。false で無効化
})
```

### 判定と進捗

判定は「各行末の空白と最終空行は無視、行内容と行数は厳密」です。進捗（解いた問題の id）は `stdpath("data")/vimro/progress.json` に保存されます。

### 問題の追加

`problems/<カテゴリ>/NNN-<slug>.json` に1問1ファイルで追加します。`i18n.ja` と `i18n.en` の両方を埋め、`solutions[].keys` が本当に `start` を `goal` に変形することを Neovim で確認してください。詳しくは英語セクションの Contributing problems を参照。
