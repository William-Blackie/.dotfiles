vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("TrimWhitespace", { clear = true }),
  pattern = "*",
  callback = function()
    if vim.bo.filetype == "markdown" or vim.bo.filetype == "diff" then
      return
    end
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd([[%s/\s\+$//e]])
    local lcount = vim.api.nvim_buf_line_count(0)
    pos[1] = math.min(pos[1], lcount)
    vim.api.nvim_win_set_cursor(0, pos)
  end,
})

-- options.lua sets 4-space default; override for web/config filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("FiletypeIndent", { clear = true }),
  pattern = {
    "css", "html", "javascript", "javascriptreact",
    "json", "jsonc", "lua", "scss", "typescript",
    "typescriptreact", "vue", "yaml",
  },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
  end,
})
