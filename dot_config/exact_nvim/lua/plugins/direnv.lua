local env_paths = {
  "build/.env",
  "django/build/.env",
}

local function prepend_env(name, path)
  local value = vim.env[name] or ""
  if (":" .. value .. ":"):find(":" .. path .. ":", 1, true) then
    return
  end
  vim.env[name] = value == "" and path or path .. ":" .. value
end

local function is_file(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type == "file"
end

local function find_env_from(start)
  if not start or start == "" then
    return nil
  end

  local dir = vim.fs.normalize(start)
  local stat = vim.uv.fs_stat(dir)
  if stat and stat.type ~= "directory" then
    dir = vim.fs.dirname(dir)
  end

  while dir and dir ~= "" do
    for _, env_path in ipairs(env_paths) do
      local path = vim.fs.joinpath(dir, env_path)
      if is_file(path) then
        return path
      end
    end

    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
end

local function find_env_file()
  return find_env_from(vim.api.nvim_buf_get_name(0)) or find_env_from(vim.uv.cwd())
end

local function brew_lib()
  if vim.fn.executable("brew") ~= 1 then
    return nil
  end

  local result = vim.system({ "brew", "--prefix", "cairo" }, { text = true }):wait()
  if result.code ~= 0 then
    return nil
  end

  return vim.fs.joinpath(vim.trim(result.stdout), "lib")
end

local function load_project_env()
  local env_file = find_env_file()
  if not env_file then
    return
  end

  require("dotenv").command({ fargs = { env_file } })

  local django_root = vim.fs.dirname(vim.fs.dirname(env_file))
  if vim.env.DB_HOST then
    vim.env.DB_HOST = "localhost"
  end
  if vim.env.REDIS_HOST then
    vim.env.REDIS_HOST = "localhost"
  end
  vim.env.PYDEVD_USE_SYS_MONITORING = "False"

  prepend_env("PYTHONPATH", django_root)

  local cairo_lib = brew_lib()
  if cairo_lib then
    prepend_env("DYLD_LIBRARY_PATH", cairo_lib)
    prepend_env("DYLD_FALLBACK_LIBRARY_PATH", cairo_lib)
  end

  if vim.uv.cwd() ~= django_root then
    vim.cmd.cd(django_root)
  end
end

return {
  {
    "ellisonleao/dotenv.nvim",
    config = function()
      require("dotenv").setup({ verbose = false })
      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("mabyduck_env", { clear = true }),
        once = true,
        callback = load_project_env,
      })
    end,
  },
}
