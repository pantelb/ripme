# RipMe Flutter Full Migration Audit

This file is the fresh, from-the-beginning parity ledger for the Flutter migration.
`MIGRATION_STATUS.md` remains the completed ripper-port ledger; this audit tracks
the whole Java desktop application surface against the Flutter app.

Current branch baseline:

- Branch: `Flutter`
- Legacy source of truth: `origin/main`
- Latest completed ripper/catalog state: every Java ripper in the tracked catalog is ported
- Required verification before marking implementation work complete:
  - Read the Java source and related Java tests first
  - Add or update focused Dart tests for Java-compatible behavior
  - Run targeted tests
  - Run `flutter analyze --no-pub`
  - Run `flutter test --no-pub --reporter expanded`
  - Commit and push each completed unit
  - Watch GitHub Actions and collect Android, Windows, macOS, and Linux artifact links

## Audit Rules

- Do not assume parity from existing Flutter code.
- Every checked item must name the Java source file(s) used for comparison.
- Mark an item `[x]` only after behavior is implemented and covered by tests.
- Use `[~]` for partially implemented behavior that still has known gaps.
- Use `[ ]` for untouched or unverified behavior.
- Prefer small, independently verified commits over broad mixed changes.
- Do not start implementation from a workstream until its Java source files and
  current Flutter counterparts are listed in this file.
- Do not remove a gap from this file without either linking it to a completed
  commit or writing why it is intentionally not applicable to Flutter.

## Completion Definition

The migration is complete only when all of these are true:

- [ ] Every Java production source file under `src/main/java/com/rarchives/ripme`
      is either ported, replaced by a documented Flutter-native equivalent, or
      explicitly marked not applicable.
- [ ] Every Java resource under `src/main/resources` is either carried forward,
      replaced by a documented Flutter-native equivalent, or explicitly marked
      not applicable.
- [ ] Every Java test behavior under `src/test/java/com/rarchives/ripme`
      has a focused Dart test, a broader integration/widget test, or a written
      reason why it no longer applies.
- [ ] All tracked Java rippers remain represented in
      `RipperMigrationCatalog.legacyRipperClasses`, and source-tree
      reconciliation proves there are no missing Java rippers.
- [ ] The Flutter app supports Windows, Linux, macOS, and Android through
      GitHub Actions artifacts for the final commit.
- [ ] `flutter analyze --no-pub` passes.
- [ ] `flutter test --no-pub --reporter expanded` passes.
- [ ] GitHub Actions passes for the final commit.

## Full Java Source Inventory

This inventory is the authoritative starting point for the second migration
pass. Each file must be touched by an audit entry before the migration is called
done.

### Application Controller

- [~] `src/main/java/com/rarchives/ripme/App.java`
  - Current finding: Flutter has GUI startup only; Java CLI/headless behavior
    still needs porting or an explicit replacement.

### Core Ripper Runtime

- [~] `src/main/java/com/rarchives/ripme/ripper/AbstractRipper.java`
- [~] `src/main/java/com/rarchives/ripme/ripper/AbstractHTMLRipper.java`
- [~] `src/main/java/com/rarchives/ripme/ripper/AbstractJSONRipper.java`
- [~] `src/main/java/com/rarchives/ripme/ripper/AbstractSingleFileRipper.java`
- [~] `src/main/java/com/rarchives/ripme/ripper/AlbumRipper.java`
- [~] `src/main/java/com/rarchives/ripme/ripper/VideoRipper.java`
- [~] `src/main/java/com/rarchives/ripme/ripper/DownloadFileThread.java`
- [~] `src/main/java/com/rarchives/ripme/ripper/DownloadVideoThread.java`
- [~] `src/main/java/com/rarchives/ripme/ripper/DownloadThreadPool.java`
- [~] `src/main/java/com/rarchives/ripme/ripper/RipperInterface.java`
  - Current finding: major behavior exists in Flutter, but
    append-to-folder, description saving, progress percentage semantics,
    URL-only edge cases, and exact status events need dedicated audit rows.

### Java UI Layer

- [~] `src/main/java/com/rarchives/ripme/ui/MainWindow.java`
- [~] `src/main/java/com/rarchives/ripme/ui/ClipboardUtils.java`
- [~] `src/main/java/com/rarchives/ripme/ui/ContextMenuMouseListener.java`
- [~] `src/main/java/com/rarchives/ripme/ui/History.java`
- [~] `src/main/java/com/rarchives/ripme/ui/HistoryEntry.java`
- [~] `src/main/java/com/rarchives/ripme/ui/HistoryMenuMouseListener.java`
- [~] `src/main/java/com/rarchives/ripme/ui/QueueMenuMouseListener.java`
- [~] `src/main/java/com/rarchives/ripme/ui/RipStatusComplete.java`
- [~] `src/main/java/com/rarchives/ripme/ui/RipStatusHandler.java`
- [~] `src/main/java/com/rarchives/ripme/ui/RipStatusMessage.java`
- [~] `src/main/java/com/rarchives/ripme/ui/UpdateUtils.java`
  - Current finding: Flutter has broad UI equivalents, but exact queue,
    history, tray, popup, clipboard, open-folder, re-rip, update, and status
    behavior need pass-by-pass verification.

### Java UI Utilities

- [~] `src/main/java/com/rarchives/ripme/uiUtils/ContextActionProtections.java`
  - Current finding: Java replaces the entire text component from the system
    clipboard for protected paste/Ctrl+V paths; Flutter text-field behavior
    needs an intentional native-replacement decision and exact widget tests.

### Java Utility Layer

- [~] `src/main/java/com/rarchives/ripme/utils/Base64.java`
- [~] `src/main/java/com/rarchives/ripme/utils/Http.java`
- [~] `src/main/java/com/rarchives/ripme/utils/Proxy.java`
- [~] `src/main/java/com/rarchives/ripme/utils/RipUtils.java`
- [~] `src/main/java/com/rarchives/ripme/utils/UTF8Control.java`
- [~] `src/main/java/com/rarchives/ripme/utils/Utils.java`
  - Current finding: many utility behaviors are represented in Flutter, but
    SOCKS proxy, config file location behavior, logger/file output, Java
    filesystem sanitization quirks, and remaining `RipUtils` helpers need
    focused audit coverage.

### Ripper Catalog And Helpers

- [x] `src/main/java/com/rarchives/ripme/ripper/rippers/*.java`
- [~] `src/main/java/com/rarchives/ripme/ripper/rippers/video/*.java`
- [~] `src/main/java/com/rarchives/ripme/ripper/rippers/ripperhelpers/ChanSite.java`
  - Current finding: all tracked Java rippers are ported, but a final
    source-tree reconciliation must compare Java files against
    `RipperMigrationCatalog.legacyRipperClasses` and factory coverage.

### Resources

- [~] `src/main/resources/LabelsBundle*.properties`
- [ ] `src/main/resources/camera.wav`
- [ ] `src/main/resources/comment.png`
- [ ] `src/main/resources/folder.png`
- [ ] `src/main/resources/gear.png`
- [ ] `src/main/resources/icon.ico`
- [ ] `src/main/resources/icon.png`
- [ ] `src/main/resources/list.png`
- [ ] `src/main/resources/log4j.file.properties`
- [ ] `src/main/resources/log4j2-example.xml`
- [~] `src/main/resources/rip.properties`
- [ ] `src/main/resources/stop.png`
- [ ] `src/main/resources/time.png`
- [ ] `src/main/resources/wrench.png`
  - Current finding: localization and defaults are partly carried forward;
    sound/icon/logging resource parity needs a platform/resource audit.

### Java Tests To Reconcile

- [~] `src/test/java/com/rarchives/ripme/tst/AbstractRipperTest.java`
- [~] `src/test/java/com/rarchives/ripme/tst/Base64Test.java`
- [~] `src/test/java/com/rarchives/ripme/tst/UtilsTest.java`
- [~] `src/test/java/com/rarchives/ripme/tst/proxyTest.java`
- [~] `src/test/java/com/rarchives/ripme/tst/ui/LabelsBundlesTest.java`
- [~] `src/test/java/com/rarchives/ripme/tst/ui/RipStatusMessageTest.java`
- [~] `src/test/java/com/rarchives/ripme/tst/ripper/rippers/*Test.java`
- [~] `src/test/java/com/rarchives/ripme/ui/RipButtonHandlerTest.java`
- [~] `src/test/java/com/rarchives/ripme/ui/UIContextMenuTests.java`
- [~] `src/test/java/com/rarchives/ripme/ui/UpdateUtilsTest.java`
  - Current finding: the ripper tests have broad Dart equivalents; the
    non-ripper and UI Java tests need reconciliation against Flutter utility,
    localization, status-message, update-checker, and widget tests.

## Workstream Plan

Workstreams are ordered. Do not jump ahead unless the current workstream is
blocked by platform constraints or missing user input.

### Workstream 0: Inventory And Baseline

- [x] Create this fresh full-app audit file.
- [~] Reconcile all Java production files with this inventory.
- [~] Reconcile all Java resources with this inventory.
- [~] Reconcile all Java tests with Dart tests.
- [ ] Add a script or test that fails when a Java ripper exists without a
      catalog entry.
- [ ] Add a script or test that fails when a Java-used config key has no Flutter
      default, migration alias, or documented intentional removal.
- [ ] Add a script or test that fails when a Java localized key has no Flutter
      lookup, generated localization mapping, or documented intentional removal.
- [ ] Add a script or test that fails when a Java test class has no Dart test,
      alias mapping, broader integration test, or documented intentional removal.
- [x] Record latest passing Actions run and artifacts for the first inventory commit.

### Workstream 1: CLI And Headless Mode

Java source:

- `src/main/java/com/rarchives/ripme/App.java`

Flutter targets:

- `lib/main.dart`
- new CLI/controller files if needed
- `lib/rip_manager.dart`
- `lib/utils/utils.dart`
- `lib/history_provider.dart`

Parity checklist:

- [ ] Detect CLI/headless invocation before launching `MaterialApp`.
- [ ] Verify desktop runner argument plumbing on every platform before CLI
      parity is claimed. Windows `main.cpp` and Linux `my_application.cc` pass
      command-line arguments into Dart, but macOS `MainFlutterWindow.swift`
      creates a default `FlutterViewController` with no Dart entrypoint
      arguments, and `lib/main.dart` currently accepts no `List<String> args`
      and always launches `MaterialApp`.
- [ ] Print Java-compatible help text for `-h` / `--help`.
- [ ] Print Flutter app version for `-v` / `--version`.
- [ ] Support single URL ripping through `-u` / `--url`.
- [ ] Support URL-file ripping through `-f` / `--urls-file`.
- [ ] Skip URL-file lines beginning with `//` or `#`.
- [ ] Apply `-t` / `--threads` to `threads.size`.
- [ ] Apply `-w` / `--overwrite` to `file.overwrite`.
- [ ] Apply `-d` / `--saveorder` to `download.save_order=true`.
- [ ] Apply `-D` / `--nosaveorder` to `download.save_order=false`.
- [ ] Reject simultaneous `-d` and `-D`.
- [ ] Apply `-4` / `--skip404` to the same config key used by Flutter HTTP.
- [ ] Apply `-l` / `--ripsdirectory` to `rips.directory`.
- [ ] Define and test `-n` / `--no-prop-file` semantics for Flutter. Java
      accepts the option and passes `!cl.hasOption("n")` into `ripURL`, but
      `ripURL(String targetURL, boolean saveConfig)` never reads `saveConfig`;
      the current Java behavior is effectively a no-op despite the help text.
- [ ] Support `-p` / `--proxy-server` for HTTP proxy strings.
- [ ] Support or explicitly reject `-s` / `--socks-server` with a documented
      platform reason.
- [ ] Support `-a` / `--append-to-folder` or document a replacement.
- [ ] Support `-H` / `--history` or document a replacement.
- [ ] Support `-r` / `--rerip` for all history entries.
- [ ] Support `-R` / `--rerip-selected` or document how selected history is
      represented in Flutter.
- [ ] Replace Java `-j` updater behavior with the Flutter GitHub release
      checker or explicitly document why CLI self-update is not applicable.

Required tests:

- [ ] CLI parser unit tests for every option.
- [ ] Config side-effect tests for options that mutate settings.
- [ ] URL-file parsing tests.
- [ ] Headless single-URL smoke test using a fake ripper resolver.
- [ ] History re-rip tests.

### Workstream 2: Main Window Input And Queue

Java source:

- `src/main/java/com/rarchives/ripme/ui/MainWindow.java`
- `src/main/java/com/rarchives/ripme/ui/QueueMenuMouseListener.java`

Flutter targets:

- `lib/main.dart`
- `lib/rip_manager.dart`

Parity checklist:

- [ ] Manual URL submission rejects duplicate queue entries like Java.
- [ ] Manual URL submission expands `{start-end}` numeric ranges like Java.
- [ ] Invalid range syntax reports an error without queueing garbage.
- [ ] URL text-field validation detects ripper host and unrippable URLs.
- [ ] Queue count is visible and updates like Java's `queue(n)` label.
- [ ] Queue is saved to config after updates.
- [ ] Queue is restored from config at startup.
- [ ] Queue clear/remove behavior matches Java context-menu actions.
- [ ] Stop interrupts current rip and leaves remaining queue behavior documented.

Required tests:

- [ ] Unit tests for queue duplicate/range parsing.
- [ ] `RipManager` tests for queue persistence/restoration.
- [ ] Widget tests for URL validation/status display.

### Workstream 3: History And Re-Rip

Java source:

- `src/main/java/com/rarchives/ripme/ui/History.java`
- `src/main/java/com/rarchives/ripme/ui/HistoryEntry.java`
- `src/main/java/com/rarchives/ripme/ui/HistoryMenuMouseListener.java`
- `src/main/java/com/rarchives/ripme/App.java`
- `src/main/java/com/rarchives/ripme/ui/MainWindow.java`

Flutter targets:

- `lib/history_provider.dart`
- `lib/download_history_provider.dart`
- `lib/rip_manager.dart`
- `lib/main.dart`

Parity checklist:

- [ ] Preserve Java history fields: URL, directory, title, created/modified
      dates, and selected state where applicable.
- [ ] Preserve Java table columns and display semantics: URL, created date,
      modified date, count, and selected checkbox.
- [ ] Preserve Java history JSON timestamp semantics: `startDate` and
      `modifiedDate` are epoch milliseconds.
- [ ] Preserve Java `toJSON()` quirk: `dir` is read from imported JSON but not
      written by Java, or document a deliberate Flutter format extension.
- [ ] Import Java `history.json` without data loss.
- [ ] Export history in a documented format.
- [ ] Support remove, clear, open folder, copy URL, and re-rip actions.
- [ ] Support selected-entry re-rip or document why selected state is removed.
- [ ] Support Java fallback history guessing from existing rip directories or
      document why Flutter does not.
- [ ] Support configurable history location or document replacement behavior.
- [ ] Keep downloaded-URL history behavior distinct from album history.

Required tests:

- [ ] Java history fixture import tests.
- [ ] History selected-state tests.
- [ ] Re-rip queueing tests.
- [ ] Configured history location tests if supported.

### Workstream 4: Configuration And Preferences

Java source:

- `src/main/java/com/rarchives/ripme/utils/Utils.java`
- `src/main/resources/rip.properties`
- `src/main/java/com/rarchives/ripme/ui/MainWindow.java`

Flutter targets:

- `lib/config_defaults.dart`
- `lib/utils/utils.dart`
- `lib/main.dart`

Parity checklist:

- [ ] Reconcile every key in Java `rip.properties` with Flutter defaults.
- [ ] Reconcile every Java config key used anywhere in `src/main/java`, not
      only keys present in `rip.properties`.
- [ ] Reconcile every Java configuration control with Flutter UI.
- [ ] Reconcile hidden/runtime-only keys not exposed in UI.
- [ ] Support Java portable config mode when `rip.properties` exists next to the
      app, or document a Flutter-native replacement.
- [ ] Support Java platform config directories:
      Windows `%LOCALAPPDATA%/ripme`, macOS `~/Library/Application Support/ripme`,
      Unix `~/.config/ripme`, or document replacement behavior.
- [ ] Reconcile Java default rip directory (`<jar directory>/rips`) with
      Flutter's current app-documents default.
- [ ] Reconcile Java old-config deletion/reload behavior when required keys are
      missing.
- [ ] Persist settings on exit or immediately in a documented Flutter-native way.
- [ ] Support language selection and reload behavior.
- [ ] Support save directory selection across desktop and Android.
- [ ] Support window position persistence or explicitly mark not applicable.
- [ ] Support log level, log save, popup, sound, URLs-only, album-title folders,
      descriptions, prefer MP4, SSL verification, URL history, retries, timeout,
      retry sleep, thread count, overwrite, and save order.
- [ ] Support or intentionally retire finish commands:
      `enable.finish.command` and `finish.command`.
- [ ] Support or intentionally retire history deletion warning:
      `history.warn_before_delete`.
- [ ] Support or intentionally retire Java auto-update preference:
      `auto.update`.
- [ ] Support or intentionally retire window geometry keys:
      `window.position`, `window.x`, `window.y`, `window.w`, `window.h`.

Required tests:

- [ ] Defaults reconciliation test against Java `rip.properties`.
- [ ] Config UI widget tests for every exposed setting.
- [ ] Persistence tests for settings changed in UI and CLI.

### Workstream 5: HTTP, Proxy, Cookies, And Networking

Java source:

- `src/main/java/com/rarchives/ripme/utils/Http.java`
- `src/main/java/com/rarchives/ripme/utils/Proxy.java`
- `src/main/java/com/rarchives/ripme/utils/Utils.java`

Flutter targets:

- `lib/utils/http_utils.dart`
- `lib/utils/utils.dart`
- `lib/config_defaults.dart`

Parity checklist:

- [ ] Verify user-agent parity.
- [ ] Verify retry count and retry sleep behavior.
- [ ] Verify timeout behavior for pages and downloads.
- [ ] Verify skip-404 config key spelling and semantics against Java.
- [ ] Verify max download size behavior.
- [ ] Verify configured domain cookies.
- [ ] Verify Java configured-cookie lookup and parsing exactly: `cookies.<host>`
      lookup checks parent domains and parses semicolon-delimited key/value
      pairs through `RipUtils.getCookiesFromString`.
- [ ] Verify per-download cookies and referer headers.
- [ ] Verify Java CLI/config proxy strings `[user:password]@host[:port]` through
      `proxy.http` and `proxy.socks`, including authenticated proxy behavior.
- [ ] Verify HTTP proxy host/port/auth.
- [ ] Port SOCKS proxy support or explicitly mark not applicable.
- [ ] Verify SSL verification toggle behavior.
- [ ] Verify Java SSL verification toggle actually disables/enables certificate
      and hostname verification for Jsoup calls.
- [ ] Verify content-type-tolerant JSON/HTML parsing.
- [ ] Verify Java `Http` chainable request APIs: `ignoreContentType`,
      `referrer`, `userAgent`, `header`, `cookies`, `data`, `method`, `post`,
      `getJSON`, and `getJSONArray`.
- [ ] Verify Java HTTP error messages: 401/403 cookie guidance, 404 file-not-found
      handling, and non-retriable/retriable status text.
- [ ] Verify Java retry attempt counts. `Http` uses exactly the configured
      number of attempts, while Flutter currently loops `attempt <= retries`.
- [ ] Verify rate-limit `Retry-After` handling.

Required tests:

- [ ] HTTP unit tests for each checklist item.
- [ ] Proxy parsing tests for Java CLI strings.
- [ ] Cookie precedence tests.

### Workstream 6: Download Engine And Status Semantics

Java source:

- `src/main/java/com/rarchives/ripme/ripper/AbstractRipper.java`
- `src/main/java/com/rarchives/ripme/ripper/AbstractHTMLRipper.java`
- `src/main/java/com/rarchives/ripme/ripper/DownloadThreadPool.java`
- `src/main/java/com/rarchives/ripme/ripper/DownloadFileThread.java`
- `src/main/java/com/rarchives/ripme/ripper/DownloadVideoThread.java`
- `src/main/java/com/rarchives/ripme/ui/RipStatusMessage.java`
- `src/main/java/com/rarchives/ripme/ui/RipStatusComplete.java`

Flutter targets:

- `lib/ripper/abstract_ripper.dart`
- `lib/ripper/abstract_html_ripper.dart`
- `lib/ripper/abstract_json_ripper.dart`
- `lib/ripper/abstract_video_ripper.dart`
- `lib/rip_manager.dart`
- `lib/ui/rip_status_message.dart`

Parity checklist:

- [ ] Verify working directory naming and sanitization.
- [ ] Verify Java `Utils.filesystemSafe`: remove characters outside
      `[a-zA-Z0-9-.,_ ]`, trim, and truncate names longer than 100 characters
      to 99.
- [ ] Verify Java `Utils.filesystemSanitized`: replace characters outside
      `[a-zA-Z0-9.-]` with `_`.
- [ ] Verify Java `Utils.sanitizeSaveAs`: replace `\\:*?"<>|` with `_` and
      preserve the Java filename-extension edge cases from `AbstractRipperTest`.
- [ ] Verify Java case-preserving existing directory behavior from
      `Utils.getOriginalDirectory`.
- [ ] Verify Java Windows path shortening behavior from `shortenSaveAsWindows`.
- [ ] Port or document `append-to-folder`.
- [ ] Verify `album_titles.save` behavior.
- [ ] Verify `descriptions.save` behavior.
- [ ] Verify URL-only output path and append behavior.
- [ ] Verify duplicate URL suppression scope.
- [ ] Verify already-downloaded URL skip counter and stopping threshold.
- [ ] Verify Java writes downloaded URL history before queueing a download and
      skips URL-history writes while `urls_only.save=true`.
- [ ] Verify stop/interruption semantics.
- [ ] Verify progress percentage semantics.
- [ ] Verify Java byte-progress semantics for `AbstractSingleFileRipper` and
      `VideoRipper`, including human-readable text.
- [ ] Verify status text/log event text.
- [ ] Verify video download filename/referrer/cookie behavior.
- [ ] Verify ignored extension behavior.
- [ ] Verify Java empty working-directory cleanup after a failed or empty rip.
- [ ] Verify Java gaussian jitter applied to ripper sleeps.
- [ ] Verify Java MIME/magic-number extension detection for
      `getFileExtFromMIME`.

Required tests:

- [ ] Abstract ripper directory naming tests.
- [ ] Status/progress event tests.
- [ ] Stop semantics tests.
- [ ] Description and URL-only tests.

### Workstream 7: UI Details, Context Actions, Tray, And Desktop Integration

Java source:

- `src/main/java/com/rarchives/ripme/ui/MainWindow.java`
- `src/main/java/com/rarchives/ripme/ui/ClipboardUtils.java`
- `src/main/java/com/rarchives/ripme/ui/ContextMenuMouseListener.java`
- `src/main/java/com/rarchives/ripme/ui/HistoryMenuMouseListener.java`
- `src/main/java/com/rarchives/ripme/ui/QueueMenuMouseListener.java`
- `src/main/java/com/rarchives/ripme/uiUtils/ContextActionProtections.java`

Flutter targets:

- `lib/main.dart`
- platform directories as needed

Parity checklist:

- [ ] Verify log filtering, copying, clearing, and display order.
- [ ] Verify history context actions.
- [ ] Verify queue context actions.
- [ ] Verify text-field context action protections or Flutter equivalent.
- [ ] Verify clipboard autorip duplicate handling.
- [ ] Verify Java clipboard autorip polls every 1000 ms, matches only the first
      URL pattern in clipboard text, keeps a per-session `rippedURLs` set, and
      starts ripping immediately through `MainWindow.ripAlbumStatic`.
- [ ] Verify tray icon/menu support or document platform-native replacement.
- [ ] Verify popup notification behavior or document replacement.
- [ ] Verify open-folder button behavior after completion.
- [ ] Verify keyboard interactions.
- [ ] Verify responsive layout across desktop and Android.

Required tests:

- [ ] Widget tests for log/history/queue actions.
- [ ] Clipboard autorip tests.
- [ ] Platform integration tests where practical.

### Workstream 8: Localization And Resources

Java source:

- `src/main/resources/LabelsBundle*.properties`
- `src/main/java/com/rarchives/ripme/utils/UTF8Control.java`
- `src/main/resources/*.png`
- `src/main/resources/*.wav`
- `src/main/resources/*.ico`

Flutter targets:

- `assets/`
- `lib/l10n/app_localizations.dart`
- platform launcher/resource files

Parity checklist:

- [ ] Verify every Java label key has a Flutter lookup or documented removal.
- [ ] Verify locale list matches Java bundles.
- [ ] Verify Java bundle parity test behavior: non-default bundles may omit
      keys, but any keys they contain must exist in the default bundle.
- [ ] Verify language switching behavior.
- [ ] Verify icon resources on Windows, Linux, macOS, and Android.
- [ ] Verify completion sound uses Java `camera.wav` or a documented platform
      replacement.
- [ ] Verify resource licensing/packaging.

Required tests:

- [ ] Localization key coverage test.
- [ ] Asset existence test.
- [ ] Platform metadata checks where scriptable.

### Workstream 9: Update, Release, Packaging, And Platform Behavior

Java source:

- `src/main/java/com/rarchives/ripme/ui/UpdateUtils.java`
- Java Gradle/build scripts

Flutter targets:

- `lib/update_checker.dart`
- `.github/workflows/`
- `android/`
- `linux/`
- `macos/`
- `windows/`
- `pubspec.yaml`

Parity checklist:

- [ ] Verify update check behavior against Java expectations.
- [ ] Document replacement for Java self-update.
- [ ] Document Java updater source of truth (`ripmeapp/ripme` `ripme.json`),
      changelist handling, SHA-256 update verification, and why jar replacement
      scripts are or are not applicable to Flutter.
- [ ] Verify version display and build number.
- [ ] Verify release artifact naming.
- [ ] Verify Android permissions and storage behavior.
- [ ] Verify macOS entitlements and minimum OS behavior.
- [ ] Verify Linux metadata and executable packaging.
- [ ] Verify Windows metadata, icon, and executable packaging.
- [ ] Verify workflow separation between CI and release.

Required tests:

- [ ] Update checker tests.
- [ ] Workflow/artifact verification by GitHub Actions.
- [ ] Platform config lint or script checks where practical.

### Workstream 10: Final Ripper Reconciliation

Java source:

- `src/main/java/com/rarchives/ripme/ripper/rippers/**/*.java`
- `src/test/java/com/rarchives/ripme/tst/ripper/rippers/**/*Test.java`

Flutter targets:

- `lib/ripper/rippers/*.dart`
- `lib/ripper/ripper_factory.dart`
- `lib/ripper/ripper_migration_catalog.dart`
- `test/*_ripper_test.dart`

Parity checklist:

- [x] Generate/verify list of Java rippers from source tree.
- [x] Compare generated list to `legacyRipperClasses`.
- [x] Compare `legacyRipperClasses` to `portedRipperClasses`.
- [ ] Verify each port has focused Dart tests.
- [ ] Verify factory can resolve every supported Java URL shape used in tests.
- [ ] Verify no placeholder/scaffold-only rippers remain.
- [ ] Verify video-subpackage Java rippers are represented.
- [ ] Verify helper classes such as `ChanSite` are represented.

Required tests:

- [~] Catalog reconciliation test.
- [ ] Factory coverage test.
- [ ] Any missing helper behavior tests.

## Deep Source Parity Findings

This section records concrete parity differences found by reading Java source
from `origin/main` and comparing it with current Flutter files. Items here are
source-backed and must either become implementation tasks or be explicitly
documented as intentional Flutter differences.

### A. Application, CLI, And Queue

Java sources read:

- `src/main/java/com/rarchives/ripme/App.java`
- `src/main/java/com/rarchives/ripme/ui/MainWindow.java`
- `src/main/java/com/rarchives/ripme/ui/QueueMenuMouseListener.java`

Flutter files checked:

- `lib/main.dart`
- `lib/rip_manager.dart`
- `lib/utils/utils.dart`

Findings:

- [ ] Flutter does not yet provide Java-compatible CLI/headless mode. Java
      enters CLI mode when the environment is headless or any CLI args are
      present, then supports URL ripping, URL-file ripping, history re-rip,
      selected-history re-rip, proxy flags, save-order flags, overwrite,
      skip-404, custom rips directory, no-property-file mode, append-to-folder,
      and updater mode.
- [ ] Java URL-file ripping skips lines beginning with `//` and `#`; Flutter
      needs parser tests for that exact behavior.
- [ ] Java CLI URL-file mode does not skip blank or whitespace-only lines:
      only raw lines starting with `//` or `#` are treated as comments, and
      every other line is trimmed and passed to `ripURL`.
- [ ] Java `-n` / `--no-prop-file` behavior must be treated as source-backed
      current behavior, not just help-text intent: `App.ripURL` receives but
      ignores its `saveConfig` argument, so history/config writes still follow
      the normal Java code paths.
- [ ] Java manual URL input rejects duplicate queue entries and expands
      `{start-end}` numeric ranges before enqueueing. Flutter currently queues
      the submitted URL string through `RipManager` and needs parity tests.
- [ ] Java persists queue state through the `queue` config key on updates and
      restores it on startup. Flutter queue persistence/restoration needs to be
      implemented or intentionally replaced.
- [ ] Java queue persistence has a shipped empty-queue edge case:
      `MainWindow.updateQueue(...)` only calls `Utils.setConfigList("queue",
      ...)` and `Utils.saveConfig()` when `model.size() > 0`. Removing the last
      queued item or using the queue context menu's remove-all action updates
      the in-memory model/label but can leave stale persisted `queue` config
      entries for the next startup. Flutter currently has no queue persistence,
      so parity needs a choice between matching this bug, fixing it with a
      migration note, or documenting retirement.
- [ ] Java queue context menu supports remove selected and remove all with a
      confirmation dialog. Flutter queue actions need matching widget coverage.
- [ ] Java `QueueMenuMouseListener` has no copy or reorder actions; it only
      removes selected queue entries or clears all entries after
      `queue.validation` confirmation. Flutter `QueueView` exposes copy,
      move-up, and move-down actions for individual queue rows, so the queue UI
      currently has extra behavior that needs an intentional parity decision.
- [ ] Java `-a` appends text to the rip working-folder name through
      `App.stringToAppendToFoldername`; Flutter has no verified equivalent.
- [ ] Java `-j` self-update replaces a jar on disk. Flutter should document the
      GitHub-release/update-checker replacement and not silently mark this as
      parity.
- [ ] Java `ripAlbum` normalizes user input by converting `gonewild:<name>` to
      `http://gonewild.com/user/<name>` and prepending `http://` when no scheme
      is supplied. Flutter URL input needs exact coverage or an intentional
      replacement.
- [ ] Java URL-list file chooser in the GUI queues only trimmed lines starting
      with `http` and logs malformed lines; CLI URL-file mode has different
      comment-skipping behavior. Flutter must preserve or document both paths.

### B. Configuration And Defaults

Java sources/resources read:

- `src/main/java/com/rarchives/ripme/utils/Utils.java`
- `src/main/resources/rip.properties`

Flutter files checked:

- `lib/config_defaults.dart`
- `lib/utils/utils.dart`
- `lib/main.dart`

Findings:

