-- Github copilot
return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  config = function()
    local minimum_node_major = 22

    local function node_version(command)
      local version = vim.trim(vim.fn.system { command, '--version' })
      if vim.v.shell_error ~= 0 then
        return
      end

      local major, minor, patch = version:match '^v?(%d+)%.(%d+)%.(%d+)'
      if major == nil then
        return
      end

      return {
        major = tonumber(major),
        minor = tonumber(minor),
        patch = tonumber(patch),
      }
    end

    local function newer_version(left, right)
      if right == nil then
        return true
      end

      if left.major ~= right.major then
        return left.major > right.major
      end

      if left.minor ~= right.minor then
        return left.minor > right.minor
      end

      return left.patch > right.patch
    end

    local function usable_node(command)
      if command == nil or command == '' or vim.fn.executable(command) ~= 1 then
        return
      end

      local version = node_version(command)
      if version ~= nil and version.major >= minimum_node_major then
        return command, version
      end
    end

    local function node_command()
      if vim.fn.executable 'asdf' == 1 then
        local node = usable_node(vim.trim(vim.fn.system { 'asdf', 'which', 'node' }))
        if node ~= nil then
          return node
        end

        local best_node
        local best_version
        local asdf_data_dir = vim.env.ASDF_DATA_DIR or vim.fn.expand '$HOME/.asdf'
        local nodes = vim.fn.glob(asdf_data_dir .. '/installs/nodejs/*/bin/node', false, true)

        for _, candidate in ipairs(nodes) do
          local usable_candidate, version = usable_node(candidate)
          if usable_candidate ~= nil and newer_version(version, best_version) then
            best_node = usable_candidate
            best_version = version
          end
        end

        if best_node ~= nil then
          return best_node
        end
      end

      return usable_node(vim.fn.exepath 'node')
    end

    local opts = {
      suggestion = {
        enabled = false,
        auto_trigger = false,
      },
      panel = {
        enabled = false,
      },
      filetypes = {
        ['*'] = true,
        ruby = true,
        javascript = true,
      },
    }

    local copilot_node_command = node_command()
    if copilot_node_command ~= nil then
      opts.copilot_node_command = { copilot_node_command, '--no-warnings' }
    end

    require('copilot').setup(opts)
  end,
}
