-- Avante

return {
  "yetone/avante.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "ravitemer/mcphub.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = { file_types = { "markdown", "Avante" } },
      ft = { "markdown", "Avante" },
    },
  },
  build = "make",
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
      provider = "copilot",
      -- provider = "openrouter",
      providers = {
        ollama = {
          endpoint = 'http://localhost:11435',
          model = 'gemma3:4b',
        },
        copilot = {
          -- model = 'claude-sonnet-4',
          -- model = 'gpt-4',
          model = 'gpt-4.1',
          -- model = 'gpt-4-0125-preview',
          extra_request_body = {
            -- max_tokens = 4096,
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
        local hub = require("mcphub").get_hub_instance()
        return hub and hub:get_active_servers_prompt() or ""
      end,
      -- Using function prevents requiring mcphub before it's loaded
      custom_tools = function()
        return {
          require("mcphub.extensions.avante").mcp_tool(),
        }
      end,
    }
  end,
}
