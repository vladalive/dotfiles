-- Avante

return {
  "yetone/avante.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = { file_types = { "markdown", "Avante" } },
      ft = { "markdown", "Avante" },
    },
  },
  build = "make",
  opts = {
    -- debug = true,
    provider = "copilot",
    -- provider = "openrouter",
    providers = {
      copilot = {
        extra_request_body = {
          max_tokens = 50000,
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
  },
}
