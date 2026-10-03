# Code style and plugin structure

## Style

The RuneLite code conventions apply to the core client, which enforces them with checkstyle. Hub reviewers read the same style. When a plugin repo's existing style differs, match the repo.

- Indent with **tabs**. Braces go **on the next line** (Allman) for classes, methods and control blocks, and are always present.
- Imports form **one block**: ASCII-sorted, no blank lines between groups, static imports not separated, **no wildcards**.
- Multi-line annotation arguments get one extra tab:
  ```java
  @PluginDescriptor(
  	name = "Tile Indicators",
  	tags = {"highlight", "overlay"}
  )
  ```
- A single blank line separates logical blocks.
- Core requires the BSD-2 copyright header on every new file. In a plugin, follow the repo.
- Core's `checkstyle.xml` is at the repo root. A plugin can adopt it with Gradle's `checkstyle` plugin, as `LlemonDuck/sailing` does (`config/checkstyle/checkstyle.xml`).

## Guice

Each plugin gets its own child injector, and `Plugin` is itself a Guice module, so `@Provides` methods on the plugin class work.

**A class without `@Singleton` is instantiated fresh at every injection point.** A tracker injected into both the plugin and its overlay becomes two trackers with diverging state. Mark every shared stateful helper `@Singleton`.

Constructor injection works too: `@Inject` on the constructor, or lombok `@RequiredArgsConstructor(onConstructor = @__(@Inject))` with `final` fields.

## Small plugin (the default)

One package holds:

- `XPlugin`: lifecycle and event handlers, with state exposed through lombok `@Getter`
- `XConfig`
- `XOverlay`, which takes the plugin and config by constructor injection and reads plugin state in `render`

Split out `@Singleton` helpers once the plugin class grows: a region matcher, a tracker. A helper that subscribes to events is registered on `startUp` (`eventBus.register(helper)`) and unregistered on `shutDown`. Registering it misses the spawn replay; see SKILL.md *Lifecycle*.

Group by feature (`friendnotes/`, `features/<area>/`) rather than by kind (`overlays/`, `util/`).

## Dev-only debug plugin

Put a second plugin under `src/test` with `@PluginDescriptor(developerPlugin = true)`, and load it beside the real one: `ExternalPluginManager.loadBuiltin(XPlugin.class, XDebugPlugin.class)`. Use it for overlays that dump internal state. It never ships, because the packager only takes `src/main`. Worth it at any size.

## Very large plugin: component loader

Use this only when a plugin carries **dozens of independently toggled features**; for anything smaller, the plugin class is the loader. The pattern comes from `LlemonDuck/sailing`: https://github.com/LlemonDuck/sailing/tree/main/src/main/java/com/duckblade/osrs/sailing/module. Read it before reproducing.

- **`PluginLifecycleComponent`** is an interface with default methods `isEnabled(XConfig)` (default `true`), `startUp()` and `shutDown()`. Each feature is one `@Singleton` class implementing it. It often also extends `Overlay` or `InfoBox`, subscribes to its own events, and returns its config toggle from `isEnabled`.
- **`XModule extends AbstractModule`** binds `ComponentManager`. One `@Provides Set<PluginLifecycleComponent>` method takes every component as a parameter and returns an `ImmutableSet` of them; it also provides `@Singleton` config. Features still in development are added only when `@Named("developerMode") boolean` is true.
- **The plugin** does three things:
  - `configure(Binder)` calls `binder.install(new XModule())`
  - `startUp` calls `componentManager.onPluginStart()`
  - `shutDown` calls `componentManager.onPluginStop()`
- **`ComponentManager`** is `@Singleton`. It registers itself on the event bus, and on every `ConfigChanged` for the group it re-checks each component's `isEnabled`.
  - It starts each newly enabled component: `startUp()`, `eventBus.register`, add to `OverlayManager`/`InfoBoxManager` when it is an `Overlay`/`InfoBox`, then `gameEventManager.simulateGameEvents(component)`.
  - It stops each newly disabled one in reverse order.
  - Each start and stop is wrapped in `try/catch (Throwable)`, so one broken feature can't take down the rest.

Adding a feature is then one class plus one line in the module. Config toggles take effect live without restarting the plugin.
