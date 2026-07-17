if vim.g.loaded_vimro then
  return
end
vim.g.loaded_vimro = true

vim.api.nvim_create_user_command("Vimro", function()
  require("vimro").start()
end, { desc = "Start vimro hands-on drills" })
