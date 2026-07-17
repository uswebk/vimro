local M = {}

function M.setup(opts)
  require("vimro.config").setup(opts)
end

function M.start()
  require("vimro.ui").start()
end

return M
