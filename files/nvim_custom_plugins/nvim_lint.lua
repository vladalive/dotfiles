return {
  'mfussenegger/nvim-lint',
  event = {
    'BufReadPost',
    'BufWritePost',
  },
  config = function()
    local lint = require('lint')

    local function executable(name)
      return vim.fn.executable(name) == 1
    end

    local linters_by_ft = {}

    if executable('rubocop') then
      linters_by_ft.ruby = { 'rubocop' }
    end

    if executable('shellcheck') then
      linters_by_ft.bash = { 'shellcheck' }
      linters_by_ft.sh = { 'shellcheck' }
    end

    lint.linters_by_ft = linters_by_ft

    vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost' }, {
      group = vim.api.nvim_create_augroup('dotfiles-lint', { clear = true }),
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
