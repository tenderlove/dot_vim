call pathogen#infect()

set nocompatible

function! SaveSession()
  let l:gitdir = finddir(".git")
  if l:gitdir == ""
    return
  endif

  let l:session = l:gitdir . "/session.vim"
  execute 'mksession! ' . l:session
endfunction

function! RestoreSession()
  if filereadable(getcwd() . "/.git/session.vim")
    execute 'so ' . getcwd() . "/.git/session.vim"
    if bufexists(1)
      for bufnum in range(1, bufnr('$'))
        if bufwinnr(bufnum) == -1
          exec 'sbuffer ' . bufnum
        endif
      endfor
    endif
  endif
endfunction

function! SetRailsEnv()
  let l:path = getcwd()
  let g:ruby_indent_access_modifier_style="normal"
  if match(l:path, "rails\$") > 0
    if filewritable(l:path . "/activesupport") == 2
      if match(&path, "activesupport") < 0
        for component in ["activesupport", "actionpack", "actionview", "activerecord"]
          let &path = component . "/lib/**," . &path
        endfor
      endif
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

function! MoveToProjectRoot(opened_file)
  let l:file_path = fnamemodify(a:opened_file, ":p:h")
  let l:git_dir = finddir(".git", l:file_path . ";")
  if strlen(l:git_dir) > 0
    let l:project_dir = fnamemodify(strpart(l:git_dir, 0, stridx(l:git_dir, "/.git")), ":p")
    if isdirectory(l:project_dir)
      execute 'lcd ' . l:project_dir
      return l:project_dir
    else
      return "" " Didn't move
    endif
  else
    return "" " Didn't move
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

function! MakeIVSet(name, max_width)
  let l:padding = repeat(" ", (a:max_width - strlen(a:name)) + 1)
  return "@" . a:name . padding . "= " . a:name
endfunction

function! MakeIVS(text)
  let l:iv_names = map(split(a:text, ","), { _, item -> trim(item) })
  let l:max_width = max(map(deepcopy(l:iv_names), { _, item -> strlen(item) }))
  let l:lines = map(l:iv_names, { _, item -> MakeIVSet(item, l:max_width) })

  call append(line("."), l:lines)
  let l:cmd = "normal! j=" . (len(l:iv_names) - 1) . "j"
  execute l:cmd
endfunction

function! MakeIVSVisual(type)
  let l:at = @@
  let l:cursor = getpos(".")
  execute "normal! `<v`>y"
  call MakeIVS(@@)
  call setpos(".", l:cursor)
  let @@ = l:at
endfunc

function! MakeIVSLine(line)
  let l:match = matchlist(a:line, 'def initialize[ (]\([^)]*\))\?$')
  if len(l:match) > 0
    call MakeIVS(get(l:match, 1))
  else
    echo "nope"
  endif
endfunc

function! GetLLVMTest(mnemonic)
  let l:cmd = "grep -i '\\b" . a:mnemonic . "\\b' /Users/aaron/git/llvm/test/MC/AArch64/*.s | grep CHECK | ruby ~/git/aarch64/convert.rb"
  let l:lines = split(system(cmd), '\v\n')
  if len(l:lines) == 0
    echo "No tests"
  else
    call append(line("."), l:lines)
  end
endfunc

function! GetLLVMTestVisual(type)
  let l:at = @@
  let l:cursor = getpos(".")
  execute "normal! `<v`>y"
  call GetLLVMTest(@@)
  call setpos(".", l:cursor)
  let @@ = l:at
endfunc

function! MakeASMTest(line)
  let l:match = matchlist(a:line, '# \([A-Z0-9]\+\)')
  if len(l:match) > 0
    call GetLLVMTest(get(l:match, 1))
  else
    let l:match = matchlist(a:line, '# \([a-z]\+.*$\)')

    if len(l:match) > 0
      let l:cmd = "ruby /Users/aaron/git/aarch64/extract_bytes.rb"
      let l:lines = split(system(cmd, get(l:match, 1)), '\v\n')
      call append(line("."), l:lines)
      let l:cmd = "normal! =" . len(l:lines) . "j"
      echo l:cmd
      execute l:cmd
    end
  endif
endfunc

function! MakeIVCall(item)
  if a:item[0] ==# "r"
    return "@" . a:item . ".to_i"
  else
    return "@" . a:item
  endif
endfunction

function! MakeDelegateCall(funcname, text)
  let l:iv_names = map(split(a:text, ","), { _, item -> trim(item) })
  let l:lines = map(l:iv_names, { _, item -> MakeIVCall(item) })

  let l:delegate = "self." . a:funcname . "(" . join(l:lines, ", ") . ")"

  let @@ = l:delegate . "\n"
  echo l:delegate
endfunction

function! MakeDelegate(line)
  let l:match = matchlist(a:line, 'def \(\w\+\)[ (]\(.*\))\?$')
  if len(l:match) > 0
    call MakeDelegateCall(get(l:match, 1), get(l:match, 2))
  endif
endfunc

augroup aaronTest
  au!

  nnoremap <silent> <leader>mr :<c-u>call MakeIVSLine(getline("."))<cr>
  nnoremap <silent> <leader>mt :<c-u>call MakeASMTest(getline("."))<cr>
  nnoremap <silent> <leader>md :<c-u>call MakeDelegate(getline("."))<cr>
