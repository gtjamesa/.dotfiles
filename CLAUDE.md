# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Personal dotfiles (Linux/macOS, WSL2-aware). Pure shell — no build/lint/test. Validate by sourcing into a live shell (`source ~/.zshrc`).

## Architecture

- **Install-time** (`bootstrap` → `installscript`): runs once, installs packages and **symlinks** dotfiles into `$HOME`. Files are linked, not copied — repo edits take effect live.
- **Runtime** (`shell/loader`): sourced by `.zshrc`; sources every other shell file. A new shell file is inert until added to `loader` — except `shell/bin/*`, which are standalone executables already on `PATH`.
- `ai/` is Claude Code global config — `CLAUDE.md`, `settings.json` and `.agents/` are symlinked into `~/.claude` / `~/.agents` by `ai-sync` (`shell/helpers/ai`). Run `ai-sync` to set up or repair the layout on any machine.
- Skills: authored ones live in `ai/skills/<name>/` (tracked, symlinked into `~/.claude/skills`); `npx skills` externals are copied into `~/.claude/skills` (untracked) and rebuilt from `ai/.agents/.skill-lock.json` by `ai-sync`. `ai-skill-new <name>` scaffolds an authored skill.

## Notes

- Gitignored, machine-local — won't exist on a fresh checkout: `custom/*`, `shell/optional/*`, `ai/.agents/skills/`.
- `installscript` flags: `--all`, `--[no-]composer`, `--[no-]docker`, `--[no-]getracker`, `--ask-optional`.
- Use `symlink_file` (in `shell/helpers/helpers`) for anything placed in `$HOME` — it backs up the existing target first.
