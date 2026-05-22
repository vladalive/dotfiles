local function has_wakatime_key()
  if vim.env.WAKATIME_API_KEY and vim.env.WAKATIME_API_KEY ~= '' then
    return true
  end

  local home = vim.env.WAKATIME_HOME or vim.env.HOME
  if not home or home == '' then
    return false
  end

  local config = home .. '/.wakatime.cfg'
  if vim.fn.filereadable(config) ~= 1 then
    return false
  end

  for _, line in ipairs(vim.fn.readfile(config)) do
    local key, value = line:match '^%s*([%w_]+)%s*=%s*(.-)%s*$'
    if value and value ~= '' and (key == 'api_key' or key == 'apikey' or key == 'api_key_vault_cmd') then
      return true
    end
  end

  return false
end

return {
  'wakatime/vim-wakatime',
  enabled = has_wakatime_key,
  lazy = false,
  opts = {
    status_bar_enabled = false,
  },
}
