local M = {}

--- Plugin root directory (two levels up from this file)
function M.root()
  local src = debug.getinfo(1, "S").source:sub(2)
  return vim.fn.fnamemodify(src, ":h:h:h")
end

--- List available categories (subdirectories of problems/)
function M.list_categories()
  local dirs = vim.fn.glob(M.root() .. "/problems/*", false, true)
  local cats = {}
  for _, dir in ipairs(dirs) do
    if vim.fn.isdirectory(dir) == 1 then
      table.insert(cats, vim.fn.fnamemodify(dir, ":t"))
    end
  end
  table.sort(cats)
  return cats
end

--- Load problems/<category>/*.json, sorted by difficulty then id
function M.load_problems(category)
  local pattern = M.root() .. "/problems/" .. category .. "/*.json"
  local files = vim.fn.glob(pattern, false, true)
  local problems = {}
  for _, file in ipairs(files) do
    local lines = vim.fn.readfile(file)
    local ok, problem = pcall(vim.json.decode, table.concat(lines, "\n"))
    if ok and problem and problem.id then
      table.insert(problems, problem)
    else
      vim.notify("vimro: failed to parse " .. file, vim.log.levels.WARN)
    end
  end
  table.sort(problems, function(a, b)
    local da, db = a.difficulty or 0, b.difficulty or 0
    if da ~= db then
      return da < db
    end
    return a.id < b.id
  end)
  return problems
end

--- Normalization for matching: strip trailing whitespace and drop trailing blank lines
local function normalize(lines)
  local out = {}
  for _, line in ipairs(lines) do
    table.insert(out, (line:gsub("%s+$", "")))
  end
  while #out > 0 and out[#out] == "" do
    table.remove(out)
  end
  return out
end

--- Whether the buffer matches the goal (trailing whitespace/blank lines ignored; line contents and count are strict)
function M.is_cleared(buf_lines, goal)
  local a = normalize(buf_lines)
  local b = normalize(goal)
  if #a ~= #b then
    return false
  end
  for i = 1, #a do
    if a[i] ~= b[i] then
      return false
    end
  end
  return true
end

-- Progress

local function progress_path()
  return vim.fn.stdpath("data") .. "/vimro/progress.json"
end

function M.load_progress()
  local path = progress_path()
  if vim.fn.filereadable(path) == 1 then
    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
    if ok and type(data) == "table" and type(data.solved) == "table" then
      return data
    end
  end
  return { solved = {} }
end

function M.is_solved(progress, id)
  for _, solved_id in ipairs(progress.solved) do
    if solved_id == id then
      return true
    end
  end
  return false
end

function M.mark_solved(progress, id)
  if M.is_solved(progress, id) then
    return
  end
  table.insert(progress.solved, id)
  local path = progress_path()
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  vim.fn.writefile({ vim.json.encode(progress) }, path)
end

return M
