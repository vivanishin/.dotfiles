execute pathogen#infect()
set expandtab
set background=dark
:map <leader>gf :e <cfile><cr>
set paste
set ruler
set tags=tags;
set splitright
set matchpairs+=<:>

let mapleader = "\<Space>"
" Copy & paste to system clipboard with <Space>p and <Space>y.
vmap <Leader>y "+y
vmap <Leader>d "+d
nmap <Leader>p "+p
nmap <Leader>P "+P
vmap <Leader>p "+p
vmap <Leader>P "+P
" Save with <Space>w.
nnoremap <Leader>w :w<CR>
" Paste after end of line with <Space>e.
nnoremap <Leader>e A
nnoremap <Leader>tl :TlistToggle<CR>
nnoremap <leader>gd :Git diff<CR>

nnoremap <Leader>dt :call Dotag()<CR>
nnoremap <Leader>o :call Outline()<CR>
" Iterate over tabs forward and backward with gt/tg.
nnoremap tg gT
nnoremap <Leader>3 #
nnoremap <Leader>8 *

" Russian keyboard.
set keymap=russian-jcukenwin
set iminsert=0
set imsearch=0
highlight lCursor guifg=NONE guibg=Cyan

" Spell check accepting Russian yo.
set spell spelllang=ru_yo,en_us
set nospell

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
    syntax on
    set hlsearch
endif

" This only tracks changes done using vim.
augroup reload_vimrc " {
    autocmd!
    autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END " }

" Reload vimrc.
nmap  <leader>rc :so $MYVIMRC<CR>
" <Ctrl-l> redraws the screen and removes any search highlighting.
nnoremap <silent> <C-l> :nohl<CR><C-l>
" <C-t> for :tag .
nnoremap <silent> <C-t> :tag |
" Remove spaces before newlines.
nmap <leader>rs :%s/\s\+$//<CR>
" Apply macro 'm'.
nmap <leader>m @m
" Toggle spell check.
map <F6> :set spell!<CR>
" Replace sequences of 8 spaces with tabs (WIP).
"  See the help at
"  :h function-range-example and
"  :h a:firstline
nmap <leader>tt  :call SpaceToTab()<CR>
"<Esc>:'<,'>s;[ ]\{8,8\};\t;g<CR>

" Go to prev/next buffer.
nnoremap <silent> '] :bnext<CR>
nnoremap <silent> ]' :bprev<CR>

" Write file to disk if there were changes.
nnoremap zz :update<CR>

" doesn't work...
imap <C-F> <Esc>

set shiftwidth=2
set softtabstop=2
set textwidth=79
set fo-=ro fo+=cql
set hidden	    " Possibility to have more than one unsaved buffer.
set wildmenu	    " Great command-line completion, use '<Tab>' to
		    " move around and '<CR>' to validate.

" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1
" Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1
" " Align line-wise comment delimiters flush left instead of following code indentation
" let g:NERDDefaultAlign = 'left'
" Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1
" Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1
let g:NERD_use_ada_with_spaces = 1

function! Dotag()
 :! dotag
 :cs reset
endfunction

function! Outline()
 :! outline %
endfunction

hi Comment	guifg=#007f7f cterm=none
hi Constant	cterm=none
hi Special	cterm=none
hi Type		cterm=none
hi Statement	cterm=none
hi PreProc	cterm=none

" Make Ctrl-P plugin a lot faster for Git projects
let g:ctrlp_use_caching = 0
if executable('ag')
    set grepprg=ag\ --nogroup\ --nocolor

    let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
else
  let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files . -co --exclude-standard', 'find %s -type f']
  let g:ctrlp_prompt_mappings = {
    \ 'AcceptSelection("e")': ['<space>', '<cr>', '<2-LeftMouse>'],
    \ }
endif
