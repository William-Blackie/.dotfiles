-- C-h/j/k/l in normal mode handled by vim-tmux-navigator
vim.keymap.set("i", "<C-h>", "<Left>", { desc = "Move left" })
vim.keymap.set("i", "<C-l>", "<Right>", { desc = "Move right" })
vim.keymap.set("i", "<C-j>", "<Down>", { desc = "Move down" })
vim.keymap.set("i", "<C-k>", "<Up>", { desc = "Move up" })

local function lsp_clients_for_buf(bufnr)
  if not vim.lsp then
    return {}
  end
  if vim.lsp.get_clients then
    return vim.lsp.get_clients({ bufnr = bufnr })
  end
  if vim.lsp.get_active_clients then
    local clients = vim.lsp.get_active_clients()
    local attached = {}
    for _, client in ipairs(clients) do
      if client.attached_buffers and client.attached_buffers[bufnr] then
        table.insert(attached, client)
      end
    end
    return attached
  end
  return {}
end

local function with_lsp(method, desc)
  return function()
    local bufnr = vim.api.nvim_get_current_buf()
    if #lsp_clients_for_buf(bufnr) == 0 then
      vim.notify("No LSP client attached to this buffer", vim.log.levels.WARN)
      return
    end
    if not vim.lsp.buf[method] then
      vim.notify("LSP method unavailable: " .. desc, vim.log.levels.WARN)
      return
    end
    vim.lsp.buf[method]()
  end
end

-- LSP call/type hierarchy helpers
vim.keymap.set("n", "<leader>ci", with_lsp("incoming_calls", "incoming_calls"), { desc = "LSP Incoming Calls" })
vim.keymap.set("n", "<leader>co", with_lsp("outgoing_calls", "outgoing_calls"), { desc = "LSP Outgoing Calls" })
vim.keymap.set("n", "<leader>ch", with_lsp("typehierarchy", "typehierarchy"), { desc = "LSP Type Hierarchy" })

-- Buffer Workflow
vim.keymap.set("n", "<leader>,", function()
  require("snacks.picker").buffers()
end, { desc = "Snacks: Open Buffer Picker" })

vim.keymap.set("n", "<leader>ff", function()
  require("snacks.picker").files()
end, { desc = "Snacks: Find Files" })

vim.keymap.set("n", "<leader>fg", function()
  require("snacks.picker").grep()
end, { desc = "Snacks: Live Grep" })

vim.keymap.set("n", "<leader>fr", function()
  require("snacks.picker").recent()
end, { desc = "Snacks: Recent Files" })

vim.keymap.set("n", "<leader>fd", function()
  require("snacks.picker").diagnostics()
end, { desc = "Snacks: Diagnostics" })

vim.keymap.set("n", "<leader>gw", function()
  require("snacks.picker").git_worktrees()
end, { desc = "Snacks: Git Worktrees" })

vim.keymap.set("n", "<leader>fz", function()
  require("snacks.zen").toggle()
end, { desc = "Snacks: Toggle Zen Mode" })

vim.keymap.set("n", "<leader>bd", function()
  if _G.Snacks and Snacks.bufdelete then
    Snacks.bufdelete()
  else
    vim.cmd("bdelete")
  end
end, { desc = "Delete Buffer" })

-- Monorepo Navigation (Example using scripts directory)
vim.keymap.set("n", "<leader>fs", function()
  require("snacks.picker").find_files({ cwd = "scripts/" })
end, { desc = "Snacks: Find Files in Scripts/" })

vim.keymap.set("n", "<leader>gs", function()
  require("snacks.picker").grep({ cwd = "scripts/" })
end, { desc = "Snacks: Grep in Scripts/" })
