local map = vim.keymap.set
local opts = { noremap = true, silent = true }

map("n", "<leader>v", "<cmd>vsplit<cr>", opts)
map("n", "<leader>-", "<cmd>split<cr>", opts)
map("n", "<leader>h", "<C-w>h", opts)
map("n", "<leader>j", "<C-w>j", opts)
map("n", "<leader>k", "<C-w>k", opts)
map("n", "<leader>l", "<C-w>l", opts)

map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", opts)
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", opts)
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", opts)
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", opts)

map("n", "<leader>gg", "<cmd>LazyGit<cr>", opts)

map("n", "gd", vim.lsp.buf.definition, opts)
map("n", "gr", "<cmd>Telescope lsp_references<cr>", opts)
map("n", "K",  vim.lsp.buf.hover, opts)
map("n", "<leader>rn", vim.lsp.buf.rename, opts)
map("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, opts)
