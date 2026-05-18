return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = function()
    local treesitter_languages = {
      'bash',
      'c',
      'comment',
      'css',
      'diff',
      'dot',
      'git_config',
      'git_rebase',
      'gitattributes',
      'gitcommit',
      'gitignore',
      'html',
      'javascript',
      'jq',
      'json',
      'lua',
      'markdown',
      'markdown_inline',
      'pug',
      'python',
      'regex',
      'ruby',
      'scss',
      'sql',
      'ssh_config',
      'typescript',
      'vim',
      'vimdoc',
      'vue',
      'xml',
      'yaml',
    }

    require('nvim-treesitter').install(treesitter_languages, { max_jobs = 1, summary = true }):wait(300000)
  end,
  config = function()
    require('nvim-treesitter').setup {
      install_dir = vim.fn.stdpath 'data' .. '/site',
    }

    local treesitter_filetypes = {
      'bash',
      'c',
      'css',
      'diff',
      'dot',
      'gitcommit',
      'gitconfig',
      'gitignore',
      'gitrebase',
      'gitattributes',
      'help',
      'html',
      'javascript',
      'jq',
      'json',
      'lua',
      'markdown',
      'pug',
      'python',
      'regex',
      'ruby',
      'scss',
      'sh',
      'sql',
      'sshconfig',
      'typescript',
      'vim',
      'vue',
      'xml',
      'yaml',
      'zsh',
    }
    local treesitter_filetypes_by_name = {}
    for _, filetype in ipairs(treesitter_filetypes) do
      treesitter_filetypes_by_name[filetype] = true
    end

    local function start_treesitter(buffer)
      if not vim.api.nvim_buf_is_loaded(buffer) then
        return
      end

      if not treesitter_filetypes_by_name[vim.bo[buffer].filetype] then
        return
      end

      if pcall(vim.treesitter.start, buffer) then
        vim.bo[buffer].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('kickstart-treesitter', { clear = true }),
      pattern = treesitter_filetypes,
      callback = function(args)
        start_treesitter(args.buf)
      end,
    })

    vim.api.nvim_create_autocmd('BufEnter', {
      group = vim.api.nvim_create_augroup('kickstart-treesitter-buffer-enter', { clear = true }),
      callback = function(args)
        start_treesitter(args.buf)
      end,
    })

    vim.schedule(function()
      for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        start_treesitter(buffer)
      end
    end)
  end,
}
