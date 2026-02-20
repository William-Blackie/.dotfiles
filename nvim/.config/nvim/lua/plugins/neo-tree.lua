return {
  "nvim-neo-tree/neo-tree.nvim",
  keys = {
    {
      "<leader>e",
      function()
        require("neo-tree.command").execute({ toggle = true, dir = (vim.uv or vim.loop).cwd() })
      end,
      desc = "Explorer NeoTree (cwd)",
    },
    {
      "<leader>E",
      function()
        require("neo-tree.command").execute({ toggle = true, dir = vim.fn.expand("%:p:h") })
      end,
      desc = "Explorer NeoTree (current file dir)",
    },
    { "<leader>fe", false },
    { "<leader>fE", false },
  },
  -- config= intentionally replaces LazyVim's neo-tree setup for full control
  config = function()
    require("neo-tree").setup({
      close_if_last_window = true,
      popup_border_style = "rounded",
      enable_git_status = true,
      enable_diagnostics = true,
      sources = { "filesystem" },
      open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
      source_selector = {
        winbar = false,
        statusline = false,
      },
      filesystem = {
        filtered_items = {
          visible = true,
          show_hidden_count = true,
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_hidden = false,
          hide_by_name = { ".DS_Store", "thumbs.db" },
          hide_by_pattern = {},
          always_show = { ".github", ".gitignore", ".env", ".envrc", "build" },
          always_show_by_pattern = { ".env*" },
          never_show = {},
          never_show_by_pattern = {},
        },
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },
        use_libuv_file_watcher = true,
      },
      window = {
        position = "left",
        width = 35,
        mappings = {
          ["H"] = "toggle_hidden",
          ["<space>"] = "none",
          ["o"] = "open",
        },
      },
      default_component_configs = {
        indent = {
          with_expanders = true,
          expander_collapsed = "",
          expander_expanded = "",
        },
        icon = {
          folder_closed = "",
          folder_open = "",
          folder_empty = "",
          default = "",
        },
        git_status = {
          symbols = {
            added = "✚",
            modified = "",
            deleted = "✖",
            renamed = "󰁕",
            untracked = "",
            ignored = "",
            unstaged = "󰄱",
            staged = "",
            conflict = "",
          },
        },
      },
    })
  end,
}
