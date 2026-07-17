local config = require("vimro.config")
local engine = require("vimro.engine")
local i18n = require("vimro.i18n")
local keys = require("vimro.keys")

local M = {}

-- Session state
local S = {
  active = false,
  problems = {},
  index = 1,
  progress = nil,
  practice_buf = nil,
  practice_win = nil,
  pane_buf = nil,
  pane_win = nil,
  tab = nil,
  cleared = false,
  show_hints = false,
  show_solutions = false,
}

local function t(key, ...)
  return i18n.t(key, ...)
end

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

-- Display name for practice_prefix; <leader> resolves to the actual key ("Space" for space)
local function prefix_display()
  local prefix = config.options.practice_prefix
  if not prefix or prefix == false then
    return nil
  end
  if prefix:lower() == "<leader>" then
    local leader = vim.g.mapleader or "\\"
    return leader == " " and "Space" or leader
  end
  return prefix
end

-- Problem pane rendering -----------------------------------------------------------

local function render_pane()
  if not (S.pane_buf and vim.api.nvim_buf_is_valid(S.pane_buf)) then
    return
  end
  local problem = S.problems[S.index]
  local text = i18n.resolve_problem(problem)
  local k = config.options.keys
  local lines = {}

  local title = text.title or problem.id
  local solved = engine.is_solved(S.progress, problem.id)
  table.insert(lines, string.format("%s %d/%d: %s%s",
    t("problem"), S.index, #S.problems, title, solved and (" " .. t("solved_mark")) or ""))
  table.insert(lines, string.format("%s: %d  [%s]", t("difficulty"), problem.difficulty or 0, problem.id))
  table.insert(lines, string.rep("─", math.max(10, config.options.pane_width - 4)))
  table.insert(lines, "")
  for _, line in ipairs(vim.split(text.description or "", "\n")) do
    table.insert(lines, line)
  end
  table.insert(lines, "")

  if S.cleared then
    table.insert(lines, "★ " .. t("cleared"))
    table.insert(lines, t("press_next"))
    table.insert(lines, "")
  end

  if S.show_hints then
    table.insert(lines, "── " .. t("hints") .. " ──")
    local hints = text.hints or {}
    if #hints == 0 then
      table.insert(lines, t("no_hints"))
    end
    for _, hint in ipairs(hints) do
      table.insert(lines, "・" .. hint)
    end
    table.insert(lines, "")
  end

  if S.show_solutions then
    table.insert(lines, "── " .. t("solutions") .. " ──")
    for si, sol in ipairs(problem.solutions or {}) do
      local note = (text.notes or {})[si]
      local mark = sol.optimal and (" " .. t("optimal")) or ""
      table.insert(lines, string.format("・%s%s", sol.keys, mark))
      if note then
        table.insert(lines, "    " .. note)
      end
    end
    table.insert(lines, "")
  end

  table.insert(lines, string.rep("─", math.max(10, config.options.pane_width - 4)))
  table.insert(lines, t("keys_help") .. ":")
  table.insert(lines, string.format("  %s: %s   %s: %s", k.next, t("key_next"), k.prev, t("key_prev")))
  table.insert(lines, string.format("  %s: %s   %s: %s", k.reset, t("key_reset"), k.hint, t("key_hint")))
  table.insert(lines, string.format("  %s: %s   %s: %s", k.solution, t("key_solution"), k.list, t("key_list")))
  table.insert(lines, string.format("  %s: %s", k.quit, t("key_quit")))
  local disp = prefix_display()
  if disp then
    local example = disp == "Space" and ("Space " .. k.next) or (disp .. k.next)
    table.insert(lines, "")
    for _, l in ipairs(vim.split(t("keys_help_practice", disp, example), "\n")) do
      table.insert(lines, l)
    end
  end

  vim.bo[S.pane_buf].modifiable = true
  vim.api.nvim_buf_set_lines(S.pane_buf, 0, -1, false, lines)
  vim.bo[S.pane_buf].modifiable = false
end

-- Problem loading -------------------------------------------------------------

local function load_current()
  local problem = S.problems[S.index]
  S.cleared = false
  S.show_hints = false
  S.show_solutions = false
  keys.reset()

  vim.api.nvim_buf_set_lines(S.practice_buf, 0, -1, false, problem.start)
  vim.bo[S.practice_buf].modified = false

  if valid_win(S.practice_win) then
    local row = math.min(problem.cursor[1], #problem.start)
    local line = problem.start[row] or ""
    local col = math.max(0, math.min(problem.cursor[2] - 1, math.max(0, #line - 1)))
    vim.api.nvim_win_set_cursor(S.practice_win, { row, col })
    vim.api.nvim_set_current_win(S.practice_win)
  end

  render_pane()
end

-- Clear detection -----------------------------------------------------------------

local function check_clear()
  if S.cleared or not S.active then
    return
  end
  local problem = S.problems[S.index]
  local buf_lines = vim.api.nvim_buf_get_lines(S.practice_buf, 0, -1, false)
  if engine.is_cleared(buf_lines, problem.goal) then
    S.cleared = true
    engine.mark_solved(S.progress, problem.id)
    vim.notify(t("cleared_with_keys", keys.count), vim.log.levels.INFO, { title = "vimro" })
    render_pane()
  end
end

-- Pane actions -----------------------------------------------------------------

local function next_problem()
  if S.index >= #S.problems then
    vim.notify(t("no_more_problems"), vim.log.levels.INFO, { title = "vimro" })
    return
  end
  S.index = S.index + 1
  load_current()
end

local function prev_problem()
  if S.index <= 1 then
    vim.notify(t("first_problem"), vim.log.levels.INFO, { title = "vimro" })
    return
  end
  S.index = S.index - 1
  load_current()
end

local function reset_problem()
  load_current()
end

local function pick_problem()
  local items = {}
  for idx, problem in ipairs(S.problems) do
    local text = i18n.resolve_problem(problem)
    local solved = engine.is_solved(S.progress, problem.id) and (" " .. t("solved_mark")) or ""
    table.insert(items, string.format("%d. %s%s", idx, text.title or problem.id, solved))
  end
  vim.ui.select(items, { prompt = t("select_problem") }, function(_, idx)
    if not idx then
      return
    end
    S.index = idx
    load_current()
  end)
end

local function toggle_hints()
  S.show_hints = not S.show_hints
  render_pane()
end

local function toggle_solutions()
  S.show_solutions = not S.show_solutions
  render_pane()
end

function M.quit()
  if not S.active then
    return
  end
  S.active = false
  keys.stop()

  -- If vimro was started from an empty Neovim, quit Neovim entirely
  -- (qa is non-forcing, so unsaved changes still block it as usual)
  if S.quit_all_on_exit then
    local ok = pcall(vim.cmd, "qa")
    if ok then
      return
    end
  end

  -- Tear down the layout first, then clean up the buffers
  local tab = S.tab
  if tab and vim.api.nvim_tabpage_is_valid(tab) then
    if #vim.api.nvim_list_tabpages() > 1 then
      vim.api.nvim_set_current_tabpage(tab)
      vim.cmd("tabclose")
    elseif valid_win(S.pane_win) then
      -- On the last tab, just close the problem pane window to undo the split
      pcall(vim.api.nvim_win_close, S.pane_win, true)
    end
  end
  for _, buf in ipairs({ S.practice_buf, S.pane_buf }) do
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  S.practice_buf, S.pane_buf, S.practice_win, S.pane_win, S.tab = nil, nil, nil, nil, nil
end

-- Layout setup -------------------------------------------------------------

local function setup_layout()
  vim.cmd("tabnew")
  S.tab = vim.api.nvim_get_current_tabpage()

  -- Left: practice buffer
  S.practice_win = vim.api.nvim_get_current_win()
  S.practice_buf = vim.api.nvim_get_current_buf()
  vim.bo[S.practice_buf].buftype = "nofile"
  vim.bo[S.practice_buf].swapfile = false
  vim.bo[S.practice_buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_name(S.practice_buf, "vimro://practice")

  -- Right: problem pane
  vim.cmd("rightbelow vsplit")
  S.pane_win = vim.api.nvim_get_current_win()
  S.pane_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(S.pane_win, S.pane_buf)
  vim.bo[S.pane_buf].buftype = "nofile"
  vim.bo[S.pane_buf].swapfile = false
  vim.bo[S.pane_buf].bufhidden = "wipe"
  vim.bo[S.pane_buf].modifiable = false
  vim.api.nvim_buf_set_name(S.pane_buf, "vimro://problem")
  vim.wo[S.pane_win].winfixwidth = true
  vim.wo[S.pane_win].number = false
  vim.wo[S.pane_win].relativenumber = false
  vim.wo[S.pane_win].wrap = true
  vim.api.nvim_win_set_width(S.pane_win, config.options.pane_width)

  -- Problem pane keymaps
  local k = config.options.keys
  local maps = {
    [k.next] = next_problem,
    [k.prev] = prev_problem,
    [k.reset] = reset_problem,
    [k.hint] = toggle_hints,
    [k.solution] = toggle_solutions,
    [k.list] = pick_problem,
    [k.quit] = M.quit,
  }
  for lhs, fn in pairs(maps) do
    vim.keymap.set("n", lhs, fn, { buffer = S.pane_buf, nowait = true, silent = true })
  end

  -- Provide the same actions in the practice buffer behind a prefix
  -- (taking plain n or r would break the very Vim behavior being trained)
  local prefix = config.options.practice_prefix
  if prefix and prefix ~= false then
    for lhs, fn in pairs(maps) do
      vim.keymap.set("n", prefix .. lhs, fn, { buffer = S.practice_buf, nowait = true, silent = true })
    end
  end

  -- Automatic clear detection
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = S.practice_buf,
    callback = check_clear,
  })
  -- End the session when the buffer is wiped
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = S.practice_buf,
    callback = function()
      vim.schedule(M.quit)
    end,
  })

  vim.api.nvim_set_current_win(S.practice_win)
end

-- Startup flow -----------------------------------------------------------------

local function is_fresh_nvim()
  if #vim.api.nvim_list_tabpages() > 1 then
    return false
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted
      and (vim.api.nvim_buf_get_name(buf) ~= "" or vim.bo[buf].modified) then
      return false
    end
  end
  return true
end

local function begin_session(category)
  local problems = engine.load_problems(category)
  if #problems == 0 then
    vim.notify(t("no_problems_found", category), vim.log.levels.ERROR, { title = "vimro" })
    return
  end
  -- If started from an empty Neovim (e.g. right after nvim +Vimro), quit Neovim entirely on exit
  S.quit_all_on_exit = is_fresh_nvim()
  S.problems = problems
  S.index = 1
  S.progress = engine.load_progress()
  S.active = true
  setup_layout()
  keys.start(S.practice_buf)
  load_current()
end

function M.start()
  if S.active then
    if valid_win(S.practice_win) then
      vim.api.nvim_set_current_win(S.practice_win)
    end
    return
  end
  -- This runs before a language is chosen, so keep the prompt language-neutral
  local langs = {
    { code = "en", label = "English" },
    { code = "ja", label = "日本語" },
  }
  vim.ui.select(langs, {
    prompt = "Select language / 言語を選択",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end
    config.options.lang = choice.code
    local categories = engine.list_categories()
    vim.ui.select(categories, { prompt = t("select_category") }, function(category)
      if not category then
        return
      end
      begin_session(category)
    end)
  end)
end

return M