augroup END

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
  autocmd BufRead *.c setlocal sw=4
  autocmd BufRead *.cpp setlocal sw=4
  autocmd Filetype gitcommit setlocal spell textwidth=72

  autocmd VimLeave * call SaveSession()
augroup END

augroup filetype_ruby
  autocmd!
  autocmd FileType ruby nnoremap <buffer> <localleader>c I#<esc>
  autocmd BufRead *_test.rb :call SetRailsMake()
  autocmd BufRead,VimEnter * :call SetRailsEnv()
  " autocmd BufRead * :call MoveToProjectRoot(expand("%"))
  autocmd FileType ruby compiler minitest
augroup END

augroup filetype_vim
  autocmd!
  autocmd FileType vim setlocal foldmethod=marker
augroup END

function! OpenPR(sha)
  let pr_number = system("git log --merges --ancestry-path --oneline ". a:sha . "..master | grep 'pull request' | tail -n1 | awk '{print $5}' | cut -c2-")
  let remote = fugitive#RemoteUrl(".")
  let root = rhubarb#homepage_for_url(remote)
  let url = root . '/pull/' . substitute(pr_number, '\v\C\n', '', 1)
  call netrw#BrowseX(url, 0)
endfunction

augroup fugitive_ext
  autocmd!
  " Browse to the commit under my cursor
  autocmd FileType fugitiveblame nnoremap <buffer> <localleader>gb :execute ":Gbrowse " . expand("<cword>")<cr>

  " Browse to the PR for commit under my cursor
  autocmd FileType fugitiveblame nnoremap <buffer> <localleader>pr :call OpenPR(expand("<cword>"))<cr>
augroup END

if has("gui_running")
  set guioptions-=m
  set guioptions-=T
  " set guifont=Cascadia\ Mono\ Light:h12
  set guifont=Inconsolata:h14
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
set path+=lib/**,test/**,app/** " look in lib and test

" Expand tabs, but set shiftwidth and softtabstop to 2.  This allows vim
" to mix tabs and spaces in Ruby C code, but it looks correct
set expandtab
set shiftwidth=2
set softtabstop=2

set kp=ri " Use ri for help

set exrc
set secure
set colorcolumn=81

set backupdir=/tmp

set tags+=.git/tags
set scrolloff=2
set ruler
set laststatus=2
set spell spelllang=en_us

" ===== Instead of backing up files, just reload the buffer when it changes. =====
" The buffer is an in-memory representation of a file, it's what you edit
set autoread                         " Auto-reload buffers when file changed on disk
set nobackup                         " Don't use backup files
set nowritebackup                    " Don't backup the file while editing
set noswapfile                       " Don't create swapfiles for new buffers
set updatecount=0                    " Don't try to write swapfiles after some number of updates
set backupskip=/tmp/*,/private/tmp/* " Let me edit crontab files

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif

if has("terminal")
  map <Leader>tt :terminal ++close<cr>
  tnoremap <Esc> <C-W>N
endif

" Add stdlib of environment's ruby to path
let g:stdlib = system('ruby --disable-gems -rrbconfig -e"print RbConfig::CONFIG[\"rubylibdir\"]"')
let &path .= "," . stdlib
let g:ruby_path = &path

let g:vim_markdown_folding_disabled=1
let g:html_font = ["Inconsolata", "Consolas"]

function! DoneTagging(channel)
  echo "Done tagging"
endfunction

function! Taggit()
  let job = job_start("ctags --tag-relative=yes --extras=+f -Rf.git/tags --languages=-javascript,sql,TypeScript --exclude=.ext --exclude=include/ruby-* --exclude=rb_mjit_header.h .", { 'close_cb': 'DoneTagging'})
endfunction

map <Leader>rt :!ctags --tag-relative=yes --extras=+f -Rf.git/tags --languages=-javascript,sql,TypeScript --exclude=.ext --exclude=include/ruby-\* --exclude=rb_mjit_header.h .<cr><cr>
map <Leader>ww :set lines=58 columns=115<cr>

let ruby_space_errors = 1
let c_space_errors = 1

command! -nargs=? -range Align <line1>,<line2>call AlignSection('<args>')
vnoremap <silent> <Leader>a :Align<CR>

" Changelog configuration
let g:changelog_username='Aaron Patterson <tenderlove@ruby-lang.org>'
let g:changelog_dateformat='%c'
let g:airline_theme='light'
let g:airline#extensions#whitespace#enabled = 0

" netrw. Tree style / relative numbering
let g:netrw_bufsettings="noma nomod nonu nobl nowrap ro rnu"

nnoremap <leader>th :let @@=printf("0x%x", str2nr(expand("<cword>")))<cr>viwp
nnoremap <leader>ev :split $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>
" Git grep visually selected text
vnoremap <leader>gg y:Ggrep <c-r>"<cr>
vnoremap <leader>lm <esc>bimethod(:<esc>ea).source_location<esc>Ip <esc>

" puts the caller
nnoremap <leader>wtf oputs "#" * 90<c-m>puts caller<c-m>puts "#" * 90<esc>

nnoremap <leader>dts :put =strftime('%b %d, %Y')<cr>
nnoremap <leader>ne gg:put! =strftime('%b %d, %Y')<cr>i# <esc>o

let g:fugitive_git_command = 'git'
