---
name: runelite
description: RuneLite plugin development for Old School RuneScape (OSRS). Use when building, debugging or reviewing a RuneLite plugin (a repo with `runelite-plugin.properties`), or submitting or updating one on the Plugin Hub.
---

# RuneLite plugins

A plugin is a Guice-injected `Plugin` subclass. It reacts to events on the event bus and draws through overlays, infoboxes and side panels. Hub plugins ship as **source**: RuneLite's packager builds them from a pinned commit, and a human reviews every line against the **hub rules**. Two questions decide whether code is right: which **thread** it runs on, and whether the hub will accept it.

## Hard rule: reviewable code

A maintainer reads every line before it reaches users. Oversized AI-written submissions that no human has read are now the hub's biggest review cost ([OSRS Wiki and RuneLite are increasingly under strain from low-effort AI development](https://oldschool.runescape.wiki/w/User:Cook_Me_Plox/OSRS_Wiki_and_RuneLite_are_increasingly_under_strain_from_low-effort_AI_development)). So every change is **reviewable**: well structured, minimal, and readable in one pass by someone new to the plugin. This rule outranks generality, future-proofing and completeness.

- **Minimal.** Build the smallest design that does what was asked. The default shape is the plugin class, its config and an overlay ([`references/structure.md`](references/structure.md)). A new class earns its place by holding its own state or being used from two places. An interface, base class, factory, manager or generic helper earns its place by having two concrete uses today.
- **In scope.** Build the request and nothing beside it. Config items and features come from the user; propose extras rather than building them. Handle the states the game actually produces (a closed interface, an off-screen projection), not hypothetical ones.
- **Plain.** Names use game terms (`trackedNpcs`, `onBossDeath`). Methods read top to bottom and are short enough to see whole. Use ordinary loops and conditionals over clever streams, generics or indirection. Comments state only what the code can't: a game quirk, an ordering constraint, the in-game meaning of a value.
- **Familiar.** Match the repo's existing code and the core precedent, so the reviewer recognises every pattern.

## Hard rule: Jagex account credentials

Under no circumstances read, print, copy or commit the contents of `~/.runelite/credentials.properties`. To learn whether it exists, test for the file (`test -f`) without opening it. Logs in `~/.runelite/logs/` are fine to read.

## Before writing code

1. **Read the hub rules.** The plugin's `AGENTS.md` is the reviewers' guidance written for agents. It covers threading, HTTP, file IO, config, packaging and testing, and lists the *Plugin Rules & Restrictions*. Repos generated before the template shipped it have none; in that case read https://github.com/runelite/example-plugin/raw/refs/heads/master/AGENTS.md in full. Check the requested feature against every restriction before designing it. A forbidden feature is rejected however well it is built: boss-mechanic prediction, menu entries that send actions, injected input. **Done when** the feature clears each restriction, or you have told the user which rule it hits.
2. **Find the precedent.** A core plugin almost always does something close: read it before inventing an approach. Core plugins are the reference for correct API usage. Hub plugins are a weaker second; their API usage "is not always correct". Core plugin classes are on the classpath but are not API and change without notice, so copy the logic rather than importing it.
3. **Check the build.** Code compiles to **Java 11**, so no records, switch expressions, text blocks or `instanceof` patterns. Without a `run` task, *Verifying* can't offer `./gradlew run`: add one, as a separate commit. Further modernising is optional and also separate: [`references/setup.md`](references/setup.md).

## Looking things up

Every id, name and mechanic in code comes from one of these sources. Recalled game knowledge and wiki prose are often wrong; when no source confirms a fact, ask the user to check it in game.

- **Signatures:** API javadoc https://static.runelite.net/runelite-api/apidocs/ and client javadoc https://static.runelite.net/runelite-client/apidocs/.
- **Core source** (`runelite/runelite`):
  - Precedent lives in `runelite-client/src/main/java/net/runelite/client/plugins/`.
  - Game ids live in `runelite-api/src/main/java/net/runelite/api/gameval/`. They are excluded from the javadoc, so the source is the only place to look them up.
  - If `~/projects/runelite/runelite` exists, it is a fork with upstream as remote `upstream`. Run `git fetch upstream`, then read `upstream/master` (`git show upstream/master:<path>`, `git grep <pat> upstream/master`), since the checkout may be stale. Otherwise use `gh api` or raw.githubusercontent.com.
  - `~/projects/runelite/` also holds the user's own plugins and clones of `plugin-hub`, `cs2-scripts` and `sailing`.
- **Ids by in-game name:** Chisel https://chisel.weirdgloop.org/moid/. The OSRS Wiki shows ids in infoboxes once *Preferences › Gadgets › advanced data* is enabled. The cache viewer is https://abextm.github.io/cache2/#/viewer.
- **Coordinates and regions:** https://mejrs.github.io/osrs.
- **In game:** the dev tools ([`references/devtools.md`](references/devtools.md)).

## Threads

All `Client` state belongs to the **client thread**, the game loop. Read and write it only there.

- **Already on it:** event-bus handlers for game events (`GameTick`, spawns, `VarbitChanged`, `ChatMessage`, `MenuEntryAdded`, …), overlay `render`, and anything run through `ClientThread`.
- **Not on it:**
  - `startUp` / `shutDown`, which run on the Swing EDT.
  - `onConfigChanged` after a panel edit (posted on the EDT).
  - Swing panel code, OkHttp callbacks, executor tasks.

  Hop over with `clientThread.invoke(...)`. Hop back for Swing with `SwingUtilities.invokeLater`.
