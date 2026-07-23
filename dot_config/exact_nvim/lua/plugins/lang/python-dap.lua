local root_markers = { "manage.py", "pyproject.toml", "pytest.ini", "setup.cfg", ".git" }

---@param path string
---@return string
local function project_root(path)
  return vim.fs.root(path, root_markers)
    or assert(vim.uv.cwd(), "Unable to determine current working directory")
end

---@param path string|nil
---@return string|nil
local function site_from_path(path)
  return path and path:match("/sites/([^/]+)/") or nil
end

---@param suffix string
---@param default string|nil
---@return string|nil
local function docker_env(suffix, default)
  return os.getenv("NVIM_DAP_DOCKER_" .. suffix)
    or os.getenv("NEOTEST_DOCKER_" .. suffix)
    or default
end

local docker_compose = {
  python = docker_env("PYTHON", "python"),
  platform = docker_env("PLATFORM")
    or os.getenv("DOCKER_DEFAULT_PLATFORM")
    or "linux/amd64",
  debug = {
    host = docker_env("HOST", "127.0.0.1"),
    port = tonumber(docker_env("DEBUG_PORT", "5678")),
  },
}

local compose_files =
  { "compose.yaml", "compose.yml", "docker-compose.yaml", "docker-compose.yml" }

---@param path string|nil
---@return string|nil
local function current_path(path)
  if path and path ~= "" then
    return path
  end
  local ok, current = pcall(vim.api.nvim_buf_get_name, 0)
  if ok and current ~= "" then
    return current
  end
  return vim.uv.cwd()
end

---@param root string
---@return string|nil
local function compose_file(root)
  for _, file in ipairs(compose_files) do
    local path = root .. "/" .. file
    if vim.uv.fs_stat(path) then
      return path
    end
  end
end

---@param root string
---@return boolean
local function is_django_docker_root(root)
  return compose_file(root) ~= nil and vim.uv.fs_stat(root .. "/manage.py") ~= nil
end

local compose_content_cache = {}

---@param root string
---@return string|nil
local function compose_content(root)
  if compose_content_cache[root] == nil then
    local file = compose_file(root)
    local handle = file and io.open(file, "r") or nil
    compose_content_cache[root] = false
    if handle then
      compose_content_cache[root] = handle:read("*a") or false
      handle:close()
    end
  end
  return compose_content_cache[root] or nil
end

---@param root string
---@return string
local function remote_root(root)
  local configured = docker_env("REMOTE_ROOT")
  if configured then
    return configured
  end

  local content = compose_content(root)
  if content and content:find("/www/mabyduck/django", 1, true) then
    return "/www/mabyduck/django"
  end

  if root:match("/mabyduck/.+/django$") then
    return "/www/mabyduck/django"
  end

  return "/app"
end

---@param root string
---@param path string|nil
---@return string
local function docker_service(root, path)
  local override = docker_env("SERVICE")
  if override then
    return override
  end

  local site = site_from_path(path)
  local content = site and compose_content(root)
  if content and content:find("\n  django-" .. site .. ":", 1, true) then
    return "django-" .. site
  end
  return "django-app"
end

---@param root string
---@return table
local function path_mappings(root)
  return {
    [root] = remote_root(root),
  }
end

---@param root string
---@return string[]
local function compose_command(root)
  local command = { "docker", "compose" }
  local file = compose_file(root)
  if file then
    vim.list_extend(command, { "-f", file })
  end
  return command
end

---@param root string
---@return string|nil
local function env_file(root)
  local local_env = root .. "/build/.env"
  if vim.uv.fs_stat(local_env) then
    return local_env
  end

  local mabyduck_env = "/Users/william/Projects/work/mabyduck/main/django/build/.env"
  if root:match("/mabyduck/.+/django$") and vim.uv.fs_stat(mabyduck_env) then
    return mabyduck_env
  end
end

---@param root string
---@return table
local function compose_env(root)
  local env = { DOCKER_DEFAULT_PLATFORM = docker_compose.platform }
  local file = env_file(root)
  if file then
    env.ENV_FILE = file
  end
  return env
end

---@param root string
---@param position table|string|nil
---@return string
local function django_settings_module(root, position)
  local path = ""
  if type(position) == "table" then
    path = position.path or position.id or ""
  elseif type(position) == "string" then
    path = position
  end

  local site = site_from_path(path)
  if
    site
    and site ~= "common"
    and vim.uv.fs_stat(root .. "/sites/" .. site .. "/settings/test.py")
  then
    return "sites." .. site .. ".settings.test"
  end
  return "sites.app.settings.test"
end

