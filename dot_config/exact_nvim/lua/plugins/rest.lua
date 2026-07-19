-- https://github.com/rest-nvim/rest.nvim
-- https://github.com/rest-nvim/rest.nvim/issues/559
return {
  "rest-nvim/rest.nvim",
  ft = "http",
  build = false,
  dependencies = {
    "j-hui/fidget.nvim",
    "nvim-neotest/nvim-nio",
    "nvim-treesitter/nvim-treesitter",
    {
      -- Lazy.nvim does not recognize this library's rocksfile, so add it
      -- to package path manually.
      "manoelcampos/xml2lua",
      config = function(plugin)
        package.path = package.path .. ";" .. plugin.dir .. "/?.lua"
      end,
    },
    "lunarmodules/lua-mimetypes",
  },
}
