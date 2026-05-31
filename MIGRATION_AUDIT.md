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

- [ ] `src/main/java/com/rarchives/ripme/uiUtils/ContextActionProtections.java`
  - Must audit copy/paste/context action behavior against Flutter text fields,
    log rows, queue rows, and history rows.

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
- [ ] Define and test `-n` / `--no-prop-file` semantics for Flutter.
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
- [ ] Queue clear/remove/reorder behavior matches Java context-menu actions.
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
      `[a-zA-Z0-9.-]` and truncate names longer than 100 characters to 99.
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
- [ ] Java manual URL input rejects duplicate queue entries and expands
      `{start-end}` numeric ranges before enqueueing. Flutter currently queues
      the submitted URL string through `RipManager` and needs parity tests.
- [ ] Java persists queue state through the `queue` config key on updates and
      restores it on startup. Flutter queue persistence/restoration needs to be
      implemented or intentionally replaced.
- [ ] Java queue context menu supports remove selected and remove all with a
      confirmation dialog. Flutter queue actions need matching widget coverage.
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
- [ ] Java uses both `error.skip404` in defaults and some code paths checking
      `errors.skip404`; Flutter uses `error.skip404`. The typo/alias behavior
      must be reconciled for CLI and download paths.
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
- [ ] Java history table displays dates as `yyyy/MM/dd`. Flutter date display
      needs comparison.
- [ ] Java history context menu supports check all, uncheck all, check selected,
      and uncheck selected. Flutter does not yet have verified selected-entry
      parity.
- [ ] Java CLI `-r` re-rips all history entries and `-R` re-rips selected
      entries. Flutter needs equivalent behavior or a documented replacement.
- [ ] Java can reconstruct history candidates from existing rip directories via
      `RipUtils.urlFromDirectoryName`; Flutter has no verified equivalent.
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
- [ ] Java `Http` retry loop attempts exactly the configured count. Flutter's
      `_getResponse` currently loops `attempt <= retries`, which is one extra
      attempt for the same setting.
- [ ] Java file download retry loop increments `tries` and fails when
      `tries > retries`; redirect handling can avoid counting the first redirect.
      Flutter's bulk-response download path needs retry-count parity tests.
- [ ] Java `DownloadFileThread` supports resume with Range headers when a ripper
      opts in, MIME/magic extension detection when requested, explicit
      non-retriable 4xx handling, retriable 5xx handling, and an Imgur
      503-byte-as-404 special case. Flutter needs shared tests or documented
      replacement behavior.
- [ ] Java `DownloadVideoThread` first issues a HEAD request for total bytes,
      then downloads with no connect timeout and byte-progress events. Flutter
      video helpers need exact progress comparison.
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

- [ ] Java `filesystemSafe` removes every character outside `[a-zA-Z0-9.-]`
      and truncates names longer than 100 characters to 99. Flutter currently
      preserves spaces, commas, and underscores and does not truncate.
- [ ] Java `filesystemSanitized` replaces disallowed characters with `_`.
      Flutter has only `filesystemSafe` and `sanitizeSaveAs`.
- [ ] Java `sanitizeSaveAs` replaces `\\:*?"<>|` and has test-backed filename
      edge cases: explicit file name plus extension yields `test.test`, explicit
      filename without extension yields `test`, query URL object yields `Object`,
      and `file.` stays `file.`.
- [ ] Java working directory creation preserves an existing directory's
      original case on Unix/macOS through `getOriginalDirectory`.
- [ ] Java shortens Windows paths above 260 characters and long filenames above
      filesystem limits; Flutter has no verified equivalent.
- [ ] Java `getFileName` strips query, fragment, ampersand, and colon segments,
      adds prefix before extension handling, then sanitizes. Flutter rippers use
      local filename helpers that need shared parity tests.
- [ ] Java writes downloaded URLs to URL history before handing a download to
      the thread pool. Flutter marks downloads after `Http.downloadFile`
      succeeds; this changes retry/interruption semantics.
- [ ] Java `urls_only.save=true` writes `urls.txt`, counts it as completed, and
      opens `urls.txt` after rip completion. Flutter writes `urls.txt` but open
      behavior and completion details need verification.
