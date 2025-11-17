-- Neo-tree file explorer configuration
return {
  "nvim-neo-tree/neo-tree.nvim",
  -- Override LazyVim defaults completely
  cmd = "Neotree",
  keys = {
    {
      "<leader>e",
      function()
        require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() })
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
    -- Disable LazyVim's default keybindings
    { "<leader>fe", false },
    { "<leader>fE", false },
  },
  deactivate = function()
    vim.cmd([[Neotree close]])
  end,
  init = function()
    -- Prevent auto-opening on startup
    vim.g.neo_tree_remove_legacy_commands = 1
  end,
  opts = {
    close_if_last_window = true, -- Close Neo-tree if it's the last window
    popup_border_style = "rounded",
    enable_git_status = true,
    enable_diagnostics = true,
    -- Only use filesystem source to avoid multiple trees
    sources = { "filesystem" },
    open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
    source_selector = {
      winbar = false, -- Disable the source selector winbar
      statusline = false,
    },
    filesystem = {
      -- Show hidden files by default
      filtered_items = {
        visible = true, -- Show hidden files
        hide_dotfiles = false,
        hide_gitignored = false,
        hide_hidden = false, -- Only works on Windows for hidden files attribute
        hide_by_name = {
          -- Still hide some annoying files
          ".DS_Store",
          "thumbs.db",
          "node_modules",
        },
        never_show = {
          -- Only hide .git directory, not .github
          ".git",
        },
        always_show = {
          -- Always show these even if other filters hide them
          ".github",
          ".gitignore",
          ".env",
        },
      },
      follow_current_file = {
        enabled = true, -- Focus on current file
        leave_dirs_open = false,
      },
      use_libuv_file_watcher = true, -- Auto-refresh on file changes
    },
    window = {
      position = "left",
      width = 35,
      mappings = {
        -- Add toggle hidden files keybinding
        ["H"] = "toggle_hidden",
        -- Better navigation
        ["<space>"] = "none", -- Disable space in neo-tree
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
          -- Cleaner git symbols
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
  },
}
