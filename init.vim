" Enhanced init.vim for Ubuntu servers
" Leader key
let mapleader =","

" Config directory (respects $XDG_CONFIG_HOME) without spawning a shell
let s:config_dir = stdpath('config')

" Auto-install vim-plug if not present.
" Pinned to a release tag (not master) and fetched with -f so an HTTP error page is
" never saved as plug.vim. Bump the tag deliberately when updating.
let s:plug_version = '0.14.0'
let s:plug_file = s:config_dir . '/autoload/plug.vim'
if !filereadable(s:plug_file)
    echo 'Downloading junegunn/vim-plug ' . s:plug_version . ' to manage plugins...'
    call mkdir(fnamemodify(s:plug_file, ':h'), 'p')
    call system(['curl', '-fsSL', '--proto', '=https', '--tlsv1.2', '-o', s:plug_file,
                \ 'https://raw.githubusercontent.com/junegunn/vim-plug/' . s:plug_version . '/plug.vim'])
    if v:shell_error
        call delete(s:plug_file)
        echohl WarningMsg | echo 'vim-plug download failed; plugins disabled for this session' | echohl None
    else
        autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
    endif
endif

" Quick template navigation
map ,, :keepp /<++><CR>ca<
imap ,, <esc>:keepp /<++><CR>ca<

" Plugins (skipped cleanly if vim-plug is unavailable)
if filereadable(s:plug_file)
call plug#begin(s:config_dir . '/plugged')
Plug 'tpope/vim-surround'              " Surround text objects
Plug 'tpope/vim-commentary'            " Comment stuff out
Plug 'tpope/vim-fugitive'              " Best git integration
Plug 'tpope/vim-dispatch'              " Run commands asynchronously
Plug 'airblade/vim-gitgutter'          " Git diff in gutter
Plug 'mbbill/undotree'                 " Undo history visualizer
" Plug 'morhetz/gruvbox'                 " Gruvbox colorscheme (disabled for minimal VM setup)
Plug 'vim-airline/vim-airline'         " Status line
Plug 'ap/vim-css-color'                " CSS color preview
Plug 'preservim/nerdtree'              " File explorer
Plug 'Xuyuanp/nerdtree-git-plugin'     " Git status in NERDTree
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'                " FZF integration
Plug 'dense-analysis/ale'              " Linting and fixing
call plug#end()
endif

" Colorscheme configuration
set background=dark
" Using vim's default colorscheme for minimal VM setup
" (gruvbox disabled - uncomment Plug line above and run :PlugInstall to enable)

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
let &undodir = (empty($XDG_CACHE_HOME) ? $HOME . '/.cache' : $XDG_CACHE_HOME) . '/nvim/undo'
call mkdir(&undodir, 'p', 0700)
set undofile
nnoremap U :UndotreeToggle<CR>

" Basic settings
set nocompatible
filetype plugin on
syntax on
set wildmode=longest,list,full
set splitbelow splitright

augroup dotfiles
    autocmd!
augroup END

" Disable automatic commenting on newline
autocmd dotfiles FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

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
autocmd dotfiles BufEnter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

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
" (skipped for diff/patch files where trailing whitespace is meaningful)
function! s:StripTrailing() abort
    if &filetype =~# '^\(diff\|gitsendemail\)$' | return | endif
    let l:view = winsaveview()
    keeppatterns %s/\s\+$//e
    keeppatterns %s/\n\+\%$//e
    call winrestview(l:view)
endfunction
autocmd dotfiles BufWritePre * call s:StripTrailing()

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
