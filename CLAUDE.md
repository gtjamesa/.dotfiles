# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Personal dotfiles (Linux/macOS, WSL2-aware). Pure shell — no build/lint/test. Validate by sourcing into a live shell (`source ~/.zshrc`).

## Architecture

- **Install-time** (`bootstrap` → `installscript`): runs once, installs packages and **symlinks** dotfiles into `$HOME`. Files are linked, not copied — repo edits take effect live.
- **Runtime** (`shell/loader`): sourced by `.zshrc`; sources every other shell file. A new shell file is inert until added to `loader` — except `shell/bin/*`, which are standalone executables already on `PATH`.
- `ai/` holds Claude Code global config; `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, and `~/.agents` are symlinks into it (see `ai-agents-link` in `shell/helpers/ai`).

## Notes

- Gitignored, machine-local — won't exist on a fresh checkout: `custom/*`, `shell/optional/*`.
- `installscript` flags: `--all`, `--[no-]composer`, `--[no-]docker`, `--[no-]getracker`, `--ask-optional`.
- Use `symlink_file` (in `shell/helpers/helpers`) for anything placed in `$HOME` — it backs up the existing target first.
