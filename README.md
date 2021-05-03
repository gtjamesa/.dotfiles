# My personal dotfiles

This repository contains my personal dotfiles, inspired by [freekmurze/dotfiles](https://github.com/freekmurze/dotfiles). 

To install, clone this repository into `~/.dotfiles`, and run the `bootstrap` script.

```bash
git clone git@github.com:gtjamesa/.dotfiles.git ~/.dotfiles && ~/.dotfiles/bootstrap
```

To load the files, add the following to `.zshrc`:

```bash
# Custom ZSH dotfiles
[ -f ~/.dotfiles/shell/loader ] && source ~/.dotfiles/shell/loader
```
