return {
  "pwntester/octo.nvim",
  cmd = "Octo",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {},
  config = function(_, opts)
    require("octo").setup(opts)

    local function bmap(buf, mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
    end

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "octo", "octo_issue", "octo_pr", "octo_review", "octo_review_diff", "octo_panel" },
      group = vim.api.nvim_create_augroup("OctoKeymaps", { clear = true }),
      callback = function(ev)
        local buf = ev.buf

        bmap(buf, "n", "<localleader>ca", ":Octo comment add<CR>", "Octo: add comment")
        bmap(buf, "x", "<localleader>ca", ":<C-u>Octo comment add<CR>", "Octo: add comment (visual)")
        bmap(buf, "n", "<localleader>ce", ":Octo comment edit<CR>", "Octo: edit comment")
        bmap(buf, "n", "<localleader>cd", ":Octo comment delete<CR>", "Octo: delete comment")

        bmap(buf, "n", "<localleader>rs", ":Octo review start<CR>", "Octo: start review")
        bmap(buf, "n", "<localleader>rr", ":Octo review resume<CR>", "Octo: resume review")
        bmap(buf, "n", "<localleader>rS", ":Octo review submit<CR>", "Octo: submit review")
        bmap(buf, "n", "<localleader>rd", ":Octo review discard<CR>", "Octo: discard review")

        bmap(buf, "n", "gx", ":Octo browser open<CR>", "Open in GitHub (browser)")
        bmap(buf, "n", "<localleader>?", ":map <buffer><CR>", "Show Octo buffer mappings")
        bmap(buf, "n", "<localleader>pi", ":Octo pr list<CR>", "List PRs")
        bmap(buf, "n", "<localleader>ii", ":Octo issue list<CR>", "List issues")
      end,
    })

    local function gmap(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
    end
    gmap("<leader>gp", ":Octo pr list<CR>", "Octo: PR list")
    gmap("<leader>gi", ":Octo issue list<CR>", "Octo: Issue list")
    gmap("<leader>gS", ":Octo search<CR>", "Octo: Search (issues & PRs)")
  end,
}
