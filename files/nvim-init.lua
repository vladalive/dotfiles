local config_file = vim.uv.fs_realpath(debug.getinfo(1, 'S').source:sub(2)) or debug.getinfo(1, 'S').source:sub(2)
local config_dir = vim.fn.fnamemodify(config_file, ':h')
local repo_dir = vim.fn.fnamemodify(config_dir, ':h')

local function load_core(name)
  dofile(config_dir .. '/nvim_core/' .. name .. '.lua')
end

load_core 'options'
load_core 'commands'
load_core 'keymaps'
load_core 'autocmds'

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  { import = 'custom.my' },
}, {
  lockfile = repo_dir .. '/lazy-lock.json',
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- vim: ts=2 sts=2 sw=2 et
