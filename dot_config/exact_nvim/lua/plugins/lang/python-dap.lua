local root_markers = { "manage.py", "pyproject.toml", "pytest.ini", "setup.cfg", ".git" }

---@param path string
---@return string
local function project_root(path)
  return vim.fs.root(path, root_markers)
    or assert(vim.uv.cwd(), "Unable to determine current working directory")
end

local service_by_site = {
  admin = "django-admin",
  api = "django-api",
  app = "django-app",
  cms = "django-cms",
  flock = "django-flock",
  www = "django-www",
  xp = "django-xp",
}

---@param path string|nil
---@return string|nil
local function site_from_path(path)
  return path and path:match("/sites/([^/]+)/") or nil
end

---@param path string|nil
---@return string
local function docker_service(path)
  return os.getenv("NEOTEST_DOCKER_SERVICE")
    or os.getenv("NVIM_DAP_DOCKER_SERVICE")
    or service_by_site[site_from_path(path)]
    or "django-app"
end

local docker_compose = {
  service = function(_, position)
    local path = position and (position.path or position.id)
    return docker_service(path)
  end,
  python = os.getenv("NVIM_DAP_DOCKER_PYTHON")
    or os.getenv("NEOTEST_DOCKER_PYTHON")
    or "python",
  platform = os.getenv("NVIM_DAP_DOCKER_PLATFORM") or os.getenv(
    "NEOTEST_DOCKER_PLATFORM"
  ) or os.getenv("DOCKER_DEFAULT_PLATFORM") or "linux/amd64",
  debug = {
    host = os.getenv("NVIM_DAP_DOCKER_HOST") or "127.0.0.1",
    port = tonumber(
      os.getenv("NVIM_DAP_DOCKER_DEBUG_PORT")
        or os.getenv("NEOTEST_DOCKER_DEBUG_PORT")
        or "5678"
    ),
  },
}

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
  if site and vim.uv.fs_stat(root .. "/sites/" .. site .. "/settings/test.py") then
    return "sites." .. site .. ".settings.test"
  end
  return "sites.app.settings.test"
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

---@param overrides? table
---@return table
local function docker_debug_configuration(overrides)
  return require("neotest-python.docker").debug_configuration(
    vim.tbl_deep_extend("force", vim.deepcopy(docker_compose), overrides or {})
  )
end

---@return table
local function django_debug_configuration()
  return docker_debug_configuration({
    name = function(context)
      return "Django: Docker Compose (" .. context.service .. ")"
    end,
    root = project_root,
    command = {
      "./manage.py",
      "runserver",
      "--noreload",
      "0.0.0.0:" .. (os.getenv("NVIM_DAP_DOCKER_APP_PORT") or "80"),
    },
  })
end

---@type table[]
local plugins = {
  {
    "nvim-neotest/neotest-python",
    url = "https://github.com/William-Blackie/neotest-python.git",
    branch = "williamblackie/docker-path-mappings",
    dev = true,
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
          runner = "pytest",
          root = project_root,
          python = { "python" },
          docker = docker_compose,
          args = function(_, position)
            local path = position and (position.path or position.id)
            local root = path and project_root(path) or vim.uv.cwd()
            local docker = require("neotest-python.docker")
            if docker.context(docker_compose, root, position) then
              return { "--ds=" .. django_settings_module(root, position) }
            end
            return {}
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
          require("dap").run(django_debug_configuration()())
        end,
        desc = "Debug Django Docker",
      },
    },
  },

  {
    "mfussenegger/nvim-dap-python",
    config = function()
      require("dap-python").setup(debugpy_adapter())
      local docker = require("neotest-python.docker")
      docker.setup_dap()

      local dap = require("dap")
      dap.defaults.python = dap.defaults.python or {}
      dap.defaults.python.exception_breakpoints = {}
      ---@type table<string, any>
      local docker_defaults = dap.defaults[docker.adapter_name]
      docker_defaults.exception_breakpoints = {}

      dap.configurations.python = dap.configurations.python or {}
      table.insert(
        dap.configurations.python,
        docker_debug_configuration({
          name = "Attach: Docker Compose",
          root = project_root,
        })
      )
      table.insert(dap.configurations.python, django_debug_configuration())

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
