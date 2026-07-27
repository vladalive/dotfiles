-- Avante

return {
  'yetone/avante.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    'stevearc/dressing.nvim',
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    'ravitemer/mcphub.nvim',
  },
  build = 'make',
  cmd = {
    'AvanteAsk',
    'AvanteBuild',
    'AvanteChat',
    'AvanteChatNew',
    'AvanteClear',
    'AvanteEdit',
    'AvanteRefresh',
    'AvanteToggle',
  },
  -- avante registers its <leader>a* mappings during setup(), which only runs
  -- once the plugin loads. With `cmd` as the sole lazy trigger the keys did
  -- nothing until an :Avante* command had been run at least once. These entries
  -- give lazy.nvim key triggers so the first press loads the plugin and then
  -- replays the key; the real mappings still come from avante's own defaults.
  keys = {
    { '<leader>aa', desc = 'avante: ask', mode = { 'n', 'v' } },
    { '<leader>ae', desc = 'avante: edit', mode = 'v' },
    { '<leader>an', desc = 'avante: new ask', mode = { 'n', 'v' } },
    { '<leader>at', desc = 'avante: toggle', mode = 'n' },
    { '<leader>af', desc = 'avante: focus', mode = 'n' },
    { '<leader>ar', desc = 'avante: refresh', mode = 'n' },
    { '<leader>aS', desc = 'avante: stop', mode = 'n' },
    { '<leader>as', desc = 'avante: toggle suggestion', mode = 'n' },
    { '<leader>az', desc = 'avante: zen mode', mode = { 'n', 'v' } },
    { '<leader>ah', desc = 'avante: history', mode = 'n' },
    { '<leader>a?', desc = 'avante: select model', mode = 'n' },
  },
  -- opts = {
  -- },
  config = function()
    require('avante').setup {
      -- debug = true,
      max_tokens = 4096,
      context_lines = 100,
      behavior = {
        auto_suggestions = true,
        auto_apply_diff_after_generation = true,
      },
      -- provider = 'ollama',
      -- provider = 'copilot',
      -- provider = "openrouter",
      provider = 'minimax',
      -- auto_suggestions fires on every pause, so it gets the fast model rather
      -- than M3. avante warns this path is request-heavy; on a shared MiniMax
      -- quota that matters. Raise suggestion.debounce if it still runs hot.
      auto_suggestions_provider = 'minimax_fast',
      providers = {
        ollama = {
          endpoint = 'http://localhost:11435',
          model = 'gemma3:4b',
        },
        copilot = {
          -- model = 'claude-sonnet-4',
          -- model = 'gpt-4',
          model = 'gpt-5-mini',
          -- model = 'gpt-4-0125-preview',
          extra_request_body = {
            -- max_tokens = 4096,
          },
        },
        -- MiniMax over its OpenAI-compatible route. MINIMAX_API_KEY comes from
        -- `envs`, so nvim launched from a shell already has it.
        -- No reasoning_split here on purpose: avante strips <think> itself via
        -- Utils.trim_think_content in both llm.lua and suggestion.lua, so the
        -- default response shape is already handled and needs no extra body.
        minimax = {
          __inherited_from = 'openai',
          endpoint = 'https://api.minimax.io/v1',
          api_key_name = 'MINIMAX_API_KEY',
          model = 'MiniMax-M3',
          timeout = 60000,
          extra_request_body = {
            max_tokens = 8192,
          },
        },
        -- Same endpoint, faster model. Used for auto_suggestions only:
        -- M3 averaged ~8.4s versus ~4.2s for M2.7-highspeed on short prompts.
        minimax_fast = {
          __inherited_from = 'openai',
          endpoint = 'https://api.minimax.io/v1',
          api_key_name = 'MINIMAX_API_KEY',
          model = 'MiniMax-M2.7-highspeed',
          timeout = 30000,
          extra_request_body = {
            max_tokens = 2048,
          },
        },
        openrouter = {
          __inherited_from = 'openai',
          endpoint = 'https://openrouter.ai/api/v1',
          api_key_name = 'OPEN_ROUTER_API_KEY',
          -- api_key_name = 'cmd:bw get notes key-open-router-coding',
          model = 'qwen/qwen3-coder:free',
          -- model = 'deepseek/deepseek-chat-v3-0324:free',
          timeout = 30000,
        },
      },
      -- https://ravitemer.github.io/mcphub.nvim/extensions/avante.html
      -- system_prompt as function ensures LLM always has latest MCP server state
      -- This is evaluated for every message, even in existing chats
      system_prompt = function()
        local hub = require('mcphub').get_hub_instance()
        return hub and hub:get_active_servers_prompt() or ''
      end,
      -- Using function prevents requiring mcphub before it's loaded
      custom_tools = function()
        return {
          require('mcphub.extensions.avante').mcp_tool(),
        }
      end,
    }
  end,
}
