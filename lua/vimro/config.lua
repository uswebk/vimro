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
  -- Prefix for the same actions in the practice buffer (e.g. <leader>n = next),
  -- so you don't have to switch panes. Set to false to disable.
  practice_prefix = "<leader>",
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
