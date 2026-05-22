return {
  'mfussenegger/nvim-lint',
  event = {
    'BufReadPost',
    'BufWritePost',
  },
  config = function()
    local lint = require 'lint'

    local function executable(name)
      return vim.fn.executable(name) == 1
    end

    local function dirname(path)
      return vim.fn.fnamemodify(path, ':h')
    end

    local function current_file()
      local source = debug.getinfo(1, 'S').source:sub(2)
      return vim.uv.fs_realpath(source) or vim.fn.fnamemodify(source, ':p')
    end

    local linters_by_ft = {}

    if executable 'selene' then
      local files_dir = dirname(dirname(current_file()))

      lint.linters.selene.cwd = files_dir
      lint.linters.selene.args = { '--config', files_dir .. '/nvim-selene.toml', '--display-style', 'json', '-' }

      linters_by_ft.lua = { 'selene' }
    end

    if executable 'rubocop' then
      linters_by_ft.ruby = { 'rubocop' }
    end

    if executable 'shellcheck' then
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
