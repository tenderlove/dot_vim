let ruby_space_errors = 1

" Run Ruby unit tests with gT (for all) or gt (only test under
" cursor) in command mode
augroup RubyTests
  au!
  autocmd BufRead,BufNewFile *_test.rb,test_*.rb
    \ :nmap rt V:<C-U>!$HOME/.vim/bin/ruby_run_focused_unit_test 
    \ % <C-R>=line("'<")<CR>p <CR>|
    \ :nmap rT :<C-U>!rake TEST=%<CR>
augroup END

if !exists( "*EndToken" )
  function EndToken()
    let current_line = getline( '.' )
    let braces_at_end = '{\s*\(|\(,\|\s\|\w\)*|\s*\)\?$'
    if match( current_line, braces_at_end ) >= 0
      return '}'
    else
      return 'end'
    endif
  endfunction
endif

nmap <Leader>ee :cf /tmp/autotest.txt<cr> :compiler rubyunit<cr>