- [ ] Java duplicate suppression is per ripper pending/completed/errored maps
      unless `allowDuplicates()` is overridden. Flutter has a per-ripper
      attempted URL set; override coverage needs verification.
- [ ] Java stops an HTML rip after `history.end_rip_after_already_seen` already
      downloaded URLs and sends `DOWNLOAD_COMPLETE_HISTORY`. Flutter sends a
      download-skip message and stops; status parity is missing.
- [ ] Java deletes an empty working directory during cleanup. Flutter does not
      yet verify this cleanup behavior.
- [ ] Java `AbstractHTMLRipper` supports queue-only pages through
      `hasQueueSupport`, `pageContainsAlbums`, and `getAlbumsToQueue`, adding
      discovered album URLs to `MainWindow` queue. Flutter needs verification
      for rippers that depend on this pattern.
- [ ] Java `descriptions.save` can save per-item description `.txt` files through
      `getDescriptionsFromPage`, `getDescription`, `saveText`, and
      `descSleepTime`. Flutter has no shared verified equivalent.
- [ ] Java `download.ignore_extensions` suppresses extension-matched URLs with
      `DOWNLOAD_SKIP`; Flutter has a similar check but needs exact tests.
- [ ] Java `sleep(milliseconds)` applies gaussian jitter with a minimum of 47%
      of requested time. Flutter delay behavior is not equivalent.
- [ ] Java `RipperInterface` contract includes `rip`, `canRip`, `sanitizeURL`,
      `setWorkingDir`, `getHost`, and `getGID`; Flutter abstract classes should
      keep all equivalent hooks covered by tests.
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
      queueing. Flutter autorip needs tests for these details.
- [ ] Java history context menu selected-state actions need Flutter equivalents.
- [ ] Java queue clear action asks for confirmation; Flutter queue clear/remove
      needs confirmation parity.
- [ ] Java queue/history/context popups position themselves around the pointer,
      shifting left when `x > 500`; Flutter popup positioning should either
      match where practical or be documented as a platform-native difference.
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
- [ ] Java save-directory label opens the working directory on click; the save
      directory chooser uses directory-only mode and stores `rips.directory`.
      Flutter save-directory interactions need parity tests.
- [ ] Java tray About dialog lists album and video ripper names from
      `Utils.getListOfAlbumRippers()` / `getListOfVideoRippers()` and can open
      the GitHub project page. Flutter About/update UI needs equivalent
      supported-site visibility or a documented replacement.

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
- [ ] Java supported languages are discovered by scanning available
      `LabelsBundle*.properties`; Flutter locale list needs comparison with:
      `ar_AR`, `de_DE`, `el_GR`, `en_US`, `es_ES`, `fi_FI`,
      `fi_FI_porrisavo`, `fr_CH`, `in_ID`, `it_IT`, `kr_KR`, `nl_NL`,
      `pl_PL`, `pt_BR`, `pt_PT`, `ru_RU`, and `zh_CN`.
- [ ] Java label-bundle tests assert every non-default key also exists in the
      default bundle. Flutter needs this coverage or an equivalent generated
      localization check.
- [ ] Java completion sound is `camera.wav`; Flutter currently uses platform
      alert sound. This is an intentional-difference candidate but not parity.
- [ ] Java logging file output is `ripme.log`, with rolling `ripme.%i.log.gz`
      output and a 20 MB size policy in log4j2. Flutter file logging is not
      verified.
- [ ] Java icon assets include `icon.ico`, `icon.png`, and toolbar PNGs
      (`comment`, `folder`, `gear`, `list`, `stop`, `time`, `wrench`).
      Flutter/platform resource parity needs explicit asset checks.
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
- [ ] Add Dart tests for Java Base64 decode/encode compatibility or document use
      of Dart `base64` as the replacement.
- [ ] Add Dart tests for `Utils.getEXTFromMagic`, `stripURLParameter`,
      `shortenPath`, `bytesToHumanReadable`, `getByteStatusText`, `between`,
      `shortenSaveAsWindows`, and `sanitizeSaveAs`.
- [ ] Add Dart tests for Java proxy string parsing for HTTP and SOCKS, even if
      SOCKS execution is later marked unsupported on a platform.
- [ ] Add Dart tests for Java label-bundle key rules and status-message string
      formatting.
