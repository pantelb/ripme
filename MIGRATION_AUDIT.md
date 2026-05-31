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
- [ ] Every Java test behavior under `src/test/java/com/rarchives/ripme/tst`
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
- [~] `src/test/java/com/rarchives/ripme/tst/ripper/rippers/*Test.java`
  - Current finding: the ripper tests have broad Dart equivalents; the
    non-ripper Java tests need reconciliation against Flutter utility/config
    tests.

## Workstream Plan

Workstreams are ordered. Do not jump ahead unless the current workstream is
blocked by platform constraints or missing user input.

### Workstream 0: Inventory And Baseline

- [x] Create this fresh full-app audit file.
- [ ] Reconcile all Java production files with this inventory.
- [ ] Reconcile all Java resources with this inventory.
- [ ] Reconcile all Java tests with Dart tests.
- [ ] Add a script or test that fails when a Java ripper exists without a
      catalog entry.
- [ ] Record latest passing Actions run and artifacts for the inventory commit.

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
- [ ] Reconcile every Java configuration control with Flutter UI.
- [ ] Reconcile hidden/runtime-only keys not exposed in UI.
- [ ] Persist settings on exit or immediately in a documented Flutter-native way.
- [ ] Support language selection and reload behavior.
- [ ] Support save directory selection across desktop and Android.
- [ ] Support window position persistence or explicitly mark not applicable.
- [ ] Support log level, log save, popup, sound, URLs-only, album-title folders,
      descriptions, prefer MP4, SSL verification, URL history, retries, timeout,
      retry sleep, thread count, overwrite, and save order.

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
- [ ] Verify per-download cookies and referer headers.
- [ ] Verify HTTP proxy host/port/auth.
- [ ] Port SOCKS proxy support or explicitly mark not applicable.
- [ ] Verify SSL verification toggle behavior.
- [ ] Verify content-type-tolerant JSON/HTML parsing.
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
- [ ] Port or document `append-to-folder`.
- [ ] Verify `album_titles.save` behavior.
- [ ] Verify `descriptions.save` behavior.
- [ ] Verify URL-only output path and append behavior.
- [ ] Verify duplicate URL suppression scope.
- [ ] Verify already-downloaded URL skip counter and stopping threshold.
- [ ] Verify stop/interruption semantics.
- [ ] Verify progress percentage semantics.
- [ ] Verify status text/log event text.
- [ ] Verify video download filename/referrer/cookie behavior.
- [ ] Verify ignored extension behavior.

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

- [ ] Generate/verify list of Java rippers from source tree.
- [ ] Compare generated list to `legacyRipperClasses`.
- [ ] Compare `legacyRipperClasses` to `portedRipperClasses`.
- [ ] Verify each port has focused Dart tests.
- [ ] Verify factory can resolve every supported Java URL shape used in tests.
- [ ] Verify no placeholder/scaffold-only rippers remain.
- [ ] Verify video-subpackage Java rippers are represented.
- [ ] Verify helper classes such as `ChanSite` are represented.

Required tests:

- [ ] Catalog reconciliation test.
- [ ] Factory coverage test.
- [ ] Any missing helper behavior tests.

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
