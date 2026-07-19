-- https://github.com/kevalin/mermaid.nvim
return {
  -- "william-blackie/mermaid.nvim",
  "kevalin/mermaid.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("mermaid").setup({
      format = {
        shift_width = 4, -- Indentation size (spaces)
      },
      lint = {
        enabled = true, -- Enable diagnostics via mmdc
        command = "mmdc", -- Path to mermaid-cli executable
      },
      preview = {
        renderer = "mermaid -W 1800 -H 1800", -- "mermaid.js" or "beautiful-mermaid"
        theme = "dark", -- Theme name (renderer-specific)
      },
    })

    -- Install the Tree-sitter parser:
    -- :TSInstall mermaid
  end,
}
