# Obsidian-flavored markdown (OFM) reference

Obsidian renders CommonMark + GitHub-Flavored Markdown + LaTeX, **plus** the Obsidian-specific extensions below. Assume ordinary GFM (headings, bold/italic, lists, fenced code, tables) works — this file covers only the non-standard parts and their gotchas.

## Internal links (wikilinks)

```
[[Note Name]]                     link to a note
[[Folder/Note Name]]              path form — use when the basename isn't unique vault-wide
[[Note Name#Heading]]             link to a heading
[[Note Name#Heading#Subheading]]  drill into a nested heading
[[Note Name#^block-id]]           link to a specific block
[[Note Name|Display text]]        aliased link (pipe = shown text)
[[#Heading]]                      heading in the same note
[[#^block-id]]                    block in the same note
```

Escape to show literally: `\[[Not a link]]`.

## Embeds / transclusion

Same targets as links, prefixed with `!` — renders the target inline:

```
![[Note Name]]            embed a whole note
![[Note Name#Heading]]    embed a section
![[Note Name#^block-id]]  embed a single block
![[image.png]]            embed an image / PDF / audio / video
```

Resize an embedded image (width×height, or width-only keeps aspect ratio). Same `|size` trick works on external markdown images:

```
![[image.png|640x480]]
![[image.png|100]]
![Alt text|640x480](https://example.com/i.jpg)
![Alt text|100](https://example.com/i.jpg)
```

## Block references

Anchor any block (paragraph, list item, table…) by appending ` ^block-id` at its end (id = letters, numbers, dashes):

```
This is the sentence future-me will want to find. ^key-point
```

Then link or embed it: `[[Note#^key-point]]` / `![[Note#^key-point]]`.

## Callouts

```
> [!note] Optional custom title
> Body content — supports **markdown**, [[links]], and lists.
```

- **Title-only:** `> [!tip] Just a title` (omit the body lines).
- **Foldable:** `> [!faq]- Collapsed by default` — `-` starts collapsed, `+` starts expanded (`> [!info]+ …`).
- **Nested:** indent an inner callout with `> >`.
- Type is case-insensitive. An unknown type falls back to the `note` style but keeps your text as the title.

| Type | Aliases |
|------|---------|
| `note` | — |
| `abstract` | `summary`, `tldr` |
| `info` | — |
| `todo` | — |
| `tip` | `hint`, `important` |
| `success` | `check`, `done` |
| `question` | `help`, `faq` |
| `warning` | `caution`, `attention` |
| `failure` | `fail`, `missing` |
| `danger` | `error` |
| `bug` | — |
| `example` | — |
| `quote` | `cite` |

## Comments

Hidden in Reading view (and from Obsidian Publish/export):

```
Inline %%comment%% mid-sentence.
%%
Block comment
across multiple lines.
%%
```

## Highlight & strikethrough

```
==highlighted==     ~~struck through~~
```

## Tags

`#tag`, nested as `#parent/child`. Must contain at least one non-numeric character.

## Footnotes

```
A claim that needs a source.[^1]

[^1]: The footnote text. Indent continuation lines by 2 spaces.
[^named]: Named refs still render as sequential numbers.
```

Inline footnote (Reading view only): `Some text.^[the footnote inline]`.

## Tables — the pipe gotcha

Column alignment via colons in the divider row:

```
| Left | Center | Right |
| :--- | :----: | ----: |
```

A literal `|` inside a cell — e.g. an **aliased link** or a **sized image** — must be escaped as `\|`, otherwise it's read as a column break:

```
| [[Note\|alias]] | ![[img.png\|100]] |
```

## Task lists

`- [ ]` incomplete, `- [x]` done. Any character between the brackets is a custom status and renders as-is: `- [?]`, `- [/]`, `- [-]`.

## Math (LaTeX / MathJax)

Inline `$e^{i\pi} = -1$`; block:

```
$$\begin{vmatrix}a & b\\ c & d\end{vmatrix} = ad - bc$$
```

## Mermaid diagrams

Fenced block tagged `mermaid`. To make a node a wikilink, add the `internal-link` class:

````
```mermaid
graph TD
  A --> B
  class A,B internal-link
```
````

## Gotchas

- **Markdown inside HTML block elements is not rendered** — `**bold**` inside a `<div>` shows literally. Avoid wrapping content in raw HTML.
- **Wikilinks resolve by shortest unique note name** across the whole vault (not just the folder). Use the `Folder/Note` path form when a basename repeats.
- **Heading/block links use the literal target text.** Rename a heading and every inbound `[[…#Heading]]` breaks — repoint them.
- **`table-of-contents` block** (this vault): a fenced ` ```table-of-contents``` ` block auto-fills from the `automatic-table-of-contents` community plugin. Renders only in Obsidian, not on GitHub/other viewers.