- [ ] Java config file name is `rip.properties`; Flutter stores settings in
      SharedPreferences. Migration/import behavior from existing Java
      `rip.properties` needs a decision and tests.
- [ ] Java portable mode uses a `rip.properties` file next to the jar/current
      working directory. Flutter does not yet verify or support portable mode.
- [ ] Java config directory resolution is platform-specific:
      `%LOCALAPPDATA%/ripme` on Windows, `~/Library/Application Support/ripme`
      on macOS, `~/.config/ripme` on Unix. Flutter currently uses
      SharedPreferences and app documents for the default rips folder.
- [ ] Java default working directory is the jar directory plus `rips/`, with the
      jar directory derived from `java.class.path` or `user.dir` and fallback to
      `user.home` when creation fails. Flutter currently defaults to app
      documents/external storage plus `rips`.
- [ ] Java deletes and reloads old configs missing required keys such as
      `twitter.auth`, `tumblr.auth`, or `download.max_size`. Flutter needs a
      compatibility or migration story.
- [ ] Java default `download.retry.sleep` is absent from `rip.properties` and
      call sites commonly default to `0`; Flutter default is `5000`. This is a
      concrete behavior difference.
- [ ] Java parallel download defaults use `Utils.getConfigInteger("threads.size",
      10)` in `DownloadThreadPool`, so a missing config runs up to ten download
      workers. Flutter `config_defaults.dart` sets `threads.size` to `5`, and
      `AbstractRipper.downloadFiles(...)` also falls back to `5`, cutting the
      default concurrency in half.
- [ ] Java uses both `error.skip404` in defaults and some code paths checking
      `errors.skip404`; Flutter uses `error.skip404`. The typo/alias behavior
      must be reconciled for CLI and download paths.
- [ ] Java `Utils.getConfigStringArray(key)` returns `null` when
      `PropertiesConfiguration.getStringArray(key)` has length zero. Flutter
      `Utils.getConfigStringList(key)` returns an empty list for missing or
      blank values. Callers that distinguish `null` from empty lists, including
      Java `RipUtils.checkTags(...)` and ignored-extension plumbing, need exact
      compatibility tests or a deliberate replacement decision.
- [ ] Java `album_titles.save=false` only changes `AbstractJSONRipper`
      directory naming: `AbstractJSONRipper.setWorkingDir(...)` falls back to
      `super.getAlbumTitle(this.url)`, while `AbstractHTMLRipper.setWorkingDir(...)`
      always calls the concrete `getAlbumTitle(...)`. Flutter
      `AbstractRipper.setup()` always calls each Dart ripper's
      `getAlbumTitle(...)`, so JSON rippers do not honor Java's no-album-title
      fallback and HTML rippers are not distinguished from JSON rippers.
- [ ] Java `TwitterRipper` defaults `twitter.rip_retweets` to `true` through
      `Utils.getConfigBoolean("twitter.rip_retweets", true)`. Flutter's
      `config_defaults.dart` sets `twitter.rip_retweets` to `false`, so the
      default Twitter media set is narrower than Java unless the user changes
      the setting.
- [ ] Java `history.location` controls downloaded-URL history
      (`url_history.txt`), not the album history JSON. Flutter currently stores
      downloaded URLs in SharedPreferences unless explicitly imported/exported.
- [ ] Java has config-driven log level and `log.save` file logging behavior.
      Flutter log display exists but rolling file output is not verified.
- [ ] Mechanical source scan found Java-used config keys missing from Flutter
      defaults and therefore requiring parity decisions:
      `DeviantartCustomLoginPassword`, `DeviantartCustomLoginUsername`,
      `auto.update`, `chans.chan_sites`, dynamic `cookies.<domain>`,
      `derpi.key`, `descriptions.save`, `download.history`,
      `download.show_popup`, `e621.cookies`, `e621.useragent`,
      `ehentai.blacklist.tags`, `enable.finish.command`, `errors.skip404`,
      `finish.command`, `furaffinity.cookies`, `furaffinity.login`,
      `hentai-foundry.filter_order`, `hentai-foundry.use_prefix`,
      `history.location`, `history.warn_before_delete`, `imgur.client_id`,
      `instagram.download_images_only`, `instagram.session_id`, `lang`,
      `log.level`, `log.save`, `nhentai.blacklist.tags`, `prefer.mp4`,
      `proxy.http`, `proxy.socks`, `queue`, `rips.directory`,
      `security.check_update_hash`, `ssl.verify.off`,
      `testing.always_try_to_update`, `twitter.max_items_request`,
      `window.h`, `window.position`, `window.w`, `window.x`, and `window.y`.
- [ ] Mechanical source scan also found Java-used config keys that do exist in
      Flutter defaults but still require explicit Java-behavior verification:
      `clipboard.autorip`, `download.retries`, `download.timeout`,
      `page.timeout`, `play.sound`, Reddit upvote/subdirectory keys
      (`reddit.rip_by_upvote`, `reddit.min_upvotes`, `reddit.max_upvotes`,
      `reddit.use_sub_dirs`), and `remember.url_history`.
- [ ] Mechanical source scan also found Flutter-only replacement keys requiring
      mapping notes: `error.skip404` versus Java `errors.skip404`,
      `history.skip_downloaded_urls`, `proxy.enabled`, `proxy.host`,
      `proxy.port`, `proxy.username`, and `proxy.password`.

### C. History And Re-Rip

Java sources read:

- `src/main/java/com/rarchives/ripme/ui/History.java`
- `src/main/java/com/rarchives/ripme/ui/HistoryEntry.java`
- `src/main/java/com/rarchives/ripme/ui/HistoryMenuMouseListener.java`

Flutter files checked:

- `lib/history_provider.dart`
- `lib/download_history_provider.dart`
- `lib/rip_manager.dart`
- `lib/main.dart`

Findings:

- [ ] Java album history fields are `url`, `title`, `dir`, `count`,
      `startDate`, `modifiedDate`, and `selected`. Flutter `HistoryEntry`
      currently stores `url`, `dir`, and one `date`; import maps Java
      `modifiedDate`/`startDate`, but `title`, `count`, `selected`, and two-date
      display semantics need parity.
- [ ] Java writes `url`, `startDate`, `modifiedDate`, `title`, `count`, and
      `selected`, but does not write `dir` even though it reads `dir`.
      Flutter writes `dir`; the migration file must track this format extension.
- [ ] Java history import is strict for the core JSON shape:
      `History.fromJSON(...)` calls `getJSONObject(i)`, and
      `HistoryEntry.fromJSON(...)` requires `url`, `startDate`, and
      `modifiedDate` through `getString`/`getLong`; malformed entries make
      `fromFile(...)` throw an `IOException`. Flutter `HistoryProvider` filters
      non-map list entries and `HistoryEntry.fromJson(...)` defaults missing
      `url` to `''` and missing dates to epoch `0`, so invalid/partial history
      files are accepted differently.
- [ ] Java history table displays dates as `yyyy/MM/dd`. Flutter date display
      needs comparison.
- [ ] Java history context menu supports check all, uncheck all, check selected,
      and uncheck selected. Flutter does not yet have verified selected-entry
      parity.
- [ ] Java CLI `-r` re-rips all history entries and `-R` re-rips selected
      entries. Flutter needs equivalent behavior or a documented replacement.
- [ ] Java can reconstruct history candidates from existing rip directories via
      `RipUtils.urlFromDirectoryName`; Flutter has no verified equivalent.
- [ ] Java fallback history guessing is narrower than its intent: `App.loadHistory`
      only scans the working directory when both `history.json` and legacy
      `download.history` are empty, and it passes each `Path.toString()` into
      `RipUtils.urlFromDirectoryName`, whose helpers mostly check for bare
      directory-name prefixes such as `imgur_`, `imagefap_`, and `deviantart_`.
      Flutter must preserve, intentionally fix, or document this current-source
      behavior.
- [ ] Java `RipUtils.urlFromRedditDirectoryName(...)` appears unreachable for
      the intended `reddit_sub_*`, `reddit_user_*`, and `reddit_post_*`
      directory names: after confirming `dir.startsWith("reddit_")`, it splits
      on `_` and switches on `fields[0]`, which is still `reddit`, not `sub`,
      `user`, or `post`. Flutter has no history-folder reconstruction, so any
      future replacement must decide whether to preserve this shipped Reddit
      reconstruction bug.
- [ ] Java `RipUtils.urlFromImgurDirectoryName(...)` also has current-source
      edge cases that must not be silently smoothed over: it builds
      `List<String> fields = Arrays.asList(dir.split("_"))`, then the subreddit
      branch calls `fields.remove(...)`, which throws
      `UnsupportedOperationException` on the fixed-size list; short names such
      as `imgur_` can also fail at `fields.get(1)`. Flutter has no equivalent
      fallback history guessing, so an implementation must choose bug parity or
      an intentional migration fix.
- [ ] Java `RipUtils.urlFromDeviantartDirectoryName(...)` accepts any directory
      starting with `deviantart`, then immediately calls
      `dir.substring("deviantart_".length())`; a bare `deviantart` directory can
      therefore throw before returning `null` or a URL. Directory names with a
      trailing underscore can also reach `fields[1]` after Java's split drops
      trailing empty fields. Flutter has no equivalent fallback history
      guessing, so this malformed-directory behavior needs a parity decision.
- [ ] Java history clear deletes both album history and downloaded-URL history
      through `Utils.clearURLHistory()`, optionally after
      `history.warn_before_delete` confirmation. Flutter clear behavior needs to
      be checked for both stores.

### D. HTTP, Cookies, Proxy, And Network Semantics

Java sources read:

- `src/main/java/com/rarchives/ripme/utils/Http.java`
- `src/main/java/com/rarchives/ripme/utils/Proxy.java`
- `src/main/java/com/rarchives/ripme/utils/RipUtils.java`
- `src/main/java/com/rarchives/ripme/ripper/DownloadFileThread.java`
- `src/main/java/com/rarchives/ripme/ripper/DownloadVideoThread.java`

Flutter files checked:

- `lib/utils/http_utils.dart`
- `lib/config_defaults.dart`
- `lib/ripper/abstract_ripper.dart`
- `lib/ripper/abstract_video_ripper.dart`

Findings:

- [ ] Java `Http` is a chainable Jsoup wrapper supporting timeout,
      `ignoreContentType`, referrer, user agent, retry count, headers, cookies,
      form data, method override, `post`, JSON object, and JSON array helpers.
      Flutter has focused helpers but not the full API surface.
- [ ] Java configured cookies use `cookies.<domain>` and check parent domains;
      values are parsed as semicolon-delimited `key=value` pairs. Flutter does
      similar domain lookup, but parser edge cases and precedence need tests.
- [ ] Java shared cookie parsing in `RipUtils.getCookiesFromString(...)` uses
      `pair.split("=")` with no split limit and no malformed-pair guard:
      `a=b=c` becomes `a -> b`, and a semicolon segment without `=` throws
      instead of being skipped. Flutter shared parsing in
      `Http._parseCookieHeader(...)` preserves extra `=` characters and ignores
      malformed segments; per-ripper parsers such as Furaffinity currently test
      the Flutter behavior, not the Java quirk.
- [ ] Java proxy CLI/config accepts single strings such as
      `[user:password]@host[:port]` for HTTP and SOCKS. Flutter currently uses
      `proxy.enabled`, `proxy.host`, `proxy.port`, `proxy.username`, and
      `proxy.password`; `proxy.http` and `proxy.socks` compatibility is missing.
- [ ] Java SOCKS proxy support sets `socksProxyHost`, `socksProxyPort`, and
      optional credentials globally. Flutter has no verified SOCKS equivalent.
- [ ] Java proxy support mutates process-wide networking through
      `Authenticator.setDefault`, `http.proxyHost`, `http.proxyPort`,
      `http.proxyUser`, `http.proxyPassword`, `https.proxyHost`, and HTTPS
      equivalents. Flutter proxy support must either match the global effect for
      all page, download, and ripper-specific HTTP clients or document a scoped
      replacement.
- [ ] Java 401/403 page requests throw a cookie-oriented error message; 404 page
      requests throw file-not-found style messaging. Flutter currently raises
      generic `HttpException` text in several paths.
- [ ] Per-ripper malformed URL/GID exception messages are not fully
      Java-compatible or test-locked. Java rippers throw exact
      `MalformedURLException` strings, including source typos such as
      `MyhentaigalleryRipper` saying `Expected myhentaicomics.com URL format`
      and `PorncomixRipper` saying `Expected proncomix URL format`; several
      Dart ports normalize or rewrite those messages with `FormatException`
      text, and the suite does not mechanically prove exact message parity.
- [ ] Java `Http` retry loop attempts exactly the configured count. Flutter's
      `_getResponse` currently loops `attempt <= retries`, which is one extra
      attempt for the same setting.
- [ ] Java `Http.response()` does not inspect `Retry-After` on 429 or 503; it
      applies the configured `download.retry.sleep` delay between retries or
      retries immediately when that value is zero. Flutter `_getResponse(...)`
      parses `Retry-After` for 429/503 and waits for that header-specific delay,
      so rate-limited pages can pause differently from Java even with the same
      retry config.
- [ ] Java file download retry loop increments `tries` and fails when
      `tries > retries`; redirect handling can avoid counting the first redirect.
      Flutter's bulk-response download path needs retry-count parity tests.
- [ ] Java `DownloadFileThread` supports resume with Range headers when a ripper
      opts in, MIME/magic extension detection when requested, explicit
      non-retriable 4xx handling, retriable 5xx handling, and an Imgur
      503-byte-as-404 special case. Flutter needs shared tests or documented
      replacement behavior.
- [ ] Java `DownloadFileThread` catches `SocketTimeoutException`, logs
      `timedout!`, breaks out of the retry loop, and then still falls through to
      `observer.downloadCompleted(url, saveAs.toPath())`. Flutter shared
      download/page requests surface timeout failures instead. This shipped Java
      timeout-completion behavior needs a compatibility test or an explicit
      intentional-fix note.
- [ ] Java `download.max_size` is only used by config validation/update
      plumbing; `DownloadFileThread` does not compare response size against that
      key before saving. Flutter `Http.downloadFile(...)` rejects any response
      whose `bodyBytes.length` exceeds `download.max_size`, adding a global
      download limit Java did not enforce.
- [ ] Java `DownloadVideoThread` first issues a HEAD request for total bytes,
      then downloads with no connect timeout and byte-progress events. Flutter
      video helpers need exact progress comparison.
- [ ] Java `DownloadVideoThread` retry behavior also differs from shared
      Flutter downloads: it has no retry-sleep delay, gets total bytes through a
      separate HEAD request before the retry loop, and only increments `tries`
      after the GET connection is configured. Flutter routes video downloads
      through the shared `Http.downloadFile(...)` response path, so timeout and
      retry timing are not Java-compatible.
- [ ] Java DASH manifest selection in `RedditRipper.parseRedditVideoMPD(...)`
      considers only the `height` attribute, treats a missing height as `0`,
      updates the candidate only when the height is strictly greater than the
      previous largest value, and then appends the selected `BaseURL` text to
      the original video URL. Flutter's shared
      `AbstractVideoRipper.bestDashVideoUrl(...)` falls back to `bandwidth` when
      `height` is absent and resolves `BaseURL` relative to the manifest URL.
      DASH manifests with missing heights, bandwidth-only variants, duplicate
      heights, or relative base paths can therefore choose a different media URL.
- [ ] Java `CliphunterRipper.rip()` schedules the decrypted video with
      `addURLToDownload(url, HOST + "_" + getGID(...))`; Java
      `VideoRipper.addURLToDownload(..., referrer, cookies, ...)` ignores
      referrers and cookies entirely. Flutter
      `CliphunterRipper.getVideoDownloadForRip(...)` attaches a `Referer`
      header equal to the decrypted video URL, and its test labels that
      behavior "Java-style", but Java downloads the Cliphunter video without
      that header.
- [ ] Java `VideoRipper.addURLToDownload` has a test-only contract: when
      `markAsTest()` / `isThisATest()` is active and `urls_only.save` is false,
      it does not enqueue or download the video; it mutates `this.url` to the
      resolved video download URL and returns true. Java `VideoRippersTest`
      asserts that the ripper URL changes from the original page URL. Flutter
      video tests capture requested downloads, but no shared equivalent
      Java-compatible test-mode URL mutation is represented.
- [ ] Java SSL verification toggle globally disables/enables certificate and
      hostname checks for Jsoup. Flutter has no verified equivalent.
- [ ] Java has two cookie parsers with different delimiters:
      `Http`/`RipUtils.getCookiesFromString` parse semicolon-delimited cookies,
      while `Utils.getCookies(host)` parses space-delimited pairs. Flutter needs
      tests for both call-site expectations.

### E. Ripper Runtime And Filesystem Semantics

Java sources read:

- `src/main/java/com/rarchives/ripme/ripper/AbstractRipper.java`
- `src/main/java/com/rarchives/ripme/ripper/AbstractHTMLRipper.java`
- `src/main/java/com/rarchives/ripme/ripper/AbstractJSONRipper.java`
- `src/main/java/com/rarchives/ripme/ripper/AbstractSingleFileRipper.java`
- `src/main/java/com/rarchives/ripme/ripper/AlbumRipper.java`
- `src/main/java/com/rarchives/ripme/ripper/VideoRipper.java`
- `src/main/java/com/rarchives/ripme/ripper/DownloadThreadPool.java`
- `src/main/java/com/rarchives/ripme/utils/Utils.java`

Flutter files checked:

- `lib/ripper/abstract_ripper.dart`
- `lib/ripper/abstract_html_ripper.dart`
- `lib/ripper/abstract_json_ripper.dart`
- `lib/ripper/abstract_video_ripper.dart`
- `lib/utils/utils.dart`

Findings:

- [ ] Java `filesystemSafe` removes every character outside
      `[a-zA-Z0-9-.,_ ]`, trims, and truncates names longer than 100 characters
      to 99. Flutter currently matches the character-removal/trim behavior, but
      does not truncate long strings.
- [ ] Java `filesystemSanitized` replaces disallowed characters with `_`.
      Flutter has only `filesystemSafe` and `sanitizeSaveAs`.
- [ ] Java `sanitizeSaveAs` replaces `\\:*?"<>|` and has test-backed filename
      edge cases: explicit file name plus extension yields `test.test`, explicit
      filename without extension yields `test`, query URL object yields `Object`,
      and `file.` stays `file.`.
- [ ] Java working directory creation preserves an existing directory's
      original case on Unix/macOS through `getOriginalDirectory`.
- [ ] Java `Utils.getWorkingDirectory()` creates the configured
      `rips.directory` when it does not exist. Flutter `Utils.getWorkingDirectory`
      returns a configured custom path directly without creating it, so custom
      rip-root creation behavior is not Java-compatible.
- [ ] Java shortens Windows paths above 260 characters and long filenames above
      filesystem limits; Flutter has no verified equivalent.
- [ ] Java `getFileName` strips query, fragment, ampersand, and colon segments,
      adds prefix before extension handling, then sanitizes. Flutter rippers use
      local filename helpers that need shared parity tests.
- [ ] Java writes downloaded URLs to URL history before handing a download to
      the thread pool. Flutter marks downloads after `Http.downloadFile`
      succeeds; this changes retry/interruption semantics.
- [ ] Java normalizes URL-history keys through overridable
      `AbstractRipper.normalizeUrl` before both history lookup and history
      write. Current Java overrides are `ArtStationRipper` (strips a terminal
      query word) and `DeviantartRipper` (uses the current offset URL).
      Flutter download history marks/checks raw download URIs with no verified
      equivalent per-ripper normalization.
- [ ] Java shared `AbstractRipper.addURLToDownload` rejects bare `http:` and
      `https:` download URLs and rewrites spaces in `url.toExternalForm()` to
      `%20` before save-path creation, history checks/writes, and queueing.
      Flutter shared download scheduling does not have an equivalent
      Java-compatible preflight guard.
- [ ] Java `urls_only.save=true` writes `urls.txt`, counts it as completed, and
      opens `urls.txt` after rip completion. Flutter writes `urls.txt` but open
      behavior and completion details need verification.
- [ ] Java duplicate suppression is per ripper pending/completed/errored maps
      unless `allowDuplicates()` is overridden. Flutter has a per-ripper
      attempted URL set; override coverage needs verification.
- [ ] Java shared download paths surface prior downloads and existing files as
      warning statuses: URL-history hits send `DOWNLOAD_WARN` with
      `Already downloaded <url>`, and `downloadExists(...)` sends
      `DOWNLOAD_WARN` with `<url> already saved as <file>` while marking the
      item completed. Flutter `downloadFile(...)` emits `RipStatus.downloadSkip`
      with `Already downloaded: <url>` or `File already exists: <path>` instead,
      changing status category, message text, and completed-item accounting for
      these common skip paths.
- [ ] Java `DownloadThreadPool.waitForThreads()` shuts down the fixed thread
      pool and waits at most 3600 seconds for termination. Flutter
      `AbstractRipper.downloadFiles` waits on all worker futures with no
      Java-compatible timeout or interrupted-wait status behavior.
- [ ] Java `AbstractHTMLRipper`/`AbstractJSONRipper` wait on overridable
      `getThreadPool()` hooks, and concrete rippers can replace the default
      pool with per-ripper pools. Current Java overrides are
      `DeviantartRipper`, `E621Ripper`, `EHentaiRipper`, `FlickrRipper`,
      `FuraffinityRipper`, `HqpornerRipper`, `ImagebamRipper`,
      `ImagevenueRipper`, `ListalRipper`, `MotherlessRipper`, `NfsfwRipper`,
      `NhentaiRipper`, and `PornhubRipper`. Flutter uses the shared
      `AbstractRipper.downloadFiles` worker queue and has no verified
      per-ripper pool hook/coverage for these classes.
- [ ] Java stops an HTML rip after `history.end_rip_after_already_seen` already
      downloaded URLs and sends `DOWNLOAD_COMPLETE_HISTORY`. Flutter sends a
      download-skip message and stops; status parity is missing.
- [ ] Java `AbstractHTMLRipper` remembers each processed `doc.location()` and
      breaks when a next page resolves to a previously processed location.
      Flutter `AbstractHTMLRipper` has no visited-location guard, so bad or
      cyclic pagination can loop until stopped or until a fetch fails.
- [ ] Java `AbstractHTMLRipper` exposes one instance-level
      `cachedFirstPage` through `getCachedFirstPage()`, so a first page fetched
      while deriving the working-directory title is reused by the later rip
      loop. Current Java concrete title/queue paths using that cache include
      `BatoRipper`, `ChanRipper`, `CheveretoRipper`, `EightmusesRipper`,
      `EromeRipper`, `FlickrRipper`, `GirlsOfDesireRipper`,
      `HentaifoxRipper`, `ImagebamRipper`, `ImagefapRipper`, `NfsfwRipper`,
      `ViewcomicRipper`, `XhamsterRipper`, and `ZizkiRipper`. Flutter has no
      shared `AbstractHTMLRipper` first-page cache; several ports fetch the
      album-title page and the rip page independently, which can change request
      counts, cookie/status side effects, and behavior when the two responses
      differ.
- [ ] Java shared HTML/JSON ripper layers throw `IOException("No images found
      at ...")` when URL extraction returns no media and the ripper is not
      doing ASAP/custom downloading. Flutter `AbstractHTMLRipper` currently
      treats an empty download list as a normal completed rip, and
      `AbstractJSONRipper` leaves this guard to each concrete parser.
- [ ] Java error/completion status ordering is not equivalent. Java
      `AbstractRipper.run()` catches failed `rip()` calls, waits for threads,
      and sends `RIP_ERRORED`, while `RIP_COMPLETE` is emitted separately from
      `checkIfComplete()` after successful scheduled-download completion.
      Flutter `AbstractJSONRipper`, `AbstractVideoRipper`, and many concrete
      rippers catch an error with `sendUpdate(RipStatus.ripErrored, ...)` and
      then still fall through to `sendUpdate(RipStatus.ripComplete, ...)`,
      making failed rips look completed in the event stream.
- [ ] Java shared test mode is a static `AbstractRipper.thisIsATest` flag set by
      `markAsTest()`. `AbstractHTMLRipper` and `AbstractJSONRipper` remove all
      but one media URL per page, stop before fetching the next page, suppress
      history checks/writes, and `addURLToDownload(...)` stops later downloads
      after the first completion/error while test mode is active. Flutter has no
      equivalent shared test-mode surface, so Java live-test contracts and
      test-only side effects are not reproducible outside ad hoc Dart mocks.
- [ ] Java video rippers that perform their own `rip()` logic throw out on
      missing extraction markers and do not emit successful completion from the
      concrete method: `TwitchVideoRipper` throws when no `<script>` exists,
      `ViddmeRipper` throws when `meta[name=twitter:player:stream]` is absent,
      `VidearnRipper` throws when no `file:"..."` token exists, and
      `MotherlessVideoRipper` throws when no `__fileurl = '...'` token exists.
      Flutter helper tests cover these thrown helper errors, but
      `AbstractVideoRipper` and custom Dart `rip()` overrides still catch and
      then send `ripComplete`, so UI/runtime status parity remains unproven
      for these source-backed failure paths.
- [ ] Java `MotherlessVideoRipper.rip()` logs the hardcoded error message
      `WTF` whenever the fetched HTML contains the `__fileurl = '` marker, and
      then still extracts the first marker and schedules the download. Flutter
      `MotherlessVideoRipper.videoUrlFromHtml(...)` extracts the same marker
      without emitting that Java-visible diagnostic side effect.
- [ ] Java deletes an empty working directory during cleanup. Flutter does not
      yet verify this cleanup behavior.
- [ ] Java `AbstractHTMLRipper` supports queue-only pages through
      `hasQueueSupport`, `pageContainsAlbums`, and `getAlbumsToQueue`, adding
      discovered album URLs to `MainWindow` queue. Flutter needs verification
      for rippers that depend on this pattern.
- [ ] Java exposes dormant `descriptions.save` machinery in
      `AbstractHTMLRipper` through `hasDescriptionSupport`,
      `getDescriptionsFromPage`, `getDescription`, `saveText`, and
      `descSleepTime`, but the source scan found no current concrete ripper
      returning `hasDescriptionSupport() == true`. `FuraffinityRipper`
      implements description helpers and an overridden `saveText`, yet returns
      false, so current-source parity must preserve or intentionally retire this
      disabled feature path rather than assuming active description downloads.
- [ ] Java `-a` / `--append-to-folder` stores
      `App.stringToAppendToFoldername`, and `AbstractRipper.getFilePath`
      applies it by resolving the working directory to a sibling named
      `<workingDirName><appendString>` before adding subdirectories and file
      names. Flutter has no verified equivalent for this path-shaping behavior.
- [ ] Java `AbstractSingleFileRipper` provides byte-progress status text and
      byte-progress percentage behavior for its subclasses: `RulePornRipper`,
      `SpankbangRipper`, `XvideosRipper`, and `YoupornRipper`. The Flutter
      ports for these classes currently extend `AbstractHTMLRipper`; their
      tests cover extraction/filenames, but not Java single-file byte-progress
      inheritance semantics.
- [ ] Java `SpankbangRipper.getURLsFromPage(...)` returns `null` when
      `.video-js > source` is absent, after logging that the embed code could
      not be found. Flutter `SpankbangRipper.videoUrlsFromDocument(...)`
      preserves that helper-level `null`, but the framework-facing
      `getURLsFromPage(...)` converts it to `const []`, so a missing video
      source becomes an empty successful extraction instead of Java's null
      result path.
- [ ] Java single-file-style rippers still use `AbstractHTMLRipper.getPrefix(...)`
      when their concrete `downloadURL(...)` calls `addURLToDownload(url,
      getPrefix(index))`, so `download.save_order=false` disables ordered
      prefixes. Flutter `XvideosRipper.prefix(...)`,
      `YoupornRipper.prefix(...)`, and album `YuvutuRipper.prefix(...)`
      unconditionally return `NNN_`; their tests cover only the enabled prefix
      path, so these ports ignore Java's global no-save-order setting.
- [ ] Java `XvideosRipper.getURLsFromPage(...)` returns raw
      `div.thumb > a` `href` strings for album pages, and
      `AbstractHTMLRipper.rip()` immediately converts each string with
      `new URI(imageURL).toURL()`. Relative album hrefs therefore fail before
      queueing in Java. Flutter `XvideosRipper.albumUrlsFromDocument(...)`
      preserves relative hrefs and `rip()` parses them as relative `Uri`
      download targets, so relative album entries fail later/differently instead
      of matching Java's immediate URI-to-URL failure path.
- [ ] Java has package-distinct album and video rippers with duplicate simple
      class names: `rippers/PornhubRipper.java` and
      `rippers/video/PornhubRipper.java`, `rippers/VkRipper.java` and
      `rippers/video/VkRipper.java`, plus `rippers/YuvutuRipper.java` and
      `rippers/video/YuvutuRipper.java`. Flutter's migration catalog tracks
      only simple class names, so simple-name set equality can hide a collapsed
      album/video implementation. Factory routing and tests must prove both
      Java behaviors are represented separately or document an intentional
      merge.
- [ ] Java `rippers/video/PornhubRipper.canRip(...)` accepts
      `https?://[wm.]*pornhub.com/view_video.php?viewkey=...` after the album
      package scan fails to match non-album URLs. Flutter only imports the album
      `PornhubRipper`, whose `canRip(...)` requires `url.path.startsWith('/album')`;
      `RipperFactory` has no separate Pornhub video route, so Java-supported
      Pornhub video URLs currently resolve to no Dart ripper.
- [ ] Java `rippers/video/YuvutuRipper.canRip(...)` accepts
      `http://www.yuvutu.com/video/ID/SLUG` after the album package scan fails.
      Flutter `YuvutuRipper` implements only the Java gallery URL pattern
      `modules.php?name=YuGallery&action=view&set_id=...`, and `RipperFactory`
      has no separate Yuvutu video route, so Java-supported Yuvutu video URLs
      currently resolve to no Dart ripper.
- [ ] Java album `YuvutuRipper.getURLsFromPage(...)` adds every
      `div#galleria > a > img` `src` value, including empty strings, and the
      shared `AbstractHTMLRipper.rip()` then converts each candidate with
      `new URI(imageURL).toURL()`. Empty or relative `src` values therefore fail
      immediately in Java. Flutter `YuvutuRipper.imageUrlsFromDocument(...)`
      also preserves empty strings, but `rip()` parses them as relative `Uri`
      download targets and builds `RipperDownload`s, changing the failure point
      and status path for malformed gallery images.
- [ ] Java `AbstractRipper(URL)` rejects a candidate constructor whenever that
      class's `canRip(url)` is false before `AbstractRipper.getRipper(...)`
      tries the next album/video class. Flutter `RipperFactory.getRipper(...)`
      bypasses that constructor guard for direct host routes, returning rippers
      without calling their stricter `canRip(...)`; for example
      `cliphunter.com` accepts any path before `CliphunterRipper.canRip(...)`
      can require `/w/ID`, and hosts such as `cliphunter.com.evil` can also
      dispatch before Java's full-URL regex would reject them;
      `hentaifox.com` accepts any path before `HentaifoxRipper.canRip(...)`
      can require `/gallery/ID`,
      `fitnakedgirls.com` accepts any path before `FitnakedgirlsRipper.canRip(...)`
      can require `/photos/gallery/...`, and `hentainexus.com` accepts any path
      before `HentaiNexusRipper.canRip(...)` can require `/view/ID` or
      `/read/ID`.
