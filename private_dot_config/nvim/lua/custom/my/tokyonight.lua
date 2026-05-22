return {
  'folke/tokyonight.nvim',
  lazy = false,
  priority = 1000,
  config = function()
    local has_true_color = (vim.env.COLORTERM == 'truecolor' or vim.env.COLORTERM == '24bit')
    local is_legacy_term = vim.env.TERM == 'screen-256color' or vim.env.TERM == 'xterm-256color' and vim.env.COLORTERM == nil

    if (not has_true_color) or is_legacy_term then
      vim.opt.background = 'dark'
      vim.cmd.colorscheme 'habamax'
    else
      vim.cmd.colorscheme 'tokyonight-night'
    end

    vim.cmd.hi 'Comment gui=none'
  end,
}
