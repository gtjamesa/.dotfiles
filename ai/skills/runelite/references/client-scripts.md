# Client scripts (CS2)

Jagex builds and updates interfaces with clientscripts, which run in the client's script VM. A plugin that changes an interface usually hooks the script that builds it. Otherwise the game rebuilds the interface and overwrites the change.

## What a hub plugin can do

| Need | Mechanism |
|---|---|
| React after the game (re)builds an interface | `@Subscribe onScriptPostFired(ScriptPostFired e)`, matching `e.getScriptId()` against `ScriptID.X`. Re-apply widget edits here. |
| Inspect a script before it runs | `ScriptPreFired`. `getScriptEvent()` gives the source widget and args, but **only for the root script** (null for nested ones). |
| Change a value a core script asks Java for | `ScriptCallbackEvent`; see below. |
| Run a script | `client.runScript(ScriptID.X, args...)`. It must be on the client thread, and it is **not reentrant**, so never call it from inside a script hook. Defer with `clientThread.invokeLater`. |

Script overrides (`.rs2asm` in `runelite-client/src/main/scripts`, paired with a `.hash` of the original) are **core-only**. A hub plugin cannot ship one. A new callback hook needs a core PR.

## `ScriptCallbackEvent`

Core's overridden scripts contain `sconst "eventName"` + `runelite_callback`. That posts `ScriptCallbackEvent` with the script's stacks live. Read the arguments off the top of the stacks and write results back in place:

```java
@Subscribe
public void onScriptCallbackEvent(ScriptCallbackEvent event)
{
	if (!"bankSearchFilter".equals(event.getEventName()))
	{
		return;
	}
	int[] intStack = client.getIntStack();
	int intStackSize = client.getIntStackSize();
	Object[] objectStack = client.getObjectStack();
	int objectStackSize = client.getObjectStackSize();

	int itemId = intStack[intStackSize - 1];
	String search = (String) objectStack[objectStackSize - 1];
	intStack[intStackSize - 2] = matches(itemId, search) ? 1 : 0; // return value
}
```

The string stack is now the **object stack**: use `getObjectStack` / `getObjectStackSize` and cast. `getStringStack` no longer exists, though the wiki still shows it.

The callback names live in core's `runelite-client/src/main/scripts/*.rs2asm`; grep `runelite_callback` to list them. They include `bankSearchFilter`, `bankBuildTab`, `chatMessageBuilding`, `chatFilterCheck`, `friendsChatSetText`, `skillTabTotalLevel`, `questFilter`, `spellbookSort` and `fakeXpDrop`. A script's exact stack layout is in its `.rs2asm`.

## Reading a script

- Decompiled source: https://github.com/runelite/cs2-scripts, as `scripts/[clientscript,<name>].cs2`. Search it by script id or by the widget it touches.
- Full cache dump with every script disassembled: https://github.com/Abextm/osrs-cache/releases.
- In game: the **Script Inspector** dev tool logs each tick's script tree with source widget and args ([`devtools.md`](devtools.md)). Scripts 3174 and 1004 fire every tick and are blacklisted by default.

`net.runelite.api.ScriptID` is current; it has no gameval replacement. An id missing from it can be used as a commented literal.
