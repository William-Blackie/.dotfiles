-- Filetype detection
vim.filetype.add({
  filename = {
    ["compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["docker-compose.yml"] = "yaml.docker-compose",
  },
})

-- Spell check for git commits and markdown
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "gitcommit", "markdown", "text" },
  callback = function()
    vim.opt_local.spell = true
  end,
})

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Chezmoi auto apply
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { os.getenv("HOME") .. "/dotfiles/*" },
  callback = function(ev)
    local bufnr = ev.buf
    local edit_watch = function()
      require("chezmoi.commands.__edit").watch(bufnr)
    end
    vim.schedule(edit_watch)
  end,
})

-- Quickfix
-- https://gosukiwi.github.io/vim/2022/04/19/vim-advanced-search-and-replace.html
-- Quickfix: Remove entry at cursor
local function qf_remove_at_cursor()
  local currline = vim.fn.line(".")
  local items = vim.fn.getqflist()
  if #items == 0 then
    return
  end

  table.remove(items, currline)
  vim.fn.setqflist(items, "r")
  if #items == 0 then
    vim.cmd.cclose()
    return
  end

  vim.cmd(("normal! %dG"):format(math.min(currline, #items)))
end

vim.api.nvim_create_augroup("quickfix", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = "quickfix",
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "x", qf_remove_at_cursor, { buffer = true, silent = true })
  end,
})

-- Grep/Replace with latest patterns
local latest_greps = {}

local function Grep(pattern, path)
  pattern = pattern or ""
  if pattern == "" then
    return
  end

  if vim.fn.executable("rg") ~= 1 then
    vim.notify("Grep requires ripgrep (rg)", vim.log.levels.ERROR)
    return
  end

  latest_greps[pattern] = true
  path = path or "."

  local result = vim
    .system({
      "rg",
      "--vimgrep",
      "--smart-case",
      "--hidden",
      "--glob",
      "!{.git,node_modules}/**",
      "--",
      pattern,
      path,
    }, { text = true })
    :wait()

  if result.code > 1 then
    vim.notify(result.stderr or "rg failed", vim.log.levels.ERROR)
    return
  end

  local lines = vim.split(result.stdout or "", "\n", { plain = true, trimempty = true })
  vim.fn.setqflist({}, "r", {
    title = "rg: " .. pattern,
    lines = lines,
    efm = "%f:%l:%c:%m",
  })

  if #lines == 0 then
    vim.notify("No matches")
    return
  end

  vim.cmd.copen()
end

-- Replace in quickfix
-- confirm: true for confirmation, false/nil for no confirmation
local function substitute_delimiter(original, replacement)
  for _, delimiter in ipairs({ "/", "#", "~", "@" }) do
    if
      not original:find(delimiter, 1, true)
      and not replacement:find(delimiter, 1, true)
    then
      return delimiter
    end
  end

  return "/"
end

local function escape_substitute(value, delimiter, is_replacement)
  value = vim.fn.escape(value, "\\" .. delimiter)
  value = value:gsub("|", "\\|")
  if is_replacement then
    value = value:gsub("&", "\\&")
  end
  return value
end

local function Replace(original, replacement, confirm)
  if not original or original == "" or replacement == nil then
    return
  end

  replacement = replacement or ""
  local delimiter = substitute_delimiter(original, replacement)
  local search = escape_substitute(original, delimiter, false)
  local replace = escape_substitute(replacement, delimiter, true)
  local flags = confirm and "gce" or "ge"
  vim.cmd(
    string.format(
      "cfdo %%s%s%s%s%s%s%s",
      delimiter,
      search,
      delimiter,
      replace,
      delimiter,
      flags
    )
  )
end

local function LatestGreps()
  local keys = {}
  for k in pairs(latest_greps) do
    table.insert(keys, k)
  end
  return keys
end

-- Grep
vim.api.nvim_create_user_command("Grep", function(opts)
  Grep(opts.fargs[1], opts.fargs[2])
end, { nargs = "+", complete = "file" })

-- Replace
vim.api.nvim_create_user_command("Replace", function(opts)
  Replace(opts.fargs[1], opts.fargs[2], opts.fargs[3])
end, {
  nargs = "+",
  complete = function()
    return LatestGreps()
  end,
})

-- Git
-- Open files changed on this branch
local function open_git_files(mode)
  local root = vim.trim(
    vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait().stdout
  )
  if root == "" then
    vim.notify("Not in a git repo", vim.log.levels.ERROR)
    return
  end

  local files = {}
  local seen = {}

  local function collect(args)
    local result = vim.system(args, { cwd = root, text = true }):wait()
    if result.code ~= 0 then
      vim.notify(result.stderr, vim.log.levels.ERROR)
      return false
    end

    for _, file in
      ipairs(vim.split(result.stdout, "\0", { plain = true, trimempty = true }))
    do
      if not seen[file] then
        seen[file] = true
        table.insert(files, root .. "/" .. file)
      end
    end

    return true
  end

  if mode == "origin" then
    if
      not collect({
        "git",
        "diff",
        "--name-only",
        "-z",
        "--diff-filter=ACMR",
        "--merge-base",
        "origin",
      })
    then
      return
    end
  else
    if not collect({ "git", "diff", "--name-only", "-z", "--diff-filter=ACMR" }) then
      return
    end
    if
      not collect({ "git", "diff", "--name-only", "-z", "--diff-filter=ACMR", "--cached" })
    then
      return
    end
  end

  if #files == 0 then
    vim.notify("No changed files")
    return
  end

  for _, file in ipairs(files) do
    vim.fn.bufadd(file)
  end

  vim.cmd.edit(vim.fn.fnameescape(files[1]))
  vim.notify(("Opened %d changed files"):format(#files))
end

vim.api.nvim_create_user_command("OpenDiffFiles", function()
  open_git_files("local")
end, { desc = "Open staged and unstaged git diff files" })

vim.api.nvim_create_user_command("OpenOriginFiles", function()
  open_git_files("origin")
end, { desc = "Open files changed vs origin merge-base" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "mermaid",
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    vim.keymap.set(
      "n",
      "<leader>mp",
      "<cmd>MermaidPreview<CR>",
      { buffer = buf, desc = "Mermaid Preview" }
    )
    vim.keymap.set(
      "n",
      "<leader>mf",
      "<cmd>MermaidFormat<CR>",
      { buffer = buf, desc = "Mermaid Format" }
    )
    vim.keymap.set(
      "n",
      "<leader>mr",
      "<cmd>MermaidRender<CR>",
      { buffer = buf, desc = "Mermaid Render" }
    )
    vim.keymap.set(
      "n",
      "<leader>mc",
      "<cmd>MermaidCopyURL<CR>",
      { buffer = buf, desc = "Mermaid Copy URL" }
    )
    vim.keymap.set(
      "n",
      "<leader>mx",
      "<cmd>MermaidPreviewStop<CR>",
      { buffer = buf, desc = "Mermaid Stop Preview" }
    )
  end,
})

-- Insert current ISO date
vim.api.nvim_create_user_command("Datenow", function()
  vim.api.nvim_put({ vim.fn.strftime("%Y-%m-%d") }, "c", true, true)
end, { desc = "Insert current ISO date" })
