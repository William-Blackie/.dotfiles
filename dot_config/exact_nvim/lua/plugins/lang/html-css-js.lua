-- https://github.com/Jezda1337/nvim-html-css
---@type LazyPluginSpec[]
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        htmx = {
          filetypes = {
            "astro",
            "blade",
            "django-html",
            "htmldjango",
            "eelixir",
            "elixir",
            "ejs",
            "erb",
            "eruby",
            "gohtml",
            "gohtmltmpl",
            "haml",
            "handlebars",
            "hbs",
            "html",
            "htmlangular",
            "html-eex",
            "heex",
            "liquid",
            "mustache",
            "njk",
            "nunjucks",
            "php",
            "razor",
            "svelte",
            "templ",
            "twig",
            "vue",
          },
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "css-lsp",
        "stylelint-language-server",
        "stylelint",
        "css-variables-language-server",
        "cssmodules-language-server",
        "html-lsp",
        "htmx-lsp",
        "tailwindcss-language-server",
      },
    },
  },
  -- Treesitter for config file syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = vim.list_extend(opts.ensure_installed or {}, {
        "html",
        "css",
      })
    end,
  },
  -- Filetype associations for LSP warnings
  {
    "LazyVim/LazyVim",
    optional = true,
    opts = function()
      vim.filetype.add({
        pattern = {
          [".*%.jsx"] = "javascriptreact",
          [".*%.tsx"] = "typescriptreact",
          [".*%.gitlab%.ya?ml"] = "yaml.gitlab",
        },
      })
    end,
  },
}
