return {
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "pyright",
        "ruff_lsp",
        "lua_ls",
        "bashls",
        "tsserver",
        "jsonls",
        "yamlls",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Let Ruff handle diagnostics/quickfixes; Pyright handles hover/typing
        ruff_lsp = {
          on_attach = function(client, _)
            client.server_capabilities.hoverProvider = false
          end,
        },
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "standard", -- change to "strict" if you want
                autoImportCompletions = true,
              },
            },
          },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_format", "black", "isort" },
        lua = { "stylua" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        json = { "jq" },
        yaml = { "yamlfmt" },
        htmldjango = { "djlint" },
      },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 2000, lsp_fallback = true }
      end,
      formatters = {
        djlint = { prepend_args = { "--profile=django" } },
      },
    },
  },
  -- Optional: run mypy on save (via nvim-lint)
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      linters_by_ft = { python = { "mypy" } },
    },
    config = function(_, opts)
      local lint = require("lint")
      lint.linters_by_ft = opts.linters_by_ft
      vim.api.nvim_create_autocmd("BufWritePost", { callback = function() lint.try_lint() end })
    end,
  },
  -- Ensure external tools exist
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = { "black", "isort", "ruff", "djlint", "mypy", "debugpy" },
      run_on_start = true,
    },
  },
  -- Git UI
  {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter" },
  },
}
