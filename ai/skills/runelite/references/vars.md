# Vars: VarPlayer, Varbit, VarClient

Most game state the server shares with the client lives in vars: quest progress, toggles, timers, the attack style.

| Kind | Set by | Shape | Read | Constants |
|---|---|---|---|---|
| **VarPlayer** (varp) | server; persists on the account | 32-bit int (some `long`) | `client.getVarpValue(id)` | `gameval.VarPlayerID` |
| **Varbit** | server; persists on the account | a fixed bit range inside one varp | `client.getVarbitValue(id)` | `gameval.VarbitID` |
| **VarClient** (varc) | clientscripts only; client-side | int or string | `getVarcIntValue(id)` / `getVarcStrValue(id)` | `gameval.VarClientID` (both kinds) |

- A varbit read is `(varp >> lsb) & ((1 << (msb - lsb + 1)) - 1)`. Several varbits can overlap the same bits.
- Clientscripts may predict a varp change before the server confirms it. `getServerVarbitValue` and `getServerVarpValue` return the server's last word.
- Some state never reaches vars. Item containers, animations, actor state, chat messages and widgets carry the rest. If the inspector shows nothing for an action, look there.
- `Varbits`, `VarPlayer`, `VarClientInt` and `VarClientStr` are deprecated, and the old `getVar(...)` overloads have been removed. Use the gameval ids with the calls above.

## Reacting

`VarbitChanged` fires for **both** kinds:

```java
@Subscribe
public void onVarbitChanged(VarbitChanged event)
{
	if (event.getVarbitId() == VarbitID.STAMINA_ACTIVE) { ... }          // a varbit changed
	if (event.getVarpId() == VarPlayerID.COM_MODE) { ... }               // its varp changed
}
```

- For a plain varp change, `getVarbitId()` is `-1`. A varbit change also reports its backing `getVarpId()`.
- `getValue()` is the new value. Don't use the deprecated `getIndex()`.
- When the client predicts a varp and the server agrees next tick, the event posts **once, on the client change**. A handler that waits for server confirmation never fires.
- VarClient changes post `VarClientIntChanged` / `VarClientStrChanged` instead, with `getIndex()`.
- Vars set before the plugin started don't replay. Read the current value in `startUp` via `clientThread.invoke`.

## Finding the var for an action

1. Open the **Var Inspector** ([`devtools.md`](devtools.md)), then do the action in game. Ask the user to do it; the agent never drives the game. The inspector logs every var change by gameval name while open.
2. Many vars change at once, so confirm the candidate by repeating the action.
3. Then look the name up in `gameval/VarbitID.java` (or `VarPlayerID.java`) in the core source.
4. Other routes:
   - An object or NPC that changes appearance names its driving varbit/varp in its cache definition (abex cache viewer).
   - Clientscripts read and write vars ([`client-scripts.md`](client-scripts.md)).

## Testing a var handler

In dev mode, `::setvarb <id> <value>` and `::setvarp <id> <value>` change the client value and post a fake `VarbitChanged`; the server value is untouched. The fake from `::setvarb` carries only `varbitId`, so a handler filtering on `getVarpId()` needs `::setvarp`. Use `::getvarb` / `::getvarp` to read.
