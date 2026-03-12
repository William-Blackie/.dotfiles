return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "stylelint_lsp") then
        table.insert(opts.ensure_installed, "stylelint_lsp")
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.stylelint_lsp = {
        filetypes = { "css", "scss", "sass", "less" },
        settings = {
          stylelintplus = {
            autoFixOnFormat = true,
            autoFixOnSave = true,
          },
        },
      }
    end,
  },
}
