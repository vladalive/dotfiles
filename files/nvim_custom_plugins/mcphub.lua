-- MCPHub.nvim configuration
-- Provides MCP (Model Context Protocol) server integration for Neovim

-- Configuration defaults
local default_config = {
  auto_approve = true, -- Require manual approval for MCP operations
  global_env = {
    "DEFAULT_MINIMUM_TOKENS", -- Environment variables to expose to MCP servers
  },
  extensions = {
    avante = {
      enabled = true, -- Enable Avante integration
      make_slash_commands = true, -- Create slash commands for Avante
    },
    copilotchat = {
      enabled = true,
      convert_tools_to_functions = true,     -- Convert MCP tools to CopilotChat functions
      convert_resources_to_functions = true, -- Convert MCP resources to CopilotChat functions
      add_mcp_prefix = false,                -- Add "mcp_" prefix to function names
    },
  },
}

-- Build function with better error handling
local function build_mcphub()
  local handle = io.popen("which npm 2>/dev/null")
  if not handle then
    vim.notify("npm not found. Please install Node.js and npm first.", vim.log.levels.ERROR)
    return
  end

  local npm_path = handle:read("*a")
  handle:close()

  if npm_path == "" then
    vim.notify("npm not found. Please install Node.js and npm first.", vim.log.levels.ERROR)
    return
  end

  -- Check if mcp-hub is already installed
  local check_handle = io.popen("which mcp-hub 2>/dev/null")
  if check_handle then
    local existing = check_handle:read("*a")
    check_handle:close()
    if existing ~= "" then
      vim.notify("mcp-hub already installed, skipping installation", vim.log.levels.INFO)
      return
    end
  end

  -- Install with specific version for reproducibility
  vim.notify("Installing mcp-hub globally...", vim.log.levels.INFO)
  local install_cmd = "npm install -g mcp-hub@latest"
  local success = os.execute(install_cmd)

  if success == 0 then
    vim.notify("mcp-hub installed successfully", vim.log.levels.INFO)
  else
    vim.notify("Failed to install mcp-hub. Please install manually: " .. install_cmd, vim.log.levels.ERROR)
  end
end

-- Setup function with configuration validation
local function setup_mcphub()
  local ok, mcphub = pcall(require, "mcphub")
  if not ok then
    vim.notify("Failed to load mcphub plugin", vim.log.levels.ERROR)
    return
  end

  -- Merge user config with defaults (if any user config exists)
  local config = vim.tbl_deep_extend("force", default_config, {})

  -- Validate configuration
  if type(config.auto_approve) ~= "boolean" then
    vim.notify("mcphub: auto_approve must be boolean, defaulting to false", vim.log.levels.WARN)
    config.auto_approve = false
  end

  if type(config.global_env) ~= "table" then
    vim.notify("mcphub: global_env must be table, defaulting to empty", vim.log.levels.WARN)
    config.global_env = {}
  end

  mcphub.setup(config)
end

return {
  "ravitemer/mcphub.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  -- Lazy loading optimization - load on specific events
  event = "VeryLazy", -- Load after UI is ready
  cmd = { "MCPHub" }, -- Load when MCP commands are used

  -- Improved build process with error handling
  build = build_mcphub,

  -- Initialization function for pre-loading setup
  init = function()
    -- Set up any keymaps or commands that should be available immediately
    vim.api.nvim_create_user_command("MCPHubStatus", function()
      vim.notify("MCPHub plugin loaded: " .. (package.loaded["mcphub"] and "Yes" or "No"))
    end, { desc = "Check MCPHub plugin status" })
  end,

  -- Main configuration
  config = setup_mcphub,

  -- Plugin options
  opts = default_config,
}
