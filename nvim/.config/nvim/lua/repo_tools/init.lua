local M = {}

local defaults = {
  repo_type = "generic",
  root_markers = {
    ".git",
    "pyproject.toml",
    "package.json",
    "go.mod",
    "Cargo.toml",
    "Makefile",
  },
  paths = {
    models = { "app/models", "apps/**/models", "models", "src/**/models" },
    serializers = { "app/serializers", "apps/**/serializers", "serializers" },
    views = { "app/views", "apps/**/views", "views", "src/**/views" },
    routes = { "config/routes", "config", ".", "src/**/routes", "app/**/routes" },
    tests = { "tests", "spec", "src/**/tests", "app/**/tests" },
    templates = { "templates", "app/**/templates" },
    infra = { ".github/workflows", "k8s", "helm", "docker", "." },
    env = { ".env", ".env.example", ".envrc", "docker-compose.yml", "compose.yml", "Makefile", ".github/workflows", "k8s", "helm" },
  },
}

local function cfg()
  return vim.tbl_deep_extend("force", {}, defaults, vim.g.repo_tools or {})
end

local function current_buf_name()
  return vim.api.nvim_buf_get_name(0)
end

local function basename_without_ext(path)
  local name = vim.fn.fnamemodify(path, ":t:r")
  name = name:gsub("^test_", "")
  name = name:gsub("_test$", "")
  name = name:gsub("%.spec$", "")
  name = name:gsub("%.test$", "")
  return name
end

local function split_words(name)
  local out = {}
  for part in name:gmatch("[^_%-%./]+") do
    out[#out + 1] = part
  end
  if #out == 0 then
    out[1] = name
  end
  return out
end

local function current_words()
  return split_words(basename_without_ext(current_buf_name()))
end

local function current_basename()
  return basename_without_ext(current_buf_name())
end

local function current_symbol()
  local cword = vim.fn.expand("<cword>")
  if cword and cword ~= "" then
    return cword
  end
  return current_basename()
end

local function root()
  local file = current_buf_name()
  local start = file ~= "" and vim.fs.dirname(file) or vim.loop.cwd()
  local marker = vim.fs.find(cfg().root_markers, { upward = true, path = start })[1]
  if marker then
    return vim.fs.dirname(marker)
  end
  return vim.loop.cwd()
end

local function flatten(list)
  local out = {}
  for _, item in ipairs(list or {}) do
    if type(item) == "table" then
      for _, inner in ipairs(item) do
        out[#out + 1] = inner
      end
    else
      out[#out + 1] = item
    end
  end
  return out
end

local function rg_args(patterns, groups)
  local globs = flatten(groups)
  local args = {
    "rg",
    "--hidden",
    "--glob",
    "!.git",
    "--line-number",
    "--column",
    "--smart-case",
    "--no-heading",
  }

  for _, glob in ipairs(globs) do
    args[#args + 1] = "-g"
    args[#args + 1] = glob .. "/**"
  end

  args[#args + 1] = table.concat(patterns, "|")
  args[#args + 1] = root()
  return args
end

local function file_candidates()
  local paths = cfg().paths
  local name = current_basename()
  local words = current_words()
  local slug = table.concat(words, "_")
  local dashed = table.concat(words, "-")

  return rg_args({ name, slug, dashed }, {
    paths.models,
    paths.serializers,
    paths.views,
    paths.routes,
    paths.tests,
    paths.templates,
    paths.infra,
  })
end

local function tests_candidates()
  local paths = cfg().paths
  local name = current_basename()
  local symbol = current_symbol()
  return rg_args({ name, symbol, "test_" .. name, name .. "_test", name .. "%.spec", name .. "%.test" }, { paths.tests })
end

local function route_candidates()
  local paths = cfg().paths
  local name = current_basename()
  local symbol = current_symbol()
  return rg_args({ name, symbol, "router%.register", "urlpatterns", "path%(", "re_path%(" }, { paths.routes, paths.views })
end

local function env_candidates()
  local paths = cfg().paths
  local symbol = current_symbol()
  return rg_args({ symbol, "getenv", "os%.environ", "env%(", "secret", "configmap" }, { paths.env, paths.infra })
end

local function blast_candidates()
  local paths = cfg().paths
  local symbol = current_symbol()
  return rg_args({ symbol }, {
    paths.models,
    paths.serializers,
    paths.views,
    paths.routes,
    paths.tests,
    paths.templates,
    paths.infra,
  })
end

local function snacks_grep(title, args)
  local ok, Snacks = pcall(require, "snacks")
  if not ok then
    vim.notify("repo_tools requires Snacks.nvim", vim.log.levels.ERROR)
    return
  end

  Snacks.picker.grep({
    prompt = title,
    args = args,
  })
end

function M.related()
  snacks_grep("Repo Related", file_candidates())
end

function M.tests()
  snacks_grep("Repo Tests", tests_candidates())
end

function M.routes()
  snacks_grep("Repo Routes", route_candidates())
end

function M.env()
  snacks_grep("Repo Env", env_candidates())
end

function M.blast()
  snacks_grep("Repo Blast Radius", blast_candidates())
end

function M.setup()
  vim.api.nvim_create_user_command("RepoRelated", M.related, {})
  vim.api.nvim_create_user_command("RepoTests", M.tests, {})
  vim.api.nvim_create_user_command("RepoRoutes", M.routes, {})
  vim.api.nvim_create_user_command("RepoEnv", M.env, {})
  vim.api.nvim_create_user_command("RepoBlast", M.blast, {})
end

return M
