# My personal dotfiles

This repository contains my personal dotfiles, inspired by [freekmurze/dotfiles](https://github.com/freekmurze/dotfiles). 

The only requirements are that `sudo` and `curl` are installed, the rest will be installed and configured automatically.

To install, simply run the following command. It will clone this repository into `~/.dotfiles`, and run the `bootstrap` script automatically.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/gtjamesa/.dotfiles/main/bootstrap)"
```

## Installation Options

The installation script supports the following options:

```bash
usage: bootstrap [OPTIONS]
    --help               Show this message
    --all                Install all additional programs and aliases
    --[no-]composer      Enable/disable Composer installation (and supporting global packages)
    --[no-]docker        Enable/disable Docker configuration
    --[no-]getracker     Enable/disable GE Tracker specific aliases
```

To use the options, you must first download the bootstrap file. 

```bash
curl -fsSL https://raw.githubusercontent.com/gtjamesa/.dotfiles/main/bootstrap > dotfiles_bootstrap
bash dotfiles_bootstrap --no-docker --composer
rm -f dotfiles_bootstrap
```

## Custom Configuration

This package provides a default configuration, but you can still provide custom customisations. Any files `.sh` files inside the `~/.dotfiles/custom/` directory will be loaded automatically.

Once you have created the files, you can reload your shell by using `source ~/.zshrc`

## Loader

The main entrypoint to be included in your `.zshrc` file is listed below. *This is added automatically by the installation script*.

```bash
# Custom ZSH dotfiles
[ -f ~/.dotfiles/shell/loader ] && source ~/.dotfiles/shell/loader
```
