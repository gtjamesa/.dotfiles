# UI: overlays, infoboxes, panels, widgets

## Overlays

`render(Graphics2D)` runs **every frame, on the client thread**. Compute state in event handlers or on `GameTick`, store it, and have `render` only read and draw it. Return `null` to draw nothing (or for world-anchored overlays); otherwise return the drawn size.

```java
class XOverlay extends Overlay
{
	private final XPlugin plugin;

	@Inject
	private XOverlay(XPlugin plugin)
	{
		super(plugin);
		this.plugin = plugin;
		setPosition(OverlayPosition.DYNAMIC);
		setLayer(OverlayLayer.ABOVE_SCENE);
	}

	@Override
	public Dimension render(Graphics2D graphics)
	{
		for (NPC npc : plugin.getTracked())
		{
			Polygon poly = npc.getCanvasTilePoly();
			if (poly != null)
			{
				OverlayUtil.renderPolygon(graphics, poly, Color.CYAN);
			}
		}
		return null;
	}
}
```

- Passing the plugin to `super(plugin)` ties the overlay to the plugin, for overlay menu entries and reset.
- **Position:**
  - `DYNAMIC` is for drawing anchored to the world or the screen.
  - The snap positions (`TOP_LEFT`, `TOP_RIGHT`, `BOTTOM_LEFT`, `BOTTOM_RIGHT`, `ABOVE_CHATBOX_RIGHT`, `CANVAS_TOP_RIGHT`, `TOP_CENTER`) are for boxed panels the user can drag.
  - `DETACHED` is deprecated; use `DYNAMIC` + `setMovable(true)`.
- **Layer:**
  - `ABOVE_SCENE`: over the 3D scene, under interfaces.
  - `UNDER_WIDGETS` (default): above overhead text.
  - `ABOVE_WIDGETS`: over interfaces, under the right-click menu.
  - `ALWAYS_ON_TOP`.
  - `MANUAL`: drawn only via `drawAfterInterface(groupId)` / `drawAfterLayer(componentId)`.
- **Priority** is a float: `setPriority(Overlay.PRIORITY_HIGH)` (`PRIORITY_LOW` 0 to `PRIORITY_HIGHEST` 1). The `OverlayPriority` enum is deprecated.
- **Drawing helpers:**
  - `OverlayUtil`: `renderPolygon`, `renderTextLocation`, `renderActorOverlay`, `renderTileOverlay`, `renderImageLocation`, `renderMinimapLocation`.
  - `Perspective` for the projections.
  - `ModelOutlineRenderer.drawOutline(actorOrObject, width, color, feather)` for model outlines.
  - Every canvas projection can be `null` off-screen.

### Boxed text: `OverlayPanel`

```java
@Override
public Dimension render(Graphics2D graphics)
{
	panelComponent.getChildren().add(TitleComponent.builder().text("Warning").color(Color.RED).build());
	panelComponent.getChildren().add(LineComponent.builder().left("Kills").right(Integer.toString(kills)).build());
	return super.render(graphics);
}
```

Children are cleared after each render by default. Style with `panelComponent.setBackgroundColor(...)` and `setPreferredSize(...)`.

### Specialised overlays

- **Items in inventory, bank or equipment:** extend `WidgetItemOverlay`, implement `renderItemOverlay(g, itemId, widgetItem)`, and call `showOnInventory()` / `showOnBank()` / `showOnEquipment()` / `showOnInterfaces(groupIds...)` in the constructor.
- **NPC highlighting** (outline, hull, tile, name): register a function with `NpcOverlayService.registerHighlighter(npc -> HighlightedNpc.builder().npc(npc).highlightColor(c).outline(true).build())`. Unregister in `shutDown`, and call `rebuild()` after config changes. Return `null` for NPCs you don't highlight. Prefer this to a hand-written NPC overlay.
- **Tooltips:** call `tooltipManager.add(new Tooltip(text))` from `render`, each frame the tooltip should show.
- **World map:** `WorldMapPointManager.add/remove(WorldMapPoint)`.

## Infoboxes

The small icons with text along the top of the game view.

- Use `Counter(image, plugin, count)` for a number, or `Timer(duration, ChronoUnit, image, plugin)` for a countdown. Otherwise extend `InfoBox` and implement `getText()` and `getTextColor()`, overriding `render()` to hide it conditionally.
- **Construct** with `new X(image, plugin)`. For a Guice-built subclass, use an `@Inject` constructor that calls `super(null, plugin)` and set the image afterwards.
- **Text** fits about **5 characters** (`"Def"`, not `"Defensive"`). Put the long form in `setTooltip(...)`.
- `infoBoxManager.addInfoBox(box)` / `removeInfoBox(box)` / `removeIf(b -> b instanceof XBox)`.
- **Icon:** use `itemManager.getImage(itemId)`, or `spriteManager.getSpriteAsync(SpriteID.X, 0, box)` to fill it in when loaded.

## Side panel

```java
panel = injector.getInstance(XPanel.class);           // XPanel extends PluginPanel
navButton = NavigationButton.builder()
	.tooltip("X")
	.icon(ImageUtil.loadImageResource(getClass(), "/icon.png"))
	.priority(5)
	.panel(panel)
	.build();
clientToolbar.addNavigation(navButton);              // shutDown: clientToolbar.removeNavigation(navButton)
```

- Panel code is Swing, so it runs on the **EDT**. Read game state via `clientThread.invoke`, then update Swing via `SwingUtilities.invokeLater`.
- Style with `ColorScheme` and `FontManager`, so the panel matches the client.
- `PluginErrorPanel` gives an empty state, and `IconTextField` a search box.
- Use `PluginPanel(false)` when the panel manages its own scrolling.

## Editing game widgets

- `client.getWidget(InterfaceID.Group.CHILD)` is **null** when the interface isn't open. Check `isHidden()` too.
- Children are reached through `getChildren()`, `getDynamicChildren()`, `getStaticChildren()` and `getNestedChildren()`. Row widgets built by scripts are usually dynamic children, identified by `getIndex()`.
- The game **rebuilds interfaces with clientscripts** and overwrites edits, e.g. a list refreshing when a friend logs in. Re-apply edits in `ScriptPostFired` for the building script, not only on `WidgetLoaded` ([`client-scripts.md`](client-scripts.md)).
- `shutDown` must restore every edited widget: text, colour, hidden state. Run the restore on the client thread.
- Hub rules forbid unhiding hidden components and resizing click zones (`AGENTS.md` *Interface Restrictions*).
