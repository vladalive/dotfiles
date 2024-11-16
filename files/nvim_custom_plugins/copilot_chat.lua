--- Copilot Chat
return {
  "CopilotC-Nvim/CopilotChat.nvim",
  event = "VeryLazy",
  dependencies = {
    { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
    { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
    { "nvim-telescope/telescope.nvim" }, -- Use telescope for help actions
  },
  opts = {
    model = 'gpt-4o', -- GPT model to use, see ':CopilotChatModels' for available models
    show_help = "yes", -- Show help text for CopilotChatInPlace, default: yes
    debug = false, -- Enable or disable debug mode, the log file will be in ~/.local/state/nvim/CopilotChat.nvim.log
    disable_extra_info = 'no', -- Disable extra information (e.g: system prompt) in the response.
    language = "English", -- Copilot answer language settings when using default prompts. Default language is English.
    -- proxy = "socks5://127.0.0.1:3000", -- Proxies requests via https or socks.
    -- temperature = 0.1,
    prompts = {
      MyCustomPrompt = {
        prompt = 'Explain how it works.',
        mapping = '<leader>ccmc',
        description = 'My custom prompt description',
      },
    },
  },
  build = function()
    vim.notify("Please update the remote plugins by running ':UpdateRemotePlugins', then restart Neovim.")
  end,
  keys = {
    { "<leader>ccco", ":CopilotChatCommit<cr>", desc = "CopilotChat - Write commit message" },
    { "<leader>cccs", ":CopilotChatCommitStaged<cr>", desc = "CopilotChat - Write commit message for staged" },
    { "<leader>ccb", ":CopilotChatBuffer ", desc = "CopilotChat - Chat with current buffer" },
    { "<leader>cce", "<cmd>CopilotChatExplain<cr>", desc = "CopilotChat - Explain code" },
    { "<leader>cct", "<cmd>CopilotChatTests<cr>", desc = "CopilotChat - Generate tests" },
    {
      "<leader>ccT",
      "<cmd>CopilotChatVsplitToggle<cr>",
      desc = "CopilotChat - Toggle Vsplit", -- Toggle vertical split
    },
    {
      "<leader>ccv",
      ":CopilotChatVisual ",
      mode = "x",
      desc = "CopilotChat - Open in vertical split",
    },
    {
      "<leader>ccx",
      ":CopilotChatInPlace<cr>",
      mode = "x",
      desc = "CopilotChat - Run in-place code",
    },
    {
      "<leader>ccf",
      "<cmd>CopilotChatFixDiagnostic<cr>", -- Get a fix for the diagnostic message under the cursor.
      desc = "CopilotChat - Fix diagnostic",
    },
    {
      "<leader>ccr",
      "<cmd>CopilotChatReset<cr>", -- Reset chat history and clear buffer.
      desc = "CopilotChat - Reset chat history and clear buffer",
    },
    -- Show help actions with telescope
    {
      "<leader>cch",
      function()
        require("CopilotChat.code_actions").show_help_actions()
      end,
      desc = "CopilotChat - Help actions",
    },
    -- Show prompts actions with telescope
    {
      "<leader>ccp",
      function()
        require("CopilotChat.code_actions").show_prompt_actions()
      end,
      desc = "CopilotChat - Help actions",
    },
    {
      "<leader>ccp",
      ":lua require('CopilotChat.code_actions').show_prompt_actions(true)<CR>",
      mode = "x",
      desc = "CopilotChat - Prompt actions",
    },
  },
}
