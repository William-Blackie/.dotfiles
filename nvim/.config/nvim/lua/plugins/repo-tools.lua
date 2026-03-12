return {
  {
    "klen/nvim-config-local",
    lazy = false,
    opts = {
      config_files = { ".nvim.lua", ".nvimrc", ".exrc" },
      hashfile = vim.fn.stdpath("data") .. "/config-local",
      autocommands_create = true,
      commands_create = true,
      silent = false,
      lookup_parents = true,
    },
  },
  {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle" },
    opts = {
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = {
        min_width = 28,
        default_direction = "right",
      },
      filter_kind = false,
      show_guides = true,
    },
    keys = {
      { "<leader>cs", "<cmd>AerialToggle!<cr>", desc = "Symbols outline" },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            ["aa"] = "@parameter.outer",
            ["ia"] = "@parameter.inner",
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            ["]f"] = "@function.outer",
            ["]c"] = "@class.outer",
          },
          goto_previous_start = {
            ["[f"] = "@function.outer",
            ["[c"] = "@class.outer",
          },
        },
      },
    },
  },
  {
    dir = vim.fn.stdpath("config"),
    name = "repo-tools-local",
    lazy = false,
    config = function()
      require("repo_tools").setup()
    end,
    keys = {
      { "<leader>rr", "<cmd>RepoRelated<cr>", desc = "Repo related files" },
      { "<leader>rt", "<cmd>RepoTests<cr>", desc = "Repo tests" },
      { "<leader>ru", "<cmd>RepoRoutes<cr>", desc = "Repo routes" },
      { "<leader>re", "<cmd>RepoEnv<cr>", desc = "Repo env usage" },
      { "<leader>rb", "<cmd>RepoBlast<cr>", desc = "Repo blast radius" },
    },
  },
}
