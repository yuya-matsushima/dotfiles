augroup alias
  autocmd!
  autocmd BufRead,BufNewFile *.md,*.md.erb setlocal filetype=markdown
  autocmd BufRead,BufNewFile *.scala.html setlocal filetype=scala
  autocmd BufRead,BufNewFile *.ts setlocal filetype=typescript
  autocmd BufRead,BufNewFile Vagrantfile,Guardfile setlocal filetype=ruby
  autocmd BufRead,BufNewFile *.envrc setlocal filetype=sh
  autocmd FileType sql setlocal ft=mysql
  autocmd FileType scss.css setlocal ft=scss
augroup END

