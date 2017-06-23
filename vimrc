set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'mattn/emmet-vim'
Plugin 'othree/html5.vim'
Plugin 'tomasr/molokai'
Plugin 'scrooloose/nerdtree'
Plugin 'airblade/vim-gitgutter'
syntax enable
set background=dark
colorscheme molokai
let g:molokai_originadark=1
let g:nerdtree_tabs_open_on_console_startup=1
call vundle#end()
filetype plugin indent on
set nu
set expandtab
set shiftwidth=2
set softtabstop=2
map <C-n> :NERDTreeToggle<CR>
