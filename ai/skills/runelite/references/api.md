# API map

This file covers which thing to reach for, and the traps. Exact signatures are in the javadoc; when the javadoc is silent, the core source is the authority.

## Events

API events live in `net.runelite.api.events`. Client events (`ConfigChanged`, loot, profiles) live in `net.runelite.client.events`. A handler is `@Subscribe public void onX(X event)` on the plugin or on a registered helper.

| Need | Event | Trap |
|---|---|---|
| Per-tick logic | `GameTick` | Posts after the tick's packets. |
| Per-frame visuals | `ClientTick` (20 ms), `BeforeRender` | Keep the work trivial. |
| Login, logout, scene load, hop | `GameStateChanged` | `LOGGED_IN` repeats after every `LOADING`. |
| NPCs | `NpcSpawned` / `NpcDespawned` / `NpcChanged` (composition change, e.g. transform) | Track these in your own collection rather than scanning the world each tick. |
| Players | `PlayerSpawned` / `PlayerDespawned` / `PlayerChanged` | `PlayerSpawned` **includes** the local player, including in the start-up replay, so skip `client.getLocalPlayer()` when tracking others. `PlayerDespawned` never fires for the local player. |
| Objects | `GameObject*`, `WallObject*`, `DecorativeObject*`, `GroundObject*` + `Spawned`/`Despawned` | No despawns on scene load, so clear on `LOADING`. |
| Ground items | `ItemSpawned` / `ItemDespawned` / `ItemQuantityChanged` | Same scene-load caveat as objects. |
| Inventory, equipment, bank | `ItemContainerChanged` | Match `getContainerId()` against `gameval.InventoryID`. |
| Skills, XP, boosts | `StatChanged` | — |
| Vars | `VarbitChanged`, `VarClientIntChanged` / `VarClientStrChanged` | See [`vars.md`](vars.md). |
| Animation, spotanim, target | `AnimationChanged`, `GraphicChanged`, `InteractingChanged` | Read the new value off the actor. |
| Damage, death | `HitsplatApplied`, `ActorDeath` | Hitsplats fire even when not rendered. |
| Projectiles | `ProjectileMoved` | Ground-targeted ones fire once. |
| Chat | `ChatMessage` | Excludes NPC dialogue (that's widgets). Text carries `<col=…>` tags, so compare `Text.removeTags(msg)`. Filter on `getType()` (`GAMEMESSAGE`, `SPAM`, …). |
| Dev `::commands` | `CommandExecuted` | — |
| Menu entries | `MenuEntryAdded`, `MenuOpened`, `PostMenuSort` (left-click swaps), `MenuOptionClicked` (`consume()` cancels) | See *Menus*. |
| Interfaces | `WidgetLoaded` / `WidgetClosed` (group id), `ScriptPostFired` | On `WidgetLoaded`, the interface's children may not be built yet. Defer with `clientThread.invokeLater`, or hook the build script ([`client-scripts.md`](client-scripts.md)). |
| Loot | `NpcLootReceived`, `PlayerLootReceived`, `ServerNpcLoot` | — |
| Account switch | `RuneScapeProfileChanged` | Reload per-account config here. |
| Boats / world entities | `WorldEntitySpawned` / `Despawned`, `WorldViewLoaded` / `Unloaded` | See *World views*. |

## Deprecated scene, menu and entity APIs

Old plugin code uses the left column. Use the right.

| Deprecated | Use |
|---|---|
| `client.getNpcs()`, `getPlayers()`, `getScene()`, `getPlane()`, `getBaseX/Y()`, `isInInstancedRegion()`, `getMapRegions()`, `getSelectedSceneTile()`, `getGraphicsObjects()`, `getCollisionMaps()` | `client.getTopLevelWorldView()` then `.npcs()`, `.players()`, `.getScene()`, `.getPlane()`, `.getBaseX()`, `.isInstance()`, `.getMapRegions()`, … |
| `client.createMenuEntry`, `getMenuEntries`, `setMenuEntries`, `getMenuX/Y/…` | `client.getMenu().createMenuEntry(-1)` etc. |
| `client.getItemContainer(InventoryID.INVENTORY)` (api enum) | `client.getItemContainer(gameval.InventoryID.INV)` (`WORN`, `BANK`) |
| `client.isPrayerActive(Prayer)` | The prayer's varbit. The old method mishandles Deadeye and Mystic Vigour. |
| `client.getUsername()`, `getAccountType()` | `getAccountHash()`, `VarbitID.IRONMAN` |
| `Skill.OVERALL` | `client.getTotalLevel()` / `getOverallExperience()`. **`OVERALL` is now `null`**: it compiles, then NPEs or never matches. |
| `MenuOptionClicked.getActionParam()` / `getWidgetId()` | `getParam0()` / `getParam1()` |
| `MenuAction.ITEM_*_OPTION`, `ITEM_USE_ON_*` | `CC_OP` / `WIDGET_TARGET_ON_*`, with `MenuEntry.isItemOp()` / `getItemOp()` |
| `Actor.getGraphic()` / `setGraphic` | `hasSpotAnim(id)`, `getSpotAnims()`, `createSpotAnim(...)` |
| `Projectile.getInteracting()`, `getX1/Y1`, `getTarget` | `getTargetActor()`, `getSourcePoint()`, `getTargetPoint()` |
| `new LocalPoint(x, y)`, `LocalPoint.fromWorld(client, x, y)`, `WorldPoint.fromLocal(client, x, y, plane)` | The overloads taking a `WorldView` |
| `ImageUtil.getResourceStreamFromClass` | `ImageUtil.loadImageResource(getClass(), "/x.png")` |

## Coordinates

- **`WorldPoint`**: an absolute tile (x, y, plane). Store and compare with this.
- **`LocalPoint`**: 1/128-tile units relative to the loaded scene, tagged with its world view. It is **invalid after a scene load**, so never keep one past `LOADING`.
- **Scene coords**: 0–103 indices into `scene.getTiles()[plane][x][y]`.
- **Instances** (raids, most bosses, POH): a player's `getWorldLocation()` there is an instance coordinate. To get the real template location, and so a stable region id, use `WorldPoint.fromLocalInstance(client, player.getLocalLocation()).getRegionID()`.
- **Canvas**: `Perspective.getCanvasTilePoly(client, lp)`, `localToCanvas`, `getCanvasTextLocation`, and the actor and object conveniences (`getCanvasTilePoly()`, `getConvexHull()`, `getClickbox()`). All return **null** off-screen, so null-check before drawing.

### World views

The top-level world view is the normal map. Since Sailing, a boat is a `WorldEntity` with its **own** world view, holding the players, NPCs and objects aboard.

- An actor or object on a boat reports that world view: `actor.getWorldView()`, and `LocalPoint` carries its id.
- Iterating only `getTopLevelWorldView().npcs()` misses everything aboard. Walk `worldView.worldViews()` too, or track spawn events, which fire for every view.
- `client.findWorldViewFromWorldPoint(wp)` resolves the view for a world point.

## Menus

- **Add** a client-side entry in `onMenuEntryAdded` (match `getOption()`/`getType()`/`getIdentifier()`) or `onMenuOpened`:
  ```java
  client.getMenu().createMenuEntry(-1)
  	.setOption("Mark")
  	.setTarget(event.getTarget())
  	.setType(MenuAction.RUNELITE)
  	.onClick(e -> mark(e.getIdentifier()));
  ```
  `MenuAction.RUNELITE` entries never reach the server. Entries that send actions to the server are forbidden (`AGENTS.md`).
- **Swap or reorder** in `PostMenuSort`, by permuting `client.getMenu().getMenuEntries()` and setting it back. Conditional removal of entries is restricted, so check the hub rules first.

## Chat

- **Send to the user:** `chatMessageManager.queue(QueuedMessage.builder().type(ChatMessageType.GAMEMESSAGE).runeLiteFormattedMessage(msg).build())`. Build `msg` with `new ChatMessageBuilder().append(ChatColorType.HIGHLIGHT).append("…").build()`. It is safe from any thread. `client.addChatMessage` needs the client thread.
- **Chat commands** (`!kc`-style, visible to others): `ChatCommandManager.registerCommand(...)`; unregister in `shutDown`.
- **Names:** `Text.toJagexName` / `Text.standardize` before comparing. Game names use non-breaking spaces.

## Items

- `ItemManager`:
  - `getItemComposition(id)` (client thread only)
  - `getItemPrice(id)` (GE price, `long`)
  - `getImage(id[, qty, stackable])` (async: may be blank until loaded; `.addTo(label)` for Swing)
  - `canonicalize(id)` maps noted or placeholder ids to the base item
- `ItemVariationMapping.getVariations(id)`: every variant of an item (ornament, charged, degraded). Use it instead of hand-listing ids.
- Equipment: `client.getItemContainer(InventoryID.WORN)` indexed by `EquipmentInventorySlot.X.getSlotIdx()`. For any player (including others), `player.getPlayerComposition().getEquipmentId(KitType.WEAPON)`.
- `client.getItemContainer(...)` is **null** until the server has sent that container. The bank is null until opened this session.

## Services to inject

| Need | Inject |
|---|---|
| Run on the client thread | `ClientThread` |
| Register helpers, post your own events | `EventBus` |
| Persist values | `ConfigManager` ([`config.md`](config.md)) |
| Item data, prices, icons | `ItemManager` |
| Game sprites | `SpriteManager` (`getSpriteAsync`; plain `getSprite` asserts the client thread) |
| Skill icons | `SkillIconManager` |
| Chat out / chat commands | `ChatMessageManager`, `ChatCommandManager` |
| Desktop notification | `Notifier` (`notify(config.myNotification(), "text")` with a `Notification` config item) |
| Hotkeys | `KeyManager` + `HotkeyListener` (with a `Keybind` config item) |
| Mouse | `MouseManager` (+ `MouseAdapter`) |
| NPC highlight | `NpcOverlayService` ([`ui.md`](ui.md)) |
| Overlays, infoboxes, side panel | `OverlayManager`, `InfoBoxManager`, `ClientToolbar` ([`ui.md`](ui.md)) |
| HTTP, JSON | `OkHttpClient`, `Gson` (`AGENTS.md` *HTTP & JSON*) |
| Replay spawns to a helper | `GameEventManager` |
| Periodic task | `@Schedule(period = …, unit = ChronoUnit.X)` on a plugin method |
| Talk to another plugin | post or subscribe to `PluginMessage(namespace, name, data)` |

Static utils: `Text` (tags, names, CSV), `ColorUtil` (`wrapWithColorTag`), `ImageUtil`, `QuantityFormatter`, `LinkBrowser`.
