-- Github copilot
return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  config = function()
    require('copilot').setup {
      copilot_node_command = vim.fn.expand '$HOME' .. '/.asdf/installs/nodejs/18.10.0/bin/node',
      suggestion = { enabled = false },
      panel = { enabled = false },
    }
  end,
}
