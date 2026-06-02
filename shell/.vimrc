color desert

" fzf vim integration — path varies by install method (distro pkg vs brew vs git)
for s:p in ['/usr/share/vim/vimfiles', '/opt/homebrew/opt/fzf', '/usr/local/opt/fzf', expand('~/.fzf')]
  if isdirectory(s:p)
    execute 'set rtp+=' . s:p
  endif
endfor

" Disable Ctrl-Left and Ctrl-Right deleting text
" You can use `od -a` in the terminal to capture the key sequences of characters, as this may differ between OS
" <ESC> is represented by ^[
" https://unix.stackexchange.com/questions/1709/how-to-fix-ctrl-arrows-in-vim
map <ESC>[1;5D <C-Left>
map <ESC>[1;5C <C-Right>
map! <ESC>[1;5D <C-Left>
map! <ESC>[1;5C <C-Right>
