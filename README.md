# My personal dotfiles

This repository contains my personal dotfiles, inspired by [freekmurze/dotfiles](https://github.com/freekmurze/dotfiles). 

To install, simply run the following command. It will clone this repository into `~/.dotfiles`, and run the `bootstrap` script automatically.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/gtjamesa/.dotfiles/master/bootstrap)"
```

## Custom Configuration

This package provides a default configuration, but you can still provide custom customisations. The following files will be loaded automatically:

* `~/.dotfiles/custom/secrets.sh`
* `~/.dotfiles/custom/aliases.sh`
* `~/.dotfiles/custom/exports.sh`

Once you have created the files, you can reload your shell by using `source ~/.zshrc`

## Loader

The main entrypoint to be included in your `.zshrc` file is listed below. *This is added automatically by the installation script*.

```bash
# Custom ZSH dotfiles
[ -f ~/.dotfiles/shell/loader ] && source ~/.dotfiles/shell/loader
```
