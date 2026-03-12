return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      for _, tool in ipairs({ "shellcheck", "shfmt" }) do
        if not vim.tbl_contains(opts.ensure_installed, tool) then
          table.insert(opts.ensure_installed, tool)
        end
      end
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.sh = { "shfmt" }
      opts.formatters_by_ft.bash = { "shfmt" }
      opts.formatters_by_ft.zsh = { "shfmt" }
    end,
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.sh = { "shellcheck" }
      opts.linters_by_ft.bash = { "shellcheck" }
      opts.linters_by_ft.zsh = { "shellcheck" }
    end,
  },
}
