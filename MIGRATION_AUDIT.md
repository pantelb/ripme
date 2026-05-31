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