---@param root string
---@param position table|string|nil
---@param debug boolean|nil
---@return string[]
local function docker_env_args(root, position, debug)
  local env = {
    "DJANGO_SETTINGS_MODULE=" .. django_settings_module(root, position),
    "PYTHONPATH=" .. remote_root(root),
  }
  if debug then
    env[#env + 1] = "NEOTEST_PYTHON_DISABLE_POSTMORTEM=1"
  end

  local args = {}
  for _, item in ipairs(env) do
    vim.list_extend(args, { "-e", item })
  end
  return args
end

---@param root string
---@param position table|string|nil
---@param debug boolean|nil
---@return string[]
local function docker_exec_command(root, position, debug)
  local path = type(position) == "table" and (position.path or position.id) or position
  local command = compose_command(root)
  vim.list_extend(command, { "exec", "-T", "-w", remote_root(root) })
  vim.list_extend(command, docker_env_args(root, position or current_path(path), debug))
  table.insert(command, docker_service(root, path))
  return command
end

---@param root string
---@param position table|string|nil
---@param debug boolean|nil
---@return string[]
local function docker_run_command(root, position, debug)
  local path = type(position) == "table" and (position.path or position.id) or position
  local command = compose_command(root)
  vim.list_extend(command, { "run", "--rm", "--no-deps", "-T", "-w", remote_root(root) })
  vim.list_extend(command, docker_env_args(root, position or current_path(path), debug))
  vim.list_extend(
    command,
    { "--entrypoint", docker_compose.python, docker_service(root, path) }
  )
  return command
end

---@param root string
---@param position table|string|nil
---@return string[]
local function python_command(root, position)
  if not is_django_docker_root(root) then
    return { docker_compose.python }
  end

  return docker_run_command(root, position or current_path(), false)
end

---@return string
local function debugpy_adapter()
  local mason_adapter = vim.fn.stdpath("data") .. "/mason/bin/debugpy-adapter"
  if vim.fn.executable(mason_adapter) == 1 then
    return mason_adapter
  end
  if vim.fn.executable("debugpy-adapter") == 1 then
    return "debugpy-adapter"
  end
  return "python3"
end

---@param root string
---@param position table|string|nil
---@param name string
---@return table
local function docker_attach_configuration(root, position, name)
  local mappings = {}
  for local_root, docker_root in pairs(path_mappings(root)) do
    mappings[#mappings + 1] = {
      localRoot = local_root,
      remoteRoot = docker_root,
    }
  end

  return {
    type = "python",
    name = name,
    request = "attach",
    connect = vim.deepcopy(docker_compose.debug),
    pathMappings = mappings,
    django = true,
    justMyCode = false,
  }
end

---@param root string
---@param position table|string|nil
---@param context table|nil
local function start_debugpy(root, position, context)
  local command
  if context and context.remote_script_path then
    command = docker_run_command(root, position, true)
  else
    command = docker_exec_command(root, position, true)
    table.insert(command, docker_compose.python)
  end

  vim.list_extend(command, {
    "-m",
    "debugpy",
    "--listen",
    "0.0.0.0:" .. docker_compose.debug.port,
    "--wait-for-client",
  })

  if context and context.remote_script_path then
    table.insert(command, context.remote_script_path)
    vim.list_extend(command, context.script_args or {})
  else
    vim.list_extend(command, {
      "./manage.py",
      "runserver",
      "--noreload",
      "0.0.0.0:" .. docker_env("APP_PORT", "80"),
    })
  end

  vim.system(command, { cwd = root, env = compose_env(root) }, function(result)
    if result.code ~= 0 then
      vim.schedule(function()
        vim.notify(result.stderr, vim.log.levels.ERROR)
      end)
    end
  end)
  vim.wait(800, function()
    return false
  end)
end

---@param config table
local function run_dap_config(config)
  local before = config.before
  config.before = nil
  if before then
    before()
  end
  require("dap").run(config)
end

---@return table
local function django_debug_configuration()
  return function()
    local path = current_path()
    local root = project_root(path)
    local service = docker_service(root, path)
    local config = docker_attach_configuration(
      root,
      { path = path },
      "Django: Docker Compose (" .. service .. ")"
    )
    config.before = function()
      start_debugpy(root, { path = path })
    end
    return config
  end
end

---@type table[]
local plugins = {
  {
    "nvim-neotest/neotest-python",
    dir = "/Users/william/Projects/neotest-python",
    url = "https://github.com/William-Blackie/neotest-python.git",
    branch = "williamblackie/docker-path-mappings",
  },

  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    keys = {
      {
        "<leader>tt",
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "Run File (Neotest)",
      },
      {
        "<leader>tT",
        function()
          local path = vim.api.nvim_buf_get_name(0)
          require("neotest").run.run(path ~= "" and project_root(path) or vim.uv.cwd())
        end,
        desc = "Run All Test Files (Neotest)",
      },
      {
        "<leader>tr",
        function()
          require("neotest").run.run()
        end,
        desc = "Run Nearest (Neotest)",
      },
      {
        "<leader>td",
        function()
          require("neotest").run.run({ strategy = "dap", suite = false })
        end,
        desc = "Debug Nearest",
      },
    },
    opts = {
      adapters = {
        ["neotest-python"] = {
          root = project_root,
          python = python_command,
          runner = function(command)
            for _, arg in ipairs(command) do
              if arg:match("^DJANGO_SETTINGS_MODULE=") then
                return "django"
              end
            end
            return require("neotest-python.base").get_runner(command)
          end,
          cwd = function(root)
            return root
          end,
          env = function(root)
            if is_django_docker_root(root) then
              return compose_env(root)
            end
            return {}
          end,
          path_mappings = function(root)
            if is_django_docker_root(root) then
              return path_mappings(root)
            end
            return {}
          end,
          args = function(runner, position)
            local path = position and (position.path or position.id)
            local root = path and project_root(path) or vim.uv.cwd()
            if runner == "pytest" and is_django_docker_root(root) then
              return { "--ds=" .. django_settings_module(root, position) }
            end
            return {}
          end,
          dap = function(root, position, default_config, context)
            if not is_django_docker_root(root) then
              return default_config
            end
            return vim.tbl_deep_extend(
              "force",
              default_config,
              docker_attach_configuration(root, position, "Debug Test: Docker Compose"),
              {
                before = function()
                  start_debugpy(root, position, context)
                end,
              }
            )
          end,
        },
      },
    },
    config = function(_, opts)
      -- Hook neotest's subprocess lib to include nvim-treesitter in the child process rtp
      local ok, subprocess = pcall(require, "neotest.lib.subprocess")
      if ok and subprocess.add_paths_to_rtp then
        local original_add_paths = subprocess.add_paths_to_rtp
        subprocess.add_paths_to_rtp = function(paths)
          local resolved_paths = {}
          for _, path in ipairs(paths) do
            if type(path) == "function" then
              local root = subprocess.resolve_plugin_root(path)
              if root then
                table.insert(resolved_paths, root)
              end
            elseif type(path) == "string" then
              table.insert(resolved_paths, path)
            end
          end

          if pcall(require, "nvim-treesitter") then
            local ts_files =
              vim.api.nvim_get_runtime_file("lua/nvim-treesitter/config.lua", false)
            if ts_files and ts_files[1] then
              local ts_root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(ts_files[1])))
              if ts_root and not vim.tbl_contains(resolved_paths, ts_root) then
                table.insert(resolved_paths, ts_root)
              end
            end
          end
          original_add_paths(resolved_paths)
        end
      end

      if os.getenv("TEST_HEADLESS_RUN") then
        opts.consumers = opts.consumers or {}
        opts.consumers.test_headless_run = function(client)
          client.listeners.results = function(_, results, partial)
            if partial then
              return
            end
            local result_file = io.open("/tmp/neotest_headless_output.json", "w")
            if result_file then
              result_file:write(vim.json.encode(results))
              result_file:close()
            end
            vim.schedule(function()
              vim.cmd("qa!")
            end)
          end
          return {}
        end
      end

      if opts.adapters then
        local adapters = {}
        for name, config in pairs(opts.adapters) do
          if type(name) == "number" then
            if type(config) == "string" then
              config = require(config)
            end
            adapters[#adapters + 1] = config
          elseif config ~= false then
            local adapter = require(name)
            if type(config) == "table" and not vim.tbl_isempty(config) then
              local meta = getmetatable(adapter)
              if adapter.setup then
                adapter.setup(config)
              elseif adapter.adapter then
                adapter.adapter(config)
                adapter = adapter.adapter
              elseif meta and meta.__call then
                adapter = adapter(config)
              else
                error("Adapter " .. name .. " does not support setup")
              end
            end
            adapters[#adapters + 1] = adapter
          end
        end
        opts.adapters = adapters
      end

      require("neotest").setup(opts)
    end,
  },

  {
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle Breakpoint",
      },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "Continue",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "Step Into",
      },
      {
        "<leader>do",
        function()
          require("dap").step_over()
        end,
        desc = "Step Over",
      },
      {
        "<leader>dO",
        function()
          require("dap").step_out()
        end,
        desc = "Step Out",
      },
      {
        "<leader>du",
        function()
          require("dapui").toggle()
        end,
        desc = "Toggle DAP UI",
      },
      {
        "<leader>dD",
        function()
          run_dap_config(django_debug_configuration()())
        end,
        desc = "Debug Django Docker",
      },
    },
  },

  {
    "mfussenegger/nvim-dap-python",
    config = function()
      require("dap-python").setup(debugpy_adapter())

      local dap = require("dap")
      dap.defaults.python = dap.defaults.python or {}
      dap.defaults.python.exception_breakpoints = {}

      dap.configurations.python = dap.configurations.python or {}
      table.insert(
        dap.configurations.python,
        setmetatable({ name = "Attach: Docker Compose" }, {
          __call = function()
            local path = current_path()
            return docker_attach_configuration(
              project_root(path),
              { path = path },
              "Attach: Docker Compose"
            )
          end,
        })
      )

      dap.listeners.after.event_initialized["dapui_config"] = function()
        vim.schedule(function()
          pcall(function()
            require("dapui").open({})
          end)
        end)
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        vim.schedule(function()
          pcall(function()
            require("dapui").close({})
          end)
        end)
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        vim.schedule(function()
          pcall(function()
            require("dapui").close({})
          end)
        end)
      end
    end,
  },
}

return plugins
