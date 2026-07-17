local config = require("vimro.config")

local M = {}

local cache = {}

local function load(lang)
  if cache[lang] == nil then
    local ok, tbl = pcall(require, "vimro.i18n." .. lang)
    cache[lang] = ok and tbl or false
  end
  return cache[lang] or nil
end

--- Look up a UI string, falling back: selected lang -> fallback_lang -> the key itself.
function M.t(key, ...)
  local opts = config.options
  local msg
  for _, lang in ipairs({ opts.lang, opts.fallback_lang }) do
    local tbl = load(lang)
    if tbl and tbl[key] then
      msg = tbl[key]
      break
    end
  end
  msg = msg or key
  if select("#", ...) > 0 then
    return string.format(msg, ...)
  end
  return msg
end

--- Resolve a problem's i18n.{lang}; fall back to fallback_lang when missing.
function M.resolve_problem(problem)
  local opts = config.options
  local i18n = problem.i18n or {}
  return i18n[opts.lang] or i18n[opts.fallback_lang] or select(2, next(i18n)) or {}
end

return M
