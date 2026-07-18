local M = {}

M.defaults = {
  lang = "en",          -- "ja" | "en"
  fallback_lang = "en",
  keys = {
    next = "n",
    prev = "p",
    reset = "r",
    hint = "?",
    solution = "s",
    list = "g",
    quit = "q",
  },
  -- Prefix for the same actions outside the problem pane (e.g. <leader>n = next),
  -- so you don't have to switch panes. Set to false to disable.
  buffer_prefix = "<leader>",
  -- Where the problem pane sits: "left" | "right" | "bottom"
  pane_position = "left",
  -- Width of the problem pane (columns), used when it sits left or right
  pane_width = 42,
  -- Height of the problem pane (lines), used when it sits at the bottom
  pane_height = 14,
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