- [ ] The same Flutter factory constructor-guard bypass affects additional
      direct routes whose own Dart `canRip(...)` is stricter than the factory
      host predicate, including `BatoRipper`, `FapDungeonRipper`,
      `FemjoyhunterRipper`, `FuskatorRipper`, `GirlsOfDesireRipper`,
      `HentaifoundryRipper`, `EightmusesRipper`, `ImgurRipper`,
      `NewgroundsRipper`, `NfsfwRipper`, `TheyiffgalleryRipper`, and
      `ViewcomicRipper`. These must be fixed as one dispatch contract, not only
      for the first examples above.
- [ ] Flutter `RipperFactory.getRipper(...)` also expands several direct host
      routes by using `host.contains(...)` instead of Java's inherited
      `AbstractHTMLRipper.canRip(...)` `url.getHost().endsWith(getDomain())`
      guard. For routes such as `AllporncomicRipper`, `ArtStationRipper`,
      `ArtstnRipper`, `BaraagRipper`, `BatoRipper`, `EightmusesRipper`,
      `FlickrRipper`, `ImagefapRipper`, `ImgurRipper`, `InstagramRipper`,
      `MastodonRipper`, `MastodonXyzRipper`, `NhentaiRipper`, `PawooRipper`,
      `RedditRipper`, `RedgifsRipper`, and `TumblrRipper`, hosts like
      `imgur.com.evil`, `evilreddit.com.invalid`, `redgifs.com.evil`, or
      `8muses.com.evil` can dispatch in Flutter where Java would reject the
      constructor and keep scanning/fail.
- [ ] Java `download.ignore_extensions` suppresses extension-matched URLs with
      `DOWNLOAD_SKIP`; Flutter has a similar check but needs exact tests.
- [ ] Java `sleep(milliseconds)` applies gaussian jitter with a minimum of 47%
      of requested time. Flutter delay behavior is not equivalent.
- [ ] Java `RipperInterface` contract includes `rip`, `canRip`, `sanitizeURL`,
      `setWorkingDir`, `getHost`, and `getGID`; Flutter abstract classes should
      keep all equivalent hooks covered by tests.
- [ ] Java `AbstractRipper` calls each concrete `sanitizeURL(url)` during
      construction and stores the sanitized result in `this.url`. Several
      Flutter ports with Java `sanitizeURL` behavior still do not store a
      sanitized constructor URL through `super(...)`, including at least
      `FlickrRipper`, `ImagefapRipper`, `ImgurRipper`, `NfsfwRipper`,
      `TumblrRipper`, and `TwitterRipper`; some sanitize selected call sites,
      but setup/working-directory/rip flows are not proven Java-equivalent.
- [ ] Mechanical public-method scan found additional Java runtime hooks that
      need explicit parity coverage or documented retirement:
      `AbstractRipper.setup`, `hasASAPRipping`, `getRipperConstructors`,
      `sendUpdate`, `setBytesTotal`, and `setBytesCompleted`.
- [ ] Mechanical public-method scan found additional Java utility APIs that
      need explicit parity coverage or documented retirement:
      `fuzzyExists`, `getPath`, `removeCWD`, `getWorkingDirectory`,
      `getConfigDir`, `getURLHistoryFile`, `clearURLHistory`,
      `getSupportedLanguages`, `getSelectedLanguage`, `setLanguage`,
      `configureLogger`, `playSound`, `getListOfAlbumRippers`, and
      `getListOfVideoRippers`.
- [ ] Java `Utils` also exposes production helpers with source/test-source
      contracts that Flutter's shared `Utils` does not currently provide:
      `stripURLParameter`, `shortenPath(Path)`, `bytesToHumanReadable`,
      `getByteStatusText`, `getEXTFromMagic`, `between`, and
      `shortenSaveAsWindows`. The Java source also keeps the shipped
      `shortenPath(String)` bug (`return shortenPath(path);` self-recursion),
      so parity needs either a compatible bug test or a documented intentional
      retirement instead of silently replacing it with Dart path shortening.
- [x] Java query parsing uses `URLDecoder` with UTF-8, preserves empty values for
      keys without `=`, and decodes each key/value independently. Flutter URL
      query helpers now cover those exact edge cases, duplicate handling, extra
      `=` characters in values, and Java trailing-empty split behavior in
      `test/utils_query_test.dart`.

### F. UI, Clipboard, Status, And Desktop Integration

Java sources read:

- `src/main/java/com/rarchives/ripme/ui/ClipboardUtils.java`
- `src/main/java/com/rarchives/ripme/ui/ContextMenuMouseListener.java`
- `src/main/java/com/rarchives/ripme/ui/HistoryMenuMouseListener.java`
- `src/main/java/com/rarchives/ripme/ui/QueueMenuMouseListener.java`
- `src/main/java/com/rarchives/ripme/ui/RipStatusMessage.java`
- `src/main/java/com/rarchives/ripme/ui/RipStatusComplete.java`
- `src/main/java/com/rarchives/ripme/uiUtils/ContextActionProtections.java`

Flutter files checked:

- `lib/main.dart`
- `lib/ui/rip_status_message.dart`
- `lib/rip_manager.dart`

Findings:

- [ ] Java `RipStatusMessage.toString()` renders display labels such as
      `Loading Resource: <value>`. Flutter currently renders enum names such as
      `loadingResource: <value>`. The log/status layer needs Java text parity.
- [ ] Java status enum includes `DOWNLOAD_COMPLETE_HISTORY`, `TOTAL_BYTES`,
      `COMPLETED_BYTES`, and `NO_ALBUM_OR_USER`; Flutter status enum does not
      include all of these.
- [ ] Java `RipStatusComplete` carries directory and count. Flutter history
      updates from `ripComplete` need exact count/directory parity.
- [ ] Java text-field context menu includes Undo, Cut, Copy, Paste, Select All,
      tracks the last cut/paste for undo, and replaces the whole text field on
      paste. Flutter default text-field menus need an intentional parity call.
- [ ] Java context actions have dynamic enabled/disabled rules and keyboard
      protections: Undo is enabled only after Cut/Paste, Cut requires editable
      selected text, Copy requires selected text, Paste requires string
      clipboard content, Select All requires non-empty text, and Ctrl+V pastes
      the entire clipboard string. Flutter text actions and shortcuts need
      exact tests or a documented native replacement.
- [ ] Java clipboard autorip polls every second, accepts
      `http`, `https`, `ftp`, and `file` URL schemes, deduplicates URLs only
      within the autorip thread, and starts ripping immediately rather than
      queueing. Flutter currently polls every 2 seconds, trims and parses the
      entire clipboard as one URI, requires `uri.host.isNotEmpty` (which blocks
      Java-style `file:` URLs), remembers only the last clipboard URL, and
      queues instead of immediately starting. Flutter autorip needs tests or
      documented intentional-difference notes for these details.
- [ ] Java history context menu selected-state actions need Flutter equivalents.
- [ ] Java queue clear action asks for confirmation; Flutter queue clear/remove
      needs confirmation parity.
- [ ] Java queue/history/context popups position themselves around the pointer,
      shifting left when `x > 500`; Flutter popup positioning should either
      match where practical or be documented as a platform-native difference.
- [ ] Java context-menu trigger/enabled-state behavior is more specific than a
      generic platform menu: `QueueMenuMouseListener` and
      `HistoryMenuMouseListener` open only when `getModifiersEx()` equals
      `BUTTON3_DOWN_MASK` and the event source is respectively a `JList` or
      `JTable`; `ContextMenuMouseListener` also uses `isPopupTrigger()` on
      press/release but, on right-click `mouseClicked`, requires a
      `JTextComponent`, requests focus, and enables Undo/Cut/Copy/Paste/Select
      All from enabled/editable/selection/clipboard/last-action state before
      showing the shifted popup. Flutter currently relies on native/context
      controls and queue/history widgets without verified parity for these
      exact trigger, focus, action-availability, and saved-string semantics.
- [ ] Java tray icon, popup notifications, and open-folder button are desktop
      behaviors that need per-platform Flutter verification or documented
      replacements. The Java implementation uses `SystemTray`, `TrayIcon`,
      `TrayIcon.displayMessage`, tray About/Hide/Show/Exit/Autorip menu items,
      and `Desktop.getDesktop().open(...)` / `.browse(...)`.
- [ ] Java main window lifecycle uses `JFrame.EXIT_ON_CLOSE`, a `WindowListener`
      to toggle tray labels and icon visibility on activate/deactivate,
      `setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE)`, and explicit
      `System.exit(0)` from the tray Exit item. A scan found no
      `WindowStateListener`, `mnemonic`, or `accelerator` registrations in the
      Java UI; Flutter desktop and Android close/minimize/background behavior
      still needs an intentional replacement decision.
- [ ] Java persists and restores desktop window bounds when `window.position`
      is true and the platform is not affected by Java's Windows positioning
      bug: shutdown saves `window.x`, `window.y`, `window.w`, and `window.h`,
      startup restores those bounds, otherwise the frame is centered. Flutter
      has no verified equivalent window-bounds persistence.
- [ ] Java user-facing modal flows use `JOptionPane.showMessageDialog`,
      `JOptionPane.showConfirmDialog`, and a custom YES/NO `JFrame` for history
      deletion warning. Flutter dialogs/snackbars need exact workflow coverage,
      especially for no-history, no-checked-history, queue clear, update/about,
      and history-load-failure cases.
- [ ] Java live URL validation updates status on every text-field document
      change, showing `<host> album detected` in green or `Can't rip this URL:
      <message>` in red. Flutter command bar needs exact behavior coverage.
- [ ] Java tab buttons toggle one panel at a time, bold the selected tab button,
      and collapse the lower panel when hidden. Flutter tab/navigation behavior
      should be verified against this workflow or documented as a native
      replacement.
- [ ] Java stop action calls `ripper.stop()`, clears progress, disables stop,
      sets localized interrupted status, and appends `Download interrupted` to
      the log. Flutter stop semantics need this full UI/status comparison.
- [ ] Java completion can run a user finish command when
      `enable.finish.command=true`, substituting `%url%` and `%path%`. Flutter
      has no verified equivalent.
- [ ] Java finish-command execution is also exact enough to require dedicated
      parity tests: `MainWindow` reads `finish.command` with default `ls`,
      applies `String.replaceAll("%url%", url)` and
      `String.replaceAll("%path%", absolutePath)`, splits the resulting command
      only on literal spaces with `cmdStr.split(" ")`, starts it with
      `Runtime.getRuntime().exec(String[])`, logs stdout line by line, prints
      stderr lines to `System.out`, and catches only `IOException`. Flutter has
      no corresponding execution path, and any future implementation using a
      shell, quote-aware parser, different placeholder semantics, or different
      stdout/stderr handling would not match Java.
- [ ] Java save-directory label opens the working directory on click; the save
      directory chooser uses directory-only mode and stores `rips.directory`.
      Flutter save-directory interactions need parity tests.
- [ ] Java tray About dialog lists album and video ripper names from
      `Utils.getListOfAlbumRippers()` / `getListOfVideoRippers()` and can open
      the GitHub project page. Flutter About/update UI needs equivalent
      supported-site visibility or a documented replacement.
- [ ] Java tray About dialog has source-visible content semantics that need
      exact replacement coverage: it builds two sections headed
      `Download albums from various websites:` and
      `Download videos from video sites:`, derives each displayed site by taking
      the constructor's fully-qualified class name, stripping everything through
      the last `.`, then stripping the first `Ripper` suffix, and asks
      `Do you want to visit the project homepage on GitHub?`; a `YES` response
      opens `http://github.com/ripmeapp/ripme`. Flutter has no verified
      equivalent supported-site/about dialog, and catalog display names,
      ordering, album-vs-video grouping, and homepage URL behavior must be
      tested or intentionally replaced.

### G. Resources, Localization, Logging, And Updates

Java sources/resources/tests read:

- `src/main/resources/LabelsBundle*.properties`
- `src/main/resources/camera.wav`
- `src/main/resources/*.png`
- `src/main/resources/icon.ico`
- `src/main/resources/log4j.file.properties`
- `src/main/resources/log4j2-example.xml`
- `src/main/java/com/rarchives/ripme/utils/UTF8Control.java`
- `src/main/java/com/rarchives/ripme/ui/UpdateUtils.java`
- `src/test/java/com/rarchives/ripme/tst/ui/LabelsBundlesTest.java`

Flutter files checked:

- `assets/`
- `lib/l10n/app_localizations.dart`
- `lib/update_checker.dart`
- `.github/workflows/`

Findings:

- [ ] Java resource bundles are UTF-8 through `UTF8Control`. Flutter
      localization loading needs an equivalent UTF-8/key coverage test.
- [~] Java uses `PropertyResourceBundle`, so `.properties` escape semantics
      apply in addition to UTF-8 loading. Flutter now decodes Java `\uXXXX`
      escapes from the Arabic and Korean bundles with focused Dart coverage,
      but continuation lines, alternate separators, and other Java property
      escapes still need compatibility tests or a documented parser replacement.
- [ ] Java supported languages are discovered by scanning available
      `LabelsBundle*.properties`; Flutter locale list needs comparison with:
      `ar_AR`, `de_DE`, `el_GR`, `en_US`, `es_ES`, `fi_FI`,
      `fi_FI_porrisavo`, `fr_CH`, `in_ID`, `it_IT`, `kr_KR`, `nl_NL`,
      `pl_PL`, `pt_BR`, `pt_PT`, `ru_RU`, and `zh_CN`.
- [ ] Flutter carries the Java `LabelsBundle_fi_FI_porrisavo.properties` file
      but `AppLocalizations.supportedLocales` has no locale/variant entry for
      it and `_bundleFor` maps all Finnish locales to `LabelsBundle_fi_FI`.
      Also, `isSupported` checks only `languageCode`, so country/variant
      distinctions such as `fr_CH`, `pt_BR`/`pt_PT`, and Java's nonstandard
      `in_ID`/`kr_KR` bundle names need exact fallback tests.
- [ ] Java language selection is a persisted runtime setting: `MainWindow`
      populates the combo box from `Utils.getSupportedLanguages()`, saves the
      selected tag to config key `lang`, calls `Utils.saveConfig()`, then
      invokes `Utils.setLanguage(...)` and `changeLocale()` to reload visible
      labels. Flutter exposes static `supportedLocales` through `MaterialApp`
      only; no `lang` config binding, language picker, or runtime label reload
      parity is proven.
- [ ] Java label-bundle tests assert every non-default key also exists in the
      default bundle. Flutter needs this coverage or an equivalent generated
      localization check.
- [ ] Java `LabelsBundlesTest.testKeyCount()` is not actually a key-count
      assertion: it builds a dictionary of keys whose translated value differs
      from the default bundle, logs them with the misleading text
      `Keys missing in ...`, and contains no `assert*` call. Flutter localization
      parity should preserve the real hard contract from
      `LabelsBundlesTest.testKeyName()` while treating `testKeyCount()` as a
      diagnostic-only source signal unless an intentional stronger check is
      documented.
- [ ] Java completion sound is `camera.wav`; the Java blob
      `src/main/resources/camera.wav` is carried forward byte-identically as
      `assets/sounds/camera.wav`, but Flutter currently uses platform alert
      sound. This is an intentional-difference candidate but not parity.
- [ ] Java logging file output is `ripme.log`, with rolling `ripme.%i.log.gz`
      output and a 20 MB size policy in log4j2. Flutter file logging is not
      verified.
- [ ] Java icon assets include `icon.ico`, `icon.png`, and toolbar PNGs
      (`comment`, `folder`, `gear`, `list`, `stop`, `time`, `wrench`).
      The toolbar PNGs and `icon.png` are carried forward byte-identically
      under `assets/`, but Java `icon.ico` is not present there; Windows uses
      `windows/runner/resources/app_icon.ico`, while Android and macOS use
      generated launcher/AppIcon sets. Platform icon provenance and visual
      parity still need explicit checks.
- [ ] `pubspec.yaml` includes `src/main/resources/`, but the local Flutter
      resource folder currently contains only `LabelsBundle*.properties`.
      Java binary resources from `origin/main:src/main/resources` are relocated
      to `assets/`, `assets/sounds/`, or platform launcher-resource folders, so
      resource parity must verify both relocated asset paths and actual runtime
      usage.
- [ ] Java `log4j.file.properties` and `log4j2-example.xml` remain Java-only
      logging resources; local Flutter `src/main/resources` does not carry
      them forward. The migration needs an explicit retirement/replacement note
      tied to Flutter file logging behavior.
- [ ] Java updater fetches `https://raw.githubusercontent.com/ripmeapp/ripme/main/ripme.json`,
      compares versions by numeric components, displays changelog entries, checks
      SHA-256 unless disabled, writes `ripme.jar.new`, and replaces the jar.
      Flutter uses GitHub Releases and needs a documented replacement test plan.
- [ ] Mechanical localized-key scan found Java UI/log labels not directly
      represented by Flutter `_label(...)` calls: `auto.update`,
      `autorip.from.clipboard`, `created`, `deleting.existing.file`,
      `download.interrupted`, `download.url.list`,
      `exceeded.maximum.retries`, `exception.while.downloading.file`,
      `failed.to.download`, `file.already.exists`, `history.check.all`,
      `history.check.none`, `history.check.selected`,
      `history.load.failed.warning`, `history.load.none`,
      `history.load.none.checked`, `history.uncheck.selected`,
      `http.status.exception`, `inactive`,
      `interrupted.while.waiting.to.rip.next.album`,
      `loading.history.from`, `loading.history.from.configuration`,
      `magic.number.was`, `nonretriable.status.code`,
      `modified`, `notification.when.rip.starts`, `open`,
      `prefer.mp4.over.gif`, `queue.remove.selected`, `queue.validation`,
      `re-rip.checked`, `remember.url.history`, `request.properties`,
      `restore.window.position`, `retriable.status.code`,
      `save.descriptions`, `save.logs`,
      `server.doesnt.support.resuming.downloads`, `skipping`,
      `ssl.verify.off`, `tray.autorip`, `tray.exit`, `tray.hide`,
      `tray.show`, and `was.unable.to.get.content.type.using.magic.number`.
- [ ] Java user-visible text is not limited to `LabelsBundle` keys. A hardcoded
      string scan found UI/updater/status/error text such as `Rip`, `Stop`,
      `URL:`, `YES`, `NO`, `Download albums and videos from various websites`,
      `Do you want to visit the project homepage on GitHub?`, updater progress
      text (`Checking for update...`, `Downloading new version...`),
      `Started ripping <url>`, and
      many thrown/logged ripper messages like `No images found at <url>`.
      Flutter parity needs tests or documented replacement text for these
      strings wherever they are user-visible through status, logs, dialogs, tray
      notifications, or CLI output.
- [ ] Java also has direct `System.out` diagnostics that bypass the logger and
      status observer: `MrCongRipper` prints the input URL, tag-page state,
      next-page URL rewrites, end-of-tag pagination, last-page discoveries, and
      collected URL lists; `NsfwAlbumRipper` prints the thumbnail count;
      `RedditRipper` prints self-post URLs; and `TeenplanetRipper` prints the
      found image-URL count. Flutter rippers generally do not print these
      diagnostics, so CLI/stdout parity needs explicit retirement or tests.

### H. Java Tests Still To Reconcile

Java test sources read/listed:

- `src/test/java/com/rarchives/ripme/tst/AbstractRipperTest.java`
- `src/test/java/com/rarchives/ripme/tst/Base64Test.java`
- `src/test/java/com/rarchives/ripme/tst/UtilsTest.java`
- `src/test/java/com/rarchives/ripme/tst/proxyTest.java`
- `src/test/java/com/rarchives/ripme/tst/ui/LabelsBundlesTest.java`
- `src/test/java/com/rarchives/ripme/tst/ui/RipStatusMessageTest.java`
- `src/test/java/com/rarchives/ripme/tst/ripper/rippers/*Test.java`
- `src/test/java/com/rarchives/ripme/ui/RipButtonHandlerTest.java`
- `src/test/java/com/rarchives/ripme/ui/UIContextMenuTests.java`
- `src/test/java/com/rarchives/ripme/ui/UpdateUtilsTest.java`

Findings:

- [ ] Add Dart tests for Java `AbstractRipper.getFileName` edge cases.
- [x] Add Dart tests for Java Base64 decode compatibility and document use of
      Dart `base64` as the replacement. Java production only calls
      `Base64.decode` from Twodgalleries and Cliphunter; direct coverage is in
      `test/base64_compat_test.dart`. Java's custom `Base64.encode` is unused in
      production and has non-standard one-byte padding, so Flutter intentionally
      uses Dart's standard encoder where encoding is needed for test fixtures or
      non-Java replacement code.
- [ ] Add Dart tests for `Utils.getEXTFromMagic`, `stripURLParameter`,
      `shortenPath(Path)`, Java's self-recursive `shortenPath(String)` overload,
      `bytesToHumanReadable`, `getByteStatusText`, `between`,
      `shortenSaveAsWindows`, and `sanitizeSaveAs`; current Flutter utility
      tests cover only `filesystemSafe` and one `sanitizeSaveAs` case.
- [ ] Add Dart tests for Java proxy string parsing for HTTP and SOCKS, even if
      SOCKS execution is later marked unsupported on a platform.
- [ ] Add Dart tests for Java label-bundle key rules and status-message string
      formatting.
- [ ] Keep the existing ripper test reconciliation, but do a final generated
      source-tree check in CI so new Java rippers cannot be missed.
- [ ] Mechanical test-method scan found 289 Java `@Test` methods across 118
      Java test classes, including 44 disabled methods and 126 tagged
      slow/flaky methods. Dart parity must be mapped at method/behavior level,
      not only file-name level.
- [ ] Non-ripper Java test methods requiring direct Dart coverage are:
      `AbstractRipperTest.testGetFileName`, `UtilsTest.testConfigureLogger`,
      `UtilsTest.testShortenFileNameWindows`, `proxyTest.testSocksProxy`,
      `proxyTest.testHTTPProxy`,
      `LabelsBundlesTest.testKeyCount`, `LabelsBundlesTest.testKeyName`,
      `RipStatusMessageTest.testConstructor`,
      `RipButtonHandlerTest.duplicateUrlTestCase`,
      `UIContextMenuTests.testCut`, `testCopy`, `testPaste`, `testSelectAll`,
      `testUndo`, and `UpdateUtilsTest.testIsNewerVersion`.
- [ ] High-density Java ripper test classes need method-by-method mapping before
      being counted as covered: `WordpressComicRipperTest` (14 methods),
      `FapwizRipperTest` (13), `EromeRipperTest` (11),
      `RedditRipperTest` (9), `XhamsterRipperTest` (8),
      `ImgurRipperTest` (7), `DeviantartRipperTest` and
      `RedgifsRipperTest` (6 each), plus `E621RipperTest`,
      `HqpornerRipperTest`, `ThechiveRipperTest`, `TumblrRipperTest`,
      `UIContextMenuTests`, `BooruRipperTest`, `FuraffinityRipperTest`,
      `NudeGalsRipperTest`, `SankakuComplexRipperTest`, `VkRipperTest`, and
      `XvideosRipperTest`.
- [ ] Mechanical test-name scan found 118 Java test classes under
      `src/test/java/com/rarchives/ripme` and 130 Dart test files. Most ripper
      tests have direct or naming-alias coverage; direct missing/non-direct
      Java utility/UI tests are `proxyTest`, `RipStatusMessageTest`,
      `RipButtonHandlerTest`, `UIContextMenuTests`, `UpdateUtilsTest`,
      aggregate suite tests `RippersTest` and
      `VideoRippersTest`, and inherited/alias ripper tests that must be mapped:
      `AbstractRipperTest`, `ArtStationRipperTest`, `BaraagRipperTest`,
      `FapDungeonRipperTest`, `HentainexusRipperTest`,
      `JabArchivesRipperTest`, `LabelsBundlesTest`, `MastodonXyzRipperTest`,
      `MrCongRipperTest`, `PawooRipperTest`, `RulePornRipperTest`,
      `ShesFreakyRipperTest`, and `SpankBangRipperTest`.
- [ ] Mechanical test-name aliases must be documented so naming differences do
      not look like missing tests: `ArtStationRipperTest` ->
      `artstation_ripper_test.dart`, `FapDungeonRipperTest` ->
      `fapdungeon_ripper_test.dart`, `JabArchivesRipperTest` ->
      `jabarchives_ripper_test.dart`, `MrCongRipperTest` ->
      `mrcong_ripper_test.dart`, `HentainexusRipperTest` ->
      `hentai_nexus_ripper_test.dart`, `RulePornRipperTest` ->
      `ruleporn_ripper_test.dart`, `SpankBangRipperTest` ->
      `spankbang_ripper_test.dart`, and `ShesFreakyRipperTest` ->
      `shesfreaky_ripper_test.dart`.
- [ ] A generated ported-ripper-to-Dart-test scan found remaining non-direct
      mappings that must be documented or split into focused tests:
      `BaraagRipper`, `MastodonXyzRipper`, and `PawooRipper` inherit Mastodon
      behavior and appear to be covered through `mastodon_ripper_test.dart`;
      `EHentaiRipper` maps to `ehentai_ripper_test.dart`; `RulePornRipper`
      maps to `ruleporn_ripper_test.dart`.
- [ ] `test/ported_ripper_parser_test.dart` still labels several cases as
      "unfinished ... scaffolds". Even where the underlying rippers have since
      been completed, this stale terminology must be cleaned up and any cases
      that only assert host/GID behavior must not be counted as full Java
      parity coverage.

### I. Per-Ripper Behavioral Hooks To Recheck

This pass found no missing Java ripper classes in the catalog, but it did find
Java runtime hooks and per-ripper config paths that must be individually proven
in Dart. A class being ported is not enough.

Java sources scanned:

- `src/main/java/com/rarchives/ripme/ripper/rippers/*.java`
- `src/main/java/com/rarchives/ripme/ripper/rippers/video/*.java`

Findings:

- [ ] Queue-only album discovery must be verified for every Java override of
      `hasQueueSupport`, `pageContainsAlbums`, and `getAlbumsToQueue`:
      `AllporncomicRipper`, `BatoRipper`, `EromeRipper`,
      `Hentai2readRipper`, `MyhentaicomicsRipper`, `NfsfwRipper`,
      `NhentaiRipper`, `WordpressComicRipper`, and `XhamsterRipper`.
- [ ] Java URL-history normalization overrides must be verified:
      `ArtStationRipper.normalizeUrl` and `DeviantartRipper.normalizeUrl`.
      These affect already-downloaded detection and are separate from URL
      factory matching.
- [ ] Java duplicate-download override must be verified:
      `ImgurRipper.allowDuplicates` permits duplicate media URLs for user rips.
- [ ] Java duplicate suppression is not disabled for `EightmusesRipper` or
      `TsuminoRipper`: neither class overrides `allowDuplicates()`, so their
      `addURLToDownload(...)` calls still use the shared pending/completed/
      errored URL maps. Flutter marks Eightmuses ASAP downloads and Tsumino
      image-object downloads with `allowDuplicate: true`, permitting duplicate
      URLs that Java would skip.
- [ ] Java byte-progress/resume overrides must be verified:
      `HqpornerRipper.tryResumeDownload` and
      `HqpornerRipper.useByteProgessBar`.
