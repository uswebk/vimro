local M = {}

M.count = 0

local ns = vim.api.nvim_create_namespace("vimro_keys")
local attached = false
local target_buf

function M.start(buf)
  target_buf = buf
  M.count = 0
  if attached then
    return
  end
  vim.on_key(function()
    if target_buf and vim.api.nvim_get_current_buf() == target_buf then
      M.count = M.count + 1
    end
  end, ns)
  attached = true
end

function M.reset()
  M.count = 0
end

function M.stop()
  if attached then
    vim.on_key(nil, ns)
    attached = false
  end
  target_buf = nil
end

return M