- `invoke` runs inline when already on the client thread, and queues otherwise. `invokeLater` always queues. A `BooleanSupplier` that returns `false` is re-queued, which is the idiom for "retry until the widget exists". `invokeAtTickEnd` runs at the end of the current **client** tick, just before `PostClientTick`, not the game tick.
- Blocking IO stays off the client thread (`AGENTS.md` *Threading*).
- Images ship in the jar. Remote data (the wiki, an API) is fetched once and cached, never per frame or tick, since every install multiplies the load on that service.

## Lifecycle

- `startUp` registers each overlay, infobox, panel, key listener and helper; `shutDown` removes each one. The user can toggle the plugin mid-session, so `shutDown` also restores anything it changed in game: widget text or colour, hidden widgets.
- **Starting while logged in:** the plugin manager replays spawn events (NPC, player, object, ground item) and `ItemContainerChanged` to the plugin object. A helper registered with `eventBus.register(helper)` misses that replay: call `gameEventManager.simulateGameEvents(helper)` (inject `GameEventManager`). Vars and widgets are not replayed, so read them in `startUp` via `clientThread.invoke`.
- `GameStateChanged` → `LOGGED_IN` fires after **every** scene load, not only at login: teleports and region crossings go `LOADING` → `LOGGED_IN`. Clear tracked tile objects and ground items on `LOADING`, since they re-spawn for the new scene. Clear session state on `LOGIN_SCREEN` / `HOPPING`.
- `GameTick` posts once per ~0.6 s tick, **after** all of that tick's packets. That tick's `ChatMessage`, `VarbitChanged` and spawn events have already fired. Use `ClientTick` (per client frame) only for visuals that must move smoothly.
- `@Subscribe(priority = n)`: higher runs first.

## Game ids: gameval

Use `net.runelite.api.gameval.*` for every id. Most older plugin code, and most training data, predates it. The left column is deprecated except where noted.

| Old | Use |
|---|---|
| `net.runelite.api.ItemID` / `NpcID` / `ObjectID` / `AnimationID` (+ `Null*`) | `gameval.ItemID` / `NpcID` / `ObjectID` / `AnimationID` |
| `Varbits`, `VarPlayer`, `VarClientInt` / `VarClientStr` | `gameval.VarbitID`, `VarPlayerID`, `VarClientID` |
| `widgets.WidgetInfo`, `WidgetID`, `ComponentID`, `widgets.InterfaceID` | `gameval.InterfaceID`: nested classes hold packed component ids |
| `client.getWidget(WidgetInfo)`; `getWidget(group, child)` (live, but `AGENTS.md` says pass the gameval component id) | `client.getWidget(InterfaceID.Bankmain.ITEMS)` |
| `GraphicID`, api `SpriteID`, api `InventoryID` | `gameval.SpotanimID`, `SpriteID`, `InventoryID` |

- Names are **Jagex internal names, not wiki names**: the Soulreaper axe is `ItemID.BETA_ITEM_1`. Find the constant by grepping the generated file for the numeric id, or for the in-game name in its doc comment.
- In `gameval.InterfaceID`, top-level ints are group ids (compare them with `WidgetLoaded.getGroupId()`), and nested-class fields are full component ids.
- `ScriptID`, `ParamID`, `EnumID`, `SoundEffectID` and `HitsplatID` in `net.runelite.api` are current; there is no gameval equivalent.

## Verifying

1. `./gradlew build` (compile + tests) is the only check you can run.
2. Re-read the whole diff as the hub reviewer, against *Hard rule: reviewable code*. Delete or inline whatever fails it. **Done when** every class, method, field and config item traces to the request, a hub rule or a core precedent, and none can be removed without losing behaviour.
3. In-game behaviour is the user's to confirm: finish as `AGENTS.md` *Testing* says. Offer `./gradlew run`, say exactly what to test, and wait.

## References

| Read | When |
|---|---|
| [`references/setup.md`](references/setup.md) | New plugin from the template, modernising an old build, running the dev client, Jagex account login, logging |
| [`references/plugin-hub.md`](references/plugin-hub.md) | `runelite-plugin.properties`, submitting or updating on the hub, CI/packager failures, third-party dependencies, resources |
| [`references/api.md`](references/api.md) | Choosing an event; deprecated `Client` scene/menu/entity methods; coordinates, world views, menus, chat, items; injectable services |
| [`references/ui.md`](references/ui.md) | Overlays, infoboxes, side panels, editing widgets |
| [`references/config.md`](references/config.md) | Config interface and panel, persisting data, per-account data, renaming keys |
| [`references/vars.md`](references/vars.md) | Varbits, varps, varcs: reading, reacting, finding the right one |
| [`references/client-scripts.md`](references/client-scripts.md) | Interfaces the game rebuilds, `ScriptPostFired`, `ScriptCallbackEvent`, `runScript` |
| [`references/devtools.md`](references/devtools.md) | Finding an id, var, widget or script in game; `::` test commands |
| [`references/structure.md`](references/structure.md) | Code style, Guice scoping, organising a growing plugin, dev-only debug plugin |
