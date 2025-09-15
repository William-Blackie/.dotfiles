return {
  "nvim-neotest/neotest",
  dependencies = { "nvim-neotest/neotest-python" },
  keys = {
    { "<leader>tn", function() require("neotest").run.run() end, desc = "Test nearest" },
    { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Test file" },
    { "<leader>ta", function() require("neotest").run.run("tests") end, desc = "Test all" },
    { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Test output" },
    { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Test summary" },
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-python")({
          dap = { justMyCode = false },
          runner = "pytest",
          args = { "-q" },
        }),
      },
    })
  end,
}
