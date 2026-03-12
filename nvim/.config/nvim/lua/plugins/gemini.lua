return {
  {
    "Robitx/gp.nvim",
    config = function()
      local conf = {
        providers = {
          google = {
            endpoint = "https://generativelanguage.googleapis.com/v1beta/models/{{model}}:streamGenerateContent?key={{secret}}",
            secret = os.getenv("GOOGLE_API_KEY") or "",
          },
          openai = {
            endpoint = "https://api.openai.com/v1/chat/completions",
            secret = os.getenv("OPENAI_API_KEY") or "",
          },
        },
        agents = {
          {
            name = "Gemini",
            chat = true,
            command = true,
            provider = "google",
            model = { model = "gemini-2.0-flash-exp", temperature = 0.7, top_p = 1 },
            system_prompt = "You are a helpful AI assistant integrated into Neovim. Be concise and technical.",
          },
          {
            name = "ChatGPT4o",
            chat = true,
            command = true,
            provider = "openai",
            model = { model = "gpt-4o", temperature = 0.7, top_p = 1 },
            system_prompt = "You are a helpful AI assistant integrated into Neovim. Be concise and technical.",
          },
        },
      }
      require("gp").setup(conf)

      -- Gemini Keybindings (Ctrl-g)
      vim.keymap.set({ "n", "i" }, "<C-g>c", "<cmd>GpChatNew vsplit<cr>", { desc = "Gemini New Chat" })
      vim.keymap.set({ "n", "i" }, "<C-g>t", "<cmd>GpChatToggle vsplit<cr>", { desc = "Gemini Toggle Chat" })
      vim.keymap.set({ "v" }, "<C-g>c", ":<C-u>'<,'>GpChatNew vsplit<cr>", { desc = "Gemini New Chat (Selection)" })
      vim.keymap.set({ "v" }, "<C-g>r", ":<C-u>'<,'>GpRewrite<cr>", { desc = "Gemini Rewrite (Inline)" })
      vim.keymap.set({ "n", "v" }, "<C-g>a", "<cmd>GpAppend<cr>", { desc = "Gemini Append" })

      -- OpenAI Keybindings (Ctrl-o)
      vim.keymap.set({ "n", "i" }, "<C-o>c", "<cmd>GpChatNew vsplit<cr>", { desc = "OpenAI New Chat" })
      vim.keymap.set({ "n", "i" }, "<C-o>t", "<cmd>GpChatToggle vsplit<cr>", { desc = "OpenAI Toggle Chat" })
      vim.keymap.set({ "v" }, "<C-o>c", ":<C-u>'<,'>GpChatNew vsplit<cr>", { desc = "OpenAI New Chat (Selection)" })
      vim.keymap.set({ "v" }, "<C-o>r", ":<C-u>'<,'>GpRewrite<cr>", { desc = "OpenAI Rewrite (Inline)" })
    end,
  },
}
