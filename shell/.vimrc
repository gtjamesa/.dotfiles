color desert
set rtp+=/home/linuxbrew/.linuxbrew/opt/fzf

" Disable Ctrl-Left and Ctrl-Right deleting text
" You can use `od -a` in the terminal to capture the key sequences of characters, as this may differ between OS
" <ESC> is represented by ^[
" https://unix.stackexchange.com/questions/1709/how-to-fix-ctrl-arrows-in-vim
map <ESC>[1;5D <C-Left>
map <ESC>[1;5C <C-Right>
map! <ESC>[1;5D <C-Left>
map! <ESC>[1;5C <C-Right>
