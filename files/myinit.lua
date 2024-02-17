vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

require('Comment').setup()

require('nvim-tree').setup({
  renderer = {
    icons = {
      glyphs = {
         default = nil,
       },
    },
  },
  filters = {
    dotfiles = true,
  },
})

require('lualine').setup({
  sections = {
    lualine_b = {},
    lualine_c = {{ 'filename', path = 1, }},
  },
})

require('neo-zoom').setup({
  popup = { enabled = false },
  winopts = {
    offset = {
      top = 0,
      left = 0,
      width = function()
        return vim.o.columns
      end,
      height = function()
        return vim.o.lines
      end,
    },
    border = 'none',
  },
})

require('gitsigns').setup()

require('nvim-treesitter').setup({
  highlight = {
    enable = true,
  },
  indent = { enable = true },
  ensure_installed = {
    "bash",
    "comment",
    "css",
    "diff",
    "dot",
    "git_config",
    "git_rebase",
    "gitattributes",
    "gitcommit",
    "gitignore",
    "html",
    "javascript",
    "jq",
    "json",
    "lua",
    "markdown",
    "markdown_inline",
    "pug",
    "python",
    "regex",
    "ruby",
    "scss",
    "sql",
    "ssh_config",
    "typescript",
    "vim",
    "vue",
    "xml",
    "yaml",
  },
  auto_install = true,
})
