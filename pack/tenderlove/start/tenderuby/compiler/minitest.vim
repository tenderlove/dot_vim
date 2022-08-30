if exists("current_compiler")
  finish
endif
let current_compiler = "minitest"

CompilerSet makeprg=gel\ exec\ rake\ test
let s:cpo_save = &cpo
set cpo-=C

CompilerSet errorformat=\%E\ %#%n)\ Error:,
			\%C%o#%.%#:,
			\%C%*\\s%f:%l:%.%#,
			\%Z\ %#,
			\%C%m,

let &cpo = s:cpo_save
unlet s:cpo_save

