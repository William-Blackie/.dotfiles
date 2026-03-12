return {
  {
    dir = "/Users/william/Projects/grove.nvim",
    opts = {
      picker = "auto",
      keys = {
        projects = "<leader>fp",
        worktrees = "<leader>fw",
      },
    },
    keys = {
      { "<leader>fp", function() require("grove").projects() end, desc = "Grove: Find Project/Worktree" },
      { "<leader>fw", function() require("grove").worktrees() end, desc = "Grove: Find Worktrees" },
    },
  },
}