- [ ] Keep the existing ripper test reconciliation, but do a final generated
      source-tree check in CI so new Java rippers cannot be missed.
- [ ] Mechanical test-method scan found 287 Java `@Test` methods across 111
      Java test classes, including 44 disabled methods and 125 tagged
      slow/flaky methods. Dart parity must be mapped at method/behavior level,
      not only file-name level.
- [ ] Non-ripper Java test methods requiring direct Dart coverage are:
      `AbstractRipperTest.testGetFileName`, `Base64Test.testDecode`,
      `UtilsTest.testConfigureLogger`, `UtilsTest.testShortenFileNameWindows`,
      `proxyTest.testSocksProxy`, `proxyTest.testHTTPProxy`,
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
      `src/test/java/com/rarchives/ripme` and 128 Dart test files. Most ripper
      tests have direct or naming-alias coverage; direct missing/non-direct
      Java utility/UI tests are `Base64Test`, `proxyTest`,
      `RipStatusMessageTest`, `RipButtonHandlerTest`, `UIContextMenuTests`,
      `UpdateUtilsTest`, aggregate suite tests `RippersTest` and
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
- [ ] Java byte-progress/resume overrides must be verified:
      `HqpornerRipper.tryResumeDownload` and
      `HqpornerRipper.useByteProgessBar`.
- [ ] Java blacklist config arrays must be verified for exact tag matching and
      warning text: `ehentai.blacklist.tags`, `nhentai.blacklist.tags`, and
      `tsumino.blacklist.tags`.
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
- [ ] Java `RipUtils.getFilesFromURL` helper coverage must be verified for
      Reddit/Chan-style direct links and embedded media expansion:
      Imgur album/gifv/single pages, Redgifs/gifdeliverynetwork, Vidble
      album/show, `v.redd.it`, Erome, Soundgasm, `i.reddituploads.com`, direct
      image/video regex, and Imgur meta fallback.
- [ ] Java per-ripper warning/error status messages must be checked where they
      feed UI parity, especially `DOWNLOAD_WARN`, `DOWNLOAD_ERRORED`,
      `RIP_ERRORED`, `NO_ALBUM_OR_USER`, and `DOWNLOAD_COMPLETE_HISTORY`
      sends from DeviantArt max-resolution/search failures, E621 cookie and
      blacklist warnings, E-Hentai/Nhentai/Tsumino blacklist skips, Flickr API
      key fallback warnings, Furaffinity shared-account errors, Imagefap
      throttling warnings, Tumblr `NO_ALBUM_OR_USER` and rate-limit handling,
      and Reddit upvote-filter/download-history completion messages.
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

- [ ] Many Java ripper tests are annotated `@Tag("flaky")` or `@Tag("slow")`,
      and several are `@Disabled` with site-specific reasons. Dart tests must
      preserve that knowledge through tags, skips, fake fixtures, or documented
      live-network test policy instead of silently omitting risky cases.
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
- [~] Java GUI behavior is represented, but a detailed MainWindow-by-MainWindow interaction audit is still required.
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
- Java rejects duplicate manual queue entries and expands numeric URL ranges using `{start-end}` syntax in `RipButtonHandler`; Flutter currently enqueues the submitted text directly. This is a likely parity gap.
- Java validates the current URL while typing and shows detected ripper host; Flutter command bar parity for live validation still needs inspection.

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
- [ ] Java `append-to-folder` behavior still needs audit/porting.
- [ ] Java description saving behavior needs audit against Flutter.
- [ ] Java popup/tray notification behavior needs audit against Flutter.

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
- [ ] Java `history.location` / `-H` behavior needs audit/porting.
- [ ] Java fallback history guessing from existing rip folders needs audit/porting.

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
- [ ] Exact Java `camera.wav` sound-resource parity needs audit.
- [ ] Java icon/resource parity needs a platform-by-platform audit.
- [ ] Logging file output parity needs audit.

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
- [ ] A final source-tree reconciliation should confirm no Java rippers are missing from `RipperMigrationCatalog.legacyRipperClasses`.

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
- [ ] Audit queue persistence, duplicate enqueue behavior, and `{start-end}` URL range expansion.
- [ ] Audit selected-history re-rip behavior.
- [ ] Audit open-folder and tray/popup behavior.
