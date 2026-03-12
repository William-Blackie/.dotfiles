return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      for _, server in ipairs({ "html", "emmet_language_server" }) do
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
      for _, tool in ipairs({ "html-lsp", "emmet-language-server", "markdownlint-cli2" }) do
        if not vim.tbl_contains(opts.ensure_installed, tool) then
          table.insert(opts.ensure_installed, tool)
        end
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.html = opts.servers.html or {}
      opts.servers.emmet_language_server = vim.tbl_deep_extend("force", opts.servers.emmet_language_server or {}, {
        filetypes = {
          "css",
          "eruby",
          "html",
          "htmldjango",
          "javascriptreact",
          "less",
          "sass",
          "scss",
          "typescriptreact",
        },
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.markdown = { "markdownlint-cli2" }
    end,
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.markdown = { "markdownlint-cli2" }
    end,
  },
}
