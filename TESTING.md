# Testing a fresh install

Quick smoke test after `bootstrap` on a clean VM (Fedora/dnf or Debian-Ubuntu/apt).
The goal is to confirm everything is **wired up and reachable** — not to test every
package. Open a new shell (`exec zsh`) and log out/in once first (default-shell and
`docker` group changes need it).

## Shell base
- [ ] Default shell is zsh; new terminals open in it (`echo $SHELL`)
- [ ] New shell loads with no errors — custom prompt/theme, autosuggestions + syntax highlighting show
- [ ] Distro detected — `echo $DOTFILES_OS $DOTFILES_DISTRO $DOTFILES_PKG`
- [ ] Dotfiles symlinked into `~/.dotfiles` — `ls -l ~/.zshrc ~/.tmux.conf`

## CLI tools
- [ ] **fzf** — `Ctrl-R` history search works (key-bindings sourced)
- [ ] **zoxide** — `z <dir>` jumps (init loaded)
- [ ] **tmux** — starts; `prefix + I` installs plugins
- [ ] **clipboard** — `echo hi | copy` pastes elsewhere

## Languages & version managers
- [ ] node — `node -v` (LTS via fnm)
- [ ] pnpm — `pnpm -v`; `pnpm add -g <pkg>` works (no "global bin directory is not in PATH")
- [ ] python — `python --version` → 3.10 (pyenv)
- [ ] asdf — `asdf current` lists tools with shims on PATH; install didn't hang on a git prompt
- [ ] asdf tools reachable — `kubectl version --client`, `helm version`, `k9s version`

## Docker (`--docker`)
- [ ] `docker run hello-world` works; user in docker group (`id -nG | grep docker`)
- [ ] `docker compose version` (plugin) **and** `docker-compose version` (shim) both run

## Optional
- [ ] Composer (`--composer`) — `composer --version`, `php -v`
- [ ] GE Tracker (`--getracker`) — aliases present
- [ ] WSL — `xdg-open` opens the Windows browser (wslu)

## Desktop (`install/desktop/install` — graphical install only)
- [ ] Installer completes without error
- [ ] Fedora — RPM Fusion enabled (`dnf repolist | grep rpmfusion`) and flathub added (`flatpak remotes`)
- [ ] `/opt/apps` set up and user-writable; JetBrains Toolbox + Navicat AppImage present
- [ ] Native apps installed — spot-check one launches (1Password / TablePlus / AnyDesk)
- [ ] Claude Code — `claude --version` (native install in `~/.local/bin`)
- [ ] Flatpaks installed — `flatpak list` spot-check (Spotify / Obsidian / Postman)
- [ ] Shell modules enabled — `dotmod list` shows `work media desktop-aliases audio installers`
