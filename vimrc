set nocompatible
set backspace=indent,eol,start
set autoindent		" always set autoindenting on
set history=50		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
set showcmd		" display incomplete commands
set incsearch		" do incremental searching
map Q gq
vnoremap p <Esc>:let current_reg = @"<CR>gvs<C-R>=current_reg<CR><Esc>

" Only do this part when compiled with support for autocommands.
if has("autocmd")

  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
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

  augroup END

else

  set autoindent		" always set autoindenting on

endif " has("autocmd")
" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif

if has("gui_running")
  set guioptions-=m
  set guioptions-=T
endif

au BufNewFile,BufRead *.ltx                      set wm=4

set backupdir=/tmp

set path+=lib/**
filetype on
filetype plugin on

set ts=2
set sw=2
set et
set kp=ri

fun GitGrep(...) 
        let save = &grepprg 
        set grepprg=git\ grep\ -n\ $* 
        let s = 'grep' 
        for i in a:000 
                let s = s . ' ' . i 
        endfor 
        exe s 
        let &grepprg = save 
endfun 

command -nargs=? G call GitGrep(<f-args>)

func GitGrepWord()
  normal! "zyiw
  call GitGrep('-w -e ', getreg('z'))
endf
nmap <C-x>G :call GitGrepWord()<CR>

" Run Ruby unit tests with gT (for all) or gt (only test under
" cursor) in command mode
augroup RubyTests
  au!
  autocmd BufRead,BufNewFile *_test.rb,test_*.rb
    \ :nmap rt V:<C-U>!$HOME/.vim/bin/ruby_run_focused_unit_test 
    \ % <C-R>=line("'<")<CR>p <CR>|
    \ :nmap rT :<C-U>!rake TEST=%<CR>
augroup END

map <Leader>rt :!ctags --extra=+f -R *<CR><CR>
set scrolloff=2
"set foldmethod=syntax
"let ruby_no_comment_fold=1
"let c_no_comment_fold=1
set ruler
set laststatus=2
set statusline=%t%(\ [%n%M]%)%(\ %H%R%W%)\ %(%c-%v,\ %l\ of\ %L,\ (%o)\ %P\ 0x%B\ (%b)%)
set lines=40
set columns=80

"match ExtraWhitespace /\s\+$/
"match ExtraTabs /\t\+/
"
"highlight ExtraWhitespace ctermbg=darkgreen guibg=lightgreen
"highlight ExtraTabs ctermbg=red guibg=red
let ruby_space_errors = 1

command! -nargs=? -range Align <line1>,<line2>call AlignSection('<args>')
vnoremap <silent> <Leader>a :Align<CR>
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

setlocal spell spelllang=en_us
compiler rubyunit
