call pathogen#runtime_append_all_bundles()
call pathogen#helptags()

set nocompatible

function! SetRailsEnv()
  let l:path = getcwd()
  let g:ruby_indent_access_modifier_style="normal"
  if match(l:path, "rails\$") > 0
    if filewritable(l:path . "/activesupport") == 2
      if match(&path, "activesupport") < 0
        let &path = "activesupport/lib,actionpack/lib,activerecord/lib," . &path
      endif
      compiler minitest
      let g:ruby_indent_access_modifier_style="indent"
    endif
  endif
endfunction

function! SetRailsMake()
  let l:path = getcwd()
  if match(l:path, "rails\$") > 0
    if filewritable(l:path . "/activesupport") == 2
      let l:base = split(expand("%"), '\/')[0]
      let l:lib = l:base . "/lib"
      let l:test = l:base . "/test"
      let l:prg = "ruby\ -I\ " . l:lib . ":" . l:test . "\ %"
      let &makeprg=l:prg
    endif
  endif
endfunction

function! MoveToProjectRoot()
  let l:dirs = [finddir('.git', ",;")]
  if dirs != ['.git'] && dirs != ['']
    call map(dirs, '"/" . join(remove(split(v:val, "/"), 0, -2), "/")')
    execute 'cd ' . dirs[0]
  endif
endfunction

function! AlignSection(regex) range
  let extra = 1
  let sep = empty(a:regex) ? '=' : a:regex
  let maxpos = 0
  let section = getline(a:firstline, a:lastline)
  for line in section
    let pos = match(line, ' *'.sep)
    if maxpos < pos
      let maxpos = pos
    endif
  endfor
  call map(section, 'AlignLine(v:val, sep, maxpos, extra)')
  call setline(a:firstline, section)
endfunction

function! AlignLine(line, sep, maxpos, extra)
  let m = matchlist(a:line, '\(.\{-}\) \{-}\('.a:sep.'.*\)')
  if empty(m)
    return a:line
  endif
  let spaces = repeat(' ', a:maxpos - strlen(m[1]) + a:extra)
  return m[1] . spaces . m[2]
endfunction

filetype plugin indent on

" Put these in an autocmd group, so that we can delete them easily.
augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 78 characters.
  autocmd FileType text setlocal textwidth=78

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  autocmd BufReadPost *
        \ if line("'\"") > 0 && line("'\"") <= line("$") |
        \   exe "normal g`\"" |
        \ endif
  autocmd BufRead *.rdoc setlocal filetype=text
  autocmd BufRead *.md setlocal filetype=markdown
  autocmd BufRead *.markdown setlocal filetype=markdown
  autocmd BufRead *.c setlocal noet sws=4 sw=4
  autocmd Filetype gitcommit setlocal spell textwidth=72
augroup END

augroup filetype_ruby
  autocmd!
  autocmd FileType ruby nnoremap <buffer> <localleader>c I#<esc>
  autocmd BufRead *_test.rb :call SetRailsMake()
  autocmd BufRead,VimEnter * :call SetRailsEnv()
  autocmd FileType ruby compiler rubyunit
augroup END

augroup filetype_vim
  autocmd!
  autocmd FileType vim setlocal foldmethod=marker
augroup END

if has("gui_running")
  set lines=50
  set columns=90
  set guioptions-=m
  set guioptions-=T
endif

set backspace=indent,eol,start
set autoindent		" always set autoindenting on
set history=50		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
set showcmd		" display incomplete commands
set incsearch		" do incremental searching
set relativenumber
set wildmode=list:full
set suffixesadd=.rb     " find ruby files
set path+=lib/**,test/** " look in lib and test

set expandtab
set shiftwidth=2
set softtabstop=2
set kp=ri

set exrc
set secure
set colorcolumn=81

set backupdir=/tmp

set tags+=.git/tags
set scrolloff=2
set ruler
set laststatus=2
setlocal spell spelllang=en_us

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif

if has("ruby") " assume system has ruby
  " Add stdlib of environment's ruby to path
  let stdlib = system('ruby -rrbconfig -e"print RbConfig::CONFIG[\"rubylibdir\"]"')
  let &l:path = &path . "," . stdlib
  let g:ruby_path = &path
endif

let g:vim_markdown_folding_disabled=1
let g:html_font = "Inconsolata"

map <Leader>rt :!ctags --tag-relative --extra=+f -Rf.git/tags --exclude=.git,pkg --languages=-javascript,sql<CR><CR>

let ruby_space_errors = 1
let c_space_errors = 1

command! -nargs=? -range Align <line1>,<line2>call AlignSection('<args>')
vnoremap <silent> <Leader>a :Align<CR>

" Changelog configuration
let g:changelog_username='Aaron Patterson <tenderlove@ruby-lang.org>'
let g:changelog_dateformat='%c'
let g:airline_theme='light'

nnoremap <leader>ev :split $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>
" Git grep visually selected text
vnoremap <leader>gg y:Ggrep <c-r>"<cr>
