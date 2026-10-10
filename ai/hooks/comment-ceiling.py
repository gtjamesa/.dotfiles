#!/usr/bin/env python3
# PreToolUse hook (Edit|Write|MultiEdit): blocks a comment block over the ceiling in
# ~/.claude/CLAUDE.md "Code". A line counts once per WIDTH chars, so wide lines can't
# dodge it. Blocks already in the old text at the same length or longer pass.
import json
import math
import os
import re
import sys

CEILING = 5
WIDTH = 120

HASH = {'py', 'sh', 'bash', 'zsh', 'rb', 'yaml', 'yml', 'toml', 'tf', 'conf', 'cfg', 'mk', 'r', 'pl', 'ps1', 'nix'}
SLASH = {'js', 'jsx', 'ts', 'tsx', 'mjs', 'cjs', 'mts', 'cts', 'java', 'kt', 'kts', 'go', 'rs', 'c', 'h', 'cc',
         'cpp', 'hpp', 'cs', 'swift', 'scala', 'dart', 'groovy', 'gradle', 'vue', 'css', 'scss', 'less'}
DASH = {'sql', 'lua', 'hs'}
NAMES = {'Makefile': 'hash', 'Dockerfile': 'hash', 'Containerfile': 'hash'}
SKIP_DIRS = ('/node_modules/', '/vendor/', '/dist/', '/.git/')

DELIMITER = re.compile(r'^(/\*\*?|\*/|\*|#|//|--)$')
DOCSTRING = re.compile(r'^[rRuUbB]?("""|\'\'\')')


def style(path):
    name = os.path.basename(path)
    if name in NAMES:
        return NAMES[name]
    ext = name.rsplit('.', 1)[-1].lower() if '.' in name else ''
    if ext == 'php':
        return 'php'
    if ext == 'py':
        return 'py'
    if ext in HASH:
        return 'hash'
    if ext in SLASH:
        return 'slash'
    if ext in DASH:
        return 'dash'
    return None


def is_comment(s, kind):
    if kind in ('hash', 'py', 'php') and s.startswith('#') and not s.startswith(('#!', '#[')):
        return True
    if kind in ('slash', 'php') and s.startswith(('//', '/*', '*')):
        return True
    return kind == 'dash' and s.startswith('--')


def weight(s):
    if DELIMITER.match(s):
        return 0
    if '://' in s:
        return 1
    return max(1, math.ceil(len(s) / WIDTH))


def docstring(lines, i):
    """Return (end index, content lines) if lines[i] opens a bare triple-quoted string."""
    s = lines[i].strip()
    m = DOCSTRING.match(s)
    if not m:
        return None
    prev = next((lines[j].strip() for j in range(i - 1, -1, -1) if lines[j].strip()), '')
    if prev and not prev.endswith(':'):
        return None
    quote = m.group(1)
    body = s[m.end():]
    if quote in body:
        return i, [s]
    content = [body] if body else []
    for j in range(i + 1, len(lines)):
        t = lines[j].strip()
        if quote in t:
            head = t[:t.index(quote)]
            return j, content + ([head] if head else [])
        content.append(t)
    return len(lines) - 1, content


def blocks(text, kind):
    """Comment blocks as (weighted length, content lines)."""
    lines = text.splitlines()
    out, run = [], []

    def flush():
        if run:
            out.append((sum(weight(s) for s in run), [s for s in run if not DELIMITER.match(s)]))
            run.clear()

    i = 0
    while i < len(lines):
        s = lines[i].strip()
        if kind == 'py' and (ds := docstring(lines, i)):
            flush()
            end, content = ds
            out.append((sum(weight(c) for c in content if c), content))
            i = end + 1
            continue
        if is_comment(s, kind):
            run.append(s)
        else:
            flush()
        i += 1
    flush()
    return out


def violations(old, new, kind):
    before = blocks(old, kind)
    found = []
    for n, content in blocks(new, kind):
        if n <= CEILING:
            continue
        overlap = [m for m, c in before if set(c) & set(content)]
        if overlap and max(overlap) >= n:
            continue
        found.append((n, content[0] if content else ''))
    return found


def pairs(tool, inp, path):
    if tool == 'Write':
        try:
            with open(path, encoding='utf-8', errors='replace') as f:
                old = f.read()
        except OSError:
            old = ''
        return [(old, inp.get('content', ''))]
    if tool == 'MultiEdit':
        return [(e.get('old_string', ''), e.get('new_string', '')) for e in inp.get('edits', [])]
    return [(inp.get('old_string', ''), inp.get('new_string', ''))]


def main():
    event = json.load(sys.stdin)
    tool, inp = event.get('tool_name'), event.get('tool_input', {})
    path = inp.get('file_path', '')
    kind = style(path)
    if not kind or any(d in path for d in SKIP_DIRS):
        return 0
    found = [v for old, new in pairs(tool, inp, path) for v in violations(old, new, kind)]
    if not found:
        return 0
    lines = '\n'.join(f'  {n} lines: {first[:100]}' for n, first in found)
    print(
        f'comment-ceiling: {path} adds or grows a comment past {CEILING} lines (one line is the default; '
        f'a line counts once per {WIDTH} chars):\n{lines}\n'
        'Keep the state the code needs and the issue/PR id. The decision process belongs in the issue/PR.\n'
        'Moving existing code unchanged between files: use git mv or cp.',
        file=sys.stderr,
    )
    return 2


if __name__ == '__main__':
    sys.exit(main())
