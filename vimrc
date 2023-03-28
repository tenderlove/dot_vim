vim9script

call pathogen#infect()

set nocompatible

def SaveSession()
  var gitdir = finddir(".git")
  if gitdir == ""
    return
  endif

  var session = gitdir .. "/session.vim"
  execute 'mksession! ' .. session
enddef

def RestoreSession()
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
enddef

func AlignSection(regex) range
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
endfunc

func AlignLine(line, sep, maxpos, extra)
  let m = matchlist(a:line, '\(.\{-}\) \{-}\('.a:sep.'.*\)')
  if empty(m)
    return a:line
  endif
  let spaces = repeat(' ', a:maxpos - strlen(m[1]) + a:extra)
  return m[1] . spaces . m[2]
endfunc

filetype plugin indent on

# Put these in an autocmd group, so that we can delete them easily.
augroup vimrcEx
  au!

  # For all text files set 'textwidth' to 78 characters.
  autocmd FileType text setlocal textwidth=78

  # When editing a file, always jump to the last known cursor position.
  # Don't do it when the position is invalid or when inside an event handler
  # (happens when dropping a file on gvim).
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
  autocmd BufRead */ruby/*.c   setlocal cinoptions=:2,=2,l1

  autocmd VimLeave * call SaveSession()
augroup END

augroup filetype_ruby
  autocmd!
  autocmd FileType ruby nnoremap <buffer> <localleader>c I#<esc>
  # autocmd BufRead * :call MoveToProjectRoot(expand("%"))
  autocmd FileType ruby compiler minitest
augroup END

augroup filetype_vim
  autocmd!
  autocmd FileType vim setlocal foldmethod=marker
augroup END

# augroup cool
#   autocmd!
#   autocmd InsertEnter * :silent call job_start(["/Users/aaron/git/initial-v/firmware/ctrl.rb", "drive"])
#   autocmd InsertLeave * :silent call job_start(["/Users/aaron/git/initial-v/firmware/ctrl.rb", "neutral"])
#   autocmd BufWritePost * :silent call job_start(["/Users/aaron/git/initial-v/firmware/ctrl.rb", "park"])
# augroup END

augroup fugitive_ext
  autocmd!
  # Browse to the commit under my cursor
  autocmd FileType fugitiveblame nnoremap <buffer> <localleader>gb :execute ":Gbrowse " . expand("<cword>")<cr>

  # Browse to the PR for commit under my cursor
  autocmd FileType fugitiveblame nnoremap <buffer> <localleader>pr :call OpenPR(expand("<cword>"))<cr>
augroup END

if has("gui_running")
  set guioptions-=m
  set guioptions-=T
  # set guifont=Cascadia\ Mono\ Light:h12
  set guifont=Inconsolata:h14
endif

set backspace=indent,eol,start
set autoindent		# always set autoindenting on
set history=50		# keep 50 lines of command line history
set ruler		# show the cursor position all the time
set showcmd		# display incomplete commands
set incsearch		# do incremental searching
set relativenumber
set wildmode=list:full
set suffixesadd=.rb     # find ruby files
set path+=lib/**,test/**,app/** # look in lib and test

# Expand tabs, but set shiftwidth and softtabstop to 2.  This allows vim
# to mix tabs and spaces in Ruby C code, but it looks correct
set expandtab
set shiftwidth=2
set softtabstop=2

set kp=ri # Use ri for help

set exrc
set secure
set colorcolumn=81

set backupdir=/tmp

set tags+=.git/tags
set scrolloff=2
set ruler
set laststatus=2
set spell spelllang=en_us

# ===== Instead of backing up files, just reload the buffer when it changes. =====
# The buffer is an in-memory representation of a file, it's what you edit
set autoread                         # Auto-reload buffers when file changed on disk
set nobackup                         # Don't use backup files
set nowritebackup                    # Don't backup the file while editing
set noswapfile                       # Don't create swapfiles for new buffers
set updatecount=0                    # Don't try to write swapfiles after some number of updates
set backupskip=/tmp/*,/private/tmp/* # Let me edit crontab files

# Switch syntax highlighting on, when the terminal has colors
# Also switch on highlighting the last used search pattern.
if has("gui_running")
  syntax on
  set hlsearch
endif

if has("terminal")
  map <Leader>tt :terminal ++close<cr>
  tnoremap <Esc> <C-W>N
endif

# Add stdlib of environment's ruby to path
g:stdlib = system('ruby --disable-gems -rrbconfig -e"print RbConfig::CONFIG[\"rubylibdir\"]"')
&path = &path .. "," .. g:stdlib
g:ruby_path = &path

g:vim_markdown_folding_disabled = 1
g:html_font = ["Inconsolata", "Consolas"]

map <Leader>rt :!ctags --tag-relative=yes --extras=+f -Rf.git/tags --languages=-javascript,sql,TypeScript --exclude=.ext --exclude=include/ruby-\* --exclude=rb_mjit_header.h .<cr><cr>
map <Leader>ww :set lines=58 columns=115<cr>

g:ruby_space_errors = 1
g:c_space_errors = 1

command! -nargs=? -range Align <line1>,<line2>call AlignSection('<args>')
vnoremap <silent> <Leader>a :Align<CR>

# Changelog configuration
g:changelog_username = 'Aaron Patterson <tenderlove@ruby-lang.org>'
g:changelog_dateformat = '%c'
g:airline_theme = 'light'
g:airline#extensions#whitespace#enabled = 0

# netrw. Tree style / relative numbering
g:netrw_bufsettings = "noma nomod nonu nobl nowrap ro rnu"

nnoremap <leader>th :let @@=printf("0x%x", str2nr(expand("<cword>")))<cr>viwp
nnoremap <leader>ev :split $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>
# Git grep visually selected text
vnoremap <leader>gg y:Ggrep <c-r>"<cr>
vnoremap <leader>lm <esc>bimethod(:<esc>ea).source_location<esc>Ip <esc>

# puts the caller
nnoremap <leader>wtf oputs "#" * 90<c-m>puts caller<c-m>puts "#" * 90<esc>

nnoremap <leader>dts :put =strftime('%b %d, %Y')<cr>
nnoremap <leader>ne gg:put! =strftime('%b %d, %Y')<cr>i# <esc>o

g:fugitive_git_command = 'git'

# Tell Vim to find vim-lsp
packadd vim-lsp

# Use clangd if available
# if executable('clangd')
#   au User lsp_setup call lsp#register_server({
#         \ 'name': 'clangd',
#         \ 'cmd': {server_info->['clangd']},
#         \ 'allowlist': ['c'],
#         \ })
# endif

# Log stuff while doing development
g:lsp_log_verbose = 1
g:lsp_log_file = expand('~/git/lsp-stream/vim-lsp.log')

# Only start the LS if there's a special file

#if executable('rust-analyzer')
#    au User lsp_setup call lsp#register_server({
#        'name': 'rust-analyzer',
#        'cmd': "server_info->['rust-analyzer']",
#        'allowlist': ['rs', 'rust']
#        })
#endif

if filereadable(".livecode")
  au User lsp_setup
        \ call lsp#register_server({
        \      'name': 'cool-lsp',
        \      'cmd': ["nc", "localhost", "2000"],
        \      'allowlist': ['ruby', 'eruby'],
        \ })
endif

def On_lsp_buffer_enabled()
    setlocal omnifunc=lsp#complete
    setlocal signcolumn=yes
    setlocal tagfunc=lsp#tagfunc
    nmap <buffer> <leader>cc :LspCallHierarchyIncoming<cr>
    nmap <buffer> [g <plug>(lsp-previous-diagnostic)
    nmap <buffer> ]g <plug>(lsp-next-diagnostic)
    nmap <buffer> K <plug>(lsp-hover)
enddef

augroup lsp_install
    au!
    # call s:on_lsp_buffer_enabled only for languages that has the server registered.
    autocmd User lsp_buffer_enabled call On_lsp_buffer_enabled()
augroup END
