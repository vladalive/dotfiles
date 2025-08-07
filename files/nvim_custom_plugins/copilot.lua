-- Github copilot
return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  config = function()
    require('copilot').setup {
      copilot_node_command = vim.fn.expand '$HOME' .. '/.asdf/installs/nodejs/20.18.1/bin/node',
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
  end,
}
