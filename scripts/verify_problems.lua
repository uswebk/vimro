-- Verify every problem in problems/: schema, and that each solution really
-- transforms `start` into `goal` when replayed in a scratch buffer.
--
--   nvim --headless -u NONE -l scripts/verify_problems.lua

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.rtp:prepend(root)

local engine = require("vimro.engine")

local errors = {}
local seen_ids = {}
local counts = {}
local total = 0

local function fail(where, msg)
  table.insert(errors, where .. ": " .. msg)
end

local function check_schema(file, p)
  local name = vim.fn.fnamemodify(file, ":t")
  local category = vim.fn.fnamemodify(file, ":h:t")

  if type(p.id) ~= "string" or not p.id:match("^" .. category .. "%-%d%d%d$") then
    fail(name, ("id %s does not match <%s>-NNN"):format(vim.inspect(p.id), category))
    return
  end
  if seen_ids[p.id] then
    fail(name, ("duplicate id %s (also in %s)"):format(p.id, seen_ids[p.id]))
  end
  seen_ids[p.id] = name

  if type(p.difficulty) ~= "number" or p.difficulty % 1 ~= 0 or p.difficulty < 1 or p.difficulty > 3 then
    fail(p.id, "difficulty must be an integer 1-3, got " .. vim.inspect(p.difficulty))
  end
  for _, field in ipairs({ "start", "goal", "solutions" }) do
    if type(p[field]) ~= "table" or vim.tbl_isempty(p[field]) then
      fail(p.id, field .. " must be a non-empty array")
    end
  end
  if type(p.solutions) ~= "table" then
    return
  end

  local optimal = 0
  for i, s in ipairs(p.solutions) do
    if type(s.keys) ~= "string" or s.keys == "" then
      fail(p.id, ("solutions[%d].keys must be a non-empty string"):format(i))
    end
    if s.optimal == true then
      optimal = optimal + 1
    end
  end
  if optimal ~= 1 then
    fail(p.id, ("exactly one solution must be optimal, found %d"):format(optimal))
  end

  for _, lang in ipairs({ "ja", "en" }) do
    local tr = p.i18n and p.i18n[lang]
    if type(tr) ~= "table" then
      fail(p.id, "missing i18n." .. lang)
    else
      for _, field in ipairs({ "title", "description" }) do
        if type(tr[field]) ~= "string" or tr[field] == "" then
          fail(p.id, ("i18n.%s.%s must be a non-empty string"):format(lang, field))
        end
      end
      if type(tr.hints) ~= "table" or vim.tbl_isempty(tr.hints) then
        fail(p.id, ("i18n.%s.hints must be a non-empty array"):format(lang))
      end
      if type(tr.notes) ~= "table" then
        fail(p.id, ("i18n.%s.notes must be an array"):format(lang))
      elseif #tr.notes ~= #p.solutions then
        fail(p.id, ("i18n.%s.notes has %d entries but there are %d solutions"):format(lang, #tr.notes, #p.solutions))
      end
    end
  end
end

local function check_solutions(p)
  if type(p.start) ~= "table" or type(p.goal) ~= "table" or type(p.solutions) ~= "table" then
    return
  end
  for i, s in ipairs(p.solutions) do
    if type(s.keys) == "string" then
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, p.start)
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      local ok, err = pcall(function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(s.keys, true, false, true), "x", false)
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
      end)
      if not ok then
        fail(p.id, ("solution %d (%s) errored: %s"):format(i, s.keys, err))
      else
        local got = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        if not engine.is_cleared(got, p.goal) then
          fail(p.id, ("solution %d (%s) produced %s, want %s"):format(i, s.keys, vim.inspect(got), vim.inspect(p.goal)))
        end
      end
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end

for _, category in ipairs(engine.list_categories()) do
  local files = vim.fn.glob(root .. "/problems/" .. category .. "/*.json", false, true)
  table.sort(files)
  counts[category] = #files
  for _, file in ipairs(files) do
    total = total + 1
    local ok, p = pcall(vim.json.decode, table.concat(vim.fn.readfile(file), "\n"))
    if not ok or type(p) ~= "table" then
      fail(vim.fn.fnamemodify(file, ":t"), "invalid JSON: " .. tostring(p))
    else
      check_schema(file, p)
      check_solutions(p)
    end
  end
end

if #errors > 0 then
  io.stderr:write(("%d problem(s) failed verification:\n"):format(#errors))
  for _, e in ipairs(errors) do
    io.stderr:write("  " .. e .. "\n")
  end
  vim.cmd("cq")
end

local parts = {}
for _, category in ipairs(engine.list_categories()) do
  table.insert(parts, ("%s: %d"):format(category, counts[category]))
end
io.stdout:write(("OK - %d problems verified (%s)\n"):format(total, table.concat(parts, ", ")))
