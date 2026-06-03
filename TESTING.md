# Testing a fresh install

Smoke-test checklist after running `bootstrap` on a clean VM (Fedora/dnf or
Debian-Ubuntu/apt). Run `--all` to exercise Docker/Composer too. Open a **new
shell** (or `exec zsh`) before checking — and log out/in once so the `docker`
group and default-shell change take effect.

## Shell base
- [ ] Default shell is zsh — `echo $SHELL` ends in `zsh`; new terminals open in zsh
- [ ] New shell loads with **no errors** and the custom theme/prompt shows
- [ ] Autosuggestions (greyed text) + syntax highlighting (coloured commands) work
- [ ] Distro detected — `echo $DOTFILES_OS $DOTFILES_DISTRO $DOTFILES_PKG` (e.g. `linux fedora dnf`)
- [ ] Dotfiles symlinked — `ls -l ~/.zshrc ~/.vimrc ~/.tmux.conf` point into `~/.dotfiles`

## Core CLI tools
- [ ] **fzf** — `Ctrl-R` opens fuzzy history search; `Ctrl-T` fuzzy file picker
- [ ] **zoxide** — `cd` around a few dirs, then `z <partial>` jumps correctly (`command -v zoxide` set)
- [ ] **tmux** — `tmux` starts; `prefix + I` fetches plugins (tpm) without error
- [ ] **clipboard** — `echo hi | copy` then paste elsewhere (xclip on X11 / wl-clipboard on Wayland)
- [ ] `git`, `vim`, `jq`, `zip`/`unzip`, `wget`, `curl` all present

## Languages & version managers
- [ ] **node (fnm)** — `node -v` (LTS), `fnm current` set as default
- [ ] **pnpm** — `pnpm -v`; `pnpm add -g <pkg>` succeeds with **no** "global bin directory is not in PATH" error; yarn + release-it present
- [ ] **python (pyenv)** — `python --version` → 3.10.x; `pyenv global` shows 3.10
- [ ] **asdf** — `asdf --version`; `asdf current` lists every tool with no "not installed" rows

## asdf tools (from `shell/.tool-versions`)
- [ ] Plugin install finished **without hanging** on a github username prompt
- [ ] `kubectl version --client`, `helm version`, `k9s version` all run
- [ ] Spot-check a couple more: `kustomize version`, `eksctl version`

## Docker (`--docker`)
- [ ] `docker run hello-world` works (after relog for group membership)
- [ ] `docker compose version` — the V2 plugin
- [ ] `docker-compose version` — the back-compat shim (`/usr/local/bin/docker-compose` → `~/.dotfiles/install/docker-compose`)
- [ ] `id -nG | grep docker` — user is in the docker group

## Optional
- [ ] **Composer** (`--composer`) — `composer --version`, `php -v` (8.3)
- [ ] **GE Tracker** (`--getracker`) — getracker aliases available
- [ ] **WSL only** — `xdg-open https://example.com` opens the Windows browser (wslu)

## Desktop (run separately)
- [ ] `~/.dotfiles/install/desktop/install` — RPM Fusion/codecs, flathub, apps install cleanly
