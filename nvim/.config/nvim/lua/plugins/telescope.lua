return {
  "nvim-telescope/telescope.nvim",
  opts = function(_, opts)
    opts.defaults = opts.defaults or {}
    opts.pickers = opts.pickers or {}

    -- Keep .git/ out, but include other dotfiles
    opts.defaults.file_ignore_patterns = {
      ".git/",
      "*.pyc",
      "./venv/",
    }

    -- <space> f f
    opts.pickers.find_files = vim.tbl_deep_extend("force", opts.pickers.find_files or {}, {
      hidden = true, -- pass --hidden to fd
      no_ignore = true, -- pass --no-ignore (include files ignored by .gitignore)
    })

    -- <space> f g
    opts.pickers.live_grep = vim.tbl_deep_extend("force", opts.pickers.live_grep or {}, {
      additional_args = function(_)
        return { "--hidden", "--no-ignore", "--glob", "!.git/*" }
      end,
    })

    return opts
  end,
}
