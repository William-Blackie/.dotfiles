return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "helm_ls") then
        table.insert(opts.ensure_installed, "helm_ls")
      end
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      for _, tool in ipairs({ "helm-ls", "hadolint" }) do
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
      opts.servers.helm_ls = vim.tbl_deep_extend("force", opts.servers.helm_ls or {}, {
        filetypes = { "helm", "yaml.helm" },
      })

      vim.filetype.add({
        pattern = {
          [".*/templates/.*%.ya?ml"] = "yaml.helm",
        },
      })
    end,
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.dockerfile = { "hadolint" }
    end,
  },
}
