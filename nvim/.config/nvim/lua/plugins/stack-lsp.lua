vim.g.lazyvim_python_lsp = "basedpyright"

return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      local servers = {
        "basedpyright",
        "ruff",
        "eslint",
        "gopls",
        "vtsls",
        "bashls",
        "jsonls",
        "marksman",
        "taplo",
        "docker_language_server",
        "docker_compose_language_service",
      }
      for _, server in ipairs(servers) do
        if not vim.tbl_contains(opts.ensure_installed, server) then
          table.insert(opts.ensure_installed, server)
        end
      end
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      local tools = {
        "basedpyright",
        "ruff",
        "pyflakes",
        "mypy",
        "gopls",
        "vtsls",
        "lua-language-server",
        "yaml-language-server",
        "json-lsp",
        "bash-language-server",
        "docker-language-server",
        "docker-compose-language-service",
      }
      for _, tool in ipairs(tools) do
        if not vim.tbl_contains(opts.ensure_installed, tool) then
          table.insert(opts.ensure_installed, tool)
        end
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      local function as_table(value)
        return type(value) == "table" and value or {}
      end

      opts.servers.basedpyright = vim.tbl_deep_extend("force", as_table(opts.servers.basedpyright), {
        enabled = true,
        settings = {
          basedpyright = {
            analysis = {
              typeCheckingMode = "standard",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "openFilesOnly",
            },
            disableOrganizeImports = true,
          },
        },
      })

      opts.servers.ruff = vim.tbl_deep_extend("force", as_table(opts.servers.ruff), {
        init_options = {
          settings = {
            logLevel = "error",
          },
        },
        on_attach = function(client)
          -- Let basedpyright own hover and type-driven UX in Python buffers.
          client.server_capabilities.hoverProvider = false
        end,
      })

      opts.servers.eslint = vim.tbl_deep_extend("force", as_table(opts.servers.eslint), {
        settings = {
          workingDirectory = { mode = "auto" },
          format = { enable = true },
        },
      })

      opts.servers.gopls = vim.tbl_deep_extend("force", as_table(opts.servers.gopls), {
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
              shadow = true,
            },
            staticcheck = true,
            gofumpt = true,
          },
        },
      })

      opts.servers.jsonls = vim.tbl_deep_extend("force", as_table(opts.servers.jsonls), {
        settings = {
          json = {
            validate = { enable = true },
          },
        },
      })

      opts.servers.bashls = opts.servers.bashls or {}
      opts.servers.dockerls = { enabled = false }
      opts.servers.docker_language_server = opts.servers.docker_language_server or {}
      opts.servers.docker_compose_language_service = opts.servers.docker_compose_language_service or {}
      opts.servers.marksman = opts.servers.marksman or {}
      opts.servers.taplo = opts.servers.taplo or {}
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        python = { "ruff_format" },
      },
    },
  },
}
