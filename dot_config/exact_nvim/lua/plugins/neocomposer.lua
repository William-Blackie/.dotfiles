-- https://github.com/ecthelionvi/NeoComposer.nvim
---@type LazyPluginSpec
return {
  "ecthelionvi/NeoComposer.nvim",
  event = "VeryLazy",
  dependencies = {
    "kkharji/sqlite.lua",
    "nvim-telescope/telescope.nvim",
  },
  keys = {
    { "<leader>q", group = "Macros" },
    { "<leader>qm", "<cmd>Telescope macros<CR>", desc = "Macros" },
    { "<leader>qe", "<cmd>EditMacros<CR>", desc = "Edit Macros" },
    { "<leader>qc", "<cmd>ClearNeoComposer<CR>", desc = "Clear Macros" },
    { "<leader>qd", "<cmd>ToggleDelay<CR>", desc = "Toggle Macro Delay" },
  },
  opts = {},
  config = function(_, opts)
    require("NeoComposer").setup(opts)
    pcall(function()
      require("telescope").load_extension("macros")
    end)
  end,
}
