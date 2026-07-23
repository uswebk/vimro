-- Require every module under lua/vimro/ so syntax and load-time errors surface.
--
--   nvim --headless -u NONE -l scripts/load_check.lua

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.rtp:prepend(root)

local files = vim.fn.glob(root .. "/lua/vimro/**/*.lua", false, true)
table.sort(files)

local failed = false
for _, file in ipairs(files) do
  local mod = file:sub(#root + #"/lua/" + 1):gsub("%.lua$", ""):gsub("/init$", ""):gsub("/", ".")
  local ok, err = pcall(require, mod)
  if not ok then
    failed = true
    io.stderr:write(("%s: %s\n"):format(mod, err))
  end
end

-- plugin/ scripts are sourced by Neovim, not required
local ok, err = pcall(vim.cmd, "source " .. root .. "/plugin/vimro.lua")
if not ok then
  failed = true
  io.stderr:write("plugin/vimro.lua: " .. tostring(err) .. "\n")
end

if failed then
  vim.cmd("cq")
end
io.stdout:write(("OK - %d modules loaded\n"):format(#files))
