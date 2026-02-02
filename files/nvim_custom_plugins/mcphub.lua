-- MCPHub.nvim configuration
-- Provides MCP (Model Context Protocol) server integration for Neovim

return {
  "ravitemer/mcphub.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  event = "VeryLazy",
  build = "bundled_build.lua",
  config = function()
    require("mcphub").setup({
      use_bundled_binary = true,
      auto_approve = true,
      auto_toggle_mcp_servers = true,
      global_env = {
        "DEFAULT_MINIMUM_TOKENS",
      },
      extensions = {
        avante = {
          enabled = true,
          make_slash_commands = true,
        },
        copilotchat = {
          enabled = true,
          convert_tools_to_functions = true,
          convert_resources_to_functions = true,
          add_mcp_prefix = false,
        },
      },
    })
  end
}
