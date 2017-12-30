set number
syntax on

filetype plugin indent on
set tabstop=2
set shiftwidth=2
set expandtab

command W w !sudo tee % > /dev/null

set so=7
set wildmenu

set whichwrap+=<,>,h,l

set ignorecase
"set smartcase
set hlsearch
set incsearch

set showmatch
set mat=1

set t_Co=256

colorscheme termschool

" Netrw configuration.
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_winsize = 15

au BufRead,BufNewFile *.install setfiletype php
