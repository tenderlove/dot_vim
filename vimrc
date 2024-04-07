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

def MakeIVSet(name: string, max_width: number): string
  var padding = repeat(" ", (max_width - strlen(name)) + 1)
  return "@" .. name .. padding .. "= " .. name
enddef

def MakeIVS(text: string): void
  var iv_names = map(split(text, ","), (_, item) => trim(item) )
  var max_width = max(map(deepcopy(iv_names), (_, item) => strlen(item) ))
  var lines = map(iv_names, (_, item) => MakeIVSet(item, max_width) )

  call append(line("."), lines)
  var cmd = "normal! j=" .. (len(iv_names) - 1) .. "j"
  execute cmd
enddef

def MakeIVSVisual(): void
  var at = @@
  var cursor = getpos(".")
  execute "normal! `<v`>y"
  call MakeIVS(@@)
  call setpos(".", cursor)
  let @@ = at
enddef

def MakeIVSLine(line: string): void
  var match = matchlist(line, 'def initialize[ (]\([^)]*\))\?$')
  if len(match) > 0
    call MakeIVS(get(match, 1))
  else
    echo "nope"
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
  autocmd Filetype cpp setlocal sw=4
  autocmd Filetype ruby setlocal sw=2 softtabstop=2 kp=ri suffixesadd=.rb
  autocmd Filetype gitcommit setlocal spell textwidth=72
  autocmd Filetype c setlocal sw=4
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
    function LSPBalloon()
        call lsp#internal#document_hover#under_cursor#do({ 'ui': 'balloon' })
        return ''
    endfunction
  autocmd FileType vim setlocal foldmethod=marker
augroup END

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
  # set guifont=Inconsolata:h14
  # set guifont=MonaspaceNeon-Light:h12
  set guifont=-monospace-:h12
endif

set backspace=indent,eol,start
set autoindent		# always set autoindenting on
set history=50		# keep 50 lines of command line history
set ruler		# show the cursor position all the time
set showcmd		# display incomplete commands
set incsearch		# do incremental searching
set relativenumber
set wildmode=list:full
set path+=lib/**,test/**,app/** # look in lib and test

# Expand tabs, but set shiftwidth and softtabstop to 2.  This allows vim
# to mix tabs and spaces in Ruby C code, but it looks correct
set expandtab

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

syntax on
set hlsearch

if has("terminal")
  nnoremap <Leader>tt :bo terminal ++close ++norestore ++rows=20<cr>
  tnoremap <Esc> <C-W>p
endif

# Add stdlib of environment's ruby to path
g:stdlib = system('ruby --disable-gems -rrbconfig -e"print RbConfig::CONFIG[\"rubylibdir\"]"')
&path = &path .. "," .. g:stdlib
g:ruby_path = &path

#g:lsp_diagnostics_virtual_text_enabled = 0
g:vim_markdown_folding_disabled = 1
g:rtf_font = "Inconsolata"

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

# Convert number below cursor to hex
nnoremap <leader>th :let @@=printf("0x%x", str2nr(expand("<cword>")))<cr>viwp

# Edit vimrc
nnoremap <leader>ev :split $MYVIMRC<cr>

# load vimrc
nnoremap <leader>sv :source $MYVIMRC<cr>

# Git grep visually selected text
vnoremap <leader>gg y:Ggrep <c-r>"<cr>
vnoremap <leader>lm <esc>bimethod(:<esc>ea).source_location<esc>Ip <esc>

# puts the caller
nnoremap <leader>wtf oputs "#" * 90<c-m>puts caller<c-m>puts "#" * 90<esc>

nnoremap <leader>dts :put =strftime('%b %d, %Y')<cr>
nnoremap <leader>ne gg:put! =strftime('%b %d, %Y')<cr>i# <esc>o

g:fugitive_git_command = 'git'

# First install vim-lsp:
#
#   $ git clone git@github.com:prabirshrestha/vim-lsp.git $HOME/.vim/pack/github/opt/vim-lsp
#
# Tell Vim to find vim-lsp
packadd vim-lsp

# Make ruby.vim indent the way standard wants them
g:ruby_indent_assignment_style = 'variable'
g:ruby_indent_hanging_elements = 0

# Log stuff while doing development
g:lsp_log_verbose = 1
g:lsp_log_file = expand('/tmp/vim-lsp.log')

if executable('./ls.rb')
  au User lsp_setup call lsp#register_server({
        \ 'name': 'ls.rb',
        \ 'cmd': ['./ls.rb'],
        \ 'allowlist': ['ruby'],
        \ })
endif

# Use standard if available
# if executable('standardrb')
#   au User lsp_setup call lsp#register_server({
#         \ 'name': 'standardrb',
#         \ 'cmd': ['standardrb', '--lsp'],
#         \ 'allowlist': ['ruby'],
#         \ })
# endif

# Use clangd if available
# if executable('clangd')
#   au User lsp_setup call lsp#register_server({
#         \ 'name': 'clangd',
#         \ 'cmd': ['clangd'],
#         \ 'allowlist': ['c'],
#         \ })
# endif
#
# au User lsp_setup call lsp#register_server({
#       \ 'name': 'xcrun sourcekit-lsp',
#       \ 'cmd': ['xcrun sourcekit-lsp'],
#       \ 'allowlist': ['c'],
#       \ })

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
        \ lsp#register_server({
        \      'name': 'cool-lsp',
        \      'cmd': ["nc", "localhost", "2000"],
        \      'allowlist': ['ruby', 'eruby'],
        \ })
endif

if filereadable(".ls-dev")
  au User lsp_setup
        \ lsp#register_server({
        \      'name': 'LSP Test',
        \      'cmd': ["/Users/aaron/git/lsp-stream/syntax-check.rb"],
        \      'allowlist': ['ruby'],
        \ })
endif

def On_lsp_buffer_enabled()
    setlocal omnifunc=lsp#complete
    setlocal signcolumn=yes
    setlocal tagfunc=lsp#tagfunc
    setlocal bexpr=LSPBalloon()
    setlocal ballooneval balloonevalterm
    nmap <buffer> <leader>cc :LspCallHierarchyIncoming<cr>
    nmap <buffer> [g <plug>(lsp-previous-diagnostic)
    nmap <buffer> ]g <plug>(lsp-next-diagnostic)
    nmap <buffer> K <plug>(lsp-hover)
enddef

def g:CleverTab(): string
  if strpart( getline('.'), 0, col('.') - 1 ) =~ '^\s*$'
    return "\<Tab>"
  else
    return "\<C-N>"
  endif
enddef

inoremap <Tab> <C-R>=CleverTab()<CR>
set completeopt=longest,menuone

augroup lsp_install
    au!
    # call s:on_lsp_buffer_enabled only for languages that has the server registered.
    autocmd User lsp_buffer_enabled call On_lsp_buffer_enabled()
augroup END
