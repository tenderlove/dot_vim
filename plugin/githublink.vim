function! GithubLink() range
  let l:giturl = system('git config remote.origin.url')
  let l:prefix = substitute(system('git rev-parse --show-prefix'), "\n", '', '')
  let l:repo = get(split(matchstr(l:giturl, '\w*\/\w*\.git'), '\.'), 0)
  let l:url = 'http://github.com/' . l:repo
  let l:branch = get(split(substitute(system('git symbolic-ref HEAD'), "\n", '', '') , '/'), -1)
  let l:filename = l:prefix . @%

  let l:full = join([l:url, 'blob', l:branch, l:filename], '/')

  let @* = l:full . '#L' . a:firstline . '-' . a:lastline
endfunction

vnoremap <silent> <Leader>gh :call GithubLink()<CR>
