return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local eslint_markers = {
        "eslint.config.js",
        "eslint.config.mjs",
        "eslint.config.cjs",
        ".eslintrc",
        ".eslintrc.js",
        ".eslintrc.cjs",
        ".eslintrc.json",
        ".eslintrc.yaml",
        ".eslintrc.yml",
        "package.json",
      }

      local function find_up(markers, startpath)
        local found = vim.fs.find(markers, { path = startpath, upward = true })[1]
        return found and vim.fs.dirname(found) or nil
      end

      vim.lsp.config("eslint", {
        root_dir = function(bufnr, on_dir)
          local fname = vim.api.nvim_buf_get_name(bufnr)
          if fname == "" then
            return on_dir(nil)
          end

          local start = vim.fs.dirname(fname)
          local root = find_up(eslint_markers, start) or find_up({ ".git" }, start)
          return on_dir(root)
        end,

        settings = {
          codeAction = {
            disableRuleComment = { enable = true, location = "separateLine" },
            showDocumentation = { enable = true },
          },
          format = true,
          run = "onSave",
          validate = "on",
          workingDirectory = { mode = "location" },
        },
      })

      vim.lsp.enable("eslint")

      -- Fix all eslint issues on save (only when eslint is attached)
      local grp = vim.api.nvim_create_augroup("EslintFixAllOnSave", { clear = true })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = grp,
        callback = function(args)
          if #vim.lsp.get_clients({ bufnr = args.buf, name = "eslint" }) == 0 then
            return
          end

          vim.lsp.buf.code_action({
            apply = true,
            context = {
              -- Use the generic kind so type-checkers are happy;
              -- servers still return sub-kinds like "source.fixAll.eslint".
              only = { "source.fixAll" },
              diagnostics = {},
            },
          })
        end,
      })
    end,
  },
}