- [ ] Java `HqpornerRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any
      host ending in `hqporner.com` is accepted before `getGID(...)` validates
      either `/hdporn/...html` or the category/top/actress/studio listing
      pattern. Flutter `HqpornerRipper.canRip(...)` applies those strict
      patterns directly, narrowing Java's domain-level dispatch surface.
- [ ] Java `HqpornerRipper.getBestQualityLink(...)` returns `null` for an
      empty candidate list before checking quality substrings. Flutter
      `HqpornerRipper.bestQualityLink(...)` currently returns an empty string
      for the same empty list, so helper-level behavior and tests do not yet
      match Java exactly.
- [ ] Java `HqpornerRipper.getAllVideoUrls(...)` selects
      `div.6u h3  a.click-trigger`, which matches any `div` containing class
      `6u`. Flutter uses `div[class="6u"] h3 a.click-trigger`, so listing
      cards with additional classes are accepted by Java but skipped by
      Flutter.
- [ ] Java `HqpornerRipper.getAllVideoUrls(...)` also adds
      `VIDEO_URL_PREFIX + e.attr("href")` whenever the anchor merely has an
      `href` attribute, even if that attribute is empty. Flutter checks
      `(href ?? '').isNotEmpty` before adding a listing URL, so empty `href`
      anchors are skipped instead of becoming Java-style prefix-only video page
      candidates.
- [ ] Java `HqpornerRipper.getVideoFromFlyFlv(...)` builds the jsoup selector
      string `video > source[label=` plus the quality token, with no closing
      bracket. Flutter uses a valid quoted selector
      `video > source[label="$quality"]`, so FlyFlv extraction behavior no
      longer mirrors Java's shipped selector contract.
- [ ] Java `HqpornerRipper.getVideoFromUnknown(...)` returns the raw best
      `[src$=.mp4]` attribute value before `fetchVideo(...)` tries to convert
      it to a download URL. Flutter normalizes the same raw source through
      `normalizeProtocolRelative(...)`, so protocol-relative direct MP4 sources
      become `https:` URLs in Flutter but remain raw in Java.
- [ ] Java `HqpornerRipper.downloadURL(...)` queues one
      `HqpornerDownloadThread` per video and `fetchVideo()` catches
      `IOException | URISyntaxException`, logging
      `[!] Exception while downloading video.` without aborting the listing
      thread pool. Flutter `_ripListing()` awaits `_downloadVideoPage(...)`
      serially, and fetch/parse exceptions bubble to the top-level `rip()`
      catch as `RipStatus.ripErrored`, so one broken Hqporner video can stop a
      listing that Java would continue.
- [ ] Java ASAP-ripping overrides must be verified for exact shared-runtime
      bypass semantics. `EightmusesRipper`, `ErofusRipper`, `FlickrRipper`,
      `TwitterRipper`, and `XhamsterRipper` return `hasASAPRipping() == true`,
      which makes the Java abstract runtime skip normal queued download
      scheduling and lets the ripper perform downloads itself. Flutter ports
      have custom `downloadFiles` paths for several of these, but no shared
      `hasASAPRipping` contract or generated audit guard proves all five match
      Java behavior.
- [ ] Java `ErofusRipper.getURLsFromPage(...)` is an ASAP side-effect parser:
      album pages call `ripAlbum(page)`, which schedules each download with
      subdirectory/prefix options, and the method still returns an empty
      `imageURLs` list. Flutter `ErofusRipper.getURLsFromPage(...)` returns
      image URL strings for album pages, while `downloadsFromPage(...)` builds
      the subdirectory download requests separately, so callers that rely on the
      shared `getURLsFromPage` contract observe behavior Java never exposed.
- [ ] Java `ErofusRipper.getURLsFromPage(...)` sends `LOADING_RESOURCE` before
      fetching each subalbum, but subalbum load failures only call
      `logger.warn("Error while loading subalbum ...")`. Flutter
      `_downloadsFromPage(...)` sends `RipStatus.downloadWarn` for the same
      failures, adding user-visible warning/status-count output Java did not
      emit.
- [ ] Java blacklist config arrays must be verified for exact tag matching and
      warning text: `ehentai.blacklist.tags`, `nhentai.blacklist.tags`, and
      `tsumino.blacklist.tags`.
- [ ] Java E-Hentai/NHentai/Tsumino blacklist matching all goes through shared
      `RipUtils.checkTags(String[], List<String>)`: a missing config array
      returns `null`, blacklist entries are trimmed/lowercased for comparison
      against lowercased page tags, the first matching blacklist entry wins
      (not the first page tag), and the returned value is the lowercased
      blacklist entry. Flutter currently has per-ripper implementations:
      E-Hentai returns the original blacklist string, NHentai checks exact
      membership while iterating page tags first, and Tsumino is closer but
      still needs a shared Java-compatible proof.
- [ ] Java per-ripper auth/config keys must be verified with Dart tests or
      documented replacements:
      `album_titles.save`, `chans.chan_sites`, `derpi.key`,
      `DeviantartCustomLoginUsername`, `DeviantartCustomLoginPassword`,
      `DeviantartLogin.cookies`, `download.save_order`, `e621.cookies`,
      `e621.useragent`, `erome.laravel_session`, `furaffinity.login`,
      `furaffinity.cookies`,
      `hentai-foundry.filter_order`, `hentai-foundry.use_prefix`,
      `history.end_rip_after_already_seen`, `imgur.client_id`,
      `instagram.session_id`, `instagram.download_images_only`, `prefer.mp4`,
      Reddit upvote/subdirectory keys (`reddit.rip_by_upvote`,
      `reddit.min_upvotes`, `reddit.max_upvotes`, `reddit.use_sub_dirs`),
      `tumblr.auth`, `twitter.auth`, `twitter.max_requests`,
      `twitter.max_items_request`, `twitter.rip_retweets`, and
      `twitter.exclude_replies`.
- [ ] Java hardcoded/response cookie flows must be rechecked for request
      propagation, not just URL extraction: Chevereto consent, DeviantArt
      agegate/auth cookies, E621 configured cookies, E-Hentai `nw/tip`,
      Eightmuses response cookies, Erome `laravel_session`, Furaffinity shared
      login cookies, Fuskator auth cookies, HentaiFoundry filter/session
      cookies, Imagebam NSFW cookie, Instagram `sessionid`, ModelMayhem
      `worksafe=0`, Paheal `ui-tnc-agreed`, Photobucket page cookies,
      `SankakuComplexRipper` cookies,
      Sta/Thechive/Tsumino/Twodgalleries/Vsco/Webtoons/Xcartx/Zizki cookies.
- [ ] Java `DeviantartRipper.login()` loads serialized
      `DeviantartLogin.cookies`, merges response cookies, forces
      `agegate_state=1`, validates cookies by requesting
      `https://www.deviantart.com/users/login`, and falls back to logging in
      with `DeviantartCustomLoginUsername`/`DeviantartCustomLoginPassword`
      before persisting the merged cookie map. Flutter `DeviantartRipper`
      currently sends only the hardcoded `agegate_state=1` cookie and has no
      persisted-cookie deserialize/validate/login flow.
- [ ] Java `DeviantartRipper.getURLsFromPage(...)` dereferences the selected
      gallery container before selecting `a.torpedo-thumb-link`, and adds every
      matching anchor `href` including empty attributes. Flutter
      `DeviantartRipper.urlsFromPage(...)` returns an empty list when the
      container is missing and filters empty `href` values, so malformed
      gallery pages stop/skip cleanly instead of following Java's
      null-dereference or empty-download-candidate paths.
- [ ] Java `DeviantartImageThread.getFullSizeURL()` has several distinct
      per-deviation error/status branches: missing image sends
      `DOWNLOAD_ERRORED` with `ERROR at\n<url>`, unexpected `/v1/` splitting
      sends `Unexpected URL Format`, broad IO/URI failure falls through to
      `No image found for <url>`, and avatar/text-art pages log without a
      status send. Flutter `downloadFromDeviationPage(...)` sends a generic
      `$pageUrl : <exception>` only for thrown exceptions, returns `null`
      silently for non-200 download-button responses and missing/avatar scaled
      images, and maps unexpected URL format through the generic catch. The
      DeviantArt per-image `DOWNLOAD_ERRORED` surface is not Java-compatible.
- [ ] Java `RipUtils.getFilesFromURL` helper coverage must be verified for
      Reddit/Chan-style direct links and embedded media expansion:
      Imgur album/gifv/single pages, Redgifs/gifdeliverynetwork, Vidble
      album/show, `v.redd.it`, Erome, Soundgasm, `i.reddituploads.com`, direct
      image/video regex, and Imgur meta fallback.
- [ ] Java `RipUtils.getFilesFromURL(...)` treats a URL as direct media only
      when it matches
      `(https?://[a-zA-Z0-9\\-.]+\\.[a-zA-Z]{2,3}(/\\S*)\\.(jpg|jpeg|gif|png|mp4)(\\?.*)?)`.
      Flutter `RedditRipper._isDirectMedia(...)` accepts any parsed URI whose
      path ends in `.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`, `.mp4`, or `.webm`,
      without Java's 2-3 letter TLD constraint. Reddit body/post links ending
      in `.webp` or `.webm`, or direct-media hosts Java's regex would not
      match, can therefore download in Flutter where Java would return no file.
- [ ] Java `RedditRipper.handleBody` extracts URLs from self text and comments
      with `RipUtils.getURLRegex()`, whose pattern only accepts `http(s)` URLs
      with `[a-zA-Z]{2,3}` TLDs and a slash path, then strips only trailing
      right parentheses. Flutter `_mediaFromBody` currently uses a broader
      `https?://[^\s<>()"]+` pattern and strips trailing `)`, `.`, and `,`, so
      Reddit body-link extraction can accept or normalize URLs that Java would
      leave untouched.
- [ ] Java `RedditRipper.getJsonArrayFromURL(...)` attempts to throttle Reddit
      requests with `if (timeDiff < SLEEP_TIME) Thread.sleep(timeDiff)`, so the
      second request after 500 ms sleeps 500 ms, not the remaining 1500 ms.
      Flutter `_getRedditJson(...)` sleeps `2 seconds - elapsed`, which is the
      intuitive throttle but not Java-compatible timing. The user agent also
      differs: Java includes `RipMe:github.com/RipMeApp/ripme:<jar version>
      (by /u/metaprime and /u/ineedmorealts)`, while Flutter sends a
      `flutter-port` marker.
- [ ] Java Reddit next-page construction uses `Utils.stripURLParameter(url,
      "after")`, whose implementation searches for the substring `"?after"` or
      `"&after"` and removes that segment before appending the new token with
      `?after=` or `&after=`. This is not structured query parsing and can also
      match parameter names that merely start with `after`. Flutter
      `RedditRipper.nextPageUrl(...)` builds a `queryParameters` map and assigns
      `after`, preserving other parameters structurally and avoiding Java's
      prefix-removal behavior.
- [ ] Java `RedditRipper.getJsonURL(...)` appends `.json` directly to
      `url.getPath()` and preserves any trailing slash, so
      `https://reddit.com/r/example/` becomes
      `https://reddit.com/r/example/.json`. Flutter `RedditRipper.getJsonUrl`
      strips a trailing slash before replacing the path, producing
      `https://reddit.com/r/example.json`. Reddit URLs ending in `/` therefore
      hit different JSON endpoints.
- [ ] Java `RedditRipper.canRip(...)` accepts any host ending in `reddit.com`,
      but Java `getGID(...)` and gallery `getJsonURL(...)` regexes only allow
      `[a-zA-Z0-9.]{0,4}` before `reddit.com`; longer accepted subdomains can
      pass construction and then fail during GID/JSON routing. Flutter
      `RedditRipper.getGID(...)` uses `[a-zA-Z0-9.]*reddit.com`, so the same
      longer subdomain URLs can succeed instead of matching Java's later
      rejection.
- [ ] Java Reddit upvote filtering defaults to
      `reddit.min_upvotes = Integer.MIN_VALUE` and
      `reddit.max_upvotes = Integer.MAX_VALUE`, and when filtering skips a post
      it sends `DOWNLOAD_WARN` with `Skipping post with score outside specified
      range of ...`. Flutter `_shouldSkipByUpvotes(...)` defaults to `0` and
      `10000`, ignores filtering when `score` is not an int, and returns an
      empty media list without emitting the Java warning. Enabling
      `reddit.rip_by_upvote` therefore changes default filtering and status
      output.
- [ ] Java `RedditRipper.parseJsonChild(...)` handles self posts by extracting
      body links and then fetching the post's own `.json` URL to call
      `saveText(...)`, which renders and writes the self-post HTML plus comments
      when `selftext` is non-empty. Flutter `extractSelfPostHtmlFromJson(...)`
      only exports HTML when the current JSON already contains a post listing
      followed by a comments listing; listing-only self posts explicitly
      produce no HTML in the Dart test suite. Java would make a second request
      and try to save the HTML for those listing self posts.
- [ ] Java `RedditRipper.saveText(...)` and nested comment rendering use strict
      JSON fields (`title`, `id`, `author`, integer `created`, `subreddit`,
      `selftext_html`, `url`, `body_html`, `name`) and catch/render nested
      comment failures per comment. Flutter `_selfPostHtmlFromData(...)` and
      `_renderComment(...)` default missing fields to empty strings, choose
      `permalink` as a fallback URL, and use local timezone string formatting
      instead of Java `new Date(...).toString()`. The generated HTML and
      malformed-comment behavior are not yet proven Java-compatible.
- [ ] Java `RedditRipper.handleGallery(...)` strictly dereferences
      `gallery_data.items[*].media_id`, matching `media_metadata[media_id].s`,
      and then `gif`/`u`, catching malformed gallery entries only after logging
      the full `gallery_data` and `media_metadata`. Flutter
      `_mediaFromGallery(...)` returns an empty list for missing/non-list
      gallery items or non-map metadata, and silently skips entries with missing
      metadata, `s`, `gif`, or `u`. Malformed Reddit galleries can therefore
      disappear quietly instead of following Java's logged per-item failure
      path.
- [ ] Java per-ripper warning/error status messages must be checked where they
      feed UI parity, especially `DOWNLOAD_WARN`, `DOWNLOAD_ERRORED`,
      `RIP_ERRORED`, `NO_ALBUM_OR_USER`, and `DOWNLOAD_COMPLETE_HISTORY`
      sends from DeviantArt max-resolution/search failures, E621 cookie and
      blacklist warnings, E-Hentai/Nhentai/Tsumino blacklist skips, Flickr API
      key fallback warnings, Furaffinity shared-account errors, Imagefap
      throttling warnings, Tumblr `NO_ALBUM_OR_USER` and rate-limit handling,
      and Reddit upvote-filter/download-history completion messages.
- [ ] Java `E621Ripper.getNextPage(...)` throws `IOException("No more pages.")`
      when `a#paginator-next` is absent, and `E621RipperTest` asserts that
      exact message for both current and legacy URL styles. Flutter
      `E621Ripper.getNextPage(...)` currently returns `null` for the same case,
      and its Dart test asserts `null`, so the no-next-page contract is not
      Java-compatible.
- [ ] Java `E621Ripper.getNextPage(...)` also treats a present
      `a#paginator-next` with an empty `href` as a page to fetch, because it
      checks only whether the selector is empty before passing
      `attr("abs:href")` to `getDocument(...)`. Flutter reads the raw `href`
      and returns `null` when it is absent or empty, so malformed next anchors
      are silent completion in Flutter instead of Java's fetch/failure path.
- [ ] Java `E621Ripper.downloadURL(...)` sleeps, then queues an
      `E621FileThread` with the candidate's Java prefix. The thread catches
      post-page fetch and direct-image URI failures and logs
      `Unable to get full sized image from <post-url>`, while only blacklist
      pages send the explicit `RIP_ERRORED` blacklist message. Flutter
      `E621Ripper.fullSizedImage(...)` catches all fetch failures and returns
      `null`; if all post candidates on a page return `null`, `rip()` emits
      `RipStatus.ripErrored` with `No images found at <album-url>`. E621
      per-post failure diagnostics and all-failed-page status behavior are not
      Java-compatible.
- [ ] Java test-backed pagination exception contracts extend beyond E621:
      `HqpornerRipperTest` asserts `IOException("No next page found.")`,
      `PornhubRipperTest` asserts `IOException("No more pages")`, and
      `PhotobucketRipperTest` has a disabled-but-source-present assertion for
      `IOException("No more pages")`. Flutter Hqporner/Pornhub tests currently
      assert nullable no-next-page helpers, and Photobucket has no equivalent
      no-next-page assertion, so pagination end-state behavior needs a shared
      Java-compatible decision.
- [ ] Java `PornhubRipper.downloadURL(...)` queues a
      `PornhubImageThread` for each photo page and sleeps after queueing; the
      thread logs `[!] Exception while loading/parsing <photo-page-url>` for
      fetch, missing-image/null-dereference, or URI failures. Flutter
      `_queueImageFromPage(...)` catches every image-page failure with
      `catch (_) { return; }` and `directImageUrlFromDocument(...)` returns
      `null` for missing/empty image sources, so broken Pornhub photo pages are
      silent skips instead of Java-visible per-page failures.
- [ ] Java `HentaifoundryRipper.getNextPage(...)` also throws
      `IOException("No more pages")` when `li.next.hidden` is present or the
      next-page anchor is missing. Flutter `HentaifoundryRipper.getNextPage(...)`
      returns `null` for both end states, and its Dart tests do not prove the
      Java exception contract.
- [ ] Java `DerpiRipper.getNextPage(...)` throws
      `IOException("No more images")` when the next JSON response has neither
      `images` nor `search`, or when the selected array is empty. Flutter
      `DerpiRipper.getNextPage()` returns `null` for the same no-more-images
      states, and the Dart tests cover URL/media parsing but not the Java
      exception contract.
- [ ] Java `DerpiRipper.getURLsFromJSON(...)` strictly iterates `images` or
      legacy `search` arrays with `arr.getJSONObject(i)` before requiring
      `representations.full`; any non-object array entry aborts the parse.
      Flutter `DerpiRipper.urlsFromJson(...)` skips non-map entries before
      calling `getImageUrlFromJson(...)`, so malformed mixed arrays can
      silently lose entries or become a later `No images found at ...` error
      instead of Java's parser failure.
- [ ] Java `CoomerPartyRipper.getNextPage(...)` always advances to the next
      50-post offset and returns a wrapped JSON array; it does not stop when a
      page has fewer than 50 posts, so an empty later page reaches
      `AbstractJSONRipper`'s `No images found at ...` failure path. Flutter
      `CoomerPartyRipper.parseJSON(...)` stops cleanly when `posts.length < 50`
      and only throws on an empty first page, changing end-of-rip semantics.
- [ ] Java `CoomerPartyRipper.canRip(...)` accepts any host ending in
      `coomer.party` or `coomer.su`, then its constructor reads path elements
      `0` and `2` before the blank/null guard. Short accepted paths therefore
      throw `IndexOutOfBoundsException` rather than the later
      `MalformedURLException("Invalid coomer.party URL: ...")`. Flutter
      `_pathElement(...)` throws a controlled `FormatException`, so malformed
      Coomer URL behavior is not Java-compatible.
- [ ] Java `CoomerPartyRipper.pullFileUrl(...)` and
      `pullAttachmentUrls(...)` catch `JSONException`, log
      `Unable to Parse FileURL ...` / `Unable to Parse AttachmentURL ...`, and
      log `Unknown extension for coomer.su path: ...` when a parsed path is not
      an image or video. Flutter `_pullFileUrl(...)` /
      `_pullAttachmentUrls(...)` silently return for missing/non-map `file`,
      missing/non-string `path`, missing/non-list attachments, non-map
      attachments, and unknown extensions. The resulting URL list can match,
      but the Java diagnostic/error surface for malformed Coomer posts is
      absent.
- [ ] Java `FlickrRipper.getLargestImageURL(...)` logs JSON/malformed/IO
      failures while reading `flickr.photos.getSizes`, then still returns
      `imageURLMap.lastEntry().getValue()`; if no sizes were recorded this can
      fail instead of skipping the photo. Flutter `largestImageUrlFromSizesJson`
      and `_largestImageUrl(...)` return `null` for missing/empty size data and
      `rip()` silently continues, so Flickr size-lookup failure semantics are
      not Java-compatible.
- [ ] Java `FlickrRipper.getJSON(...)` catches only `IOException` from a Flickr
      API page fetch and returns `null`, after which `getURLsFromPage(...)`
      immediately calls `jsonData.has("stat")`; malformed/non-object JSON
      returned with HTTP 200 also throws from `new JSONObject(...)`. Flutter
      `_fetchListing(...)` catches all fetch/decode failures, sends a generic
      `DOWNLOAD_WARN`, returns `null`, and `rip()` breaks cleanly. Flickr API
      transport and malformed-response failures therefore become quiet
      completion in Flutter instead of Java's null dereference or parser
      failure.
- [ ] Java `FlickrRipper.getURLsFromPage(...)` strictly reads listing root
      `pages`, `photo`, and each photo `id`; missing `photoset` falls back to
      `photos`, but missing both only logs and breaks. Flutter
      `photoIdsFromListJson(...)` returns `null` for missing roots or non-list
      `photo`, parses non-integer `pages` as `0`, and skips photo entries
      missing `id`. This can shorten a Flickr rip or produce partial output
      where Java would throw or log a root-level failure.
- [ ] Java `FuraffinityRipper.getNextPage(...)` throws
      `IOException("No more pages")` when no `a.right` next-page link exists.
      Flutter `FuraffinityRipper.getNextPage(...)` returns `null`, so
      Furaffinity pagination end-state behavior follows Flutter's nullable
      helper convention instead of Java's exception contract.
- [ ] Java `FuraffinityRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any
      host ending in `furaffinity.net` is accepted before `getGID(...)`
      validates `/gallery/USER` or `/scraps/USER` on `www.furaffinity.net`.
      Flutter `FuraffinityRipper.canRip(...)` applies those two regexes
      directly, narrowing Java's domain-level dispatch surface.
- [ ] Java `FuraffinityRipper.getURLsFromPage(...)` calls
      `getImageFromPost(...)`, but then checks the ripper field `url != null`
      before calling `urlToAdd.startsWith("http")`; if an image post has no
      Download link or fetch fails, `urlToAdd` can be `null` and Java can throw.
      Flutter checks `imageUrl != null` and skips the post, changing missing
      image-link failure behavior.
- [ ] Java `FuraffinityRipper.setCookies(...)` parses
      `furaffinity.cookies` through shared `RipUtils.getCookiesFromString(...)`
      and sends `DOWNLOAD_ERRORED` when the configured value equals the bundled
      shared account cookie string. Flutter reimplements cookie parsing locally
      in `FuraffinityRipper.parseCookies(...)`, so it needs proof that malformed
      cookie strings, repeated keys, whitespace, and empty values match the
      Java helper exactly before login/cookie parity can be claimed.
- [ ] Java `FuraffinityRipper` overrides `hasDescriptionSupport()` to `false`
      but still implements `getDescriptionsFromPage(...)`, `getDescription(...)`,
      `descSleepTime()`, and `saveText(...)` with FurAffinity-specific title
      rewriting and text cleanup. Flutter has no corresponding description/text
      pipeline in `furaffinity_ripper.dart`. Because the Java support flag is
      false, this may be intentionally dormant, but the migration audit needs a
      decision and test evidence before treating FurAffinity description parity
      as closed.
- [ ] Java `ImagefapRipper.getNextPage(...)` throws
      `IOException("No next page found")` when no `a.link3` text contains
      `next`. Flutter `ImagefapRipper.getNextPage(...)` returns `null` for the
      same end state, and its Dart test currently asserts only the positive
      next-link construction path.
- [ ] Java `ImagefapRipper.getURLsFromPage(...)` skips thumbnails only when the
      thumbnail itself lacks `src` or `width`; it then calls
      `getFullSizedImage("https://www.imagefap.com" + thumb.parent().attr("href"))`
      even when the parent `href` is empty, retrying the site root before
      failing. Flutter reads the parent `href` as nullable and `continue`s when
      it is missing or empty, silently dropping malformed thumbnail entries.
- [ ] Mechanical Java `getNextPage`/pagination exception scan found additional
      source-backed no-next-page/no-more-results contracts that need exact
      Flutter parity checks instead of assuming nullable helpers are equivalent:
      `ArtStationRipper` (`No more projects`), `CfakeRipper` (`No more pages
      (cannot find nav/anchor/last page)`), `CheveretoRipper`,
      `DeviantartRipper`, `DribbbleRipper`, `DynastyscansRipper`,
      `FapwizRipper` (`No more pages.`), `FivehundredpxRipper`
      (`No more pages` / `No more results`), `FreeComicOnlineRipper`,
      `Hentai2readRipper`, `HentaiimageRipper`, `ImagebamRipper`,
      `JabArchivesRipper`, `MastodonRipper`, `MyhentaicomicsRipper`,
      `NewgroundsRipper`, `NfsfwRipper`, `NsfwXxxRipper`, `OglafRipper`,
      `PichunterRipper`, `PicstatioRipper`, `PorncomixinfoRipper`,
      `Rule34Ripper`, `SankakuComplexRipper`, `SinfestRipper`, `SmuttyRipper`,
      `ThechiveRipper` (`No more pages.`), `TheyiffgalleryRipper`,
      `TwodgalleriesRipper` (`No more images to retrieve`), `WebtoonsRipper`,
      `WordpressComicRipper`, and `XhamsterRipper`. Several of these Flutter
      rippers already expose nullable `getNextPage` helpers, so later fix work
      must decide whether to restore Java's exact exceptions/messages or
      document a deliberate cross-platform replacement.
- [ ] Java `ArtStationRipper.parseURL(...)` only falls back from an artwork
      HTML page to `https://www.artstation.com/projects/<id>.json` when the
      HTML request returns status `403` and the URL contains `artwork/`; other
      IO failures are caught into an empty HTML string and resolve to
      `URL_TYPE.UNKNOWN`. Flutter `ArtStationRipper.parseUrl(...)` catches any
      `Http.getText` failure for an artwork URL, and
      `parseUrlFromHtml(...)` also treats empty artwork HTML as a single
      project. That widens Java's Cloudflare-only fallback and can rip URLs
      Java would reject with the expected ArtStation URL-format error.
- [ ] Java `ArtStationRipper.getURLsFromJSON(...)` strictly reads
      `json.getString("title")`, `json.getJSONArray("assets")`, each asset as a
      `JSONObject`, and each `image_url` string before filtering only the empty
      `image_url` case. Flutter `ArtStationRipper.urlsFromProjectJson(...)`
      returns an empty list for non-map/non-list JSON, skips non-map asset
      entries, treats missing `title` as nullable, and drops missing/empty
      `image_url` values. Malformed project JSON can therefore become a clean
      empty or partial rip in Flutter where Java would throw.
- [ ] Java `ArtStationRipper` portfolio traversal has source-visible index
      semantics that Flutter does not reproduce: `getFirstPage()` downloads
      `data[0]`, then the first `getNextPage(...)` initializes
      `projectIndex = 0` and returns `data[0]` again when `total_count > 1`,
      while the `total_count > currentProject` guard skips the final project.
      Flutter `_downloadPortfolio(...)` walks each returned `data` page once
      and increments `processed` per item, so multi-project ArtStation
      portfolios avoid Java's duplicate-first/skip-last behavior instead of
      matching it.
- [ ] Java `LusciousRipper` is still an `AbstractHTMLRipper`: `rip()` first
      fetches the sanitized album page through `getCachedFirstPage()`, then
      `getURLsFromPage(...)` ignores the HTML body but strictly walks
      `data.picture.list.items` and `info.total_pages` in the GraphQL response.
      Missing JSON structure propagates as a JSON exception or an empty list
      that `AbstractHTMLRipper.rip()` turns into `IOException("No images found
      at ...")`. Flutter `LusciousRipper.rip()` bypasses the album HTML fetch,
      `totalPagesFromJson({})` returns `1`, `urlsFromJson({})` returns an empty
      list, and the rip can send `ripComplete` with no downloads. That changes
      both source-page validation and malformed/empty API failure behavior.
- [ ] Java `LusciousRipper` also inherits `AbstractHTMLRipper.canRip(...)`, so
      any host ending in `luscious.net` is accepted before `getGID(...)`
      validates the `/albums/...` shape. Flutter `LusciousRipper.canRip(...)`
      applies the album regex directly, narrowing Java's domain-level dispatch
      surface for non-album Luscious URLs.
- [ ] Java `RedgifsRipper.sanitizeURL(...)` removes `/gifs/detail` rather
      than rewriting it to `/watch`; for
      `https://www.redgifs.com/gifs/detail/exampleid`, Java sanitizes to
      `https://www.redgifs.com/exampleid`, which does not match the singleton
      pattern and later fails `getGID(...)`. Flutter
      `RedgifsRipper.sanitizeUrl(...)` rewrites `/gifs/detail/` to `/watch/`,
      and the Dart test currently asserts the broader accepted URL form. This
      is an intentional-or-not behavior expansion that must be decided and
      tested against Java compatibility.
- [ ] Java `RedgifsRipper.getURLsForGallery(...)` catches `IOException` from
      the gallery API, logs `Error fetching gallery <galleryID> for gif
      <gifID>`, and returns only the URLs accumulated so far, while Flutter
      `_getUrlsForGallery(...)` lets `Http.getJSON(...)` and malformed gallery
      response failures propagate. Gallery handling already has a Java TODO,
      so parity work must cover both successful gallery expansion and this
      partial-failure behavior instead of relying on singleton video tests.
- [ ] Java `RedgifsRipper.getURLsFromJSON(...)`, `getURLsForGallery(...)`, and
      static `getVideoURL(...)` strictly read `gif.urls.hd` with
      `getString("hd")`; a response that only contains `sd` throws through JSON
      parsing instead of downloading a lower-quality fallback. Flutter
      `_getUrlsFromJson(...)`, `_getUrlsForGallery(...)`, and `getVideoUrl(...)`
      all fall back from `hd` to `sd`, changing both malformed API failure
      semantics and selected media quality.
- [ ] Java `RedgifsRipper.getSearchOrTagsURL(...)` logs warnings for
      unsupported `tab` values, unexpected query parameters, and missing
      tags/search tab selections before defaulting to GIF results. Flutter
      `_searchOrTagsUri(...)` silently ignores unknown query parameters and
      unsupported tab values while defaulting to GIFs, so Redgifs search/tag URL
      normalization loses Java's warning diagnostics.
- [ ] Java `ScrolllerRipper.getPosts(...)` catches transport/parsing failures
      and returns `new JSONObject("{}")`, after which
      `getURLsFromJSON(...)` strictly dereferences
      `data.getSubreddit.children.items` and fails on malformed or empty GraphQL
      structure. Flutter `ScrolllerRipper.urlsFromJson(...)` returns an empty
      list when the same structure is missing, and `rip()` can then send
      `ripComplete` without reporting the Java-style no-images/malformed-page
      failure. This is separate from the already-tested query shape and
      Java-compatible best-area bug.
- [ ] Java `ScrolllerRipper` inherits `AbstractJSONRipper.canRip(...)`, so any
      host ending in `scrolller.com` is accepted before `getGID(...)` applies
      the `https?://scrolller.com/r/[a-zA-Z0-9]+` regex. Flutter
      `ScrolllerRipper.canRip(...)` applies that regex directly, and its Dart
      test rejects `www.scrolller.com` and hyphenated subreddit paths that Java
      would accept at dispatch and reject later.
- [ ] Java `ScrolllerRipper.convertFilterString(...)` logs
      `Invalid filter <value> using no filter` for unsupported `filter=` values
      before returning an empty filter string. Flutter `convertFilterString(...)`
      returns the same empty string silently, so invalid Scrolller filter
      diagnostics are not Java-compatible.
- [ ] Java `TwitterRipper.sanitizeURL(...)` only recognizes
      `twitter.com` and `m.twitter.com` account/search URLs. Flutter
      `TwitterRipper.classifyUrl(...)` also accepts `x.com`, and
      `twitter_ripper_test.dart` asserts `https://x.com/...` account and search
      support, so Twitter/X URL acceptance is broader than Java's shipped
      implementation.
- [ ] Java `SankakuComplexRipper.getNextPage(...)` calls
      `doc.select("div.pagination").first()` and immediately dereferences the
      result; a missing pagination block can throw before Java reaches its
      `IOException("No more pages")` path. Flutter
      `SankakuComplexRipper.getNextPage(...)` returns `null` for missing
      pagination, missing `next-page-url`, empty next URL, and page 26, so it
      turns multiple Java failure/end-state paths into a clean stop. Java also
      stores jsoup `Response.cookies()` from the first page, while Flutter
      reconstructs cookies by splitting the raw `set-cookie` header on commas,
      which is not equivalent for cookie attributes such as `Expires`.
- [ ] Java `SankakuComplexRipper` inherits `AbstractHTMLRipper.canRip(...)`,
      so any host ending in `sankakucomplex.com` is accepted before
      `getGID(...)` validates a `tags=` query. Flutter
      `SankakuComplexRipper.canRip(...)` applies the tag regex directly, and
      its Dart test rejects `https://idol.sankakucomplex.com/posts` even though
      Java would accept it at dispatch and fail later in `getGID(...)`.
- [ ] Java `SankakuComplexRipper.getSubDomain(...)` calls
      `URLDecoder.decode(m.group(1), "UTF-8")` even when the optional
      subdomain group is absent. A bare `https://sankakucomplex.com/?tags=abc`
      URL can match `getGID(...)` as `null_abc`, but `getURLsFromPage(...)`
      then dereferences the null subdomain path. Flutter returns an empty
      subdomain string for the same URL and its Dart test currently treats bare
      `sankakucomplex.com` tag URLs as supported.
- [ ] Java `SankakuComplexRipper.getURLsFromPage(...)` builds post-page URLs
      by concatenating `siteURL + postLink`; if a thumbnail href is already
      absolute, Java attempts a malformed URL such as
      `https://idol.sankakucomplex.comhttps://...`. Flutter resolves each
      `postLink` with `siteUrl.resolve(...)`, and its Dart test explicitly
      accepts an absolute thumbnail href, so post-link handling has drifted
      from Java.
- [ ] Java `SankakuComplexRipper.getURLsFromPage(...)` catches per-thumbnail
      `IOException`s from loading post pages, logs
      `Error while loading page <postLink>`, and continues. Flutter catches only
      `IOException` in the same loop but silently skips those thumbnails, so
      SankakuComplex per-post load failures lose Java's diagnostic log surface.
- [ ] Java `BooruRipper.getNextPage(...)` dereferences the first `<posts>`
      element and parses `offset` / `count` with strict
      `Integer.parseInt(...)`; missing or malformed attributes fail before a
      clean end-of-pagination result. Flutter `BooruRipper.getNextPage(...)`
      returns `null` when `<posts>` is absent and defaults malformed numeric
      attributes to zero, turning Java parse failures into a normal stop.
- [ ] Java `BooruRipper.canRip(...)` checks `url.toExternalForm().contains(...)`
      for `xbooru` or `gelbooru`, so the constructor accepts any URL string
      containing either token before later `getGID(...)` validation. Flutter
      `RipperFactory` only routes hosts containing `xbooru.com` or
      `gelbooru.com`, narrowing Java's shipped candidate-selection behavior for
      malformed or non-canonical URLs.
- [ ] Java `BooruRipper.getURLsFromPage(...)` adds
      `e.absUrl("file_url") + "#" + e.attr("id")` for every `<post>`, even when
      `file_url` is missing or empty, producing `#<id>` entries. Flutter skips
      posts whose `file_url` is missing/empty and resolves relative file URLs
      explicitly against the DAPI page URL, so malformed/relative post handling
      is not Java-identical.
- [ ] Java `EHentaiRipper.getNextPage(...)` throws
      `IOException("No navigation links found")` when `.ptt a` links are
      missing and `IOException("Reached last page of results")` when the last
      link equals `lastURL`; `AbstractHTMLRipper` logs those exceptions as the
      pagination stop path. Flutter `EHentaiRipper.getNextPage(...)` returns
      `null` for missing/empty navigation links and repeated URLs, collapsing
      Java's explicit end/failure exceptions into a clean nullable stop.
- [ ] Java `EHentaiRipper.getURLsFromPage(...)` adds every `#gdt > a`
      `href`, including the empty string when `href` is missing. Flutter
      `EHentaiRipper.imagePageUrlsFromGallery(...)` filters out empty hrefs, so
      malformed gallery entries no longer schedule the Java empty-URL image-page
      load/failure path.
- [ ] Java `EHentaiRipper.getPageWithRetries(...)` logs each IP-ban retry with
      `logger.warn("Hit rate limit while loading ...")`, and
      `EHentaiImageThread.fetchImage()` logs missing images or image-page
      exceptions before returning. Flutter `getPageWithRetries(...)` delays
      silently on the same IP-ban marker, and `downloadFromImagePage(...)`
      catches all image-page failures and returns `null` silently, so E-Hentai
      retry/missing-image log parity is missing even when the download result is
      otherwise skipped.
- [ ] Java `ImagebamRipper.getURLsFromPage(...)` selects
      `div > a[class=thumbnail]:not(.footera)`, which requires the `class`
      attribute to be exactly `thumbnail` before the `:not(.footera)` filter.
      Flutter uses `div > a.thumbnail:not(.footera)`, so links with additional
      non-`footera` classes are included by Flutter but skipped by Java.
- [ ] Java `ImagebamRipper.ImagebamImageThread.fetchImage(...)` passes the raw
      `img[class*=main-image]` `src` through `new URI(imgsrc).toURL()`;
      protocol-relative values such as `//images.example/full.jpg` fail that
      conversion instead of downloading. Flutter normalizes protocol-relative
      image sources to `https:` and its Dart test asserts that behavior, so
      direct image extraction is not Java-identical.
- [ ] Java `ImagebamRipper.ImagebamImageThread.fetchImage(...)` also isolates
      each image-page fetch/parse in a thread-level `try/catch`: missing
      `img[class*=main-image]` logs `Image not found at ...` and returns, while
      `IOException` / `URISyntaxException` logs
      `Exception while loading/parsing ...` and the album continues. Flutter
      `directImageUrlFromDocument(...)` returns `null` silently for missing
      images, and `directImageUrlFromPageUrl(...)` fetch failures escape the
      main rip loop, so Imagebam per-page diagnostics and continue/abort
      behavior are not Java-compatible.
- [ ] Java `ImagevenueRipper.getURLsFromPage(...)` adds `thumb.attr("href")`
      for every `a[target=_blank]`, including anchors with a missing or empty
      `href`, so the later image-thread URL conversion sees those empty
      candidates. Flutter `ImagevenueRipper.imagePageUrlsFromDocument(...)`
      filters missing/empty `href` values, silently dropping candidates Java
      would attempt.
- [ ] Java `ImagevenueRipper.ImagevenueImageThread.fetchImage(...)` isolates
      each image-page fetch in its own `try/catch`, logs and continues after
      `IOException`/`URISyntaxException`, and when an `a > img` exists with an
      empty `src` it still builds `http://<image-page-host>/` and queues that
      download. Flutter `directImageUrlFromPageUrl(...)` lets image-page fetch
      failures escape through `rip()`, while `directImageUrlFromDocument(...)`
      returns `null` for missing/empty `src`, so failed and malformed
      Imagevenue image pages no longer follow Java's per-page continue and
      empty-host download behavior.
- [ ] Java `ListalRipper.getURLsForFolderType(...)` appends `h` to
      `e.attr("abs:href")` for every `#browseimagescontainer .imagewrap-outer a`;
      a folder anchor with no `href` becomes the literal image-page candidate
      `h`. Flutter `ListalRipper.urlsForFolderType(...)` resolves a missing
      `href` against `https://www.listal.com/` first and returns
      `https://www.listal.com/h`, changing malformed folder-page URL
      extraction before the image-page download thread/fetch step.
- [ ] Java `ImgboxRipper.getURLsFromPage(...)` rewrites and adds
      `thumb.attr("src")` for every `div.boxed-content > a > img`, even when
      `src` is missing or empty; jsoup returns `""`, which Java then keeps as
      an empty URL candidate. Flutter `ImgboxRipper.imageUrlsFromDocument(...)`
      filters missing/empty `src` values before rewriting, so malformed
      thumbnail entries are silently skipped instead of matching Java.
- [ ] Java `ListalRipper.getNextPage(...)` starts by calling
      `super.getNextPage(page)` before switching on `urlType`; because
      `AbstractHTMLRipper.getNextPage(...)` throws `IOException("getNextPage not implemented")`,
      Listal-specific `.loadmoreitems` and folder `.pages a` pagination may be
      unreachable in the shipped Java flow. Flutter bypasses that abstract
      call and implements nullable Listal pagination directly, so next-page
      behavior is not Java-identical.
- [ ] Java `ListalRipper.downloadURL(...)` queues a
      `ListalImageDownloadThread` for each image-page candidate with the
      candidate's `index`; the thread logs `Couldnt find image from url: ...`
      for missing `.pure-img` sources and logs `[!] Exception while downloading
      image: ...` for fetch/URI failures. Flutter resolves each image page
      before creating a `RipperDownload`, `imageUrlFromImagePageUrl(...)`
      catches all failures and returns `null`, and the ordered index increments
      only after a direct image URL is found. Missing or broken Listal image
      pages are therefore silent and can shift later ordered filenames compared
      with Java.
- [ ] Java `MotherlessRipper.getFirstPage(...)` reads
      `path.charAt(2)` for every URL that reaches the ripper, so malformed or
      short paths can throw before the homepage-to-`/GM...` rewrite completes.
      Flutter `MotherlessRipper.firstPageUrl(...)` guards `path.length > 2` and
      returns the original URL for short paths, smoothing over Java's failure
      mode.
- [ ] Java `MotherlessRipper.getNextPage(...)` throws
      `IOException("Last page reached")` when `link[rel=next]` is absent, and
      separately dereferences `link[rel=canonical]` when a next link exists.
      Flutter returns `null` for a missing/empty next link and falls back to the
      original URL as referrer when canonical is absent, changing both end-state
      and malformed-page behavior.
- [ ] Java `MotherlessRipper.getURLsFromPage(...)` adds a URL for every
      `div.thumb-container a.img-container` whose `href` does not contain
      `pornmd.com`; a missing/empty `href` becomes `https://motherless.com`.
      Flutter filters empty hrefs, so malformed thumbnail anchors are silently
      skipped instead of matching Java.
- [ ] Java `MotherlessRipper.MotherlessImageRunnable.run()` handles image-page
      fetch/parse exceptions with `logger.error(...)` only, and handles a
      missing `__fileurl` token with `logger.warn(...)` only. Flutter
      `MotherlessRipper.fileUrlFromImagePage(...)` converts fetch/parse
      exceptions into `RipStatus.downloadWarn` while still returning `null`,
      so failed Motherless image pages become visible warning/count events that
      Java did not send.
- [ ] Java `OglafRipper.getNextPage(...)` throws `IOException("No more pages")`
      both when `div#nav > a > div#nx` is missing and when the parent link's
      `href` is empty. Flutter `OglafRipper.getNextPage(...)` returns `null`
      for both states, and its Dart test asserts that nullable completion
      behavior.
- [ ] Java `PichunterRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any
      host ending in `pichunter.com` is accepted before `getGID(...)` later
      validates the URL shape. Flutter `PichunterRipper.canRip(...)` requires
      one of the explicit listing/photos/tag/gallery regexes, and its Dart test
      rejects `https://pichunter.com/models/Madison_Ivy`, narrowing Java's
      domain-level support.
- [ ] Java `PichunterRipper.getNextPage(...)` dereferences the last
      `div.paperSpacings > ul > li.arrow` link when present and throws
      `IOException("No more pages")` only when the arrow list is absent.
      Flutter returns `null` for an absent arrow list, so pagination end-state
      behavior diverges even though empty `href` handling is currently tested
      as Java-compatible.
- [ ] Java `PicstatioRipper` inherits `AbstractHTMLRipper.canRip(...)`, so
      domain-level `picstatio.com` URLs are accepted before
      `getGID(...)` applies the stricter `https?://www.picstatio.com/...`
      regex. Flutter `PicstatioRipper.canRip(...)` directly uses the strict GID
      regex and its Dart test rejects `https://picstatio.com/...`, narrowing
      Java's accepted URL surface.
- [ ] Java `PicstatioRipper.getURLsFromPage(...)` assumes every `img.img`
      parent href splits into at least three slash-separated segments and adds
      the result of `getFullSizedImageFromURL(...)` even when that helper
      returns an empty `href`. Flutter filters malformed parent hrefs out of
      `wallpaperSlugsFromDocument(...)` and later skips empty `imageUrl` values
      during `rip()`, so malformed/empty media candidates no longer follow
      Java's failure path.
- [ ] Java `PorncomixinfoRipper` inherits
      `AbstractHTMLRipper.canRip(...)`, so any host ending in
      `porncomixinfo.net` is accepted before `getGID(...)` applies the stricter
      `/chapter/CHAP/ID` regex. Flutter `PorncomixinfoRipper.canRip(...)`
      directly uses that strict regex and its Dart test rejects `http://...`,
      `www...`, and `comic0` URL variants, narrowing Java's accepted
      domain-level surface.
- [ ] Java `PorncomixinfoRipper.getNextPage(...)` throws
      `IOException("No more pages")` when `a.next_page` is absent, but returns
      `null` only for a present next link with an empty `href`. Flutter
      `PorncomixinfoRipper.nextPageUrl(...)` returns `null` for both absent and
      empty next links, and the Dart test asserts nullable completion for the
      absent-link case instead of Java's exception contract.
- [ ] Java `TheyiffgalleryRipper` inherits
      `AbstractHTMLRipper.canRip(...)`, so any host ending in
      `theyiffgallery.com` is accepted before `getGID(...)` validates
      `index?/category/####`. Flutter `TheyiffgalleryRipper.canRip(...)`
      directly uses the strict category regex and its Dart test rejects
      `www.theyiffgallery.com`, narrowing Java's domain-level support.
- [ ] Java `TheyiffgalleryRipper.getNextPage(...)` throws
      `IOException("No more pages")` when the nav link is absent, empty, or
      lacks `start-`. Flutter `TheyiffgalleryRipper.nextPageFromDocument(...)`
      returns `null` for those same states, and its Dart test asserts nullable
      completion for the missing/non-start cases.
- [ ] Java `TwodgalleriesRipper.getNextPage(...)` increments the offset, loads
      the next AJAX document with cookies, and throws
      `IOException("No more images to retrieve")` when that fetched document has
      no `div.hcaption > img`. Flutter's framework-facing
      `getNextPage(...)` only returns the next AJAX URI without fetching or
      checking the image list; its separate `getNextDocument(...)` keeps the
      Java stop check for `rip()`, but callers using the inherited pagination
      contract see different behavior.
- [ ] Java `TwodgalleriesRipper.login()` stores jsoup
      `Connection.Response.cookies()` from both the initial page and login
      response. Flutter reconstructs `_cookies` by splitting raw `set-cookie`
      headers with `FuskatorRipper.cookiesFromSetCookieHeader(...)`, which is
      not equivalent for comma-bearing cookie attributes such as `Expires` and
      can alter the authenticated gallery request state.
- [ ] Java `TwodgalleriesRipper.login()` dereferences
      `resp.parse().select("form > input[name=ctoken]").first().attr("value")`,
      so a login page without that token fails through the Java null path and is
      not caught by `getFirstPage()`'s `catch (IOException)`. Flutter
      `loginTokenFromPage(...)` returns `null` and `login()` throws an explicit
      `FormatException("Could not find 2dgalleries login token")`, changing the
      malformed-login-page exception contract.
- [ ] Java `WebtoonsRipper.getFirstPage()` stores jsoup
      `Connection.Response.cookies()` before adding `needCOPPA`, `needCCPA`,
      and `needGDPR`. Flutter `WebtoonsRipper.cookiesFromResponse(...)`
      reconstructs cookies by splitting the raw `set-cookie` header on commas,
      which is not equivalent for comma-bearing cookie attributes such as
      `Expires` and can alter the referer/cookie state used for protected image
      downloads.
- [ ] Java `WebtoonsRipper.getNextPage(...)` dereferences
      `doc.select("a.pg_next").first()` and throws
      `IOException("No more pages")` only when the link exists but its `href` is
      empty or `#`; a missing link instead fails through the null dereference.
      Flutter `WebtoonsRipper.getNextPage(...)` returns `null` for missing,
      empty, and `#` links, and its Dart test asserts nullable completion for
      the missing-link case.
- [ ] Java `WordpressComicRipper.getNextPage(...)` throws
      `IOException("No more pages")` when the theme-specific next link is
      absent or has an empty `href`. Flutter `WordpressComicRipper.getNextPage`
      returns `null` for the same absent/empty cases, changing the
      Java-compatible pagination end-state into normal completion.
- [ ] Java `WordpressComicRipper.getURLsFromPage(...)` dereferences the
      theme1 comic image after trying the linked-image and direct-image
      selectors; if both are absent, `elem.attr("src")` throws. Flutter adds an
      empty string for the missing image and `rip()` skips empty image URLs, so
      malformed theme1 comic pages can complete without Java's failure.
- [ ] Java `WordpressComicRipper.getURLsFromPage(...)` also dereferences
      `span.post-date`, `h2.post-title`, and `title` for the
      `www.totempole666.com` and `themonsterunderthebed.net` title-prefix
      cases. Flutter substitutes empty strings when those elements are absent,
      producing sanitized empty-prefix filenames instead of Java's immediate
      null-dereference failure.
- [ ] Java `WordpressComicRipper.downloadURL(...)` falls through after the
      page-title-prefix branch: for `buttsmithy.com`,
      `www.totempole666.com`, and `themonsterunderthebed.net`, it calls
      `addURLToDownload(url, pageTitle + "_")` and then also calls
      `addURLToDownload(url, getPrefix(index))`, scheduling title-prefixed and
      order-prefixed download candidates. Flutter
      `WordpressComicRipper.fileNameForUrl(...)` chooses either the title
      prefix or the numeric prefix and schedules only one candidate for those
      hosts.
- [ ] Java `NewgroundsRipper.getNextPage(...)` throws
      `IOException("No more pages")` when fewer than 60 art links were seen,
      resets `count` when pagination continues, fetches the next AJAX document
      immediately, and lets that fetch failure escape to the HTML pagination
      loop. Flutter `NewgroundsRipper.getNextPage(...)` returns `null` when
      `count < 60` and otherwise only returns the next URI without resetting
      `count` or fetching/checking the document; `rip()` separately catches
      next-page fetch failures and breaks as successful completion.
- [ ] Java `NewgroundsRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any
      host ending in `newgrounds.com` is accepted before `getGID(...)` requires
      a username subdomain. Flutter constructs `NewgroundsRipper` with
      `_usernameFromUrl(...)` and `canRip(...)` uses the strict subdomain regex,
      so bare/domain-level Newgrounds URLs fail earlier than Java.
- [ ] Java `NewgroundsRipper.getURLsFromPage(...)` logs
      `IO Error on trying to check extension: <detail-url>` when a detail page
      fetch fails while probing allowed extensions, then skips that entry.
      Flutter `imageUrlsFromDocument(...)` catches `IOException` with a
      comment-only silent skip, so Newgrounds detail-probe failure diagnostics
      are not Java-compatible even when the resulting URL list matches.
- [ ] Java `JabArchivesRipper.getNextPage(...)` throws
      `IOException("No more pages")` when `a[title="Next page"]` is absent,
      sleeps, then fetches the hardcoded `https://jabarchives.com...` URL.
      Flutter `JabArchivesRipper.getNextPage(...)` returns `null` for the
      absent selector and only returns the URL; `rip()` performs the sleep/fetch
      later and catches fetch failures as quiet completion.
- [ ] Java `JabArchivesRipper.getSlug(...)` uses `Normalizer.normalize(...,
      Form.NFD)` before stripping non-word characters, so every Unicode code
      point with a Java NFD decomposition participates in title-prefix
      normalization. Flutter `JabArchivesRipper.getSlug(...)` uses a
      hardcoded Latin replacement table plus an ASCII regex, so decomposable
      characters outside that table can be dropped instead of normalized to the
      Java-compatible base character.
- [ ] Java `FreeComicOnlineRipper` inherits
      `AbstractHTMLRipper.canRip(...)`, so any host ending in
      `freecomiconline.me` is accepted before `getGID(...)` applies the strict
      `https://freecomiconline.me/comic/...` regexes. Flutter
      `FreeComicOnlineRipper.canRip(...)` directly uses those strict regexes
      and its Dart test rejects an `http://freecomiconline.me/comic/title/`
      URL, narrowing Java's domain-level support.
- [ ] Java `FreeComicOnlineRipper.getNextPage(...)` directly reads
      `doc.select("div.select-pagination a").get(1)`, so a missing or
      one-link paginator fails through jsoup's index access before the
      Java no-more-pages `IOException` path. Flutter checks `links.length <= 1`
      and returns `null`, and it also returns `null` when the second link does
      not match the chapter regex instead of throwing `IOException("No more
      pages")`.
- [ ] Java `CfakeRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any host
      ending in `cfake.com` is accepted before `getGID(...)` enforces
      `/images/celebrity/MODEL/ID`. Flutter `CfakeRipper.canRip(...)` directly
      uses the strict GID regex and its Dart test rejects `www.cfake.com`,
      narrowing Java's accepted URL surface.
- [ ] Java `CfakeRipper.getNextPage(...)` throws distinct `IOException`
      messages when the pagination nav, anchor, or next-page span is absent,
      returns `null` only for an empty `href`, and fetches the next document
      itself. Flutter collapses all absent/empty/last-page cases to `null` and
      only returns the next URI; `rip()` later catches next-fetch failures as a
      quiet stop.
- [ ] Java `CfakeRipper.getURLsFromPage(...)` adds
      `https://cfake.com` plus the transformed `src` for every matching image,
      even when `src` is missing or empty. Flutter
      `CfakeRipper.imageUrlsFromDocument(...)` skips missing/empty `src`
      values, so malformed image nodes no longer follow Java's malformed-URL
      download path.
- [ ] Java `CheveretoRipper.getAlbumTitle(...)` catches only `IOException`
      around the cached first-page title lookup; missing
      `meta[property=og:title]` or malformed title content can throw before the
      fallback to `super.getAlbumTitle(...)`. Flutter
      `CheveretoRipper.getAlbumTitle(...)` catches all failures and
      `albumTitleFromDocument(...)` returns `null` for missing/empty content,
      so those malformed album-title states quietly fall back.
- [ ] Java `CheveretoRipper.getNextPage(...)` throws
      `IOException("No more pages")` when `li.pagination-next > a` is absent,
      uses the Java reference comparison `nextPage == ""` for empty hrefs, and
      fetches the next page with the consent cookie before returning. Flutter
      returns `null` for absent/empty hrefs and only returns the URI; `rip()`
      later catches next-fetch failures as normal completion.
- [ ] Java `CheveretoRipper.getURLsFromPage(...)` adds each
      `a.image-container > img` `src` after removing `.md`, including missing
      or empty `src` values. Flutter skips missing/empty `src`, so malformed
      Chevereto image nodes are silently ignored instead of becoming Java-style
      empty/malformed download candidates.
- [ ] Java `DribbbleRipper.getNextPage(...)` throws
      `IOException("No more pages")` when `a.next_page` is absent, constructs
      `https://www.dribbble.com` plus jsoup's `attr("href")` when the link is
      present, sleeps, and fetches the next document before returning. Flutter
      returns `null` for an absent link, returns a URI without fetching it, and
      string-interpolates a missing `href` attribute as `null`
      (`https://www.dribbble.comnull`) instead of Java's empty-attribute base
      URL.
- [ ] Java `FapDungeonRipper.getURLsFromPage(...)` calls
      `doc.select("div.entry-content").get(0)`, so a malformed page without
      that container throws before any media list is returned. Its
      `returnLargestImgUrlFromSrcAndSrcset(...)` also uses
      `Integer.parseInt(...)` without catching `NumberFormatException`, so a
      malformed width descriptor aborts extraction instead of falling back to
      `src`. Flutter `FapDungeonRipper.mediaFromPage(...)` returns an empty
      list when the content container is absent and uses `int.tryParse(...)` to
      ignore malformed srcset widths, converting Java parser failures into
      successful empty/fallback media results.
- [ ] Java `SinfestRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any
      host ending in `sinfest.net` is accepted before `getGID(...)` checks the
      strict `view.php?date=...` shape. Flutter `SinfestRipper.canRip(...)`
      directly uses the strict GID regex, narrowing Java's domain-level support.
- [ ] Java `SinfestRipper.getNextPage(...)` logs
      `elem.parent().attr("href")` before checking `elem == null`, throws
      `IOException("No more pages")` for the sentinel `view.php?date=`, returns
      `null` only for an empty `href`, and fetches the next page before
      returning. Flutter's helper uses `.last` on the selector result, returns a
      URI without fetching it, and `rip()` catches both helper and fetch
      failures as a quiet stop.
- [ ] Java `Rule34Ripper.getNextPage(...)` only stops when the API document
      contains `Search error: API limited due to abuse`; otherwise it increments
      `pageNumber` and fetches the next API page regardless of whether the
      current page produced any image URLs. Flutter `Rule34Ripper.rip()` emits
      `No images found at ...` and stops whenever a page yields no downloads,
      so empty API result pages end the rip earlier than Java's pagination
      contract.
- [ ] Java `Rule34Ripper.getURLsFromPage(...)` adds the selected `file_url`
      value for every `posts > post`, including empty/missing attributes, and
      `downloadURL(...)` receives those candidates through the HTML rip loop.
      Flutter `Rule34Ripper.fileUrlsFromDocument(...)` also returns empty
      strings, but `rip()` explicitly skips `imageUrl.isEmpty`, so malformed
      post entries no longer follow Java's empty-URL download path.
- [ ] Java `VscoRipper.getUserTkn(...)` stores jsoup
      `Connection.Response.cookies()` from `https://vsco.co/content/Static`
      and returns the `vs` cookie value. Flutter `VscoRipper.getUserToken()`
      reconstructs cookies by splitting the raw `set-cookie` header on commas,
      which is not equivalent for comma-bearing cookie attributes such as
      `Expires` and can alter the VSCO AJAX token used for profile requests.
- [ ] Java `VscoRipper.getURLsFromPage(...)` lets profile parsing fail through
      strict `JSONObject` access after helper methods return `null` on fetch
      failures: `getSiteID(...)` requires `sites[0].id`, profile pages require
      `media`, each media object, `responsive_url`, and `total`. Flutter throws
      explicit `HttpException`s for missing token/site JSON but then treats
      absent/non-list `media`, non-map media items, missing `responsive_url`,
      and missing/non-numeric `total` as empty lists or zero totals, changing
      malformed VSCO profile responses into partial or clean completion.
- [ ] Java `VscoRipper.vscoImageToURL(...)` returns an empty string when a
      single-media page lacks `meta[property=og:image]`; the caller adds that
      empty string to the URL list. Flutter `imageUrlFromMediaPage(...)`
      returns `null` for a missing `og:image`, and `getURLsFromPage(...)`
      converts it into an empty list, so malformed single-media pages skip
      Java's empty-URL candidate.
- [ ] Java `ZizkiRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any host
      ending in `zizki.com` is accepted before `getGID(...)` validates the root
      or `www` URL shape. Flutter `ZizkiRipper.canRip(...)` only accepts
      exactly `zizki.com` or `www.zizki.com`, and its Dart test rejects
      `https://cdn.zizki.com/...`, narrowing Java's domain-level support.
- [ ] Java `ZizkiRipper.getAlbumTitle(...)` catches only `IOException`; missing
      `h1.title`, missing `span.creator`, or a creator span without an anchor
      can throw before the fallback to `super.getAlbumTitle(...)`. Flutter
      `albumTitleFromDocument(...)` returns `null` for missing title/author and
      `getAlbumTitle(...)` catches all failures, so malformed title markup
      quietly falls back instead of matching Java's null-dereference path.
- [ ] Java `ZizkiRipper.getFirstPage()` stores jsoup
      `Connection.Response.cookies()` and later passes that cookie map into
      `downloadURL(...)` with the album referrer. Flutter rebuilds cookies from
      the raw `set-cookie` header with `cookiesFromSetCookieHeader(...)`; this
      is not equivalent to jsoup cookie extraction for all valid Set-Cookie
      headers and can alter authenticated/referrer image downloads.
- [ ] Java `HentaiimageRipper.getNextPage(...)` throws
      `IOException("No more pages")` when no paginator span contains an anchor
      whose text is exactly `next>`, and fetches the next page before returning
      when it does find one. Flutter `HentaiimageRipper.nextPageFromDocument`
      returns `null` for the missing-next case and only returns the URI; `rip()`
      then catches next-page fetch failures as a quiet stop.
- [ ] Java `MyhentaicomicsRipper.getAlbumsToQueue(...)` queues
      `getDomain() + elem.attr("href")`, producing strings such as
      `myhentaicomics.com/index.php/...` without a scheme. Flutter
      `albumUrlsFromDocument(...)` prefixes `https://myhentaicomics.com`,
      changing the queue payloads produced for search/tag pages.
- [ ] Java `MyhentaicomicsRipper.getNextPage(...)` throws
      `IOException("No more pages")` when the right-arrow link exists but its
      `href` does not match `/index.php/<slug>?page=<digit>`. Flutter
      `nextPageUrlFromDocument(...)` returns `null` for the same non-matching
      href and ends pagination cleanly.
- [ ] Java `StaRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any host
      ending in `sta.sh` is accepted before `getGID(...)` enforces the strict
      `https://sta.sh/ALBUMID` pattern. Flutter `StaRipper.canRip(...)` only
      accepts exactly `sta.sh`, and its Dart test rejects `https://www.sta.sh`,
      narrowing Java's domain-level support.
- [ ] Java `StaRipper.getURLsFromPage(...)` catches malformed/IO failures while
      loading each thumb page but then unconditionally dereferences
      `thumbPage.select("a.dev-page-download")`; failed thumb-page loads can
      therefore null-dereference. Flutter wraps each thumb-page flow in a broad
      catch and simply continues to the next thumb, turning those Java failures
      into skipped entries.
- [ ] Java `StaRipper.getImageLinkFromDLLink(...)` returns `null` when the
      non-followed download request fails, and the caller adds that return value
      to the result list when the download link itself was non-empty. Flutter
      `imageLinkFromDownloadLink(...)` also returns `null`, but
      `getURLsFromPage(...)` skips null/empty image links, so failed Sta.sh
      download redirects no longer produce Java's null download candidate.
- [ ] Java `StaRipper` stores jsoup `Connection.Response.cookies()` from each
      thumb page and sends that cookie map to the non-followed download request.
      Flutter reconstructs cookies from raw `set-cookie` headers with
      `cookiesFromSetCookieHeader(...)`, which is not equivalent to jsoup cookie
      extraction for all valid Set-Cookie headers and can alter Sta.sh download
      redirect requests.
- [ ] Java `PahealRipper.getURLsFromPage(...)` adds `e.absUrl("href")` for
      every `.shm-thumb.thumb > a` that is not `.shm-thumb-link`, including an
      empty string when `href` is absent, and resolves relative links against
      jsoup's document base URI. Flutter `PahealRipper.urlsFromPage(...)` skips
      missing/empty hrefs and, when no explicit `baseUri` is supplied, resolves
      against `http://rule34.paheal.net` rather than the document location used
      by Java.
- [ ] Java `PahealRipper.downloadURL(...)` derives the output basename with
      `new URI(name).getPath()` inside a `try/catch`; malformed percent-encoding
      or other URI syntax errors log `Error while downloading URL ...` and skip
      that item. Flutter `PahealRipper.downloadFileName(...)` calls
      `Uri.decodeComponent(name)` without a per-download catch, so malformed
      Paheal filenames can abort the rip path instead of following Java's
      logger-only skip behavior.
- [ ] Java `PornpicsRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any
      host ending in `pornpics.com` is accepted before `getGID(...)` checks the
      strict `www.pornpics.com/galleries/ID` shape. Flutter
      `PornpicsRipper.canRip(...)` directly uses the strict GID regex and its
      Dart test rejects `https://pornpics.com/galleries/...`, narrowing Java's
      domain-level URL support.
- [ ] Java `PornpicsRipper.getURLsFromPage(...)` adds every `a.rel-link`
      `href`, including an empty string when the attribute is absent. Flutter
      `PornpicsRipper.imageUrlsFromDocument(...)` returns the same list helper
      values, but `rip()` explicitly skips empty `imageUrl` values, so malformed
      rel-link anchors no longer follow Java's empty-URL download path.
- [ ] Java `JagodibujaRipper.getURLsFromPage(...)` only catches
      `IOException` around each child comic page. If the child page loads but
      lacks `span.full-size-link > a`, Java dereferences `elem.attr("href")`
      and fails; Flutter `JagodibujaRipper.getURLsFromPage(...)` catches all
      errors from the child-page flow and silently skips that entry.
- [ ] Java `JagodibujaRipper.getURLsFromPage(...)` schedules downloads
      immediately with `addURLToDownload(new URI(elem.attr("href")).toURL(), "")`
      and leaves `downloadURL(...)` empty, while also adding the href to its
      returned list. Flutter defers scheduling until `rip()` converts returned
      strings into `RipperDownload`s with generated filenames, so malformed
      full-size hrefs and download naming/order do not follow Java's in-method
      scheduling path.
- [ ] Java `Jpg3Ripper.getNextPage(...)` fetches the next page document with
      `Http.url(href).get()` before returning it, so next-page request failures
      escape through the HTML pagination loop. Flutter `Jpg3Ripper.getNextPage`
      returns only the next URI and `rip()` catches next-page fetch failures as
      gallery errors, changing where and how Java's pagination look-ahead
      failure is surfaced.
- [ ] Java `MrCongRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any
      host ending in `misskon.com` is accepted before `getGID(...)` checks the
      gallery/tag regexes. Flutter `MrCongRipper.canRip(...)` requires the URL
      to match those strict regexes up front, narrowing Java's domain-level
      acceptance behavior.
- [ ] Java non-tag `MrCongRipper.getNextPage(...)` throws
      `IOException("Error: Page number provided goes past last valid page number\n")`
      after the final gallery page. Flutter `MrCongRipper.getNextPage(...)`
      returns `null` when `currPageNum >= lastPageNum`, turning Java's final-page
      exception path into normal pagination completion.
- [ ] Java `MrCongRipper.getNextPage(...)` mutates `url`, fetches the next
      document immediately into `currDoc`, increments `currPageNum`, and returns
      the fetched document. Flutter returns only the computed `Uri`, increments
      state before the caller fetches it, and lets `rip()` perform the request,
      so failed next-page loads can leave different current-page state and error
      reporting than Java.
- [ ] Java tag-page `MrCongRipper.downloadURL(...)` recursively constructs a
      new `MrCongRipper` for each collected child gallery URL, calls `setup()`,
      and runs `rip()` immediately. Flutter tag-page `rip()` only emits
      `RipStatus.queueAdd` messages for the collected child URLs and completes,
      so tag pages no longer execute the same recursive child-gallery rip flow.
- [ ] Java `HentaifoxRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any
      host ending in `hentaifox.com` is accepted before `getGID(...)` checks the
      strict `https://hentaifox.com/gallery/ID` shape. Flutter
      `HentaifoxRipper.canRip(...)` directly uses the strict gallery regex,
      narrowing Java's domain-level support.
- [ ] Java `HypnohubRipper.ripPost(...)` uses
      `doc.selectFirst("a:matchesOwn(^Original image$")`, a malformed jsoup
      selector, for the Original-image fallback in both string and document
      variants. Flutter `HypnohubRipper.imageUrlFromPostDocument(...)` instead
      scans `a[href]` text and successfully supports the Original-image fallback,
      so post pages without `img#image` no longer follow Java's selector-failure
      behavior.
- [ ] Java `HypnohubRipper.ripPost(...)` logs
      `No image found on post page...` / `No image found in document...` when
      all image selectors fail, and pool rips log `Failed to rip post...` for
      per-post `IOException`s before continuing. Flutter returns `null` or
      catches the fetch failure with a comment-only silent skip, so those
      Hypnohub missing-image and per-post failure diagnostics disappear from the
      Java-compatible log/status surface.
- [ ] Java `MultpornRipper.getGID(...)` may rewrite the instance `url` to the
      canonical `/node/ID/...` simple-mode URL, and `downloadURL(...)` passes
      that `this.url.toExternalForm()` as the download referrer via
      `addURLToDownload(...)`. Flutter uses the canonical URL for loading the
      page, but its `RipperDownload` path does not carry Java's canonical
      Multporn referrer into each image download.
- [ ] Java `PorncomixRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any
      host ending in `porncomix.info` is accepted before `getGID(...)` checks
      the strict `www.porncomix.info/SLUG` pattern. Flutter
      `PorncomixRipper.canRip(...)` directly uses the strict GID regex,
      narrowing Java's domain-level support.
- [ ] Java `ShesFreakyRipper` and `TsuminoRipper` inherit
      `AbstractHTMLRipper.canRip(...)`, so any host ending in
      `shesfreaky.com` or `tsumino.com` is accepted before their strict
      `getGID(...)` regexes run. Flutter `ShesFreakyRipper.canRip(...)` and
      `TsuminoRipper.canRip(...)` use those strict regexes directly; additionally,
      `RipperFactory` only routes exact `www.tsumino.com` hosts and constructs
      `TsuminoRipper` without calling its `canRip(...)`, so Tsumino dispatch does
      not match Java's domain-level constructor guard.
- [ ] Java `ReadcomicRipper` and `ViewcomicRipper` inherit
      `AbstractHTMLRipper.canRip(...)`, so any host ending in `read-comic.com`
      or `view-comic.com` is accepted before their strict slug-only
      `getGID(...)` regexes run. Flutter `ReadcomicRipper.canRip(...)` and
      `ViewcomicRipper.canRip(...)` use those strict regexes directly.
- [ ] Java `ReadcomicRipper.getURLsFromPage(...)` and
      `ViewcomicRipper.getURLsFromPage(...)` add each selected image `src`,
      including the empty string when `src` is absent. Flutter helpers return
      the same empty strings, but both `rip()` implementations skip empty image
      URLs before scheduling downloads, removing Java's empty-URL download path.
- [ ] Java `ViewcomicRipper.getAlbumTitle(...)`, inherited by
      `ReadcomicRipper`, only catches `IOException`; a cached page with no
      `<title>` element can null-dereference at `.first().text()`. Flutter
      title extraction treats a missing `<title>` as an empty string and returns
      `view-comic_`/`read-comic_` rather than surfacing Java's failure.
- [ ] Java `ArtstnRipper.getFinalUrl(...)` follows `location` redirects by
      constructing `new URI(response.header("location")).toURL()`, so relative
      redirect locations fail URL conversion instead of being resolved against
      the short URL. Flutter `ArtstnRipper.redirectTarget(...)` uses
      `source.resolve(location)`, so relative ArtStation short-link redirects
      are accepted rather than following Java's failure path.
- [ ] Java `ArtstnRipper.getGID(...)` logs redirect-resolution failures and then
      calls `super.getGID(artStationUrl)` even if `artStationUrl` is still
      `null`, allowing the Java failure to surface through the superclass/null
      path. Flutter throws `FormatException('Could not resolve ArtStation short URL...')`
      as soon as the final URL is unresolved, changing the observable error.
- [ ] Java `FemjoyhunterRipper` inherits `AbstractHTMLRipper.canRip(...)`, so
      any host ending in `femjoyhunter.com` is accepted before `getGID(...)`.
      Flutter `FemjoyhunterRipper.canRip(...)` requires a `www.femjoyhunter.com`
      URL that matches the GID regex, narrowing Java's domain-level acceptance.
- [ ] Java `FemjoyhunterRipper.getGID(...)` uses `Matcher.matches()` with
      `https?://www.femjoyhunter.com/SLUG/?`, so the whole URL must match.
      Flutter uses `RegExp.hasMatch`/`firstMatch` with the same unanchored
      pattern, accepting longer URLs whose prefix matches where Java would throw.
- [ ] Java `FitnakedgirlsRipper` inherits `AbstractHTMLRipper.canRip(...)`, so
      any host ending in `fitnakedgirls.com` is accepted before its gallery
      regex runs. Flutter `FitnakedgirlsRipper.canRip(...)` requires the strict
      `/photos/gallery/...` pattern up front, narrowing Java's URL acceptance.
- [ ] Java `XcartxRipper` and `XlecxRipper` inherit domain-level
      `AbstractHTMLRipper.canRip(...)`, then rely on `getGID(...)` to reject
      non-matching `.html` pages. Flutter also uses domain-level `canRip(...)`,
      but Dart `XcartxRipper.getGID(...)` anchors and escapes `.html` more
      strictly than Java's `^https?://xcartx.com/SLUG.html` `matches()` pattern,
      changing which xcartx URLs are rejected at GID time.
- [ ] Java `XlecxRipper` inherits `XcartxRipper.getURLsFromPage(...)`, whose
      image URL construction calls virtual `getDomain()`, so Xlecx image URLs
      are prefixed with `https://xlecx.org`. Flutter `XlecxRipper` inherits
      Dart `XcartxRipper.imageUrlsFromDocument(...)`, which hard-codes
      `https://xcartx.com`, so Xlecx downloads are pointed at the wrong host.
- [ ] Java `ChanRipper.getURLsFromPage(...)` sends non-self-hosted links through
      `RipUtils.getFilesFromURL(...)`, which expands redgifs/gifdeliverynetwork
      pages, preserves `v.redd.it` URLs, handles `i.reddituploads.com`, and
      returns generic direct media URLs in addition to Imgur, Vidble, Erome, and
      Soundgasm. Flutter `ChanRipper` delegates that branch to
      `RedditRipper.expandNonDirectUrl(...)`, which currently covers only the
      latter subset, so several Java-expanded Chan links now disappear.
- [ ] Java `ChanRipper.canRip(...)` accepts baked-in or configured chan domains
      without validating a board/thread path, and `getHost()` later reads
      `this.url.toExternalForm().split("/")[3]`. A bare accepted domain can
      therefore fail with the Java split/index behavior. Flutter
      `ChanRipper.getHost()` uses `url.pathSegments.isNotEmpty ? first : ''`,
      returning an empty board instead of matching the Java malformed-path
      failure.
- [ ] Java `NsfwXxxRipper.getNextPage(...)` strictly reads
      `doc.getInt("page")`, requires `nextPage.getJSONArray("items")`, and
      throws `IOException("No more pages")` when that array is empty. Flutter
      returns `null` when `page` is absent/non-integer or when `items` is
      absent/empty, and `entriesFromJson(...)` returns an empty list when the
      first page has no `items`. This changes malformed JSON and no-next-page
      behavior into nullable completion instead of Java's exception contracts.
- [ ] Mechanical Java strict-JSON access scan found additional rippers whose
      Java source uses `JSONObject.get*` / `JSONArray.get*` contracts that
      throw on missing or malformed API data, while the current Flutter tree has
      many nullable casts, `??`, and empty-list returns in corresponding parser
      code. Exact parity checks are still required for at least:
      `ArtStationRipper`, `BatoRipper`, `CoomerPartyRipper`,
      `DanbooruRipper`, `DerpiRipper`, `DynastyscansRipper`,
      `FivehundredpxRipper`, `FuskatorRipper`, `HentaiNexusRipper`,
      `HitomiRipper`, `ImgurRipper`, `InstagramRipper`, `MangadexRipper`,
      `MastodonRipper`, `PhotobucketRipper`, `RedditRipper`, `TapasticRipper`,
      `ThechiveRipper`, `TsuminoRipper`, and `TumblrRipper`. This is not a
      request to make Dart brittle everywhere; it is a requirement to decide,
      per source-backed case, whether Java's thrown parse failure, Java's
      `No images found at ...`, or a deliberate Flutter replacement is the
      compatible behavior.
- [ ] Java `MastodonRipper.getNextPage(...)` throws
      `IOException("No more pages")` when the `.load-more.load-gap` selector is
      absent, and it lets a failed `Http.url(nextUrl).get()` escape to
      `AbstractHTMLRipper`'s pagination handling. Flutter
      `MastodonRipper.nextPageUrl(...)` returns `null` for a missing selector,
      missing `href`, or empty `href`, and `rip()` catches next-page fetch
      failures and breaks before sending `ripComplete`. The Mastodon-family
      ports (`BaraagRipper`, `MastodonXyzRipper`, `PawooRipper`) inherit this
      nullable/quiet-stop behavior instead of Java's exception contract.
- [ ] Java `MastodonRipper.getURLsFromPage(...)` strictly parses each
      `data-props` value as JSON, requires `media`, and requires each media
      item's `url` and `id`. Flutter `MastodonRipper.mediaFromDocument(...)`
      skips empty `data-props`, non-map decoded JSON, missing/non-list `media`,
      non-map media entries, and entries missing `url`/`id`. Malformed Mastodon
      gallery markup can therefore become a successful empty page in Flutter
      where Java would throw before completing.
- [ ] Java `DanbooruRipper.getURLsFromJSON(...)` strictly requires
      `resources` to exist and every iterated entry to be a JSON object, while
      only the optional `file_url` key is guarded with `has("file_url")`.
      Flutter `DanbooruRipper.urlsFromJson(...)` returns an empty list when
      `resources` is absent/non-list and skips non-map resources. Under
      `AbstractJSONRipper`, Java malformed `resources` fails at parser time,
      while Flutter can convert it into a `No images found at ...` rip error or
      silently skip malformed entries.
- [ ] Java `FivehundredpxRipper.getFirstPage(...)` strictly aggregates root
      `/galleries` and `/stories` responses: it requires `galleries` /
      `blog_posts`, each gallery/story object, `id`, `user_id`, nested
      `user.username`, and each fetched child response's `photos`. Flutter
      `FivehundredpxRipper.getFirstPage(...)` skips non-list or malformed
      gallery/blog containers, uses nullable IDs/usernames in child API URLs,
      and ignores child responses whose `photos` value is absent/non-list. Root
      gallery/story malformed data can therefore become an empty or partial
      result in Flutter where Java would fail while building the first page.
- [ ] Java `FivehundredpxRipper.getURLsFromJSON(...)` strictly requires
      top-level `photos`, each photo object, `url`, and fallback `image_url`;
      `AbstractJSONRipper.rip()` then throws `IOException("No images found at
      ...")` when the resulting URL list is empty. Flutter
      `FivehundredpxRipper.getURLsFromJSON(...)` returns an empty list when
      `photos` is absent/non-list, skips non-map photo entries, builds
      `https://500px.comnull` when `url` is absent, and falls back to an empty
      string when `image_url` is absent. Its `parseJSON(...)` has no Java-style
      empty-list error, so malformed or empty 500px pages can complete cleanly
      or queue an empty URL instead of failing like Java.
- [ ] Java `FivehundredpxRipper.getNextPage(...)` treats missing
      `current_page` or `total_pages` as `IOException("No more pages")`, and a
      last page as `IOException("No more results")`; `AbstractJSONRipper` logs
      and stops pagination through its catch path. Flutter
      `FivehundredpxRipper.getNextPage(...)` returns `null` for missing or
      non-integer page fields and for the last page, so these Java end-state
      exception contracts are collapsed into the same nullable stop.
- [ ] Java `FivehundredpxRipper.keepSortOrder()` returns `false`, but its
      concrete `downloadURL(...)` bypasses the abstract save-order gate and
      writes an explicit `saveAs` path of `getPrefix(index) + photoId + ".jpg"`.
      Flutter `FivehundredpxRipper.downloadFileName(...)` extracts the same
      photo ID but drops the Java `getPrefix(index)` portion, so 500px
      filenames lose Java's ordered `NNN_` prefix even though the source test
      labels them "Java-style".
- [ ] Java `TapasticRipper.getURLsFromPage(...)` returns an empty list only when
      the page lacks the literal `episodeList : ` marker; once the marker is
      present it assumes `Utils.between(...).get(0)`, `new JSONArray(...)`,
      `getJSONObject(i)`, `getInt("id")`, and `getString("title")` all succeed.
      Flutter `TapasticRipper.episodesFromDocument(...)` returns an empty list
      when the marker has no trailing `,\n` delimiter, when decoded JSON is not
      a list, and skips non-map episode entries. Java `downloadURL(...)` also
      aborts the whole episode image loop on the first invalid/empty image
      `src` because the broad try/catch wraps every image, while Flutter skips
      empty `src` images and continues later images. These parser and per-image
      failure paths are not Java-equivalent.
- [ ] Java `TapasticRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any
      host ending in `tapas.io` is accepted before `getGID(...)` validates
      exact `https://tapas.io/series/...` or `/episode/...` paths. Flutter
      `TapasticRipper.canRip(...)` requires `url.host == "tapas.io"`, and its
      Dart test rejects `https://www.tapas.io/series/TPIAG`, narrowing Java's
      domain-level dispatch surface.
- [ ] Java `TapasticRipper.downloadURL(...)` logs
      `[!] Exception while downloading <episode-url>` when an individual episode
      page fetch or image URL conversion throws, and the exception remains tied
      to that episode's download task. Flutter `TapasticRipper.rip()` catches
      every per-episode fetch/parse failure with `catch (_) { continue; }`, so
      failed Tapas episodes disappear without Java-compatible diagnostics.
- [ ] Java `TsuminoRipper.getPageUrls(...)` catches only the page-load
      `IOException` path, sends the captcha warning, returns `null`, and then
      `getURLsFromPage(...)` immediately dereferences `imageIds.length()`.
      Successful but malformed load responses still throw from
      `new JSONObject(...)` / `getJSONArray("reader_page_urls")` /
      `getString(i)`. Flutter `getPageUrls(...)` catches all failures,
      including JSON shape failures, sends the captcha warning, returns `null`,
      and `getURLsFromPage(...)` converts that into an empty list. That changes
      both Java's malformed JSON failure and Java's post-warning null
      dereference into clean completion.
- [ ] Java `TsuminoRipper.downloadURL(...)` sleeps, then schedules each
      `Image/Object?name=...` URL with `getPrefix(index)` and
      `getFileExtFromMIME=true`, explicitly relying on the downloader to choose
      the saved extension because Tsumino object URLs do not contain one.
      Flutter `TsuminoRipper.fileNameForUrl(...)` names the same URL
      `NNN_Object` / `Object` from the path segment and has no MIME-derived
      extension path, so the saved filename contract is not Java-compatible.
- [ ] Java `TsuminoRipper.getFirstPage(...)` stores jsoup
      `Connection.Response.cookies()` from the album page before loading reader
      URLs. Flutter reconstructs cookies by splitting the raw `set-cookie`
      header with `ThechiveRipper.cookiesFromSetCookieHeader(...)`, which is
      not equivalent for comma-bearing cookie attributes such as `Expires`.
      This repeats the cookie-parsing class of gap seen in other rippers but is
      a separate source-backed Tsumino request-state difference.
- [ ] Java `DynastyscansRipper.getNextPage(...)` throws
      `IOException("No more pages")` when `a#next_link` is absent or has
      `href="#"`, and lets a failed fetch of the next chapter page escape to
      `AbstractHTMLRipper`'s pagination handling. Flutter
      `DynastyscansRipper.getNextPage(...)` returns `null` for the absent/`#`
      cases, and `rip()` catches next-page fetch failures and breaks before
      sending `ripComplete`. This changes both no-next-page and next-fetch
      failure behavior into quiet completion.
- [ ] Java `DynastyscansRipper.getURLsFromPage(...)` passes the discovered
      `var pages` payload directly into `new JSONArray(jsonText)` and strictly
      reads each entry with `getJSONObject(i).getString("image")`; a missing
      script, non-array JSON, non-object item, or missing `image` throws.
      Flutter `DynastyscansRipper.pagesJsonText(...)` throws a different
      `FormatException` for a missing script, while `urlsFromPage(...)` returns
      an empty list for non-list decoded JSON and skips non-map or missing-image
      entries. Several malformed page-data states therefore become Flutter's
      later `No images found at ...` status or partial output instead of Java's
      immediate parser failure.
- [ ] Java `FuskatorRipper.getURLsFromPage(...)` catches only the auth/fetch
      `IOException` block and returns an empty list for missing cookies,
      missing `X-Auth`, or JSON request failures, but once JSON is fetched it
      strictly calls `json.getJSONArray("images")`,
      `image.getString("imageUrl")`. Flutter `FuskatorRipper.imageUrlsFromJson`
      returns an empty list for non-map JSON, missing/non-list `images`, and
      per-image missing `imageUrl`, so malformed successful API responses are
      silently treated like no images instead of Java's parser failure.
- [ ] Java `FuskatorRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any
      host ending in `fuskator.com` is accepted before `sanitizeURL(...)` and
      `getGID(...)` enforce the `/full/<id>/...` gallery shape. Flutter
      `FuskatorRipper.canRip(...)` sanitizes `/thumbs/` and `/expanded/` first
      but then applies the strict full-gallery regex, narrowing Java's
      domain-level acceptance.
- [ ] Java `HentaiNexusRipper.getURLsFromJSON(...)` strictly requires JSON keys
      `f`, `b`, `r`, `i`, and each image's `h`/`p`, and a missing
      `initReader(...)` payload returns `""` which then reaches Java Base64
      decode / JSON construction failure. Flutter `urlsFromJson(...)` defaults
      missing `b`/`r`/`i` to empty strings and returns an empty list when `f` is
      absent or malformed. That can produce malformed URLs or clean completion
      where Java would throw.
- [ ] Java `EightmusesRipper.getURLsFromPage(...)` recurses into subalbums but
      only logs `subalbumImages.size()` and ignores the returned list. Images
      in a subalbum that use `data-cfsrc` are added only to that returned list
      and are therefore not scheduled by Java's parent call, while Flutter
      `_downloadsFromPage(...)` recursively collects and downloads them.
- [ ] Java `EightmusesRipper.getURLsFromPage(...)` also handles subalbum fetch
      failures by logging `logger.warn("Error while loading subalbum ...")`
      after the prior `LOADING_RESOURCE` update. Flutter `_downloadsFromPage(...)`
      converts those failures into `RipStatus.downloadWarn`, changing the
      visible status feed and warning counters for broken 8muses subalbums.
- [ ] Java `EightmusesRipper.getURLsFromPage(...)` schedules discovered picture
      tiles immediately through `addURLToDownload(..., getPrefixShort(i), "",
      null, true)`, so the downloader uses `getFileExtFromMIME=true` and can
      replace the saved extension from response content/magic-number detection.
      Flutter `_downloadForImage(...)` derives the saved name from the URL path
      with `fileNameForUrl(...)`, so 8muses full-image URLs whose path lacks or
      misstates the extension do not follow Java's MIME-derived filename
      behavior.
- [ ] Java `EightmusesRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any
      host ending in `8muses.com` is accepted before `getGID(...)` validates the
      `/comix|comics/album/...` path. Flutter `EightmusesRipper.canRip(...)`
      applies the album regex directly, narrowing Java's domain-level dispatch
      surface for non-album 8muses URLs.
- [ ] Java `EightmusesRipper.getURLsFromPage(...)` directly dereferences
      `thumb.select("img").first().attr("data-src")` for picture tiles without
      `data-cfsrc`; missing `img` or `data-src` markup can throw or build the
      Java empty `https://comics.8muses.com`-style candidate. Flutter
      `imageUrlFromTile(...)` returns `null` for missing/empty `data-src` and
      skips the tile, so malformed 8muses picture tiles no longer follow
      Java's failure/empty-candidate behavior.
- [ ] Java `EightmusesRipper.getAlbumTitle(...)` catches only `IOException`;
      a successful page missing `meta[name=description]` can null-dereference
      before falling back to `super.getAlbumTitle(...)`. Flutter
      `albumTitleFromDocument(...)` returns `null` for missing/empty
      descriptions and `getAlbumTitle(...)` falls back to `8muses_GID`, masking
      Java's malformed-title failure path.
- [ ] Java `HentaifoundryRipper.getFirstPage(...)` stores jsoup
      `Response.cookies()` from both the age-gate request and the filter POST,
      and directly dereferences `doc.select("input[name=YII_CSRF_TOKEN]").first()`
      before checking whether `csrf_token != null`. Flutter reconstructs
      cookies from raw `set-cookie` headers via `FuskatorRipper` helpers and
      uses a nullable CSRF selector. Missing CSRF markup or comma-bearing cookie
      attributes therefore follow different request-state and failure behavior.
- [ ] Java `HentaifoundryRipper` inherits `AbstractHTMLRipper.canRip(...)`, so
      any host ending in `hentai-foundry.com` is accepted before `getGID(...)`
      validates `/pictures/user/...` or `/stories/user/...`. Flutter
      `HentaifoundryRipper.canRip(...)` applies that regex directly, narrowing
      Java's domain-level dispatch surface for other Hentai Foundry paths.
- [ ] Java `HentaifoundryRipper.getURLsFromPage(...)` catches image-page fetch
      `IOException`, sets `imagePage = null`, then immediately dereferences
      `imagePage.select(...)`; a failed image page can throw before the rip
      continues. Flutter catches each image-page fetch failure and simply skips
      that thumbnail. Java also emits `https:` plus an empty `src` if the image
      page lacks `div.boxbody > img.center`, while Flutter returns `null` and
      skips it. These image-page failure paths are not Java-equivalent.
- [ ] Java `EromeRipper.getAlbumsToQueue(...)` adds `elem.attr("href")` for
      every `div#albums > div.album > a`, including missing or empty `href`
      attributes. Flutter `EromeRipper.getAlbumsToQueue(...)` filters
      missing/empty `href` values, so malformed profile album links are no
      longer queued the way Java would queue them.
- [ ] Java `EromeRipper.setAuthCookie()` calls
      `Utils.getConfigString("erome.laravel_session", null)` and adds the
      `laravel_session` cookie whenever the result is non-null, including an
      explicitly configured empty string. Flutter `setAuthCookie()` requires
      the value to be non-null and non-empty, so empty configured session
      cookies are dropped instead of being sent as Java would.
- [ ] Java `EromeRipper.getMediaFromPage(...)` logs the empty-result
      `erome.laravel_session` hint with `logger.warn(...)` only when no media
      is found and the cookie map is empty. Flutter `EromeRipper.getURLsFromPage(...)`
      sends the same hint as `RipStatus.downloadWarn`, changing visible status
      feed/count behavior for empty unauthenticated Erome pages.
- [ ] Java `ImgurRipper.getImgurAlbum(...)` tries API JSON first and, if
      `data.images[*].link` parsing throws `JSONException` or
      `URISyntaxException`, falls back to the `/noscript` HTML parser for the
      whole album. Flutter `ImgurRipper.albumImagesFromApiJson(...)` returns an
      empty list for missing/non-list `data.images`, skips non-map entries, and
      drops images missing `link`; if any valid link remains, it accepts that
      partial API result and never falls back to `/noscript`. Malformed Imgur
      album API data can therefore produce partial Flutter output where Java
      would discard the API parse and use the fallback path.
- [ ] Java `ImgurRipper.getGID(...)` mutates `this.url` to canonical album URLs
      for gallery, `/a`/`/t`, and subreddit-media inputs
      (`https://imgur.com/a/<gid>` or `https://imgur.com/r/<sub>/<gid>`) before
      `rip()` calls `ripAlbum(this.url)`. Flutter `ImgurRipper.classifyUrl(...)`
      returns only the type/GID and leaves the stored `url` unchanged, so
      loading-resource statuses and any logic using the instance URL continue
      to see the user-supplied URL rather than Java's canonical URL.
- [ ] Java `ImgurRipper.ripUserAccount(...)` strictly requires account
      submission JSON `success`, `status == 200`, array `data`, and per-item
      `link`, `is_album`, `id`, optional `mp4`; unexpected status throws
      `IOException("Unexpected status code ...")`, and malformed item fields
      throw out of the user rip. Flutter `_ripUserAccount(...)` accepts only a
      broad map/status check, skips non-map items and missing/empty links, uses
      an empty album ID when `id` is missing, and has a different unexpected
      response error message. User-account malformed data and error reporting
      are not Java-equivalent.
- [ ] Java `ImgurRipper.ripUserImages(...)` wraps each AJAX page in a broad
      `catch (Exception)` and breaks the user-images loop on any parse/fetch
      failure after strictly reading `data.images[*].hash` and `ext`. Flutter
      `ImgurRipper.userImagesFromAjaxJson(...)` converts missing/non-map `data`
      or missing/non-list `images` into an empty page, skips images missing
      `hash`/`ext`, and then breaks as if the account had no more images. That
      turns malformed user-image pages into clean pagination end states instead
      of Java's logged error path.
- [ ] Java `ImgurRipper.ripSubreddit(...)` processes every `.post img` and
      immediately builds a URL from `src`, after `//` and thumbnail `b.`
      normalization; an empty or malformed `src` can throw and abort the
      subreddit rip through `rip()`. Flutter `_ripSubreddit(...)` skips empty
      `src` attributes and continues, so malformed subreddit image elements can
      disappear silently instead of following Java's failure path.
- [ ] Java `InstagramRipper.getFirstPage(...)` requires shared-data JSON to be
      found and then strictly resolves the ID path with `getJsonStringByPath`;
      if the document lacks usable `window._sharedData` /
      `window.__additionalDataLoaded`, Java reaches strict JSON path access on
      `null` or missing objects. Flutter `jsonObjectFromDocument(...)` returns
      `null`, `rip()` substitutes `{}`, and `idStringFromJson(...)` returns an
      empty string. Missing or malformed Instagram shared-data can therefore
      continue into GraphQL calls with an empty ID instead of failing like Java.
- [ ] Java `InstagramRipper.getQhash(...)` always builds a JS URL from the
      selected preload `href` (empty string if none is found), fetches that body,
      and extracts query hashes by parsing JavaScript with GraalVM AST offsets.
      Flutter `_queryHash(...)` returns `null` when no matching preload is
      found and `queryHashFromJavaScript(...)` uses a local regex window around
      keywords. The Dart ripper can send GraphQL requests with
      `query_hash=null`, and even when JS is present it is not exercising
      Java's AST/offset extraction semantics.
- [ ] Java `InstagramRipper.getNextPage(...)` strictly reads
      `getMediaRoot(source).getJSONObject("page_info")`,
      `has_next_page`, and `end_cursor`; missing pagination structure throws
      and stops through `AbstractJSONRipper`'s catch path. Flutter
      `_nextPage(...)` returns `null` when the media root or `page_info` is
      missing, and uses a nullable `end_cursor` value in variables. Malformed
      Instagram pagination can become a clean stop or null-cursor request rather
      than Java's parser failure.
- [ ] Java `InstagramRipper.getURLsFromJSON(...)`, `parseStoryItemForUrls(...)`,
      `addPrefixInfo(...)`, and `parseRootForUrls(...)` use strict
      `getJSONArray` / `getJSONObject` / `getString` / `getBoolean` /
      `getLong` contracts for reels, posts, sidecars, timestamps, and media
      URLs. Flutter's `storyMediaFromJson(...)`, `prefixInfoForItem(...)`,
      `parseRootForUrls(...)`, and JSON path helpers return empty lists,
      `null`, or timestamp `0` for missing/malformed fields. This changes many
      malformed Instagram API/media-item states into skipped media or
      `1970-01-01_00-00-00_` prefixes instead of Java-compatible failures.
- [ ] Java `InstagramRipper.getVideoUrlFromPage(...)` catches per-shortcode
      page-fetch failures by logging `logger.warn("Unable to get page ...")`
      and returning an empty string. Flutter `_videoUrlFromPage(...)` sends
      `RipStatus.downloadWarn` for the same failure, so broken Instagram video
      fallback pages become user-visible warnings/counts that Java did not
      emit.
- [ ] Java `InstagramRipper.downloadItemDetailsJson(...)` records failed
      shortcodes in `failedItems` and `getNextPage(...)` later writes those
      entries with `logger.error` only when pagination reaches its natural end.
      Flutter `_downloadItemDetailsJson(...)` records the same shortcodes but
      `rip()` emits every entry as `RipStatus.downloadWarn`, so missing
      Instagram item-detail pages become user-visible warning statuses instead
      of Java's logger-only failures.
- [ ] Java `InstagramRipper.downloadURL(...)` honors
      `instagram.download_images_only=true` by logging `Skipped video url: ...`
      and returning before scheduling `.mp4?` downloads; it does not send a
      `DOWNLOAD_SKIP` status. Flutter checks the same key but emits
      `RipStatus.downloadSkip`, changing UI/log/count semantics for skipped
      Instagram videos.
- [ ] Java `MangadexRipper.getURLsFromJSON(...)` strictly reads chapter JSON
      keys `hash`, `server`, and `page_array`, and manga JSON key `chapter` plus
      `lang_name` / numeric `chapter`; missing or malformed fields throw. During
      manga rips, Java catches `IOException | URISyntaxException` from an
      individual chapter fetch, prints the stack trace, and then still
      dereferences `chapterJSON`, which can fail immediately. Flutter returns
      empty lists/maps for missing chapter fields or manga chapter maps, skips
      malformed chapter entries, and propagates failed chapter fetches through
      `getJson(...)`. Both parser leniency and chapter-fetch failure behavior
      differ from Java.
- [ ] Java `PhotobucketRipper.getFirstPage(...)` requires
      `getCollectionData(currAlbum.currPage).getInt("total")`; if the script
      JSON is missing, malformed, or lacks `total`, Java throws before ripping.
      Flutter `PhotobucketRipper.getFirstPage(...)` sets `numPages = 0` when
      collection data is missing or `total` is not an int, then later completes
      cleanly with no downloads. Java `getImageURLs(...)` also strictly
      dereferences `items.objects[*].fullsizeUrl`, while Flutter returns empty
      lists/skips malformed objects. Pagination differs too: Java
      `getNextPage(...)` throws `IOException("No more pages")` after the final
      album/page, while Flutter returns `null` from `getNextDocument(...)` and
      `getNextPage(...)`.
- [ ] Java `PhotobucketRipper` inherits `AbstractHTMLRipper.canRip(...)`, so
      any host ending in `photobucket.com` is accepted before `sanitizeURL(...)`
      and `getGID(...)` apply the `SUBDOMAIN.photobucket.com/user/USER/library`
      URL shape. Flutter `PhotobucketRipper.canRip(...)` sanitizes and applies
      that regex directly, narrowing Java's domain-level dispatch surface.
- [ ] Java `PhotobucketRipper.AlbumMetadata` strictly reads metadata keys
      `url`, `location`, and `sortOrder`, keeps the raw `location` path except
      replacing spaces with underscores, and stores jsoup response cookies for
      each album page. Flutter uses `.toString()` defaults for `url` and
      `location`, casts only `sortOrder`, splits `location` into platform path
      segments when saving, and reconstructs cookies from the raw `set-cookie`
      header via the Fuskator helper. These path/cookie differences need
      source-backed tests before claiming Photobucket parity.
- [ ] Java `ThechiveRipper.downloadURL(...)` calls `getPrefix(index)`, so
      `download.save_order=false` disables ordered filename prefixes for both
      `thechive.com` posts and `i.thechive.com` user rips. Flutter
      `ThechiveRipper.prefix(...)` always returns a zero-padded prefix and does
      not read `download.save_order`, making TheChive ignore the global
      save-order setting.
- [ ] Java `ThechiveRipper.getUrlsFromIDotThechive(...)` catches
      `IOException` and `JSONException`, logs the failure, and returns an empty
      list; `getNextPage(...)` separately throws `IOException("Error fetching
      next page.", e)` when its look-ahead JSON request fails. Flutter
      `fetchIDotThechivePage(...)` / `urlsFromIDotJson(...)` propagates network
      and JSON shape failures, and `getNextPage(...)` is a stub that always
      returns `null` even for `i.thechive.com` URLs. That changes both failure
      reporting and the Java look-ahead pagination contract.
- [ ] Java `ThechiveRipper.getUrlsFromThechive(...)` strips query parameters
      with `s.substring(0, s.indexOf("?"))` for every extracted gallery URL,
      so an image or GIF URL with no `?` throws before returning results.
      Flutter `ThechiveRipper.stripAfterQuestionMark(...)` returns queryless
      URLs unchanged, and the Dart tests only cover URLs that contain query
      strings, so post-gallery parsing is not Java-compatible for queryless
      media.
- [ ] Java ships both `rippers/VkRipper.java` for photos/albums/videos lists
      and `rippers/video/VkRipper.java` for individual `/video...` pages. The
      video ripper accepts `^https?://[wm.]*vk\\.com/video[0-9]+.*$`, extracts
      the numeric video GID, and saves the download with prefix `vk_` plus that
      GID. Flutter only has `lib/ripper/rippers/vk_ripper.dart`, where
      `canRip(...)` deliberately rejects individual `/video123_456` URLs and
      no equivalent `vk_<gid>` save-name path exists.
- [ ] Java album `VkRipper.rip()` handles `/videos...` URLs by first loading the
      silent video JSON, scheduling every resolved video URL with its own
      `downloadURL(..., index)` loop, waiting for those threads, and then still
      falling through to `super.rip()`. That second pass reloads the video JSON
      through `getFirstPage()`, runs duplicate/history handling in
      `AbstractJSONRipper`, and can continue into the normal `getNextPage(...)`
      pagination/error path. Flutter `VkRipper._ripVideos()` performs only the
      first eager video pass and returns, so Java's second-pass statuses,
      duplicate-skip side effects, and possible pagination failure behavior are
      absent.
- [ ] Java `VkRipper.getPage(...)` collects photo IDs in a `HashSet`, then
      iterates that set when fetching each photo JSON object, so album image
      request/download order is hash-set dependent rather than document order.
      Flutter `VkRipper.photoIdsFromAnchors(...)` uses Dart's insertion-ordered
      set and returns IDs in page order, changing Java's ordering behavior.
- [ ] Java `VkRipper.getPhotoIDsToURLs(...)` only lets checked `IOException`s
      be caught by the caller's per-photo skip path; JSON parsing failures from
      `new JSONObject(response.body())` or strict object traversal escape the
      loop. Flutter catches every exception from `getPhotoIDsToURLs(...)` in
      `getImagePage(...)`, so malformed per-photo JSON is silently skipped
      instead of aborting like Java.
- [ ] Java `TumblrRipper.rip(...)` handles Tumblr API `404` and `429`
      `HttpStatusException`s specially: `404` sends `NO_ALBUM_OR_USER` with
      `Album or user doesn't exist!`, `429` sends `DOWNLOAD_ERRORED` with
      `Tumblr rate limit has been exceeded`, and both stop the rip loop without
      retrying other media types. Flutter `TumblrRipper.parseJSON(...)` only
      retries `401` based on `e.toString().contains("401")`; other API failures
      are rethrown through `AbstractJSONRipper`, so the Java status messages and
      stop semantics are missing.
- [ ] Java `TumblrRipper.canRip(...)` is a broad host guard that accepts any
      URL whose host ends with `tumblr.com`, then `getGID(...)` decides whether
      the path is a supported subdomain, tag, post, or likes URL. Flutter
      `TumblrRipper.canRip(...)` delegates to `classifyUrl(...)`, which rejects
      unsupported Tumblr-host paths before Java's later `getGID` failure point
      and also accepts non-`tumblr.com` hosts that happen to match the generic
      `/tagged/...` or `/post/...` regexes. Tumblr URL acceptance/rejection is
      therefore not Java-compatible.
- [ ] Java `TumblrRipper.getApiKey()` caches one randomly selected default key
      in static `API_KEY` via `new Random().nextInt(...)`, and its
      `useDefaultApiKey` fallback flag is static across Tumblr ripper instances.
      Flutter `TumblrRipper.getApiKey()` stores `_selectedDefaultApiKey` and
      `_useDefaultApiKey` per instance, and chooses the default key with
      deterministic `Random(0)`. Default-key selection and post-401 fallback
      lifetime therefore differ from Java.
- [ ] Java `TumblrRipper.handleJSON(...)` strictly dereferences
      `response.posts` / `response.liked_posts` and each post `date`; missing or
      malformed top-level API structure throws. Flutter
      `TumblrRipper.mediaFromJson(...)` returns an empty list when `response` or
      the post arrays are missing/non-list, and defaults missing `date` to an
      empty string. That can turn malformed Tumblr API data into normal
      pagination completion and empty filename prefixes where Java would fail.
- [ ] Java `TumblrRipper.handleJSON(...)` catches malformed photo, video, audio,
      album-art, and embedded-body media differently: photo failures are logged
      and the same post/page continues, while video/audio/album-art/body image
      failures return `true` and continue the outer pagination. Flutter
      `TumblrRipper.mediaFromJson(...)` constructs `Uri.parse(...)` values
      directly and skips missing photo URLs, so invalid media URLs can abort
      parsing or disappear instead of following Java's per-media catch/continue
      contracts.
- [ ] Java `AbstractJSONRipper.rip()` keeps one global download index across
      all Twitter pages before calling `TwitterRipper.downloadURL(...)`, so
      ordered filenames continue `001_`, `002_`, ... across pagination. Flutter
      `TwitterRipper.parseJSON(...)` builds each page's download list with
      `i + 1`, so ordered filenames can restart at `001_` on each API page.
- [ ] Java `TwitterRipper` reads `twitter.max_requests`,
      `twitter.rip_retweets`, `twitter.exclude_replies`, and
      `twitter.max_items_request` into `static final` fields when the class is
      loaded, while `twitter.auth` and `download.save_order` are read later.
      Flutter reads these same request/filter/count settings from
      `Utils` during each rip/API URL build. Runtime preference changes after
      first Java class load therefore have different lifetime semantics in
      Flutter.
- [ ] Java `TwitterRipper.getURLsFromJSON(...)` logs malformed/unsupported
      media decisions: missing `extended_entities` emits
      `XXX Tweet doesn't have entities`, video/gif variants with no selected
      bitrate URL emit `URLToDownload was null`, and unexpected photo
      `media_url` hosts emit `Unexpected media_url`. Flutter
      `TwitterRipper.mediaFromTweets(...)` / `mediaUrl(...)` silently skip all
      three cases, so Twitter diagnostics and failed-media visibility are not
      Java-compatible.
- [ ] Java `BatoRipper.getAlbumTitle(...)` builds
      `bato_<gid>_<cached-first-page-title-with-spaces-as-underscores>` by
      calling `getCachedFirstPage()`, with a disabled Java test documenting the
      expected title
      `bato_1207152_I_Messed_Up_by_Teaching_at_a_Black_Gyaru_School!_Ch.2`.
      Flutter `BatoRipper.getAlbumTitle(...)` fetches the URL again with
      `Http.get(url)` instead of using the cached first page, and the Dart test
      suite does not prove the Java title contract or cache behavior.
- [ ] Java `BatoRipper.getAlbumTitle(...)` catches only `IOException`; after a
      successful fetch with a missing `<title>`, `select("title").first().text()`
      can null-dereference. Flutter `BatoRipper.getAlbumTitle(...)` uses a
      nullable title lookup and falls back to the superclass title for missing
      or empty title text, so malformed-but-successful Bato pages do not follow
      Java's failure behavior.
- [ ] Java `BatoRipper.getURLsFromPage(...)` extracts the `imgHttps = [...]`
      script payload with `scanForImageList(...)`, then strictly calls
      `JSONArray.getString(i)` for every entry. Flutter
      `BatoRipper.imageUrlsFromDocument(...)` ignores decoded non-list payloads
      and stringifies every list entry with `value.toString()`. Non-string
      entries or non-array `imgHttps` JSON can therefore become partial/coerced
      Dart URLs instead of Java parser failures.
- [ ] Java `HitomiRipper.getURLsFromPage(...)` parses gallery info with
      `new JSONArray(json)` and strictly calls
      `json_data.getJSONObject(i).getString("name")`. Flutter
      `HitomiRipper.imageUrlsFromGalleryInfo(...)` casts entries to maps but
      interpolates `item['name']`, which can emit
      `https://ba.hitomi.la/galleries/<category>/null` for a missing `name`
      field instead of matching Java's strict missing-key failure.
- [ ] Java `HitomiRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any
      host ending in `hitomi.la` is accepted before `getGID(...)` validates the
      strict `https://hitomi.la/(cg|doujinshi|gamecg|manga)/...html` shape.
      Flutter `HitomiRipper.canRip(...)` applies that regex directly, and its
      Dart test rejects another `hitomi.la` path that Java would accept at the
      dispatch layer.
- [ ] Java `AllporncomicRipper.getURLsFromPage(...)` and
      `getAlbumsToQueue(...)` add jsoup `attr(...)` values directly, including
      empty strings when `data-src` or `href` is absent. Flutter
      `AllporncomicRipper` filters empty image and queue URLs, so malformed
      chapter pages can silently drop entries that Java would pass into the
      shared download/queue path.
- [ ] Java `Hentai2readRipper.getFirstPage(...)` first tries the reader
      controls thumbnail link, then falls back to
      `tempDoc.select("a[data-original-title=Thumbnails").attr("href")` with
      the Java selector typo preserved. Flutter
      `thumbnailPageUrlFromReader(...)` uses the corrected
      `a[data-original-title="Thumbnails"]` selector and throws a controlled
      `Unable to get first page` when no link exists, so fallback selection and
      malformed-selector failure behavior are not Java-compatible.
- [ ] Java `Hentai2readRipper` inherits `AbstractHTMLRipper.canRip(...)`, so
      any host ending in `hentai2read.com` is accepted before
      `pageContainsAlbums(...)` or `getGID(...)` validates comic/chapter path
      shapes. Flutter `Hentai2readRipper.canRip(...)` applies the root/chapter
      regexes directly, narrowing Java's domain-level dispatch surface.
- [ ] Java `Hentai2readRipper.getAlbumsToQueue(...)` and
      `chapterUrlsFromPage` parity is only partial: Java queues raw jsoup
      `href` values from `.nav-chapters > li > div.media > a`, including empty
      strings. Flutter mirrors the selector but also needs tests proving empty
      `href` handling remains intentionally Java-compatible because the current
      list helper returns `''` while other queue rippers filter empties.
- [ ] Java `MyhentaicomicsRipper.getNextPage(...)` dereferences
      `doc.select("a.ui-icon-right").first().attr("href")` before checking
      whether a next page exists, so a missing next link can throw a null
      dereference instead of the later `IOException("No more pages")`. Flutter
      `nextPageUrlFromDocument(...)` returns `null` for a missing link and ends
      pagination cleanly.
- [ ] Java `NfsfwRipper.pageContainsAlbums(...)` is a real queue-discovery hook:
      it loads the cached first page and returns true when there are no image
      pages but subalbum links exist. Flutter `NfsfwRipper.pageContainsAlbums`
      always returns false and performs the subalbum-only check inside
      `rip()`, so the public queue-support contract exposed by
      `AbstractHTMLRipper` is not equivalent even though the main rip path has
      similar behavior.
- [ ] Java `NfsfwRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any host
      ending in `nfsfw.com` is accepted before `getGID(...)` validates the
      `/gallery/v/...` shape. Flutter `NfsfwRipper.canRip(...)` sanitizes the
      URL and applies the gallery regex directly, narrowing Java's domain-level
      dispatch surface.
- [ ] Java `NfsfwRipper.getNextPage(...)` sleeps and then throws
      `IOException("No more pages")` when neither `a.next` nor queued
      subalbums provide a valid next URL. Flutter `NfsfwRipper.getNextPage(...)`
      returns `null` for the same end state, and its Dart test asserts `null`,
      so pagination completion behavior is not Java-compatible.
- [ ] Java `NfsfwRipper.getNextPage(...)` removes one queued subalbum URL and,
      if it does not match the subalbum pattern, logs `Invalid sub-album URL`
      and throws `IOException("No more pages")` instead of considering later
      queued subalbums. Flutter loops over `_subalbumURLs` until it finds a
      matching subalbum or exhausts the queue, skipping invalid entries and
      potentially continuing where Java would stop.
- [ ] Java `NhentaiRipper.getAlbumsToQueue(...)` and
      `getURLsFromPage(...)` add raw/transformed jsoup attributes directly:
      missing `href` queues `https://nhentai.net`, and missing `data-src`
      becomes an empty image URL after the thumbnail replacements. Flutter
      filters empty `href` and `data-src` values, changing malformed tag/gallery
      page behavior.
- [ ] Java `NhentaiRipper.getAlbumTitle(...)` returns `"nhentai" + title` even
      when `#info > h1` exists but has empty text, and if the first page fetch
      fails it can still dereference `firstPage` afterward. Flutter
      `albumTitleFromDocument(...)` treats missing/empty title text as `null`
      and falls back to `nhentai_GID`, so empty-title and failed-first-page
      states no longer match Java.
- [ ] Java `XhamsterRipper` declares `hasASAPRipping() == true` and performs
      downloads inside `getURLsFromPage(...)` through `downloadFile(...)`, where
      filenames use Java `getPrefix(index)` and therefore honor
      `download.save_order`. Flutter schedules returned URLs through its normal
      async path and `XhamsterRipper.prefix(...)` always emits a padded prefix,
      so both ASAP side effects and save-order configuration parity need exact
      tests.
- [ ] Java downloaded-URL history normalization is per-ripper:
      `AbstractRipper.normalizeUrl(...)` returns the original URL unchanged,
      while `ArtStationRipper` strips only a terminal `?\w+` suffix and
      `DeviantartRipper` replaces the URL with `urlWithParams(offset)`.
      Flutter `DownloadHistoryProvider._normalize(...)` removes fragments for
      every URL and has no per-ripper normalization hook, so duplicate/skip
      behavior differs both globally and for ArtStation/DeviantArt.
- [ ] Java `ArtStationRipper.normalizeUrl(...)` uses the narrow regex
      `url.replaceAll("\\?\\w+$", "")`, so query strings containing `=`, `&`,
      or non-word characters are preserved in downloaded-URL history. Flutter's
      global history normalizer preserves all query strings but strips fragments
      and does not exercise the ArtStation-specific terminal-query behavior.
- [ ] Java `DeviantartRipper.normalizeUrl(...)` records
      `urlWithParams(this.offset).toExternalForm()` for every downloaded URL,
      tying history entries to the ripper's current pagination offset instead
      of the actual downloaded deviation URL. Flutter records the media URL
      after global fragment removal, so Java's DeviantArt already-downloaded
      skip semantics are not reproduced.
- [ ] Java `GirlsOfDesireRipper` inherits the broad
      `AbstractHTMLRipper.canRip(...)` host check for `girlsofdesire.org`, but
      `getGID(...)` then matches `^www\\.girlsofdesire\\.org/...` against
      `url.toExternalForm()`, which includes the scheme and therefore rejects
      normal `http://www.girlsofdesire.org/galleries/.../` URLs. Flutter
      `GirlsOfDesireRipper` corrected the regex to allow an optional scheme, so
      accepted URL/GID behavior no longer matches Java's shipped implementation.
- [ ] Java `FapwizRipper.getGID(...)` matches the original
      `url.toExternalForm()` against `[a-zA-Z0-9_%-]+` and returns the captured
      post slug verbatim, including the original case of percent-encoded bytes.
      Flutter `FapwizRipper.getGID(...)` first lowercases every `%XX` escape via
      `_lowercasePercentEscapes(...)`, so uppercase-encoded emoji or other
      escaped bytes produce different GIDs and filesystem-safe album names than
      Java.
- [ ] Java `FapwizRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any
      host ending in `fapwiz.com` is accepted before `getGID(...)` applies the
      category/user/post regexes and may throw. Flutter
      `FapwizRipper.canRip(...)` applies those strict regexes up front, so
      domain-valid but path-invalid Fapwiz URLs are rejected earlier than Java.
- [ ] Java `FapwizRipper.getNextPage(...)` throws `IOException("No more pages.")`
      when `a.next` is absent, and `FapwizRipperTest.testGetNextPage_NoNextPage`
      documents that exception contract. Flutter `FapwizRipper.getNextPage(...)`
      returns `null` for a missing/empty `a.next` href, so pagination completion
      and test expectations differ.
- [ ] Java dependency-backed ripper behavior must be audited at feature level,
      not just by class names: `ScrolllerRipper` uses Java-WebSocket for a
      GraphQL websocket flow, `InstagramRipper` uses the GraalVM
      `com.oracle.js.parser` JavaScript parser to extract query/hash metadata,
      `RedditRipper` uses j2html for self-post/comment HTML export,
      `DanbooruRipper` uses OkHttp with mobile API headers, and Redgifs/
      Scrolller use Apache HttpComponents `URIBuilder`/`URLEncodedUtils` query
      encoding. Flutter currently needs explicit equivalent behavior and tests
      for each of these surfaces.

### J. Build, Release, Versioning, And Platform Packaging

Java build/release sources read:

- `build.gradle.kts`
- `.github/workflows/gradle.yml`
- `ripme.json`
- `README.md`
- `src/main/java/com/rarchives/ripme/ui/UpdateUtils.java`

Flutter files checked:

- `pubspec.yaml`
- `.github/workflows/release.yml`
- Android, Linux, macOS, and Windows platform metadata files
- `README.md`

Findings:

- [ ] Java derives build versions with `jgitver` from tag/base version/commit
      metadata and embeds `Implementation-Version` in the jar manifest. Flutter
      currently declares `version: 1.0.0+1`; version display, release artifact
      naming, update comparison, and reproducible commit identity need a
      Flutter-native equivalent.
- [ ] Java README documents semantic version strings with commit count, short
      SHA, and branch suffix. Flutter README currently claims complete feature
      parity without linking to this audit or describing remaining gaps; that
      is misleading until this file is fully closed.
- [ ] Java CI builds a fat jar on Linux, Windows, and macOS and uploads the Java
      17 Ubuntu jar artifact. Flutter release CI builds Android APK/AAB,
      Windows, macOS, and Linux artifacts. The migration must document that this
      is a platform expansion, not direct artifact-name parity.
- [ ] Java release automation creates/updates prereleases named
      `latest-<branch-slug>` with jar artifacts. Flutter release automation
      publishes tag-driven releases through `softprops/action-gh-release`; the
      branch-latest release behavior needs a replacement decision.
- [ ] Java build excludes `flaky` and `slow` JUnit tags by default and exposes
      `testAll`, `testFlaky`, `testSlow`, and `testTagged` Gradle tasks.
      Flutter currently runs one `flutter test` suite. Dart test metadata needs
      an equivalent policy for network/slow/flaky parity tests.
- [ ] Java docs require contributors to run source-compatible targeted tests
      such as `testAll --tests XhamsterRipperTest.testXhamster2Album`.
      Flutter README needs migration-specific test instructions that include
      `flutter analyze --no-pub`, targeted tests, and expanded reporter full
      suite.
- [ ] Java updater reads `ripme.json`, compares versions component-by-component,
      verifies SHA-256 by default through `security.check_update_hash`, downloads
      the new jar, and installs by platform script. Flutter update checker must
      either reproduce the user-visible check/changelog/hash behavior for
      Flutter artifacts or explicitly retire self-update behavior.
- [ ] Java `UpdateUtils.isNewerVersion` has a string-inequality fallback after
      the first four numeric components compare equal: if `latestVersion` and
      `getThisJarVersion()` are not exactly equal, Java treats the latest string
      as newer. Flutter `UpdateChecker.isNewerVersion` returns false once the
      numeric components compare equal, so suffix-only release changes such as
      commit-count/hash text are not Java-compatible.
- [ ] Java updater installation uses runtime process behavior:
      `Runtime.getRuntime().exec`, `ProcessBuilder`, a shutdown hook, a Windows
      batch file, `Files.move`, and optional `java -jar` restart. Flutter must
      decide whether each desktop/Android platform has a native self-update
      equivalent, an external release flow, or a documented retirement.
- [ ] Java `ripme.json` is a bundled/public changelog source. Flutter has no
      verified equivalent changelog feed, release notes parser, or
      app-visible recent changes text.
- [ ] Java uses `LICENSE.txt` and README links to MIT licensing. Flutter Linux
      metadata and package resources must be checked against the inherited
      license text and platform metadata requirements.
- [ ] Android support is new relative to Java desktop. Android permissions,
      scoped storage, directory picking, background downloads, and notification
      behavior need explicit parity/replacement notes for every desktop-only
      Java behavior.
- [ ] Flutter Android release configuration currently uses the debug signing
      config for release builds. Final Android artifact evidence must distinguish
      CI-build availability from production-signing/readiness and either add a
      real signing flow or document the migration limitation.
- [ ] macOS sandbox entitlements, Linux metadata, Windows resource versioning,
      and app icons must be verified as first-class release artifacts rather
      than assumed from Flutter defaults.
- [ ] Linux packaging metadata currently declares `ripme.desktop`,
      `Icon=ripme`, app id `com.rarchives.ripme`, and summary
      `Cross-platform media album ripper`; the audit still needs to verify that
      the packaged Linux artifact actually installs an icon named `ripme` and
      that the metadata/license text matches the Java project contract.
- [ ] macOS `Info.plist` leaves `CFBundleIconFile` empty and relies on the
      generated AppIcon asset catalog. This must be verified against Java
      `icon.png`/`icon.ico` branding instead of assumed from Flutter defaults.
- [ ] Windows `Runner.rc` embeds `windows/runner/resources/app_icon.ico`, but
      its Git blob differs from Java `src/main/resources/icon.ico`; Windows
      executable icon parity requires a visual/provenance decision.
- [ ] Android launcher icons are new platform resources under
      `android/app/src/main/res/mipmap-*`; Android icon branding parity cannot
      be inferred from Java desktop resources and needs explicit visual/source
      verification.
- [ ] Java dependency removal/replacement needs a checked migration decision for
      non-feature infrastructure as well as app behavior: `commons-cli` command
      parsing, `commons-configuration` property loading/persistence,
      `commons-io` file/path helpers, `org.json` parsing/exception semantics,
      jsoup HTML parsing tolerance, Disruptor/log4j logging infrastructure,
      Apache HttpComponents request/query helpers, OkHttp request behavior,
      Java-WebSocket websocket transport, GraalVM JavaScript parsing, and j2html
      HTML generation. Some are intentionally retired infrastructure, but none
      should vanish from the audit without a Dart equivalent, retirement note,
      or source-compatible test.

### K. README, Wiki-Promised Features, And User-Facing Contract

Java user-facing source read:

- `README.md`

Flutter files checked:

- `README.md`
- `MIGRATION_AUDIT.md`

Findings:

- [ ] Java README promises quick album downloads, easy re-rips, a built-in
      updater, default already-downloaded skipping, e-hentai/nhentai blacklist
      support, and URL range downloads. Each promise now has a corresponding
      audit item, but Flutter README should not claim complete parity until
      those items are implemented and tested.
- [ ] Java README points users to wiki pages for supported sites, config
      options, running the jar, URL ranges, and creating rippers. Flutter needs
      replacement documentation for desktop/mobile installation, config import,
      supported sites, CLI/headless usage, Android storage, and new ripper
      development.
- [ ] Java supported platform claim is Windows, Linux, and macOS. Flutter adds
      Android, so parity is not just preservation: the final migration must
      prove platform behavior and document Android-specific limitations where
      Java desktop concepts do not apply.
- [ ] Java README lists known broken/flaky sites in prose, such as Twitter/X and
      DeviantArt. Flutter catalog/docs must keep those caveats instead of
      presenting every port as fully operational without current evidence.

### L. Java Test Metadata And Disabled/Flaky Coverage

Java test sources scanned:

- `src/test/java/com/rarchives/ripme/tst/**/*.java`

Findings:

- [ ] Mechanical test metadata scan found 119 Java `@Tag("flaky")`
      annotations, 7 Java `@Tag("slow")` annotations, and 44 Java
      `@Disabled` annotations under `src/test/java`. Dart currently has only
      two environment-gated live smoke tests in `test/live_ripper_smoke_test.dart`
      (`RIPME_LIVE_REDDIT_URL` and `RIPME_LIVE_REDGIFS_URL`). Dart tests must
      preserve the broader Java risk taxonomy through tags, skips, fake
      fixtures, or documented live-network test policy instead of silently
      omitting risky cases.
- [ ] Java UI tests include flaky coverage for the rip button and context menu
      behavior. Flutter needs widget/integration coverage for those UI workflows
      before UI parity can be marked complete.
- [ ] Java video tests include disabled cases for known site issues. Flutter
      video ripper tests must record whether each disabled Java behavior is
      still broken upstream, fixed by the port, or intentionally not supported.
- [ ] Java tests include config-driven opt-in live checks such as
      `test.run_flaky_tests` in Hqporner/Pornhub tests. Flutter needs an
      equivalent opt-in mechanism before live flaky parity tests are added to
      CI.

### M. Java Known Limitations That Must Not Become Silent Flutter Claims

Java sources scanned:

- `README.md`
- `src/main/java/com/rarchives/ripme/**/*.java`
- `src/test/java/com/rarchives/ripme/**/*.java`

Findings:

- [ ] Java README explicitly marks Twitter/X and DeviantArt as currently
      broken. Flutter must either prove those ports work now with current
      source-backed tests/live opt-in checks or preserve the caveat in docs/UI.
- [ ] Java `ArtStationRipper` has a TODO for external content. Flutter must not
      claim ArtStation external content support unless it intentionally exceeds
      Java and tests that behavior.
- [ ] Java `FlickrRipper` notes that users cannot provide their own API key.
      Flutter must either keep the built-in-key behavior or add and document a
      compatible user-key preference.
- [ ] Java `PhotobucketRipper` notes possible queue support that is not
      implemented. Flutter must verify whether its Photobucket behavior follows
      Java or intentionally adds queue discovery.
- [ ] Java `RedditRipper` has TODOs for self-text parsing and gallery captions.
      Flutter Reddit parity must distinguish Java-compatible media extraction
      from any deliberate improvements.
- [ ] Java `RedgifsRipper` notes unresolved image-gallery handling. Flutter must
      verify Redgifs gallery behavior rather than assuming video-only tests are
      enough.
- [ ] Java `VscoRipper` notes missing journals and collections support.
      Flutter must preserve/document that limit or add tested support.
- [ ] Java clipboard autorip has a TODO to queue instead of immediately starting
      a rip. Flutter currently queues clipboard URLs; this may be an intentional
      UX improvement, but it must be documented as a Java behavior difference.
- [ ] Java completion handling has a TODO to update history `modifiedDate`.
      Flutter history updates must be checked against Java's actual behavior,
      not the intended TODO.
- [ ] Java `AbstractRipper` URL-list opening has a TODO noting the desktop open
      call does not work reliably. Flutter URL-only output behavior should be
      tested on all target platforms instead of copying that failure blindly.
- [ ] Java `FuraffinityRipper` has an unresolved story-cleanup TODO. Flutter
      Furaffinity story output must be compared against Java's current cleaned
      text behavior before claiming parity or improvement.
- [ ] Java `ImgurRipper` has TODOs for optional username-in-album-title
      behavior and cached-image fallback for empty albums. Flutter Imgur parity
      must either preserve Java's current omission or intentionally add tested
      support.
- [ ] Java `WordpressComicRipper` carries a stale refactor TODO around
      theme-specific navigation behavior. Flutter Wordpress domain handling
      must be checked against the actual Java branch logic, not the stale
      comment.
- [ ] Java `DownloadFileThread` has a resume-support TODO for servers that do
      not honor range requests. Flutter resume/partial-file behavior must be
      verified rather than inferred from generic HTTP retry tests.
- [ ] Java build metadata includes a Compose plugin-management TODO in
      `settings.gradle.kts`. Flutter does not need Compose parity, but the
      migration audit must record this as retired Java build infrastructure,
      not an application feature gap.

## Audit Coverage Evidence

The current audit file was expanded using both manual source reading and
mechanical scans against `origin/main`. These checks are evidence for the audit;
they are not yet a substitute for committed Dart tests.

- [x] Read Java application/controller/UI sources:
      `App.java`, `MainWindow.java`, clipboard/context/history/queue/status
      UI classes, `UpdateUtils.java`, and `ContextActionProtections.java`.
- [x] Read Java utility sources:
      `Utils.java`, `Http.java`, `Proxy.java`, `RipUtils.java`, `Base64.java`,
      and `UTF8Control.java`.
- [x] Read Java ripper runtime sources:
      `AbstractRipper.java`, `AbstractHTMLRipper.java`,
      `AbstractJSONRipper.java`, `AbstractSingleFileRipper.java`,
      `AlbumRipper.java`, `VideoRipper.java`, `DownloadFileThread.java`,
      `DownloadVideoThread.java`, `DownloadThreadPool.java`, and
      `RipperInterface.java`.
- [x] Listed all Java resource files and label bundles.
- [x] Listed all Java test files under `src/test/java/com/rarchives/ripme`,
      including the UI tests outside `tst`, and inspected non-ripper Java
      tests.
- [x] Re-ran the audit path-coverage check after the 2026-05-31 gap sweep:
      every Java production source, Java resource, and Java test path from
      `origin/main` is now represented directly in this file or covered by an
      explicit glob entry.
- [x] Generated Java ripper source list and compared it to
      `RipperMigrationCatalog.legacyRipperClasses`; no missing or extra class
      names were found.
- [x] Compared `legacyRipperClasses` to `portedRipperClasses`; both currently
      contain 116 class names and there are no set differences.
- [x] Added a Dart catalog guard in `test/ripper_factory_test.dart` so the
      tracked legacy/ported ripper class sets must remain equal and duplicate
      free. This still needs a source-tree-backed generator before Workstream 0
      can be marked complete.
- [x] Generated Java-used config keys and compared them to Flutter defaults;
      missing, replacement, and implemented-but-still-unverified keys are
      recorded in section B.
- [x] Generated Java localized keys and compared them to Flutter localization
      lookups; missing keys are recorded in section G. The 2026-05-31 rerun
      confirmed all missing localized keys from the scan are named there.
- [x] Generated Java test class names and compared them to Dart test files;
      missing/non-direct mappings are recorded in section H. The 2026-05-31
      rerun covered all 118 Java test classes under
      `src/test/java/com/rarchives/ripme`.
- [x] Generated Java public utility/runtime methods and recorded previously
      implicit helper/runtime parity checks in section E.
- [x] Scanned Java build/release files, README, updater metadata, test tags,
      resource usage, desktop integration calls, and source TODOs for
      user-visible parity risks; findings are recorded in sections J-M.
- [x] Generated Java dependency and import capability lists from
      `origin/main:build.gradle.kts` and production imports, compared them with
      Flutter `pubspec.yaml`, and recorded missing/replacement surfaces in
      sections I-J, including Java-WebSocket, GraalVM JavaScript parsing, OkHttp,
      j2html, Apache HttpComponents, Commons libraries, `org.json`, jsoup,
      Disruptor, and log4j.
- [x] Scanned Java platform/runtime API usage for system properties, environment
      variables, process execution, shutdown hooks, proxy authenticators,
      clipboard/tray/desktop calls, file/path helpers, URL decoding, and timing
      calls; new exact-semantics findings are recorded in sections B, D, E, and
      J.
- [x] Scanned Java user-visible string surfaces beyond localization bundles:
      hardcoded Swing text, updater labels, tray notifications, thrown
      exceptions, status updates, and logged errors. Non-bundle string parity is
      recorded in section G.
- [x] Scanned Java binary resources from
      `origin/main:src/main/resources` against Flutter assets/platform
      resources using Git blob IDs. Java toolbar PNGs, `icon.png`, and
      `camera.wav` are carried forward byte-identically under `assets/` or
      `assets/sounds/`; Java `icon.ico` differs from the Windows embedded
      `app_icon.ico`, and Android/macOS launcher icons are generated platform
      resources requiring visual/provenance verification. Resource-path and
      packaging findings are recorded in sections G and J.
- [x] Re-scanned Java TODO/disabled/test-tag surfaces and Flutter skipped/live
      tests. The Java suite has 119 flaky tags, 7 slow tags, and 44 disabled
      annotations, while Flutter currently exposes only two environment-gated
      live smoke tests; the test-policy parity gap is recorded in section L.
- [x] Inspected desktop runner argument plumbing for Windows, Linux, and macOS.
      Windows and Linux forward launch arguments into Dart, but macOS currently
      uses the default `FlutterViewController` with no entrypoint arguments and
      `lib/main.dart` ignores arguments entirely; the cross-platform CLI launch
      gap is recorded in Workstream 1.
- [x] Re-read Java `ClipboardUtils` and Flutter clipboard autorip code.
      Exact differences in polling interval, accepted schemes, duplicate
      memory scope, whole-clipboard matching, and queue-vs-start behavior are
      recorded in section F.
- [x] Re-read Flutter localization locale mapping against the Java
      `LabelsBundle*.properties` inventory. The `fi_FI_porrisavo` bundle is
      present but unreachable from Flutter's supported locale list/mapping, and
      language-only support checks require exact fallback tests; findings are
      recorded in section G.
- [x] Scanned Java label bundles for `.properties` syntax beyond simple
      `key=value` loading. Arabic and Korean bundles contain Java `\uXXXX`
      escapes; Flutter now has focused coverage for those escapes, while
      remaining parser compatibility findings are recorded in section G.
- [x] Scanned Java ripper inheritance against Flutter ripper inheritance. The
      Java `AbstractSingleFileRipper` subclasses `RulePornRipper`,
      `SpankbangRipper`, `XvideosRipper`, and `YoupornRipper` are implemented
      as Flutter `AbstractHTMLRipper` subclasses, so byte-progress inheritance
      parity needs explicit verification; the finding is recorded in section E.
- [x] Rechecked Java package-distinct rippers with duplicate simple class names
      against Flutter factory/catalog routing. Java has separate album and
      video implementations for Pornhub, Vk, and Yuvutu, while Flutter catalog
      equality is simple-name based; the collapsed-catalog risk is recorded in
      section E.
- [x] Scanned Java `hasASAPRipping()` overrides and compared them with Flutter
      custom download paths. The exact Java ASAP-ripper class list and missing
      shared-contract guard are recorded in section I.
- [x] Rechecked Java language selection/config persistence against Flutter
      localization startup. Java's persisted `lang` key, generated language
      combo list, `Utils.setLanguage(...)`, and `MainWindow.changeLocale()`
      runtime reload behavior are recorded in section G.
- [x] Re-ran the Java-vs-Flutter ripper filename inventory with normalized
      class/file names. No missing Java ripper simple names were found in the
      Flutter ripper file inventory; behavior parity still depends on the
      per-ripper hook and test-mapping findings above.
- [x] Re-ran Java hook/status/CLI scans for queue support, URL normalization,
      duplicate allowances, byte progress, ASAP ripping, command-line/update
      behavior, and status messages. New exact findings were recorded where
      missing; the remaining surfaces were already represented in sections A,
      E, I, J, and the pass ledgers.
- [x] Re-ran Java `sanitizeURL` override discovery against Flutter constructor
      wiring. A new exact finding was recorded in section E for Java
      constructor-time URL sanitization that is not uniformly stored in
      Flutter `AbstractRipper.url`.
- [x] Re-ran Java `normalizeUrl` override discovery. A new exact finding was
      recorded in section E for the `ArtStationRipper` and `DeviantartRipper`
      URL-history normalization hooks.
- [x] Re-read Java `UpdateUtils.isNewerVersion` and Flutter
      `UpdateChecker.isNewerVersion`. Java's exact-string fallback after equal
      numeric components is missing from Flutter; the finding is recorded in
      section J.
- [x] Re-read Java `Http`, `DownloadFileThread`, and `DownloadVideoThread`
      against Flutter `http_utils.dart` and `AbstractRipper`. The concrete
      differences found in this pass were already represented in section D:
      chainable request APIs, exact retry counts, resume/range behavior,
      MIME/magic extension detection, status-code handling, Imgur byte-length
      404 behavior, video HEAD/progress semantics, and URL-history timing.
- [x] Re-ran the Java config-key census from `Utils.getConfig*` call sites and
      `rip.properties` against Flutter defaults and call sites. No new config
      key names were found beyond the already recorded missing/renamed keys in
      sections B, C, F, G, J, and I.
- [x] Re-read Java `AbstractHTMLRipper` and `AbstractJSONRipper` against
      Flutter `AbstractHTMLRipper` and `AbstractJSONRipper`. New exact shared
      behavior gaps were recorded in section E for repeated-page guards and
      empty-media failure semantics.
- [x] Re-read Java `AlbumRipper` and `VideoRipper` against Flutter
      `AbstractRipper`/`AbstractVideoRipper`. A new exact finding was recorded
      in section D for Java `VideoRipper` test-mode URL mutation. The observed
      URL-only, album-title, duplicate-suppression, byte-progress/status-text,
      video HEAD/progress, and shared download-path differences are also
      represented in section E.
- [x] Re-read Java `AbstractRipper` and `RipperInterface` against Flutter
      `AbstractRipper`. A new exact shared preflight gap was recorded in
      section E for bare-scheme rejection and `%20` rewriting of spaces in
      download URLs before history/save-path/queue behavior.
- [x] Re-read Java `DownloadThreadPool` against Flutter
      `AbstractRipper.downloadFiles`. The Java 3600-second termination wait
      cap/interruption behavior is not represented in Flutter and is recorded
      in section E.
- [x] Re-ran the Java per-ripper `getThreadPool()` override scan against
      Flutter `AbstractRipper.downloadFiles`. A new exact finding was recorded
      in section E for the Java rippers that replace or name their own
      `DownloadThreadPool` through `AbstractHTMLRipper`/`AbstractJSONRipper`
      waiting hooks.
- [x] Re-read Java `Utils.getWorkingDirectory()` against Flutter
      `Utils.getWorkingDirectory`. A new exact finding was recorded in section E
      for Java creating a configured `rips.directory` path before returning it.
- [x] Re-read Java `App` option parsing and `AbstractRipper.getFilePath`
      around `-a` / `--append-to-folder`. A new exact finding was recorded in
      section E for Java resolving the working directory to a sibling named
      `<workingDirName><appendString>` before subdirectories and filenames are
      added.
- [x] Re-ran source-tree reconciliation from Java `*Ripper.java` files against
      Flutter `RipperMigrationCatalog.legacyRipperClasses` and local Dart ripper
      files. No missing Java ripper simple names were found in the catalog in
      this pass.
- [x] Re-read Java `MainWindow.saveWindowPosition` /
      `restoreWindowPosition` against Flutter desktop code. A new exact finding
      was recorded in section F for Java `window.position` plus
      `window.x`/`window.y`/`window.w`/`window.h` bounds persistence.
- [x] Re-scanned Java `descriptions.save` and description helper overrides.
      Section E was corrected: Java has shared description-save machinery, but
      no current concrete ripper returns `hasDescriptionSupport() == true`;
      `FuraffinityRipper` implements helpers while explicitly disabling the
      feature.
- [x] Re-read Java `RipUtils.getURLRegex` and `RedditRipper.handleBody`
      against Flutter `RedditRipper._mediaFromBody`. A new exact finding was
      recorded in section I for the narrower Java Reddit body-link regex and
      trailing-parenthesis-only cleanup.
- [x] Re-read Java `HqpornerRipper.getBestQualityLink` against Flutter
      `HqpornerRipper.bestQualityLink`. A new exact finding was recorded in
      section I for the empty candidate-list result (`null` in Java, empty
      string in Flutter).
- [x] Re-read Java `Utils.filesystemSafe` against Flutter
      `Utils.filesystemSafe`. The existing audit wording was corrected in
      Workstream 6 and section E: Java allows comma, underscore, and space,
      trims, and truncates overlong strings to 99 characters; Flutter only
      lacks the truncation.
- [x] Re-read Java `E621Ripper.getNextPage` and `E621RipperTest` against
      Flutter `E621Ripper.getNextPage` and `e621_ripper_test.dart`. A new exact
      finding was recorded in section I for Java's asserted
      `IOException("No more pages.")` behavior versus Flutter's `null`.
- [x] Re-scanned Java tests that assert exact no-next-page exception messages.
      A new section I finding records the matching Hqporner/Pornhub assertions
      plus the disabled Photobucket source assertion against Flutter's nullable
      next-page helpers/tests.
- [x] Re-read Java `RipUtils.checkTags` and the E-Hentai/NHentai/Tsumino
      blacklist tests against Flutter per-ripper blacklist helpers. A new
      section I finding records the shared Java ordering/case/return semantics
      and the divergent Flutter implementations.
- [x] Re-read Java `BatoRipper.getAlbumTitle` and `BatoRipperTest` against
      Flutter `BatoRipper.getAlbumTitle` and `bato_ripper_test.dart`. A new
      section I finding records the cached-first-page title behavior and the
      missing Dart proof for the disabled Java title expectation.
- [x] Re-read Java `DeviantartRipper.login`, cookie serialization/validation,
      and DeviantArt image download flow against Flutter
      `deviantart_ripper.dart` and `deviantart_ripper_test.dart`. A new exact
      section I finding records Java's persisted cookie/login flow versus
      Flutter's hardcoded agegate cookie.
- [x] Re-read Java `HentaifoundryRipper.getNextPage` and flaky
      `HentaifoundryRipperTest` against Flutter `hentaifoundry_ripper.dart`
      and `hentaifoundry_ripper_test.dart`. A new section I finding records
      Java's `IOException("No more pages")` pagination contract versus
      Flutter's nullable end-state helper.
- [x] Re-read Java `TwitterRipper`, `AbstractJSONRipper`, and Flutter
      `twitter_ripper.dart`/`twitter_ripper_test.dart`. New source-backed
      findings were recorded for the retweet default mismatch and Twitter's
      per-page ordered-filename index reset.
- [x] Re-read Java `DerpiRipper.getNextPage` against Flutter
      `derpi_ripper.dart` and `derpi_ripper_test.dart`. A new section I finding
      records Java's `IOException("No more images")` pagination contract versus
      Flutter's nullable end-state helper.
- [x] Re-read Java `CoomerPartyRipper` and `CoomerPartyRipperTest` against
      Flutter `coomer_party_ripper.dart` and `coomer_party_ripper_test.dart`.
      A new section I finding records Java's no-short-page-stop pagination
      behavior versus Flutter's `posts.length < 50` clean stop.
- [x] Re-read Java `FlickrRipper` against Flutter `flickr_ripper.dart` and
      `flickr_ripper_test.dart`. A new section I finding records Java's
      empty-size-map failure path in `getLargestImageURL` versus Flutter's
      nullable skip behavior.
- [x] Re-read Java `FuraffinityRipper` against Flutter
      `furaffinity_ripper.dart` and `furaffinity_ripper_test.dart`. New section
      I findings record Java's next-page exception contract and missing
      Download-link null-deref behavior versus Flutter's nullable/skip paths.
- [x] Re-read Java `ImagefapRipper` against Flutter `imagefap_ripper.dart` and
      `imagefap_ripper_test.dart`. A new section I finding records Java's
      `IOException("No next page found")` pagination contract versus Flutter's
      nullable end-state helper.
- [x] Ran a mechanical Java source scan for `throw new IOException(...)`
      no-next-page/no-more-results contracts across `AbstractHTMLRipper`,
      `AbstractJSONRipper`, and concrete Java rippers, then compared the result
      against Flutter nullable `getNextPage` helpers. A new section I finding
      records the remaining class/message inventory so later parity work does
      not discover these piecemeal.
- [x] Re-read Java `ArtStationRipper.parseURL(...)` and Flutter
      `ArtStationRipper.parseUrl(...)` / `parseUrlFromHtml(...)`. A new section
      I finding records Java's status-403-only artwork JSON fallback versus
      Flutter's broader any-error/empty-HTML artwork fallback.
- [x] Re-read Java `LusciousRipper` against Flutter `luscious_ripper.dart` and
      `luscious_ripper_test.dart`. A new section I finding records Java's
      album-page fetch and strict GraphQL structure handling versus Flutter's
      API-only empty-list completion path.
- [x] Re-read Java `RedgifsRipper` against Flutter `redgifs_ripper.dart` and
      `redgifs_ripper_test.dart`. New section I findings record the Java
      `/gifs/detail` sanitization outcome and gallery-fetch `IOException`
      handling versus Flutter's broader detail rewrite and propagated gallery
      failures.
- [x] Re-read Java `ScrolllerRipper` against Flutter `scrolller_ripper.dart`
      and `scrolller_ripper_test.dart`. A new section I finding records Java's
      strict malformed GraphQL response failure path versus Flutter's empty-list
      completion behavior.
- [x] Re-read Java `SankakuComplexRipper` against Flutter
      `sankaku_complex_ripper.dart` and its tests. A new section I finding
      records Java's missing-pagination dereference/no-more-pages behavior and
      jsoup cookie parsing versus Flutter's nullable next-page helper and
      comma-split cookie parsing.
- [x] Re-read Java `NsfwXxxRipper` against Flutter `nsfw_xxx_ripper.dart` and
      its tests. A new section I finding records Java's strict `page`/`items`
      JSON reads and `IOException("No more pages")` contract versus Flutter's
      nullable/empty-list completion paths.
- [x] Ran a mechanical Java strict-JSON access scan for `getJSONArray`,
      `getJSONObject`, and `getString` across concrete rippers, then compared
      the result to Flutter parser sites using nullable casts, `??`, and empty
      lists. A new section I inventory records remaining rippers that require
      exact parse-failure parity decisions.
- [x] Re-read Java `FuskatorRipper`, `HentaiNexusRipper`, and
      `MangadexRipper` against their Flutter ports and focused Dart tests. New
      section I findings record Java strict JSON parser behavior and Mangadex
      per-chapter fetch failure behavior versus Flutter's nullable/empty-list
      or propagated-error paths.
- [x] Re-read Java `PhotobucketRipper` and `ThechiveRipper` against their
      Flutter ports. New section I findings record Photobucket strict
      collection/metadata parsing, page-end exception, path/cookie behavior,
      and TheChive save-order plus `i.thechive.com` JSON failure/look-ahead
      pagination differences.
- [x] Re-read Java `Utils.getConfigStringArray` usages against Flutter
      `Utils.getConfigStringList`. A new section B finding records Java's
      zero-length-array-to-`null` behavior versus Flutter's empty-list behavior
      for list-style config keys.
- [x] Re-read Java `App.handleArguments`/`ripURL` against Flutter startup. A
      new exact CLI finding was recorded in sections A/Workstream 1: Java
      accepts `-n` / `--no-prop-file`, but the `saveConfig` argument is unused,
      making the option a current-source no-op despite the help text.
- [x] Re-read Java CLI URL-file and history fallback paths. New exact findings
      were recorded for blank URL-file line handling and for the current
      `App.loadHistory`/`RipUtils.urlFromDirectoryName` directory-path behavior.
- [x] Re-ran a low-audit-mention ripper sweep against Java source from
      `origin/main` and the corresponding Dart ports/tests. `KingcomixRipper`,
      `ModelmayhemRipper`, `MyreadingmangaRipper`, `NatalieMuRipper`,
      `NsfwAlbumRipper`, `NudeGalsRipper`, `SmuttyRipper`, `SoundgasmRipper`,
      `TeenplanetRipper`, and `VidbleRipper` were rechecked without finding a
      new source-backed gap beyond already recorded shared/runtime risks.
      `MyhentaigalleryRipper`, `HypnohubRipper`, `MultpornRipper`, `OglafRipper`,
      `ReadcomicRipper`, and `ArtStationRipper` were also re-read; their
      observed source-backed differences are already represented in sections
      D, E, and I. A local jsoup 1.11.3 check confirmed that
      `OglafRipper`'s `el.select("img").attr("src")` includes the selected
      image element itself, so that suspected extraction drift was rejected.
- [x] Re-ran Java concrete-ripper sleep/throttle scans against Dart delay sites.
      The only Java sleep class without a same-file Dart delay was
      `TsuminoRipper`, whose missing download sleep/object-file behavior is
      already recorded in section I; all other concrete sleep classes have an
      explicit Dart delay site, with the remaining gaussian-jitter mismatch
      tracked as a shared runtime gap in section E.
- [x] Re-ran Java strict DOM dereference scans for `.get(0)`, `.first()`, and
      `selectFirst(...)` against nullable Dart selector helpers. The follow-up
      reads of `CheveretoRipper`, `WebtoonsRipper`, `FapDungeonRipper`,
      `FapwizRipper`, and `CfakeRipper` found no new source-backed gaps beyond
      the existing section I rows for title fallback scope, next-page exception
      contracts, strict parser failures, domain-level `canRip(...)`, and
      empty-attribute download scheduling.
- [x] Re-read Java reflective `AbstractRipper.getRipper(...)` behavior against
      Flutter `RipperFactory` and `RipperMigrationCatalog`. The source-backed
      dispatch differences found in this pass were already represented in
      section E: duplicate simple-name album/video rippers, constructor-guard
      bypass for direct factory routes, and `host.contains(...)` expansion for
      several Flutter routes. Since `portedRipperClasses` currently equals
      `legacyRipperClasses`, `findUnportedLegacyRipper(...)` is inert today;
      it still needs generated source-tree backing before final parity can be
      claimed.
- [ ] Convert the mechanical scans above into checked-in tests/scripts before
      claiming final parity.

### Workstream 11: Final QA And Release Evidence

- [ ] Run targeted tests for the last changed unit.
- [ ] Run `flutter analyze --no-pub`.
- [ ] Run `flutter test --no-pub --reporter expanded`.
- [ ] Commit and push final migration state.
- [ ] Watch GitHub Actions to success.
- [ ] Record artifact links for Android, Windows, macOS, and Linux.
- [ ] Record remaining intentional differences from Java, if any.
- [ ] Update README or migration docs with final status.

## Source Map

### 1. Application Entry And Launch

Java sources:

- `src/main/java/com/rarchives/ripme/App.java`
- `src/main/java/com/rarchives/ripme/ui/MainWindow.java`
- `src/main/java/com/rarchives/ripme/ui/UpdateUtils.java`

Flutter sources:

- `lib/main.dart`
- `lib/rip_manager.dart`
- `lib/update_checker.dart`
- `lib/app_version.dart`

Initial status:

- [x] GUI launch exists in Flutter with localized title, main command bar, status/progress, log, history, queue, and configuration tabs.
- [x] Flutter initializes persisted configuration before app launch through `Utils.init()`.
- [x] Flutter has update checking through GitHub Releases instead of Java self-update.
- [~] Java GUI behavior is partly represented; source-audited MainWindow gaps
      are tracked in sections F, G, and the workflow notes below.
- [ ] Java CLI/headless mode from `App.java` is not yet verified as ported.
- [ ] Java command-line options are not yet fully mapped to Flutter behavior.

CLI/headless Java behavior to verify and port:

- `-h` / `--help`: print command help
- `-v` / `--version`: print current version and exit
- `-u` / `--url`: rip one URL
- `-f` / `--urls-file`: rip URLs from a file, skipping `//` and `#` comments
- `-t` / `--threads`: set `threads.size`
- `-w` / `--overwrite`: set `file.overwrite`
- `-r` / `--rerip`: re-rip all history entries
- `-R` / `--rerip-selected`: re-rip selected history entries
- `-d` / `--saveorder`: set `download.save_order=true`
- `-D` / `--nosaveorder`: set `download.save_order=false`
- `-4` / `--skip404`: set 404 skip behavior
- `-l` / `--ripsdirectory`: set `rips.directory`
- `-n` / `--no-prop-file`: do not persist property/config changes for that run
- `-s` / `--socks-server`: use SOCKS proxy
- `-p` / `--proxy-server`: use HTTP proxy
- `-j` / `--update`: run updater
- `-a` / `--append-to-folder`: append a string to output folder names
- `-H` / `--history`: set history file location

First findings:

- Java chooses CLI/headless mode when either the environment is headless or any CLI args are present. Flutter currently starts the GUI from `main()` and does not branch on process arguments.
- Java supports persisted queue restoration through the `queue` config key in `MainWindow`; Flutter keeps an in-memory queue in `RipManager`, and queue persistence/restoration still needs a focused parity check.
- Java rejects duplicate manual queue entries and expands numeric URL ranges
  using `{start-end}` syntax in `RipButtonHandler`; Flutter currently enqueues
  the submitted text directly, so queue-entry parity is missing.
- Java validates the current URL while typing and shows detected ripper host;
  Flutter command bar parity for live validation is tracked as a source-backed
  UI gap in section F.

### 2. Main Window And User Workflows

Java sources:

- `src/main/java/com/rarchives/ripme/ui/MainWindow.java`
- `src/main/java/com/rarchives/ripme/ui/ClipboardUtils.java`
- `src/main/java/com/rarchives/ripme/ui/ContextMenuMouseListener.java`
- `src/main/java/com/rarchives/ripme/ui/HistoryMenuMouseListener.java`
- `src/main/java/com/rarchives/ripme/ui/QueueMenuMouseListener.java`
- `src/main/java/com/rarchives/ripme/ui/RipStatusMessage.java`
- `src/main/java/com/rarchives/ripme/ui/RipStatusComplete.java`

Flutter sources:

- `lib/main.dart`
- `lib/rip_manager.dart`
- `lib/ui/rip_status_message.dart`
- `lib/history_provider.dart`
- `lib/download_history_provider.dart`

Initial status:

- [x] Basic log/history/queue/configuration panels exist as Flutter tabs.
- [x] Stop behavior exists through `RipManager.stop()`.
- [x] Progress is determinate from download events.
- [x] Log view is Java-style plain text rather than row/card based.
- [~] Clipboard autorip exists through periodic clipboard polling, but tray-menu parity and exact Java duplicate handling still need audit.
- [~] History import/export/clear/remove exists, but Java selected-entry re-rip and selected flags need audit.
- [ ] Java tray icon behavior is not yet verified in Flutter.
- [ ] Java open-folder button behavior after rip completion needs focused cross-platform verification.
- [ ] Java queue context-menu actions need a detailed Flutter parity check.
- [ ] Java history context-menu actions need a detailed Flutter parity check.

### 3. Core Ripping And Download Engine

Java sources:

- `src/main/java/com/rarchives/ripme/ripper/AbstractRipper.java`
- `src/main/java/com/rarchives/ripme/ripper/AbstractHTMLRipper.java`
- `src/main/java/com/rarchives/ripme/ripper/AbstractJSONRipper.java`
- `src/main/java/com/rarchives/ripme/ripper/AbstractSingleFileRipper.java`
- `src/main/java/com/rarchives/ripme/ripper/VideoRipper.java`
- `src/main/java/com/rarchives/ripme/ripper/DownloadFileThread.java`
- `src/main/java/com/rarchives/ripme/ripper/DownloadVideoThread.java`
- `src/main/java/com/rarchives/ripme/ripper/DownloadThreadPool.java`

Flutter sources:

- `lib/ripper/abstract_ripper.dart`
- `lib/ripper/abstract_html_ripper.dart`
- `lib/ripper/abstract_json_ripper.dart`
- `lib/ripper/abstract_video_ripper.dart`
- `lib/rip_manager.dart`
- `lib/utils/http_utils.dart`

Initial status:

- [x] Parallel download scheduling honors `threads.size`.
- [x] Duplicate URL suppression exists for scheduled downloads.
- [x] Existing-file skip behavior exists when overwrite is disabled.
- [x] URL-only saving exists.
- [x] Download history skip behavior exists.
- [x] Download headers and cookies can flow through scheduled downloads.
- [x] Video helper behavior has shared manifest selection coverage.
- [ ] Java `append-to-folder` behavior is source-audited and still needs
      porting/tests.
- [ ] Java description saving behavior is source-audited and still needs a
      Flutter shared equivalent or documented retirement.
- [ ] Java popup/tray notification behavior is source-audited and still needs
      per-platform Flutter replacement decisions.

### 4. Configuration, History, And Utilities

Java sources:

- `src/main/java/com/rarchives/ripme/utils/Utils.java`
- `src/main/java/com/rarchives/ripme/utils/Http.java`
- `src/main/java/com/rarchives/ripme/utils/Proxy.java`
- `src/main/java/com/rarchives/ripme/utils/RipUtils.java`
- `src/main/resources/rip.properties`
- `src/main/java/com/rarchives/ripme/ui/History.java`
- `src/main/java/com/rarchives/ripme/ui/HistoryEntry.java`

Flutter sources:

- `lib/utils/utils.dart`
- `lib/utils/http_utils.dart`
- `lib/config_defaults.dart`
- `lib/history_provider.dart`
- `lib/download_history_provider.dart`

Initial status:

- [x] Java `rip.properties` defaults are represented in `ConfigDefaults`.
- [x] HTTP retries, timeouts, retry-after handling, configured cookies, and HTTP proxy support exist.
- [x] Album history and downloaded URL history have Flutter providers.
- [~] History JSON imports can read Java date fields, but Java selected flags and file-location behavior need audit.
- [~] HTTP proxy support exists; SOCKS proxy parity is not yet verified.
- [ ] Java `history.location` / `-H` behavior is source-audited and still needs
      porting/tests.
- [ ] Java fallback history guessing from existing rip folders is source-audited
      and still needs porting/tests.

### 5. Resources, Localization, And Platform Integration

Java sources:

- `src/main/resources/LabelsBundle*.properties`
- `src/main/resources/*.png`
- `src/main/resources/*.wav`
- `src/main/resources/*.ico`
- `src/main/resources/log4j*.properties`

Flutter/platform sources:

- `assets/`
- `lib/l10n/app_localizations.dart`
- `android/`
- `linux/`
- `macos/`
- `windows/`
- `.github/workflows/`

Initial status:

- [x] Java label bundles are available to Flutter localization with English fallback.
- [x] Platform build artifacts are produced by GitHub Actions for Android, Windows, macOS, and Linux.
- [x] Completion sound behavior exists through platform alert sound.
- [ ] Exact Java `camera.wav` sound-resource parity is source-audited and still
      needs runtime replacement/intentional-difference tests.
- [ ] Java icon/resource parity is source-audited and still needs
      platform-by-platform visual/provenance verification.
- [ ] Logging file output parity is source-audited and still needs Flutter file
      logging implementation or documented retirement.

### 6. Ripper Catalog

Java source:

- `src/main/java/com/rarchives/ripme/ripper/rippers/**/*.java`

Flutter sources:

- `lib/ripper/rippers/*.dart`
- `lib/ripper/ripper_factory.dart`
- `lib/ripper/ripper_migration_catalog.dart`
- `MIGRATION_STATUS.md`

Initial status:

- [x] All tracked Java rippers are ported in the current catalog.
- [x] No unsupported legacy catalog entries remain.
- [x] Factory/catalog tests verify the current tracked count.
- [x] Source-tree reconciliation currently confirms no Java rippers are missing
      from `RipperMigrationCatalog.legacyRipperClasses`; keep this generated
      check in CI before claiming durable parity.

## Active Pass

### Pass 1: Application Entry And Main Window

Started: 2026-05-31

Sources read:

- `origin/main:src/main/java/com/rarchives/ripme/App.java`
- `origin/main:src/main/java/com/rarchives/ripme/ui/MainWindow.java`
- `lib/main.dart`
- `lib/rip_manager.dart`
- `lib/history_provider.dart`
- `lib/utils/utils.dart`
- `lib/utils/http_utils.dart`

Open work:

- [ ] Port or explicitly replace Java CLI/headless mode.
- [ ] Add Dart tests for CLI parsing/config side effects.
- [ ] Queue persistence, duplicate enqueue behavior, and `{start-end}` URL range
      expansion are source-audited and still need implementation/tests.
- [ ] Selected-history re-rip behavior is source-audited and still needs a
      Flutter selected-history model or documented replacement.
- [ ] Open-folder and tray/popup behavior is source-audited and still needs
      platform-specific Flutter replacement decisions.
