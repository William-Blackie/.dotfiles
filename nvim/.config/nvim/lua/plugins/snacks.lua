return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    notifier = { enabled = true, timeout = 3000 },
    picker = {
      enabled = true,
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
          follow_file = true,
        },
        files = {
          hidden = true,
        },
        grep = {
          hidden = true,
        },
        buffers = {
          hidden = true,
        },
      },
    },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    zen = { enabled = true },
  },
}
