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
    \ :nmap rT :<C-U>!ruby -I lib:ext:test %<CR>
augroup END

