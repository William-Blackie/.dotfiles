return {
  -- ESLint LSP configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        eslint = {
          -- Configure working directory to project root
          root_dir = function(fname)
            return require("lspconfig.util").find_git_ancestor(fname) or vim.fn.getcwd()
          end,
          settings = {
            codeAction = {
              disableRuleComment = {
                enable = true,
                location = "separateLine",
              },
              showDocumentation = {
                enable = true,
              },
            },
            format = true,
            run = "onType",
            validate = "on",
            workingDirectory = {
              mode = "location",
            },
          },
        },
      },
    },
  },
}


