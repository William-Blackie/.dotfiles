return {
  "obsidian-nvim/nldates.nvim",
  build = function(plugin)
    if not vim.g.node_host_prog or vim.g.node_host_prog == "" then
      local node_host = vim.fn.exepath("neovim-node-host")
      if node_host ~= "" then
        vim.g.node_host_prog = node_host
      end
    end

    local result = vim
      .system({ "npm", "install" }, {
        cwd = plugin.dir .. "/rplugin/node/nldates",
        text = true,
      })
      :wait()

    if result.code ~= 0 then
      local message = result.stderr or result.stdout or "nldates.nvim npm install failed"
      if message == "" then
        message = "nldates.nvim npm install failed"
      end
      error(message)
    end

    vim.cmd("UpdateRemotePlugins")
  end,
}
