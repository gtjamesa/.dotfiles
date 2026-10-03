# Developer tools

Enabled by `--developer-mode` plus `-ea`, which the template `run` task passes. They appear as a sidebar panel with a devtools icon. The user drives the game; the agent tells them which tool to open and what to report back.

## Finding an id or value

| To find | Tool |
|---|---|
| NPC id, animation, graphic | **NPCs** overlay: `ID`, `A:` anim, `P:` pose, `G:` graphic. A varbit-morphing NPC shows its *transformed* id. |
| Own or other player animation | **Players** overlay. |
| Object id | **Game Objects**, **Walls**, **Decorations**, **Ground Objects** overlays. |
| Ground item id | **Ground Items**. |
| Id of anything examinable | **Examine** appends ids to the examine menu entry. |
| Projectile / graphics object ids | **Projectiles**, **Graphics Objects**. |
| Tile coordinates, region id | **Tile Location** (hovered tile) and **Location** (local, world, scene, chunk, instance flag, map regions). |
| Region boundaries | **Map Squares**, **Zone Borders**, **Loading Lines**. |
| Pathing and collision | **Line Of Sight**, **Valid Movement**, **Movement Flags**, **Tile flags**. |
| Interface / widget id | **Widget Inspector**: *Pick* then click the widget in game. It shows group/child plus the gameval `InterfaceID` name. |
| Var behind an action | **Var Inspector**: logs every varbit, varp and varc change by gameval name while its window is open. |
| Script building an interface | **Script Inspector**: a per-tick tree of fired scripts with args and source widget. |
| Inventory/equipment changes | **Inventory Inspector**: `ItemContainerChanged` diffs. |
| Sound effect id | **Sound Effects**. |
| Boats and other world entities | **World Entities**: worldview id and config id. |

**Shell** is an in-client JShell with the plugin's injector. It runs on the client thread, so it can poke `client` live. It needs the `jshell` test dependency, which the template has.

## `::` chat commands (dev mode)

Typed into the chatbox. Every change is **client-side only**, which makes them useful for exercising handlers without the game state:

| Command | Effect |
|---|---|
| `::getvarb <id>` / `::setvarb <id> <val>` | Read or set a varbit, posting `VarbitChanged` with only `varbitId` set. |
| `::getvarp <id>` / `::setvarp <id> <val>` | Same, for a varp. |
| `::setstat <skill> <lvl>`, `::addxp <skill> <xp>` | Post `StatChanged`. |
| `::anim <id>`, `::gfx <id>`, `::transform <npcId>`, `::wear <slot> <itemId>` | Local player visuals. |
| `::sound <id>`, `::msg <text>` | Play a sound; inject a chat message. |
| `::getconf <group> <key>`, `::setconf <group> <key> = <value>` | Read or write config. With no value, `setconf` unsets. |
| `::logger [level]` | Get or set the root log level. |
