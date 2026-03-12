return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    opts = function(_, opts)
      local function workspace_root()
        local cwd = vim.loop.cwd()
        local git = vim.fs.find(".git", { path = cwd, upward = true })[1]
        if git then
          return vim.fs.dirname(git)
        end
        return cwd
      end

      opts = opts or {}
      opts.settings = opts.settings or {}
      opts.default = opts.default or {}
      opts.settings.key = workspace_root
      opts.default.get_root_dir = workspace_root

      return opts
    end,
    config = function(_, opts)
      require("harpoon"):setup(opts)
    end,
  },
}
