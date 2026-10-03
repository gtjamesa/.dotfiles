# Setup, running, logging

## New plugin

Generate a repo from https://github.com/runelite/example-plugin/generate. It must be **public**, since the hub builds from it. Then rename every `example` identifier, following `AGENTS.md` *Plugin Setup & Packaging*. Two renames that list leaves out:

- `pluginMainClass` in `build.gradle`. It names the test launcher, so `./gradlew run` breaks until it matches.
- The `<logger name="com.example" level="DEBUG"/>` line in `src/test/resources/logback-test.xml`. Rename it to match the new package or the plugin's debug logs disappear.

Fill `runelite-plugin.properties` per [`plugin-hub.md`](plugin-hub.md).

## The template `build.gradle`

```groovy
repositories {
	mavenLocal()
	maven {
		url = 'https://repo.runelite.net'
		content {
			includeGroupByRegex("net\\.runelite.*")
		}
	}
	mavenCentral()
}

def runeLiteVersion = 'latest.release'
def pluginMainClass = 'com.example.ExamplePluginTest'

dependencies {
	compileOnly group: 'net.runelite', name:'client', version: runeLiteVersion

	compileOnly 'org.projectlombok:lombok:1.18.30'
	annotationProcessor 'org.projectlombok:lombok:1.18.30'

	testImplementation 'junit:junit:4.12'
	testImplementation group: 'net.runelite', name:'client', version: runeLiteVersion
	testImplementation group: 'net.runelite', name:'jshell', version: runeLiteVersion
}

tasks.withType(JavaCompile).configureEach {
	options.encoding = 'UTF-8'
	options.release.set(11)
}

tasks.register('run', JavaExec) {
	classpath = sourceSets.test.runtimeClasspath
	mainClass = pluginMainClass

	jvmArgs "-ea"
	args "--developer-mode", "--debug"
}
```

The template also has a `shadowJar` task, which builds a standalone dev-client jar (`<name>-<version>-all.jar`). The authority is upstream: https://raw.githubusercontent.com/runelite/example-plugin/master/build.gradle.

- `latest.release` resolves to the newest client. A stale API after a RuneLite release means Gradle cached the old one: run `./gradlew build --refresh-dependencies`.
- With `build=standard` (the template's value), the packager **replaces** `build.gradle` and `settings.gradle` with its own: client, lombok and jetbrains annotations only. Extra dependencies or build logic exist only locally.

**Older repos** predate this shape. Signs are `sourceCompatibility = '1.8'`, no `run` task, no repository `content` filter, and no `build=` in the properties file.

- A missing `run` task and a missing `build=` need fixing.
- With `build=standard` the packager ignores the rest of `build.gradle`, but `AGENTS.md` still asks for the template's structure. Port the blocks above when the user wants it, keeping the repo's `group` and `version`.
- Always commit build changes separately from feature work.

## Running the dev client

`./gradlew run` starts RuneLite with the plugin side-loaded, plus `-ea --developer-mode --debug`. It blocks until the client window closes, so start it in the background.

- The launcher is the test class: `ExternalPluginManager.loadBuiltin(MyPlugin.class); RuneLite.main(args);`. `loadBuiltin` is varargs, so it can also load a dev-only plugin from `src/test` (see [`structure.md`](structure.md)).
- If the repo has no `run` task, add the block above. The alternative is an IntelliJ Application config on the test class with VM options `-ea` and program args `--developer-mode --debug`. A `.run/<Name>.run.xml` committed to the repo shares that config.
- `--developer-mode` enables the dev tools sidebar ([`devtools.md`](devtools.md)). `--debug` sets the root logger to DEBUG, which is noisy, so drop it to see only the plugin's package logger.
- `--profile <name>` runs with a separate RuneLite config profile, which keeps dev settings out of the user's main profile.

## Logging in with a Jagex account

A dev client cannot log a Jagex Account in directly. The user does the following once:

1. Use RuneLite launcher **2.6.3+**. Open its configure dialog: on Windows that's `RuneLite (configure)`; elsewhere, launch it with `--configure`.
2. Add `--insecure-write-credentials` to *Client arguments*, then Save.
3. Launch RuneLite via the Jagex launcher once. This writes `~/.runelite/credentials.properties`.
4. The dev client (`./gradlew run`) now logs in with it.

`credentials.properties` logs into the account without a password. Leave it untouched: never read, print, copy or commit it. To revert, delete the file. *End sessions* in runescape.com account settings revokes it.

## Logging

- Put `@Slf4j` (lombok) on the class. For levels, follow `AGENTS.md` *Logging*.
- Logs go to the console and to `~/.runelite/logs/client.log`.
- The logback config must stay in `src/test/resources`, never `src/main`, or it ships inside the plugin.
- In dev mode, `::logger debug` in the chatbox changes the root level at runtime.

## Core client (rare)

Core PRs are reserved for bug fixes and small features. Discuss anything large in `#development` on the RuneLite Discord before writing it.

- Fork `runelite/runelite` and use JDK 11. Main class: `net.runelite.client.RuneLite`.
- Hub plugins won't load on a snapshot build. Add VM option `-Drunelite.pluginhub.version=<current release>` to load them.
- White or black screen on start: `./gradlew :cleanAll`. Failing tests: delete the `cache-165` dir in the temp folder.
- macOS on JDK 17+ needs `--add-opens=java.desktop/com.apple.eawt=ALL-UNNAMED`.
- The style rules in [`structure.md`](structure.md) are enforced here by checkstyle.
