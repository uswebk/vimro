# vimro.nvim

Neovim の中で、vim のキーバインディングをハンズオンで学ぶプラグイン。

vimro はお題テキスト（start）と目標テキスト（goal）を提示します。バッファを編集して goal に一致させればクリア — 到達方法（キー操作列）は問いません。ヒントと解法は要求するまで表示されません。

[English README is here](README.md)

## 特徴

- ドリル形式の問題: `start` を `goal` に変形すると自動でクリア判定
- どんなキー操作でも OK — 判定は最終的なバッファの状態のみ
- ヒントと解法は要求時のみ表示（`?` / `s`）。デフォルトでは見えない
- 問題ペインは左 / 右 / 下から選択可能（`pane_position`）
- 日本語 / 英語 UI。問題ごとの翻訳とフォールバックに対応
- 進捗はローカルに保存
- 問題は素の JSON ファイル — 誰でも追加しやすい

<div align="center">
<img width="800" alt="Screenshot 2026-07-18 at 0 41 43" src="https://github.com/user-attachments/assets/ac07f49d-0835-484b-acfa-7eccb74dd20b" />
</div>


## 動作要件

- Neovim 0.9+

## インストール

[lazy.nvim](https://github.com/folke/lazy.nvim) でインストールします。lazy.nvim がまだ無い場合は先に[公式のインストール手順](https://lazy.folke.io/installation)に従ってください（LazyVim や kickstart.nvim などのディストリビューションには最初から入っています）。

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

Neovim を再起動（または `:Lazy sync` を実行）するとインストールされます。そのあと `:Vimro` で起動できます。

補足:

- `cmd = "Vimro"` は「`:Vimro` を初めて実行したときに読み込む」遅延読み込みの指定です
- `opts = { lang = "ja" }` で日本語 UI になります。`opts = {}` なら英語（デフォルト）です。全オプションは[設定](#設定)を参照

## はじめかた

1. `:Vimro` を実行（ノーマルモードで `:` を押し、`Vimro` と入力して Enter）。ターミナルから `nvim +Vimro` で直接起動することもできます。`alias vimro='nvim +Vimro'` をシェル設定に足せば `vimro` 一語で始められます。
2. 表示言語（`ja` / `en`）とカテゴリを選択します（`plain` または `python`）。
3. 画面が**問題ペイン**と編集用のバッファに分割されます。問題ペインのお題どおりにバッファを編集してください。ペインの位置は既定で左、`pane_position` で右または下にも変更できます。
4. クリアは自動で判定されます。問題ペインで `n` を押すと次の問題へ。

問題ペインの操作キー:

| キー | 動作 |
|------|------|
| `n` | 次の問題へ |
| `p` | 前の問題へ |
| `r` | バッファをリセット |
| `?` | ヒントの表示切替 |
| `s` | 解法の表示切替 |
| `g` | 問題一覧から選んでジャンプ |
| `q` | 終了 |

同じ操作は**バッファ側からも**プレフィックス付きで実行できます（ペイン移動不要）: `<leader>n` で次へ、`<leader>r` でリセットなど。`<leader>` の実キーは環境によって異なり（LazyVim なら Space、未設定なら `\`）、問題ペインの案内には解決済みの実キー名が表示されます。素の `n` や `r` はバッファ側では vim 本来の動きのままです — それを練習するためのプラグインなので。プレフィックスは `buffer_prefix` で変更でき、`false` で無効化できます。

判定は「各行末の空白と最終空行は無視、行内容と行数は厳密」です。どのキーを何回使って到達するかは自由です。

進捗（解いた問題の id）は `stdpath("data")/vimro/progress.json`（例: `~/.local/share/nvim/vimro/progress.json`）に保存されます。

## 設定

デフォルト値を示します。すべて省略可能です。

```lua
require("vimro").setup({
  lang = "en",          -- 既定の表示言語: "ja" | "en"
  fallback_lang = "en", -- 翻訳欠損時のフォールバック
  keys = {              -- 問題ペインのキーマップ
    next = "n",
    prev = "p",
    reset = "r",
    hint = "?",
    solution = "s",
    list = "g",
    quit = "q",
  },
  buffer_prefix = "<leader>",   -- 問題ペイン外で同じ操作を使うときの前置キー
                                -- （例: <leader>n で次へ）。false で無効化
  pane_position = "left", -- 問題ペインの位置: "left" | "right" | "bottom"
  pane_width = 42,      -- 問題ペインの幅（列数）。left / right のとき
  pane_height = 14,     -- 問題ペインの高さ（行数）。bottom のとき
})
```

## 問題の追加（コントリビュート）

問題は `problems/<category>/NNN-<slug>.json` に 1 問 1 ファイルで置きます:

- 言語非依存フィールドを埋める: `id` / `category` / `difficulty` / `start` / `goal` / `cursor`（1 始まりの `[行, 列]`）/ `solutions`（`keys` は `<Esc>` などの vim 表記。最短解に `"optimal": true`）/ `tags`
- `i18n.ja` と `i18n.en` の両方を埋める（`title` / `description` / `hints` / `notes`）。`notes[i]` は `solutions[i]` の説明
- 各 `solutions[].keys` が本当に `start` を `goal` に変形することを Neovim で確認する
- 1 問につき狙う操作は 1 つに絞り、`description` と `goal` を必ず一致させる

完全な例は `problems/plain/001-delete-word.json` を参照してください。

## ライセンス

[MIT](LICENSE)
