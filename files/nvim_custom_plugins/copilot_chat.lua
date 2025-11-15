-- Copilot Chat
return {
  'CopilotC-Nvim/CopilotChat.nvim',
  branch = 'main',
  build = "make tiktoken",
  dependencies = {
    { 'zbirenbaum/copilot.lua' }, -- or github/copilot.vim
    { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
  },
  opts = {
    -- model = 'gpt-4.1',
    model = 'gpt-4o', -- GPT model to use, see ':CopilotChatModels' for available models
    debug = false, -- Enable or disable debug mode, the log file will be in ~/.local/state/nvim/CopilotChat.nvim.log
    prompts = {
      MyCustomPrompt = {
        prompt = 'Explain how it works.',
        mapping = '<leader>ccmc',
        description = 'My custom prompt description',
      },
    },
    mappings = {
      reset = false,
    },
  },
  keys = {
    {
      '<leader>ccco',
      ':CopilotChatCommit<cr>',
      desc = 'CopilotChat - Write commit message'
    },
    {
      '<leader>cccs',
      ':CopilotChatCommitStaged<cr>',
      desc = 'CopilotChat - Write commit message for staged'
    },
    {
      '<leader>ccb',
      ':CopilotChatBuffer ',
      desc = 'CopilotChat - Chat with current buffer'
    },
    {
      '<leader>cce',
      '<cmd>CopilotChatExplain<cr>',
      desc = 'CopilotChat - Explain code'
    },
    {
      '<leader>cct',
      '<cmd>CopilotChatTests<cr>',
      desc = 'CopilotChat - Generate tests'
    },
    {
      '<leader>ccT',
      '<cmd>CopilotChatVsplitToggle<cr>',
      desc = 'CopilotChat - Toggle Vsplit', -- Toggle vertical split
    },
    {
      '<leader>ccv',
      ':CopilotChatVisual ',
      mode = 'x',
      desc = 'CopilotChat - Open in vertical split',
    },
    {
      '<leader>ccx',
      ':CopilotChatInPlace<cr>',
      mode = 'x',
      desc = 'CopilotChat - Run in-place code',
    },
    {
      '<leader>ccf',
      '<cmd>CopilotChatFix<cr>', -- Get a fix for the diagnostic message under the cursor.
      desc = 'CopilotChat - Fix diagnostic',
    },
    {
      '<leader>ccr',
      '<cmd>CopilotChatReset<cr>', -- Reset chat history and clear buffer.
      desc = 'CopilotChat - Reset chat history and clear buffer',
    },
  },
}
