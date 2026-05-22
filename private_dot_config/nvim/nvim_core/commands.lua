vim.api.nvim_create_user_command('RunSubstitutions', function(args)
  local lines = vim.api.nvim_buf_get_lines(0, args.line1 - 1, args.line2, false)

  for index, line in ipairs(lines) do
    line = line:gsub('%s+$', '')
    line = line:gsub('"', "'")
    line = line:gsub(':([^= ]*)%s*=>%s*', '%1: ')
    line = line:gsub('{([^ ].*[^ ])}', '{ %1 }')
    line = line:gsub('^(%s*)%+', '%1')
    line = line:gsub('%[', ' ')
    line = line:gsub('%]', ',')
    lines[index] = line
  end

  vim.api.nvim_buf_set_lines(0, args.line1 - 1, args.line2, false, lines)
end, { range = true })

vim.api.nvim_create_user_command('FormatDisable', function(args)
  if args.bang then
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, {
  desc = 'Disable autoformat-on-save',
  bang = true,
})

vim.api.nvim_create_user_command('FormatEnable', function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, {
  desc = 'Re-enable autoformat-on-save',
})

vim.api.nvim_create_user_command('Format', function(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ['end'] = { args.line2, end_line:len() },
    }
  end
  require('conform').format { async = true, lsp_format = 'fallback', range = range }
end, { range = true })
