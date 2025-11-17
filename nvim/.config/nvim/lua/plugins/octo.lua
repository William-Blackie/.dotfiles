-- Octo.nvim: comfy keymaps for reviews & comments (buffer-local)
return {
  "pwntester/octo.nvim",
  cmd = "Octo",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-tree/nvim-web-devicons", -- optional but nice
  },
  opts = {},
  config = function(_, opts)
    require("octo").setup(opts)

    -- Helper: buffer-local mapping
    local function bmap(buf, mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
    end

    -- Apply maps only in Octo buffers
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "octo", "octo_issue", "octo_pr", "octo_review", "octo_review_diff", "octo_panel" },
      group = vim.api.nvim_create_augroup("OctoKeymaps", { clear = true }),
      callback = function(ev)
        local buf = ev.buf

        ----------------------------------------------------------------------
        -- Comments (use your <localleader>; you said it’s "\")
        ----------------------------------------------------------------------
        bmap(buf, "n", "<localleader>ca", ":Octo comment add<CR>", "Octo: add comment")
        bmap(buf, "x", "<localleader>ca", ":<C-u>Octo comment add<CR>", "Octo: add comment (visual)")
        bmap(buf, "n", "<localleader>ce", ":Octo comment edit<CR>", "Octo: edit comment")
        bmap(buf, "n", "<localleader>cd", ":Octo comment delete<CR>", "Octo: delete comment under cursor")

        ----------------------------------------------------------------------
        -- Reviews (start / resume / submit / discard)
        ----------------------------------------------------------------------
        bmap(buf, "n", "<localleader>rs", ":Octo review start<CR>", "Octo: start review")
        bmap(buf, "n", "<localleader>rr", ":Octo review resume<CR>", "Octo: resume review")
        bmap(buf, "n", "<localleader>rS", ":Octo review submit<CR>", "Octo: submit review")
        bmap(buf, "n", "<localleader>rd", ":Octo review discard<CR>", "Octo: discard review")

        ----------------------------------------------------------------------
        -- Handy helpers
        ----------------------------------------------------------------------
        bmap(buf, "n", "gx", ":Octo browser open<CR>", "Open in GitHub (browser)")
        bmap(buf, "n", "<localleader>?", ":map <buffer><CR>", "Show Octo buffer mappings")
        -- Quick lists
        bmap(buf, "n", "<localleader>pi", ":Octo pr list<CR>", "List PRs")
        bmap(buf, "n", "<localleader>ii", ":Octo issue list<CR>", "List issues")
      end,
    })

    ------------------------------------------------------------------------
    -- Global (works anywhere) — quick access to lists/search
    ------------------------------------------------------------------------
    local wk = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
    end
    wk("<leader>gp", ":Octo pr list<CR>", "Octo: PR list")
    wk("<leader>gi", ":Octo issue list<CR>", "Octo: Issue list")
    wk("<leader>gS", ":Octo search<CR>", "Octo: Search (issues & PRs)")
  end,
}
