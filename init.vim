" Enhanced init.vim for Ubuntu servers
" Leader key
let mapleader =","

" Auto-install vim-plug if not present
if ! filereadable(system('echo -n "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/plug.vim"'))
    echo "Downloading junegunn/vim-plug to manage plugins..."
    silent !mkdir -p ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/
    silent !curl "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" > ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/autoload/plug.vim
    autocmd VimEnter * PlugInstall
endif

" Quick template navigation
map ,, :keepp /<++><CR>ca<
imap ,, <esc>:keepp /<++><CR>ca<

" Plugins
call plug#begin(system('echo -n "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/plugged"'))
Plug 'tpope/vim-surround'              " Surround text objects
Plug 'tpope/vim-commentary'            " Comment stuff out
Plug 'tpope/vim-fugitive'              " Best git integration
Plug 'tpope/vim-dispatch'              " Run commands asynchronously
Plug 'airblade/vim-gitgutter'          " Git diff in gutter
Plug 'mbbill/undotree'                 " Undo history visualizer
Plug 'morhetz/gruvbox'                 " Gruvbox colorscheme
Plug 'vim-airline/vim-airline'         " Status line
Plug 'ap/vim-css-color'                " CSS color preview
Plug 'preservim/nerdtree'              " File explorer
Plug 'Xuyuanp/nerdtree-git-plugin'     " Git status in NERDTree
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'                " FZF integration
Plug 'dense-analysis/ale'              " Linting and fixing
call plug#end()

" Gruvbox colorscheme configuration
let g:gruvbox_contrast_dark = 'medium'
let g:gruvbox_contrast_light = 'hard'
let g:gruvbox_italic = 1
set background=dark
colorscheme gruvbox

" Toggle background command
command! ToggleBackground call ToggleBackgroundMode()
function! ToggleBackgroundMode()
    if &background ==# 'dark'
        set background=light
    else
        set background=dark
    endif
endfunction
map <leader>bg :ToggleBackground<CR>

" Basic settings
set title
set mouse=a
set nohlsearch
set clipboard+=unnamedplus
set noshowmode
set noruler
set laststatus=2
set noshowcmd
set scrolloff=8
set number relativenumber
set encoding=utf-8

" Undo configuration (XDG-compliant)
set undodir=${XDG_CACHE_HOME:-$HOME/.cache}/nvim/undo
set undofile
nnoremap U :UndotreeToggle<CR>

" Basic settings
set nocompatible
filetype plugin on
syntax on
set wildmode=longest,list,full
set splitbelow splitright

" Disable automatic commenting on newline
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" Perform dot commands over visual blocks
vnoremap . :normal .<CR>

" Safer delete - don't yank with c
nnoremap c "_c

" Replace all is aliased to S
nnoremap S :%s//g<Left><Left>

" Replace ex mode with gq
map Q gq

" Spell-check toggle
map <leader>o :setlocal spell! spelllang=en_us<CR>

" Split navigation shortcuts
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l
nnoremap <leader>vs :vsplit<CR>
nnoremap <leader>hs :split<CR>

" Buffer management
nnoremap <leader>bd :bdelete<CR>
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprev<CR>
nnoremap <leader>bl :buffers<CR>

" Search and replace helpers
nnoremap <leader>/ :nohlsearch<CR>
vnoremap <leader>r "hy:%s/<C-r>h//g<left><left>

" NERDTree configuration
let g:NERDTreeWinSize=35
let g:NERDTreeShowHidden=1
let g:NERDTreeMinimalUI=1
let g:NERDTreeDirArrows=1
let g:NERDTreeShowLineNumbers=0
let g:NERDTreeCascadeOpenSingleChildDir=1
let g:NERDTreeShowBookmarks=1
let g:NERDTreeIgnore = ['^\.DS_Store', '^tags', '^node_modules', '^\.git$[[dir]]', '\.pyc$']

map <leader>n :NERDTreeToggle<CR>
map <leader>N :NERDTreeFind<CR>

" Auto-close NERDTree if it's the only window left
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Git integration (vim-fugitive & gitgutter)
map <leader>gs :Git<CR>
map <leader>gd :Gdiffsplit<CR>
map <leader>gc :Git commit<CR>
map <leader>gb :Git blame<CR>
map <leader>gl :Git log --oneline<CR>
map <leader>gp :Git push<CR>

" GitGutter settings
let g:gitgutter_enabled = 1
let g:gitgutter_map_keys = 0
let g:gitgutter_highlight_linenrs = 1
nmap ]h <Plug>(GitGutterNextHunk)
nmap [h <Plug>(GitGutterPrevHunk)
nmap <leader>hp <Plug>(GitGutterPreviewHunk)
nmap <leader>hs <Plug>(GitGutterStageHunk)
nmap <leader>hu <Plug>(GitGutterUndoHunk)

" FZF (Fuzzy Finder) settings
map <leader>ff :Files<CR>
map <leader>fb :Buffers<CR>
map <leader>fg :GFiles<CR>
map <leader>fr :Rg<CR>
map <leader>fl :Lines<CR>
map <leader>fh :History<CR>
map <leader>fc :Commits<CR>

" ALE (Linting) settings
let g:ale_enabled = 1
let g:ale_sign_column_always = 1
let g:ale_fix_on_save = 1
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 0
nmap ]a <Plug>(ale_next_wrap)
nmap [a <Plug>(ale_previous_wrap)
map <leader>af :ALEFix<CR>

" Check file in shellcheck
map <leader>s :!clear && shellcheck -x %<CR>

" Automatically delete trailing whitespace on save
autocmd BufWritePre * let currPos = getpos(".")
autocmd BufWritePre * %s/\s\+$//e
autocmd BufWritePre * %s/\n\+\%$//e
autocmd BufWritePre * cal cursor(currPos[1], currPos[2])

" Save file as sudo
cabbrev w!! execute 'silent! write !sudo tee % >/dev/null' <bar> edit!

" Better diff highlighting
if &diff
    highlight! link DiffText MatchParen
endif

" Toggle statusbar visibility
let s:hidden_all = 0
function! ToggleHiddenAll()
    if s:hidden_all  == 0
        let s:hidden_all = 1
        set noshowmode
        set noruler
        set laststatus=0
        set noshowcmd
    else
        let s:hidden_all = 0
        set showmode
        set ruler
        set laststatus=2
        set showcmd
    endif
endfunction
nnoremap <leader>h :call ToggleHiddenAll()<CR>
