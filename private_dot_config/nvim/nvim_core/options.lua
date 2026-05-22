vim.g.mapleader = '\\'
vim.g.maplocalleader = '\\'
vim.g.have_nerd_font = false

vim.opt.number = true
vim.opt.mouse = ''
vim.opt.showmode = false
vim.opt.clipboard = 'unnamedplus'
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 5
vim.opt.hlsearch = true

vim.g.disable_autoformat = true
vim.wo.wrap = false

vim.diagnostic.config {
  severity_sort = true,
  underline = true,
  signs = true,
  virtual_text = false,
  float = {
    border = 'rounded',
    source = true,
  },
}

local has_true_color = (vim.env.COLORTERM == 'truecolor' or vim.env.COLORTERM == '24bit')
local is_legacy_term = vim.env.TERM == 'screen-256color' or vim.env.TERM == 'xterm-256color' and vim.env.COLORTERM == nil
if (not has_true_color) or is_legacy_term then
  vim.opt.termguicolors = false
end
