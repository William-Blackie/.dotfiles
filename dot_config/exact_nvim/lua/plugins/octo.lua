---@type LazyPluginSpec
return {
  ---GitHub integration for Neovim
  ---@see https://github.com/pwntester/octo.nvim
  "pwntester/octo.nvim",
  cmd = "Octo",
  opts = { picker = "snacks", enable_builtin = true },
  keys = {
    { "<leader>o", group = "Octo" },
    { "<leader>oi", "<CMD>Octo issue list<CR>", desc = "Issues" },
    { "<leader>op", "<CMD>Octo pr list<CR>", desc = "PRs" },
    { "<leader>on", "<CMD>Octo notification list<CR>", desc = "Notifications" },
    {
      "<leader>os",
      function()
        require("octo.utils").create_base_search_command({ include_current_repo = true })
      end,
      desc = "Search GitHub",
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "folke/snacks.nvim",
    "nvim-tree/nvim-web-devicons",
  },
}
