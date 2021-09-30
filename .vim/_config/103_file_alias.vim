augroup alias
  autocmd!
  autocmd BufRead,BufNewFile *.md,*.md.erb setlocal filetype=markdown
  autocmd BufRead,BufNewFile *.scala.html setlocal filetype=scala
  autocmd FileType js setlocal ft=javascript
  autocmd BufRead,BufNewFile *.ts set filetype=typescript
  autocmd FileType rb,watchr,vagrantfile,Guardfile setlocal ft=ruby
  autocmd FileType smarty,tpl,ciunit,ctp setlocal ft=php
  autocmd FileType sql setlocal ft=mysql
  autocmd FileTYpe scss.css setlocal ft=scss
  autocmd FileType .envrc setlocal ft=sh
augroup END

