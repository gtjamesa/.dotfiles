# Plugin Hub: submit, update, pass CI

The hub builds each plugin from a pinned commit of its public repo. RuneLite's packager (`runelite/plugin-hub-tooling`) builds it, and a human reviews the source. A check that fails in the packager fails the PR, whatever the code does. *Rules* (forbidden features and APIs) live in `AGENTS.md`; this file covers the mechanics.

## `runelite-plugin.properties`

```properties
displayName=Helmet check
author=dekvall
description=Alerts you when you have nothing equipped in your head slot
tags=hint,gear,head
plugins=com.helmetcheck.HelmetCheckPlugin
version=1.2.0
build=standard
```

- The allowed keys are exactly `displayName`, `author`, `description`, `tags`, `plugins`, `version`, `build` and `support`. Any other key is fatal.
- Template placeholders are rejected: `Example`, `Nobody` and `An example greeter plugin`.
- `build` takes `standard` or `gradle`, and it is **required**. Older repos omit it; add `build=standard`.
  - `standard` builds with a replacement build file: only `src/main/java`, `src/main/resources` and `lombok.config` are copied. It is reviewed faster.
  - `gradle` keeps the repo's build. Every `*.gradle` line must be ≤120 chars, counting a tab as 8.
- In `plugins`, each class must extend `Plugin` and carry `@PluginDescriptor`. One class is normal.
- If `version` is empty or ends in `SNAPSHOT`, the packager uses the commit's short hash instead.

## Packager checks

- **Bytecode ≤ Java 11** (`options.release.set(11)`).
- No classes in a `net.runelite.*` package.
- No `.class` files in `src/main/resources`, and no `Class-Path` in the manifest.
- Jar ≤ 10 MiB; a warning appears from 80%.
- A root `LICENSE` that allows free redistribution of the jar. BSD 2-Clause is the recommended one.
- `icon.png` is optional. If present: a real PNG, ≤256 KiB, and no more than 50×100 px in area. 48×72 px is the intended size.
- `@PluginDescriptor(internalName = ...)` must equal the `plugins/<name>` filename **when set**. The javadoc says "snake-cased", but filenames only allow `[a-z0-9-]`, so use dashes.
- **Disallowed APIs** are fatal. Constructing your own HTTP or JSON client fails: `new OkHttpClient()`, `new OkHttpClient.Builder()`, `new Gson()`, `new GsonBuilder()`. Inject them instead, as `AGENTS.md` says. The other banned APIs are:
  - `WidgetInfo` and `WidgetID*`
  - `ChatMessageManager.update(MessageNode)`, which is a no-op
  - `ItemManager.getItemStats(int, boolean)`; use `getItemStats(int)`
  - `net.runelite.client.account.*`: `AccountClient`, `AccountSession`, `SessionManager`
- CI also checks API compatibility. Plugins rebuild whenever the RuneLite API changes, so a plugin built on a since-removed API breaks for users.

## Resources

Resources go in `src/main/resources`. The plugin ships as a jar on the classpath and is **never unpacked**. `getResource()` returns a `file:` URL in the IDE and a `jar:` URL in production, so code that builds `File` paths from it works locally and breaks for users. Load with `getResourceAsStream()`, or with `ImageUtil.loadImageResource(getClass(), "/icon.png")` for images.

## Third-party dependencies

A dependency that is not already a transitive dependency of `runelite-client` must be hash-verified. That means a PR to `plugin-hub/package/verification-template/build.gradle`:

```groovy
thirdParty("group:artifact:version") { because "<plugin-name>" }
```

Then run `./gradlew --write-verification-metadata sha256` in `package/verification-template` (it ships its own wrapper). Indent with tabs; a line starting with a space fails `verifyAll`.

A maintainer checks each hash against Maven Central by hand, which adds significantly to review time. Prefer the JDK, the client's own libraries (Guava, Gson, OkHttp, Lombok), or a few dozen lines of your own. Some libraries are already approved: jsoup, sqlite-jdbc and java-websocket. Reusing one still means adding your plugin name to its `because`.

## Submitting

1. Fork `runelite/plugin-hub`, branch, and add `plugins/<name>`. The filename must match `^[a-z0-9-]+$`, with no subdirectory:
   ```
   repository=https://github.com/<user>/<repo>.git
   commit=<full 40-char sha>
   ```
   - `repository` must be an `https://github.com/....git` URL.
   - Use `key=value` lines with no spaces around `=`.
   - Maintainers may add `authors`, `warning`, `disabled`, `unavailable` or `jarSizeLimitMiB` to the file. Keep any that exist; any other key is fatal.
2. Open the PR. An agent must run `gh` non-interactively from the fork: `gh pr create --repo runelite/plugin-hub --head <user>:<branch> --title "..." --body "..."`. End the body with the footer from `AGENTS.md` *Submitting*.
3. CI runs `build`, plus *RuneLite Plugin Hub Checks*, which matters only when it says "Changes are needed". Fix problems in the same PR.

## Updating

1. **Is there anything to ship?** Read the pinned commit from upstream: `git show upstream/master:plugins/<name>` in a plugin-hub clone, or `gh api repos/runelite/plugin-hub/contents/plugins/<name>`. Compare it with the plugin repo's pushed `HEAD`. If they are equal, stop and tell the user.
2. **Review what reviewers will review:** `git log --stat <pinned>..HEAD` and `git diff <pinned>..HEAD` in the plugin repo. Check that diff against `AGENTS.md` and the packager checks above.
3. **Release in the plugin repo, following its own convention.** Read `git log` for it (e.g. `chore: release vX.Y.Z` commits bumping `version` in both `runelite-plugin.properties` and `build.gradle`, plus a tag). Bump `version` in `runelite-plugin.properties`, or users see a hash. Push before pinning: the hub can only build a commit GitHub has.
4. **Bump the pin** on a fresh branch off upstream:
   ```bash
   git remote add upstream https://github.com/runelite/plugin-hub.git   # once
   git fetch upstream
   git checkout -B <name> upstream/master
   # edit only commit= in plugins/<name>
   git commit -am "update <name>"
   git push -f -u origin <name>
   ```
   Then open the PR as in *Submitting* step 2.
