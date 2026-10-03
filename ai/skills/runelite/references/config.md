# Config

The config panel is generated from an interface. RuneLite proxies the interface, persists each value under `group.key`, and syncs it with the user's profile.

## The interface

```java
@ConfigGroup(MyConfig.GROUP)
public interface MyConfig extends Config
{
	String GROUP = "myplugin-specific-name";

	@ConfigSection(name = "Colours", description = "Highlight colours", position = 100, closedByDefault = true)
	String SECTION_COLOURS = "colours";

	@ConfigItem(keyName = "highlightFriends", name = "Highlight friends", description = "...", position = 1)
	default boolean highlightFriends()
	{
		return true;
	}

	@Alpha
	@ConfigItem(keyName = "friendColour", name = "Friend colour", description = "...", position = 101, section = SECTION_COLOURS)
	default Color friendColour()
	{
		return new Color(0, 200, 83, 150);
	}

	@Range(min = 1, max = 20)
	@Units(Units.TICKS)
	@ConfigItem(keyName = "delay", name = "Delay", description = "...", position = 2)
	default int delay()
	{
		return 5;
	}
}
```

Provide it from the plugin and inject it anywhere:

```java
@Provides
MyConfig provideConfig(ConfigManager configManager)
{
	return configManager.getConfig(MyConfig.class);
}
```

- A `default` method body is the default value.
- Items sort by `position`, then `name`. Sections sort the same way.
- `@ConfigSection` goes on a `String` **field**. An item's `section` must equal that field's *value*. Reference the constant.
- `@ConfigItem` fields beyond the required `keyName`/`name`/`description`:
  - `position`, `section`.
  - `hidden`: persists but is not shown. Useful for plugin-owned state.
  - `secret`: a `String` item becomes a password field.
  - `warning`: a Yes/No confirm on every change. A third-party-server toggle requires the exact `AGENTS.md` text.
- `@Range(min, max)` clamps only `int`. A `double` spinner ignores it, with a fixed min 0 and step 0.1.
- `@Units`: `MILLISECONDS`, `SECONDS`, `MINUTES`, `TICKS`, `PERCENT`, `PIXELS`.
- `@Alpha` adds an alpha slider to a `Color`.

## Types

Types that get a panel widget:

- primitive `boolean`, `int`, `double` (a boxed `Integer` gets no widget)
- `String`, `Color`, `Dimension`
- any `enum` (a dropdown that shows an overridden `toString()`, or else the title-cased `name()`)
- `Keybind`, `ModifierlessKeybind`
- `Notification`, `FontType`
- `Set<SomeEnum>` (a multi-select)

Types that are storable but have no widget (use them with `hidden = true` or via `ConfigManager`):

- `long`
- `Point`, `Rectangle`, `Instant`, `Duration`, `WorldPoint`
- `byte[]`
- any type annotated `@ConfigSerializer`

Enums are stored by `name()`, so renaming a constant resets every user who chose it.

A value that fails to parse logs a warning and silently falls back to the default.

**Setter:** a one-argument `@ConfigItem` method with the same `keyName` writes the value: `void delay(int value);`.

## Reacting to changes

```java
@Subscribe
public void onConfigChanged(ConfigChanged event)
{
	if (!MyConfig.GROUP.equals(event.getGroup()))
	{
		return;
	}
	// event.getKey(), getOldValue(), getNewValue() (null when unset)
}
```

`ConfigChanged` fires for **every** plugin's group, so filter first. It is posted synchronously on the thread that set the value. A panel edit runs on the EDT, so wrap any `Client` access in `clientThread.invoke(...)`.

## `ConfigManager` directly

For data that isn't a user setting (caches, last-seen state):

- `getConfiguration(group, key[, Type])`, `setConfiguration(group, key, value)`, `unsetConfiguration(group, key)`, `getConfigurationKeys(prefix)`.
- **Per RuneScape account:** use `getRSProfileConfiguration(...)`, `setRSProfileConfiguration(...)` and `unsetRSProfileConfiguration(...)`. They are keyed to the logged-in account (and world type), and setting one while logged out does nothing. `RuneScapeProfileChanged` fires on account switch, so reload per-account state there.

Config is synced to the user's RuneLite account. Large or high-churn data belongs in a file under the plugin's data dir (`AGENTS.md` *File I/O*), not in config.

## Renaming a key or group

Users' saved values live under the old name, and renaming without a migration silently resets them. Migrate once in `startUp`:

```java
String old = configManager.getConfiguration(MyConfig.GROUP, "oldKey");
if (old != null)
{
	configManager.setConfiguration(MyConfig.GROUP, "newKey", old);
	configManager.unsetConfiguration(MyConfig.GROUP, "oldKey");
}
```
