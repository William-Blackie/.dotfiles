local defaults = require("css-vars.default_config")

local M = {}

local cache_key
local css_variables
local loading = false

local function current_dir()
  return (vim.uv or vim.loop).cwd()
end

local function make_cache_key(config)
  return current_dir() .. "\0" .. table.concat(config.search_extensions or {}, "\0")
end

local function parse_variables(output)
  local items = {}
  local seen = {}

  for line in (output or ""):gmatch("[^\r\n]+") do
    local css_var, css_value = line:match("^'(%-%-[^']+)' '(.-)'")
    if css_var and not seen[css_var] then
      seen[css_var] = true
      table.insert(items, {
        label = css_var,
        filterText = css_var,
        documentation = css_value,
      })
    end
  end

  return items
end

local function refresh(config)
  if loading then
    return
  end

  loading = true

  local args = {
    "rg",
    "-e",
    "[^\\w](--[^:)]*):([^;]+);",
    "-r",
    "'$1' '$2'",
    "-o",
    "--no-filename",
  }

  for _, extension in ipairs(config.search_extensions or {}) do
    table.insert(args, "-g")
    table.insert(args, "*" .. extension)
  end

  table.insert(args, current_dir())

  vim.system(args, { text = true }, function(result)
    vim.schedule(function()
      loading = false

      if result.code == 0 then
        css_variables = parse_variables(result.stdout)
      elseif result.code == 1 then
        css_variables = {}
      else
        css_variables = {}
        vim.notify(result.stderr or "Failed to load CSS variables", vim.log.levels.WARN)
      end
    end)
  end)
end

local function css_var_prefix_start(context)
  local before_cursor = context.line:sub(1, context.cursor[2])
  return before_cursor:find("%-%-[-_%w]*$")
end

local function completion_items(items, context, prefix_start)
  local range = {
    start = {
      line = context.cursor[1] - 1,
      character = prefix_start - 1,
    },
    ["end"] = {
      line = context.cursor[1] - 1,
      character = context.cursor[2],
    },
  }

  return vim.tbl_map(function(item)
    return vim.tbl_extend("force", item, {
      kind = vim.lsp.protocol.CompletionItemKind.Variable,
      textEdit = {
        newText = item.label,
        range = range,
      },
    })
  end, items)
end

function M.new(opts)
  local config = vim.tbl_deep_extend("force", defaults, opts or {})
  local key = make_cache_key(config)

  if cache_key ~= key then
    cache_key = key
    css_variables = nil
    refresh(config)
  elseif not css_variables then
    refresh(config)
  end

  return setmetatable({ config = config }, { __index = M })
end

function M:get_trigger_characters()
  return { "-" }
end

function M:get_completions(context, callback)
  local prefix_start = css_var_prefix_start(context)

  if not prefix_start then
    callback({ is_incomplete_forward = true, is_incomplete_backward = true, items = {} })
    return
  end

  if not css_variables then
    refresh(self.config)
    callback({ is_incomplete_forward = true, is_incomplete_backward = true, items = {} })
    return
  end

  callback({
    is_incomplete_forward = true,
    is_incomplete_backward = true,
    items = completion_items(css_variables, context, prefix_start),
  })
end

function M:reload()
  css_variables = nil
  refresh(self.config)
end

return M
