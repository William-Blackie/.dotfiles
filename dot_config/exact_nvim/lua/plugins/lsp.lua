---LSP configuration
---Note: Language-specific settings are consolidated here from lang/*.lua files

local utils = require("lib.utils")

---@return string|nil
local function typeshed_path()
  local paths = {}
  local env_path = os.getenv("TYPESHED_PATH")
  if env_path and env_path ~= "" then
    paths[#paths + 1] = env_path
  end
  paths[#paths + 1] = vim.fn.expand("~/.local/src/typeshed")

  for _, path in ipairs(paths) do
    if vim.fn.isdirectory(path) == 1 then
      return path
    end
  end
  return nil
end

---@return table
local function ty_settings()
  local settings = {}
  local typeshed = typeshed_path()
  if typeshed then
    settings.configuration = {
      environment = {
        typeshed = typeshed,
      },
    }
  end
  return settings
end

---@param bufnr number
---@param on_dir fun(root_dir: string)
local function django_root_dir(bufnr, on_dir)
  local root = vim.fs.root(bufnr, utils.django_root_markers)
  if root then
    on_dir(root)
  end
end

return {
  {
    "Jezda1337/nvim-html-css",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "saghen/blink.cmp",
    },
    opts = {
      enable_on = {
        "html",
        "htmldjango",
        "tsx",
        "jsx",
        "templ",
      },
      handlers = {
        definition = {
          bind = "gd",
        },
        hover = {
          bind = "K",
          wrap = true,
          border = "none",
          position = "cursor",
        },
      },
      documentation = {
        auto_show = true,
      },
      peek = {
        enabled = true,
        border = "rounded",
        position = "center",
        width = 0.5,
        height = 0.5,
        focus = true,
        style = "minimal",
      },
      -- Resolved from the git root (not nvim's launch-time cwd, which is
      -- stale the moment you `:cd` into a project after starting nvim) and
      -- globbed across every site under django/build/static/css/*, so hover
      -- works no matter which site (app, www, xp, rubrics, ...) you're in.
      style_sheets = (function()
        local root = utils.git_root() or vim.uv.cwd()
        local sheets = {}
        for _, file in
          ipairs(vim.fn.glob(root .. "/django/build/static/css/*/*.css", false, true))
        do
          table.insert(sheets, file)
        end
        return sheets
      end)(),
    },
    config = function(_, opts)
      require("html-css").setup(opts)

      -- html-css's own hover keymap (hover.lua) is a plain global
      -- `vim.keymap.set`, but LazyVim registers its "K" through
      -- `Snacks.keymap.set()` with an `lsp` filter: Snacks re-applies
      -- whichever `n:K` registration has the highest id (i.e. was
      -- registered most recently) as a *buffer-local* mapping every time an
      -- LSP client (re)attaches - debounced by 100ms, so it always fires
      -- after (and clobbers) a plain keymap set from an LspAttach handler.
      -- Registering ours the same way, deferred past startup so it's
      -- guaranteed to register after LazyVim's, is what actually wins.
      local bind = opts.handlers.hover.bind
      local html_css_hover = vim.fn.maparg(bind, "n", false, true).callback
      if not html_css_hover then
        return
      end

      vim.schedule(function()
        Snacks.keymap.set("n", bind, html_css_hover, {
          lsp = {},
          silent = true,
          desc = "Hover (html-css aware)",
          enabled = function(buf)
            local ext = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":e")
            return vim.tbl_contains(opts.enable_on, ext)
          end,
        })
      end)
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        jsonls = {
          settings = {
            json = {
              schemas = require("schemastore").json.schemas(),
            },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              runtime = {
                version = "LuaJIT",
              },
              diagnostics = {
                globals = { "vim" },
              },
              workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
              },
            },
          },
        },

        bashls = {
          filetypes = { "sh", "bash", "sh.chezmoitmpl", "bash.chezmoitmpl" },
        },
        ty = {
          root_dir = django_root_dir,
          root_markers = utils.python_root_markers,
          settings = {
            ty = ty_settings(),
          },
          cmd_env = {
            DJANGO_SETTINGS_MODULE = utils.get_django_settings_module(),
          },
        },
        -- https://github.com/joshuadavidthomas/django-language-server/blob/main/docs/clients/neovim.md
        djlsp = {
          filetypes = { "htmldjango" },
          root_dir = django_root_dir,
          init_options = {
            env_directories = vim.env.VIRTUAL_ENV or ".env",
            django_settings_module = utils.get_django_settings_module(),
            docker_compose_service = utils.get_django_docker_compose_service(),
            docker_compose_file = utils.get_django_docker_compose_file(),
          },
        },
        djls = {
          cmd = { "djls", "serve" },
          filetypes = { "htmldjango", "html", "python" },
          root_markers = utils.django_root_markers,
          init_options = {
            django_settings_module = utils.get_django_settings_module(),
          },
          venv_path = utils.get_python_venv,
          env_file = vim.env.VIRTUAL_ENV,
        },
        tombi = {
          keys = {
            {
              "K",
              function()
                if vim.bo.filetype == "toml" or vim.bo.filetype == "toml.chezmoitmpl" then
                  local win = vim.api.nvim_get_current_win()
                  local cursor = vim.api.nvim_win_get_cursor(win)
                  vim.lsp.buf.hover()
                  vim.api.nvim_win_set_cursor(win, cursor)
                end
              end,
              mode = "n",
              buffer = 0,
              desc = "Show hover (tombi)",
            },
          },
        },
      },
    },
  },
}
