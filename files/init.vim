" call plug#begin()

call plug#begin(has('nvim') ? stdpath('data') . '/plugged' : '~/.vim/plugged')

if has('nvim')
  Plug 'nvim-lua/popup.nvim'
  Plug 'nvim-lua/plenary.nvim'
  Plug 'nvim-lualine/lualine.nvim'
  Plug 'romainl/Apprentice'
  " Plug 'nvim-tree/nvim-web-devicons'
  Plug 'nvim-tree/nvim-tree.lua'
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.5' }
  Plug 'wakatime/vim-wakatime'
  Plug 'github/copilot.vim'
  Plug 'folke/which-key.nvim'
  Plug 'numToStr/Comment.nvim'
  Plug 'tpope/vim-projectionist'
  Plug 'airblade/vim-gitgutter'
  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-surround'
  Plug 'nyngwang/NeoZoom.lua'
  Plug 'lewis6991/gitsigns.nvim'
  " Plug 'dense-analysis/ale'
  Plug 'neovim/nvim-lspconfig'
endif

call plug#end()

colorscheme apprentice

set number
set ruler
set nowrap
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
set smartindent
set breakindent
set autoread

set hlsearch
set incsearch
set ignorecase
set smartcase

set mouse=

let mapleader = '\'

nnoremap ; :
nmap <silent> // :nohlsearch<CR>

nmap <C-h> <C-w>h
nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
nmap <C-l> <C-w>l

nmap Y Vy

map <Leader>n :NvimTreeToggle<CR>
nmap <Leader>a :A<CR>
nmap <Leader><Leader> :NeoZoomToggle<CR>

nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

let g:ale_linters = {
  \ 'ruby': ['rubocop'],
  \ 'javascript': ['eslint'],
  \ 'vue': ['javascript', 'html', 'stylus'],
  \ }

let g:ale_fixers = {
  \ '*': ['remove_trailing_lines', 'trim_whitespace'],
  \ 'ruby': ['rubocop'],
  \ }

source ~/.config/nvim/myinit.lua
