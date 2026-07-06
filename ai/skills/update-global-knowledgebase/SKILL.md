---
name: update-global-knowledgebase
description: Capture durable knowledge into James's Obsidian Knowledgebase as focused, cross-linked, house-style reference notes. Use when the user says "update global knowledgebase", or asks to save/record what was just figured out into his knowledgebase notes.
---

# Update global Knowledgebase

Capture what was just figured out into James's Obsidian Knowledgebase — a personal reference vault he reads on desktop and **Obsidian mobile (Android)**. Write every note for **future-James**: terse, skimmable, assumes his setup and expertise.

## Steps

### 1. Resolve the Knowledgebase path
- If `~/.obsidian-notes` exists, read it — its trimmed contents are the Notes vault path. Otherwise use `~/Documents/Notes`.
- Append `/Knowledgebase`, expand `~`, and confirm the directory exists before writing.

### 2. Distill what to capture
Pull the durable, reference-worthy facts from the conversation (or what James dictates): commands that worked, final configs, gotchas, decisions and their *why*. Drop dead ends, conversational scaffolding, and anything trivially reproducible. If it's unclear what he wants saved, ask.

**Done when:** you have a concrete list of facts to record.

### 3. Place it in focused notes
James prefers **small, single-topic notes cross-linked**, not monoliths. Browse the existing tree (folders + note names) first, then:
- **Extend** an existing note only when the fact belongs to that exact topic.
- **Create** a new focused note when it's a distinct topic — even if a broad note already touches it. Name it for the topic; drop it in the matching folder (`Linux`, `Docker`, `Kubernetes`, …). New folder only when nothing fits.
- **Split** a note that the new material reveals has grown into two topics: extract each into its own note and link them.
- **Link** every new note to its neighbours with `[[wikilinks]]` so nothing is orphaned.

**Done when:** you have the exact file path(s), new-vs-existing for each, and which notes to link.

### 4. Write in house style
Follow **House style** below. Update stale facts in place — one source of truth per fact, no duplicated sections.

### 5. Report
List the file path(s) and section names you touched so James can review them on desktop or mobile.

## House style

- **For future-James.** Terse, skimmable, imperative. Assume his environment and skill; no tutorial padding.
- **Obsidian-flavored markdown.** These render in Obsidian (desktop + Android), not plain markdown — reach for wikilinks, embeds, callouts, block refs, `==highlight==`, `%%comments%%`, tags. For exact syntax and gotchas beyond the basics below, see [references/obsidian-flavored-markdown.md](references/obsidian-flavored-markdown.md).
- **Headings** — structure with `##`/`###`. On any multi-section note, put this at the very top (the *Automatic Table of Contents* plugin fills it in); skip it on short single-topic notes:
  ````
  ```table-of-contents
  ```
  ````
- **Callouts** for anything that must stand out: `> [!TIP]`, `> [!WARNING]`, `> [!NOTE]`. Date-stamp time-sensitive facts ("as of Jan 2026").
- **Links** — cross-link related notes with `[[Note Name]]` and headings with `[[Note Name#Heading]]`; link companion files with relative `[label](file.sh)` links.
- **Code** in fenced blocks with a language tag (`bash`, `yaml`, `ini`, `dockerfile`, …). Comment non-obvious commands inline.
- **Mobile-friendly** — he reads on Android. Keep code lines short; prefer bullet lists over wide tables.
