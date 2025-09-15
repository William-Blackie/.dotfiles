return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    -- don't try to replace netrw since we've disabled it already
    filesystem = {
      hijack_netrw_behavior = "disabled", -- "open_default" or "open_current" also ok, but disabled avoids surprises
      filtered_items = {
        hide_dotfiles = false, -- you asked to show hidden
        hide_gitignored = false,
      },
    },
    close_if_last_window = true, -- optional QoL
  },
}
