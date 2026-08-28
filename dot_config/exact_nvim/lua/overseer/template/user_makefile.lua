local overseer = require("overseer")

-- Repo-local task files that aren't the project's own top-level Makefile,
-- e.g. an app-specific Makefile in a monorepo. Checked relative to the
-- directory Overseer is run from (opts.dir). Every candidate that exists is
-- included, with tasks labeled by which file they came from.
local CANDIDATES = {
  "django/users/Makefile",
  "users/Makefile",
}

---@param opts overseer.SearchParams
---@return {rel: string, path: string}[]
local function find_user_makefiles(opts)
  local found = {}
  for _, rel in ipairs(CANDIDATES) do
    local path = vim.fs.joinpath(opts.dir, rel)
    if vim.fn.filereadable(path) == 1 then
      table.insert(found, { rel = rel, path = path })
    end
  end
  return found
end

---@param cwd string
---@param cb fun(targets: nil|string[], err: nil|string)
local function parse_make_targets(cwd, cb)
  overseer.builtin.system(
    { "make", "-rRpq" },
    {
      cwd = cwd,
      text = true,
      env = {
        ["LANG"] = "C.UTF-8",
      },
    },
    vim.schedule_wrap(function(out)
      if out.code ~= 0 and out.code ~= 1 then
        return cb(nil, out.stderr or out.stdout or "Error running 'make'")
      end

      local targets = {}
      local parsing = false
      local prev_line = ""
      for line in vim.gsplit(out.stdout, "\n") do
        if line:find("# Files") == 1 then
          parsing = true
        elseif line:find("# Finished Make") == 1 then
          break
        elseif parsing then
          if line:match("^[^%.#%s]") and prev_line:find("# Not a target") ~= 1 then
            local idx = line:find(":")
            if idx then
              table.insert(targets, line:sub(1, idx - 1))
            end
          end
        end
        prev_line = line
      end
      cb(targets, nil)
    end)
  )
end

---@type overseer.TemplateFileProvider
return {
  cache_key = function(opts)
    local found = find_user_makefiles(opts)
    if #found == 0 then
      return nil
    end
    local paths = {}
    for _, f in ipairs(found) do
      table.insert(paths, f.path)
    end
    return table.concat(paths, "|")
  end,
  generator = function(opts, cb)
    if vim.fn.executable("make") == 0 then
      return 'Command "make" not found'
    end
    local found = find_user_makefiles(opts)
    if #found == 0 then
      return "No user Makefile found"
    end

    local ret = {}
    local errors = {}
    local remaining = #found

    for _, f in ipairs(found) do
      local cwd = vim.fs.dirname(f.path)
      local label = f.rel:gsub("/Makefile$", "")
      parse_make_targets(cwd, function(targets, err)
        if err then
          table.insert(errors, string.format("%s: %s", label, err))
        else
          for _, target in ipairs(targets) do
            table.insert(ret, {
              name = string.format("user(%s): %s", label, target),
              builder = function()
                return {
                  cmd = { "make", target },
                  cwd = cwd,
                }
              end,
            })
          end
        end

        remaining = remaining - 1
        if remaining == 0 then
          if #ret == 0 and #errors > 0 then
            cb(table.concat(errors, "; "))
          else
            cb(ret)
          end
        end
      end)
    end
  end,
}
