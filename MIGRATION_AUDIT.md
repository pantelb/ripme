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
  - Current finding: Java CLI/headless argument behavior is ported. Java's
    album-history fallback guessing from existing rip directories remains
    tracked in Workstream 3.

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

- [x] `src/main/resources/LabelsBundle*.properties`
- [x] `src/main/resources/camera.wav`
- [x] `src/main/resources/comment.png`
- [x] `src/main/resources/folder.png`
- [x] `src/main/resources/gear.png`
- [x] `src/main/resources/icon.ico`
- [x] `src/main/resources/icon.png`
- [x] `src/main/resources/list.png`
- [ ] `src/main/resources/log4j.file.properties`
- [ ] `src/main/resources/log4j2-example.xml`
- [~] `src/main/resources/rip.properties`
- [x] `src/main/resources/stop.png`
- [x] `src/main/resources/time.png`
- [x] `src/main/resources/wrench.png`
  - Current finding: localization, sound, icons, and toolbar resources are
    packaged and guarded against `origin/main`; Java logging configuration
    files remain replaced by the tested Dart logger implementation.

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
- [x] Add a script or test that fails when a Java ripper exists without a
      catalog entry.
  - Completed: `tool/check_legacy_ripper_catalog.dart` compares the unique
    `*Ripper.java` class names in `origin/main` with
    `RipperMigrationCatalog.legacyRipperClasses`. Flutter CI fetches the Java
    baseline and runs the guard before analysis. Focused extraction coverage is
    in `test/legacy_ripper_inventory_test.dart`, including duplicate class
    names shared by base and video packages.
  - CI: commit `56057d53` passed
    [Flutter CI run 27325422672](https://github.com/pantelb/ripme/actions/runs/27325422672).
    Artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27325422672/artifacts/7555452945),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27325422672/artifacts/7555428847),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27325422672/artifacts/7555413445),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27325422672/artifacts/7555404037).
- [x] Add a script or test that fails when a Java-used config key has no Flutter
      default, migration alias, or documented intentional removal.
  - Completed: `tool/check_java_config_keys.dart` reads every Java production
    source file and `rip.properties` from `origin/main`, extracts literal,
    constant-backed, dynamic-prefix, and required config keys, and compares the
    result with `ConfigDefaults.javaRuntimeKeys`. Flutter CI runs the guard
    before analysis.
  - Source discrepancy fixed: the previous hand-maintained inventory omitted
    `DeviantartLogin.cookies`, `download.ignore_extensions`, `gw.api`, and
    `tsumino.blacklist.tags`; all four are now recorded.
- [x] Add a script or test that fails when a Java localized key has no Flutter
      lookup, generated localization mapping, or documented intentional removal.
  - Completed: `tool/check_java_localization_keys.dart` scans every Java
    `Utils.getLocalizedString(...)` call in `origin/main` and requires its key
    to exist in the packaged default Java bundle. `AppLocalizations.javaLabel`
    provides the generic Flutter lookup path, while focused tests cover source
    extraction, property parsing, translated lookup, and unknown-key fallback.
    Flutter CI runs the guard before analysis.
- [x] Add a script or test that fails when a Java test class has no Dart test,
      alias mapping, broader integration test, or documented intentional removal.
  - Completed: `tool/check_java_test_coverage.dart` generates all Java test
    classes from `origin/main`, compares them with checked-in Dart test files,
    and applies the reviewed aliases in `JavaTestInventory.coverageAliases`.
    The guard currently covers all 118 Java test classes, including 20 naming,
    inherited-ripper, aggregate-suite, or broader-integration mappings. Flutter
    CI runs the guard before analysis.
  - Scope: this proves class-level representation only. Section H remains open
    for the stricter method-by-method and disabled/flaky behavior reconciliation.
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

- [x] Detect CLI/headless invocation before launching `MaterialApp`.
  - Completed: `lib/main.dart` now accepts Dart entrypoint arguments and routes
    every non-empty argument list through `CliController` before initializing
    Flutter bindings or constructing the GUI. Unported options currently fail
    explicitly instead of launching `MaterialApp`.
- [x] Verify desktop runner argument plumbing on every platform before CLI
      parity is claimed.
  - Completed: Windows `main.cpp` and Linux `my_application.cc` explicitly set
    Dart entrypoint arguments. macOS now explicitly constructs
    `FlutterDartProject`, whose embedding implementation initializes
    `dartEntrypointArguments` from process arguments with the executable name
    removed, and passes that project to `FlutterViewController`.
- [x] Print Java-compatible help text for `-h` / `--help`.
  - Completed: the help output mirrors the option names, value requirements,
    and descriptions declared by Java `App.getOptions()`.
- [x] Print Flutter app version for `-v` / `--version`.
  - Completed: both forms print `appVersion` and exit successfully.
  - CI: commit `e4bbf119` passed
    [Flutter CI run 27325776867](https://github.com/pantelb/ripme/actions/runs/27325776867).
    Artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27325776867/artifacts/7555586171),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27325776867/artifacts/7555560948),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27325776867/artifacts/7555540263),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27325776867/artifacts/7555529614).
- [x] Support single URL ripping through `-u` / `--url`.
  - Completed: both separated and `--url=<value>` forms validate the URL,
    resolve it through `RipperFactory`, and run `setup()` / `rip()` headlessly
    with guaranteed disposal. Invalid URLs use Java's expected-format message.
  - CI: commit `f35de47c` passed
    [Flutter CI run 27326311304](https://github.com/pantelb/ripme/actions/runs/27326311304).
    Artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27326311304/artifacts/7555801256),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27326311304/artifacts/7555768155),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27326311304/artifacts/7555765455),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27326311304/artifacts/7555739398).
- [x] Support URL-file ripping through `-f` / `--urls-file`.
  - Completed: URL files are read line-by-line and valid entries are ripped
    sequentially. Individual malformed URLs and rip failures are reported
    without stopping later entries, matching Java `ripURL(...)` handling.
  - CI: commit `c3b8ea00` passed
    [Flutter CI run 27326603695](https://github.com/pantelb/ripme/actions/runs/27326603695).
    Artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27326603695/artifacts/7555909782),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27326603695/artifacts/7555887063),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27326603695/artifacts/7555863569),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27326603695/artifacts/7555855241).
- [x] Skip URL-file lines beginning with `//` or `#`.
  - Completed: comment detection occurs before trimming, preserving Java's
    distinction between `//comment` and whitespace-prefixed `  //comment`.
- [x] Apply `-t` / `--threads` to `threads.size`.
- [x] Apply `-w` / `--overwrite` to `file.overwrite`.
- [x] Apply `-d` / `--saveorder` to `download.save_order=true`.
- [x] Apply `-D` / `--nosaveorder` to `download.save_order=false`.
- [x] Reject simultaneous `-d` and `-D`.
  - Completed: side effects preserve Java order, so `-D` writes `false` before
    the conflict is reported.
- [x] Apply `-4` / `--skip404` to the same config key used by Flutter HTTP.
  - Completed: CLI writes Java's `errors.skip404`; Flutter HTTP now prefers
    that key and falls back to the former `error.skip404` key for migration.
- [x] Apply `-l` / `--ripsdirectory` to `rips.directory`.
- [x] Define and test `-n` / `--no-prop-file` semantics for Flutter. Java
      accepts the option and passes `!cl.hasOption("n")` into `ripURL`, but
      `ripURL(String targetURL, boolean saveConfig)` never reads `saveConfig`;
      the current Java behavior is effectively a no-op despite the help text.
  - Completed: Flutter recognizes both forms as an explicit no-op and exits
    successfully when no rip target is provided. The behavior is locked by a
    config-store test proving no setting is written.
- [x] Support `-p` / `--proxy-server` for HTTP proxy strings.
  - Completed: Java `[user:password]@host[:port]` syntax is parsed using the
    same last-`@` and colon rules, stored under `proxy.http`, and mapped to the
    active Flutter HTTP proxy fields.
- [x] Support or explicitly reject `-s` / `--socks-server` with a documented
      platform reason.
  - Decision: explicitly rejected with exit code 64 because Flutter's current
    `dart:io` `HttpClient` backend exposes HTTP proxy routing but no SOCKS proxy
    API. The option is not silently accepted.
- [x] Support `-a` / `--append-to-folder` or document a replacement.
  - Completed: the exact CLI suffix is retained for the process. Shared
    download path resolution redirects files from `<workingDir>/...` to the
    Java-compatible sibling `<workingDir><suffix>/...` without changing the
    ripper's reported working directory.
- [x] Support `-H` / `--history`.
  - Completed: Java's option name is misleading: `history.location` controls
    the downloaded-URL history file returned by `Utils.getURLHistoryFile()`,
    not album `history.json`. Flutter now writes the same config key and uses
    the configured file for downloaded-URL checks, writes, and clearing.
    Source verification found that Java scans this file by line but appends
    URLs without separators; Flutter preserves that shipped behavior.
- [x] Support `-r` / `--rerip` for all history entries.
  - Completed: Flutter loads persisted album history in stored order, re-rips
    every valid URL, continues after invalid URLs or rip failures, and retains
    Java's 500 ms delay after each successful rip.
- [x] Support `-R` / `--rerip-selected`.
  - Completed: Flutter history now preserves Java's selected flag, title,
    count, and separate created/modified timestamps. The history view exposes a
    persisted checkbox, and CLI selected rerip processes only checked entries
    with Java-compatible empty-history and no-selection errors.
- [x] Replace Java `-j` updater behavior with the Flutter GitHub release
      checker.
  - Completed: CLI update checks use the existing GitHub Releases API checker
    and report current/latest versions plus the release URL. Java's downloaded
    jar replacement is intentionally retired because Flutter outputs are
    platform-specific signed/packaged artifacts; replacing a running binary
    would bypass the Android, Windows, macOS, and Linux installation models.

Recent CI evidence:

- Desktop argument plumbing: commit `6f9a93d9` passed
  [run 27328484169](https://github.com/pantelb/ripme/actions/runs/27328484169):
  [Android](https://github.com/pantelb/ripme/actions/runs/27328484169/artifacts/7556619588),
  [Windows](https://github.com/pantelb/ripme/actions/runs/27328484169/artifacts/7556584421),
  [macOS](https://github.com/pantelb/ripme/actions/runs/27328484169/artifacts/7556594602),
  [Linux](https://github.com/pantelb/ripme/actions/runs/27328484169/artifacts/7556560797).
- Downloaded-URL history location: commit `756e7c9f` passed
  [run 27328908471](https://github.com/pantelb/ripme/actions/runs/27328908471):
  [Android](https://github.com/pantelb/ripme/actions/runs/27328908471/artifacts/7556819032),
  [Windows](https://github.com/pantelb/ripme/actions/runs/27328908471/artifacts/7556775471),
  [macOS](https://github.com/pantelb/ripme/actions/runs/27328908471/artifacts/7556772659),
  [Linux](https://github.com/pantelb/ripme/actions/runs/27328908471/artifacts/7556741634).
- All-history rerip: commit `f3b7e6a5` passed
  [run 27329308507](https://github.com/pantelb/ripme/actions/runs/27329308507):
  [Android](https://github.com/pantelb/ripme/actions/runs/27329308507/artifacts/7556952466),
  [Windows](https://github.com/pantelb/ripme/actions/runs/27329308507/artifacts/7556925808),
  [macOS](https://github.com/pantelb/ripme/actions/runs/27329308507/artifacts/7556925904),
  [Linux](https://github.com/pantelb/ripme/actions/runs/27329308507/artifacts/7556888261).
- Selected-history rerip: commit `fc30aefc` passed
  [run 27329758516](https://github.com/pantelb/ripme/actions/runs/27329758516):
  [Android](https://github.com/pantelb/ripme/actions/runs/27329758516/artifacts/7557141177),
  [Windows](https://github.com/pantelb/ripme/actions/runs/27329758516/artifacts/7557106373),
  [macOS](https://github.com/pantelb/ripme/actions/runs/27329758516/artifacts/7557076825),
  [Linux](https://github.com/pantelb/ripme/actions/runs/27329758516/artifacts/7557073975).
- CLI release check: commit `3adb2fed` passed
  [run 27330134771](https://github.com/pantelb/ripme/actions/runs/27330134771):
  [Android](https://github.com/pantelb/ripme/actions/runs/27330134771/artifacts/7557290787),
  [Windows](https://github.com/pantelb/ripme/actions/runs/27330134771/artifacts/7557255728),
  [macOS](https://github.com/pantelb/ripme/actions/runs/27330134771/artifacts/7557247426),
  [Linux](https://github.com/pantelb/ripme/actions/runs/27330134771/artifacts/7557219103).
- CLI configuration options: commit `ec5f63f5` passed
  [run 27326985119](https://github.com/pantelb/ripme/actions/runs/27326985119):
  [Android](https://github.com/pantelb/ripme/actions/runs/27326985119/artifacts/7556054692),
  [Windows](https://github.com/pantelb/ripme/actions/runs/27326985119/artifacts/7556032207),
  [macOS](https://github.com/pantelb/ripme/actions/runs/27326985119/artifacts/7556016565),
  [Linux](https://github.com/pantelb/ripme/actions/runs/27326985119/artifacts/7555990604).
- No-properties-file no-op: commit `b48d1ecb` passed
  [run 27327236737](https://github.com/pantelb/ripme/actions/runs/27327236737):
  [Android](https://github.com/pantelb/ripme/actions/runs/27327236737/artifacts/7556151184),
  [Windows](https://github.com/pantelb/ripme/actions/runs/27327236737/artifacts/7556121715),
  [macOS](https://github.com/pantelb/ripme/actions/runs/27327236737/artifacts/7556123396),
  [Linux](https://github.com/pantelb/ripme/actions/runs/27327236737/artifacts/7556094979).
- Proxy parsing: commit `dc22a35e` passed
  [run 27327529896](https://github.com/pantelb/ripme/actions/runs/27327529896):
  [Android](https://github.com/pantelb/ripme/actions/runs/27327529896/artifacts/7556266104),
  [Windows](https://github.com/pantelb/ripme/actions/runs/27327529896/artifacts/7556235535),
  [macOS](https://github.com/pantelb/ripme/actions/runs/27327529896/artifacts/7556238218),
  [Linux](https://github.com/pantelb/ripme/actions/runs/27327529896/artifacts/7556207391).
- Append-to-folder: commit `0526fef1` passed
  [run 27328024609](https://github.com/pantelb/ripme/actions/runs/27328024609):
  [Android](https://github.com/pantelb/ripme/actions/runs/27328024609/artifacts/7556442668),
  [Windows](https://github.com/pantelb/ripme/actions/runs/27328024609/artifacts/7556409595),
  [macOS](https://github.com/pantelb/ripme/actions/runs/27328024609/artifacts/7556395878),
  [Linux](https://github.com/pantelb/ripme/actions/runs/27328024609/artifacts/7556389359).

Required tests:

- [x] CLI parser unit tests for every option.
- [x] Config side-effect tests for options that mutate settings.
- [x] URL-file parsing tests.
  - Added exact comment, trimming, invalid-line, failure-continuation, and
    sequential callback coverage in `test/cli_controller_test.dart`.
- [x] Headless single-URL smoke test using a fake ripper resolver.
  - Completed: `test/cli_controller_test.dart` injects an offline URL rip
    callback and verifies both short and long option forms.
- [x] History re-rip tests.

### Workstream 2: Main Window Input And Queue

Java source:

- `src/main/java/com/rarchives/ripme/ui/MainWindow.java`
- `src/main/java/com/rarchives/ripme/ui/QueueMenuMouseListener.java`

Flutter targets:

- `lib/main.dart`
- `lib/rip_manager.dart`

Parity checklist:

- [x] Manual URL submission rejects duplicate queue entries like Java.
  - Completed: `RipManager.addUrlToQueue` rejects an exact string only when it
    is already present in the pending queue and reports Java's duplicate URL
    status. Current/history URLs and ripper-emitted child URLs remain outside
    this manual pending-queue check.
  - CI: commit `df040d0b` passed
    [run 27330528640](https://github.com/pantelb/ripme/actions/runs/27330528640):
    [Android](https://github.com/pantelb/ripme/actions/runs/27330528640/artifacts/7557427635),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27330528640/artifacts/7557408578),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27330528640/artifacts/7557392341),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27330528640/artifacts/7557380394).
- [x] Manual URL submission expands `{start-end}` numeric ranges like Java.
  - Completed: the first numeric range defines an inclusive loop and every
    brace group is replaced with the current number, preserving Java's unusual
    same-value substitution when a URL contains multiple brace groups.
- [x] Invalid range syntax reports an error without queueing garbage.
  - Completed: missing/unbalanced braces, non-numeric bounds, and descending
    ranges produce an `Invalid URL range` status before any URL is queued.
  - CI: commit `9b1dfd79` passed
    [run 27331147207](https://github.com/pantelb/ripme/actions/runs/27331147207):
    [Android](https://github.com/pantelb/ripme/actions/runs/27331147207/artifacts/7557693313),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27331147207/artifacts/7557654881),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27331147207/artifacts/7557652736),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27331147207/artifacts/7557626682).
- [x] URL text-field validation detects ripper host and unrippable URLs.
  - Completed: live field changes trim input, prepend `http://` when the text
    does not start with Java's case-sensitive `http` prefix, resolve a ripper,
    and display `<host> album detected`. Invalid or unsupported URLs display
    `Can't rip this URL: <reason>` without changing queue state.
  - CI: commit `ce06595c` passed
    [run 27339640361](https://github.com/pantelb/ripme/actions/runs/27339640361):
    [Android](https://github.com/pantelb/ripme/actions/runs/27339640361/artifacts/7561356122),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27339640361/artifacts/7561303045),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27339640361/artifacts/7561365279),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27339640361/artifacts/7561268197).
- [x] Queue count is visible and updates like Java's `queue(n)` label.
  - Completed: the Queue tab displays the localized base label when no items
    are pending and appends `(n)` with no separator when pending items exist.
    The count follows the queue after enqueue, current-rip removal, manual
    removal, and clear operations.
  - CI: commit `6003d563` passed
    [run 27340488328](https://github.com/pantelb/ripme/actions/runs/27340488328):
    [Android](https://github.com/pantelb/ripme/actions/runs/27340488328/artifacts/7561671564),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27340488328/artifacts/7561642147),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27340488328/artifacts/7561616181),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27340488328/artifacts/7561600170).
- [x] Queue is saved to config after updates.
  - Completed: ordered pending entries are saved under Java's `queue` key
    after additions, active-item removal, reordering, manual removal, and
    ripper-emitted child additions.
  - Java discrepancy: `MainWindow.updateQueue` only writes non-empty models.
    Clearing or removing the last pending entry therefore leaves the previous
    persisted value until `ripNextAlbum` runs with an empty queue. Flutter
    preserves this behavior and covers it with a regression test.
- [x] Queue is restored from config at startup.
  - Completed: `RipManager.init` restores the ordered `queue` list without
    starting a rip, matching Java loading entries before its list listener is
    attached.
  - CI: commit `78399dde` passed
    [run 27340948343](https://github.com/pantelb/ripme/actions/runs/27340948343):
    [Android](https://github.com/pantelb/ripme/actions/runs/27340948343/artifacts/7561890928),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27340948343/artifacts/7561843809),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27340948343/artifacts/7561837699),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27340948343/artifacts/7561803682).
- [x] Queue clear/remove behavior matches Java context-menu actions.
  - Completed: per-entry removal immediately removes the selected pending URL,
    and clear-all requires confirmation with Java's localized
    `queue.validation` prompt before mutating the queue.
  - CI: commit `83f70f7e` passed
    [run 27341625795](https://github.com/pantelb/ripme/actions/runs/27341625795):
    [Android](https://github.com/pantelb/ripme/actions/runs/27341625795/artifacts/7562164251),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27341625795/artifacts/7562127290),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27341625795/artifacts/7562108748),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27341625795/artifacts/7562087339).
- [x] Stop interrupts current rip and leaves remaining queue behavior documented.
  - Completed: stop signals only the active ripper, resets active progress,
    reports Java's `Download interrupted` status/log entry, and leaves all
    pending URLs in order. The stopped run cannot advance the queue from its
    completion path. As in Java, adding another URL while idle resumes from the
    oldest pending entry.
  - CI: commit `36249312` passed
    [run 27342057234](https://github.com/pantelb/ripme/actions/runs/27342057234):
    [Android](https://github.com/pantelb/ripme/actions/runs/27342057234/artifacts/7562343382),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27342057234/artifacts/7562342297),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27342057234/artifacts/7562292069),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27342057234/artifacts/7562262915).

Required tests:

- [x] Unit tests for queue duplicate/range parsing.
- [x] `RipManager` tests for queue persistence/restoration.
- [x] Widget tests for URL validation/status display.

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

- [x] Preserve Java history fields: URL, directory, title, created/modified
      dates, and selected state where applicable.
  - Completed: `HistoryEntry` retains URL, directory, title, count, start date,
    modified date, and selected state. New rip completions populate all fields;
    repeat rips retain the original row/start date and update count plus
    modified date like Java.
  - Flutter derives completion count from per-run resource events because its
    current rip-complete event carries only the directory, unlike Java's
    `RipStatusComplete(dir, count)`. Rips without resource events retain
    Java's default count of one.
  - CI: commit `683abd02` passed
    [run 27342560448](https://github.com/pantelb/ripme/actions/runs/27342560448):
    [Android](https://github.com/pantelb/ripme/actions/runs/27342560448/artifacts/7562545410),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27342560448/artifacts/7562513096),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27342560448/artifacts/7562505367),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27342560448/artifacts/7562465605).
- [x] Preserve Java table columns and display semantics: URL, created date,
      modified date, count, and selected checkbox.
  - Completed: the history view exposes Java's five data columns in order,
    formats both dates as `yyyy/MM/dd`, displays count numerically, and binds
    the final checkbox to persisted selected state. Existing folder-open and
    row action controls remain available in an additional action column.
  - CI: commit `dbe66468` passed
    [run 27343169058](https://github.com/pantelb/ripme/actions/runs/27343169058):
    [Android](https://github.com/pantelb/ripme/actions/runs/27343169058/artifacts/7562798341),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27343169058/artifacts/7562792859),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27343169058/artifacts/7562736478),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27343169058/artifacts/7562726722).
- [x] Preserve Java history JSON timestamp semantics: `startDate` and
      `modifiedDate` are epoch milliseconds.
  - Completed: import treats numeric values as milliseconds since the Unix
    epoch and export writes both fields as integer epoch milliseconds, with
    exact non-second-aligned values covered by tests.
  - CI: commit `d1a64aea` passed
    [run 27343485825](https://github.com/pantelb/ripme/actions/runs/27343485825):
    [Android](https://github.com/pantelb/ripme/actions/runs/27343485825/artifacts/7562914852),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27343485825/artifacts/7562884299),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27343485825/artifacts/7562893046),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27343485825/artifacts/7562847726).
- [x] Preserve Java `toJSON()` quirk: `dir` is read from imported JSON but not
      written by Java, or document a deliberate Flutter format extension.
  - Deliberate extension: Flutter exports Java's six written fields and also
    writes `dir` so folder-open behavior survives export/import, plus the
    legacy Flutter ISO `date` field for backward compatibility. Java accepts
    `dir` on import and ignores the extra `date` key, so the extended export
    remains Java-readable while avoiding Java's directory data loss.
  - CI: commit `d3c8fdab` passed
    [run 27345948995](https://github.com/pantelb/ripme/actions/runs/27345948995):
    [Android](https://github.com/pantelb/ripme/actions/runs/27345948995/artifacts/7563976679),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27345948995/artifacts/7563918014),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27345948995/artifacts/7563922907),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27345948995/artifacts/7563882741).
- [x] Import Java `history.json` without data loss.
  - Completed: strict external import requires Java's object array shape and
    mandatory string `url` plus numeric `startDate`/`modifiedDate`, preserves
    every optional Java field including imported `dir`, and rejects malformed
    entries instead of silently filtering/defaulting them.
  - Internal preference loading remains tolerant only for pre-migration
    Flutter records that used `date` without Java's two mandatory timestamps.
  - CI: commit `59a231f1` passed
    [run 27346555325](https://github.com/pantelb/ripme/actions/runs/27346555325):
    [Android](https://github.com/pantelb/ripme/actions/runs/27346555325/artifacts/7564246369),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27346555325/artifacts/7564201769),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27346555325/artifacts/7564184387),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27346555325/artifacts/7564157791).
- [x] Export history in a documented format.
  - Completed: the UI writes `history.json` as a UTF-8, two-space-indented JSON
    array matching Java's file name and pretty-print structure. Entries contain
    Java's written fields plus the documented Flutter `dir` and legacy `date`
    extensions described above.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27347041762/artifacts/7564436319),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27347041762/artifacts/7564390585),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27347041762/artifacts/7564376857),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27347041762/artifacts/7564349235).
- [x] Support remove, clear, open folder, copy URL, and re-rip actions.
  - Completed: each history row exposes folder-open from its URL cell plus copy
    URL, re-rip, and remove actions. Clear removes both album history and the
    distinct downloaded-URL history like Java, and honors
    `history.warn_before_delete` with Java's literal confirmation controls.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27348354800/artifacts/7565027633),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27348354800/artifacts/7564982994),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27348354800/artifacts/7564959396),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27348354800/artifacts/7564922827).
- [x] Support selected-entry re-rip or document why selected state is removed.
  - Completed: `Re-rip Checked` queues every selected history URL in table
    order, including duplicate URLs like Java's direct queue-model additions.
    Empty history and history with no checked rows produce Java's distinct
    localized messages in a `RipMe Error` dialog.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27348862852/artifacts/7565263191),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27348862852/artifacts/7565229602),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27348862852/artifacts/7565210118),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27348862852/artifacts/7565156681).
- [x] Support Java fallback history guessing from existing rip directories or
      document why Flutter does not.
  - Completed: Flutter ports `RipUtils.urlFromDirectoryName(...)` mapping order
    and invokes it only when album history is absent and legacy
    `download.history` is empty. Explicit working directories pass each full
    directory path like Java, preserving the shipped limitation that normal
    absolute paths do not match bare prefixes; Flutter skips the equivalent
    no-op scan for its default absolute documents path. Reddit's unreachable
    switch and the Imgur fixed-list failure are preserved as non-candidates;
    malformed names are ignored instead of aborting Flutter startup.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27351233433/artifacts/7566332445),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27351233433/artifacts/7566290613),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27351233433/artifacts/7566235400),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27351233433/artifacts/7566210134).
- [x] Support configurable history location or document replacement behavior.
  - Completed: `history.location` redirects only runtime downloaded-URL checks,
    appends, and clearing to the configured file. Java's separator-free append
    bug is covered explicitly. Without a configured path, Flutter deliberately
    retains downloaded URLs in SharedPreferences instead of Java's config-dir
    `url_history.txt`.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27351781506/artifacts/7566547823),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27351781506/artifacts/7566546505),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27351781506/artifacts/7566482793),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27351781506/artifacts/7566437236).
- [x] Keep downloaded-URL history behavior distinct from album history.
  - Completed: album metadata remains in `HistoryProvider` under `rip_history`;
    configured downloaded-URL files are owned by `DownloadHistoryProvider`.
    Clearing either provider alone leaves the other store intact, while the
    Java-compatible UI clear action intentionally clears both.

Required tests:

- [x] Java history fixture import tests.
- [x] History selected-state tests.
- [x] Re-rip queueing tests.
- [x] Configured history location tests if supported.

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

- [x] Reconcile every key in Java `rip.properties` with Flutter defaults.
  - Completed: all 15 active Java resource defaults match Flutter by key, type,
    and value. A checked-in source fixture and parser-based test fail when a
    Java default is missing or diverges.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27352278102/artifacts/7566755427),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27352278102/artifacts/7566696376),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27352278102/artifacts/7566684492),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27352278102/artifacts/7566650198).
- [x] Reconcile every Java config key used anywhere in `src/main/java`, not
      only keys present in `rip.properties`.
  - Completed: Flutter now carries an explicit inventory of every literal Java
    runtime key plus dynamic `cookies.<domain>`. A source-derived fixture test
    enforces exact inventory equality; behavioral support remains tracked by
    the following control and hidden-key checklist items.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27352807572/artifacts/7566977046),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27352807572/artifacts/7566914395),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27352807572/artifacts/7566913351),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27352807572/artifacts/7566857039).
- [~] Reconcile every Java configuration control with Flutter UI.
  - In progress: Flutter now exposes Java's `prefer.mp4` and
    `history.warn_before_delete` controls with immediate persistence and widget
    coverage. Java's visible `descriptions.save` checkbox is intentionally
    retired: source inspection found no reachable description support because
    the only ripper overriding the hooks, `FuraffinityRipper`, returns `false`
    from `hasDescriptionSupport()`. Java's `auto.update` checkbox is also
    explicitly disabled in favor of the actionable GitHub release checker.
    Remaining Java controls are tracked below.
  - CI artifacts for the media/history controls:
    [Android](https://github.com/pantelb/ripme/actions/runs/27357472965/artifacts/7568924806),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27357472965/artifacts/7568877198),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27357472965/artifacts/7568861014),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27357472965/artifacts/7568820741).
- [x] Reconcile hidden/runtime-only keys not exposed in UI.
  - Completed: `ConfigParity` partitions all 71 source-derived Java keys
    between separately tracked controls and exhaustive hidden-key
    dispositions. Hidden keys are classified as active, migration aliases,
    Java sentinel-only keys, intentional retirements, or explicitly
    unsupported behavior, and tests require exact, disjoint inventory coverage.
  - Source-backed exceptions: `download.max_size` and `gw.api` are only old
    config validity sentinels in current Java; `error.skip404` is retained as a
    migration alias for active `errors.skip404`; SOCKS remains explicitly
    rejected; Java jar-updater-only hash/testing keys are retired.
  - DeviantArt's custom credentials and Java-serialized cookie map are retired.
    All six Java DeviantArt tests are disabled as `Broken ripper`, and importing
    Java object serialization into Flutter would create an unsafe,
    platform-specific persistence format. Public DeviantArt ripping retains the
    Java age-gate cookie; authenticated/private gallery parity remains a
    documented limitation rather than a silent claim.
- [x] Support Java portable config mode when `rip.properties` exists next to the
      app, or document a Flutter-native replacement.
  - Completed: desktop startup detects `rip.properties` beside the resolved
    executable and uses it as the authoritative typed configuration backend,
    ahead of SharedPreferences and bundled defaults. String, integer, boolean,
    comma-list, and queue-list reads are supported; all setting writes update
    the portable file immediately. Android skips executable-adjacent detection
    because packaged APK contents are not a writable portable-app directory.
    Tests cover precedence, Java property escaping, typed/list values,
    immediate persistence, and executable-relative path resolution.
- [x] Support Java platform config directories:
      Windows `%LOCALAPPDATA%/ripme`, macOS `~/Library/Application Support/ripme`,
      Unix `~/.config/ripme`, or document replacement behavior.
  - Completed by documented Flutter-native replacement: outside portable mode,
    settings, rip history, and downloaded-URL history use the
    `shared_preferences` platform backend instead of creating Java's
    `rip.properties`, `history.json`, and `url_history.txt` directory tree.
    This maps configuration to each platform's native preference store and
    extends the same behavior to Android. Portable desktop mode remains the
    explicit file-backed exception. A persistence test verifies that
    non-portable writes are committed to the preference backend and survive
    utility reinitialization.
- [x] Reconcile Java default rip directory (`<jar directory>/rips`) with
      Flutter's current app-documents default.
  - Completed: desktop defaults now resolve to `rips` beside the executable,
    matching Java's application-directory behavior. Both configured and
    default paths use Java's leaf-directory creation behavior and fall back to
    the user home directory when creation fails. Android intentionally retains
    its writable external-storage/application-documents base because packaged
    application binaries are not a writable download location. Tests cover
    Windows and POSIX path resolution, creation, configured paths, failure
    fallback, and the Android replacement.
- [x] Reconcile Java old-config deletion/reload behavior when required keys are
      missing.
  - Completed: external desktop `rip.properties` files are accepted only when
    they contain Java's seven exact sentinel keys: `twitter.auth`,
    `twitter.max_requests`, `tumblr.auth`, `error.skip404`, `gw.api`,
    `page.timeout`, and `download.max_size`. An obsolete file missing any
    sentinel is deleted and configuration falls back to platform preferences
    plus bundled Java defaults. Flutter's non-portable preference backend is
    intentionally sparse and resolves missing keys individually, so it does
    not require destructive whole-file migration. Tests remove each sentinel
    independently and verify deletion/default reload behavior.
- [x] Persist settings on exit or immediately in a documented Flutter-native way.
  - Completed by Flutter-native immediate persistence. Java mutates an
    in-memory `PropertiesConfiguration` and calls `saveConfig()` during window
    shutdown; Flutter's string, integer, boolean, and list setters instead await
    each write to either the platform preference backend or portable
    `rip.properties`. UI and CLI setting changes await those setters, avoiding
    dependence on a desktop-only exit callback and providing the same behavior
    on Android. Tests verify every setter type is visible in the backend as
    soon as its future completes and that values survive reinitialization.
- [x] Support language selection and reload behavior.
  - Completed: the configuration view exposes every Java bundle language tag,
    persists `lang`, translates Java's legacy `in-ID`/`kr-KR` tags to Flutter
    locale codes, and immediately rebuilds the localized UI.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27358136986/artifacts/7569217681),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27358136986/artifacts/7569156958),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27358136986/artifacts/7569155864),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27358136986/artifacts/7569106595).
- [x] Support Java save directory selection on desktop and define the Android
      storage replacement.
  - Completed: the Files configuration section uses the platform directory
    picker, persists the exact selected path as Java's `rips.directory`, updates
    the displayed path immediately, and leaves the existing value unchanged on
    cancellation on Windows, Linux, and macOS. Android instead uses its
    app-specific external `rips` directory with application documents fallback
    and does not request legacy, media-read, or all-files permissions. Audit
    correction: `file_picker 11.0.2` opens `ACTION_OPEN_DOCUMENT_TREE` but
    converts the tree URI to a raw path without persisting a URI grant; that
    path cannot provide reliable Dart `File` access under scoped storage.
    Android arbitrary-directory selection is therefore disabled rather than
    falsely represented as Java-equivalent. Widget tests cover desktop
    selection/cancellation and the Android-disabled replacement.
- [x] Support window position persistence or explicitly mark not applicable.
  - Completed with Java platform semantics: Linux and macOS restore valid
    `window.x`, `window.y`, `window.w`, and `window.h` bounds when
    `window.position` is enabled, center on disabled/invalid geometry, and save
    integer bounds before controlled window destruction. Java explicitly
    disables positioning on Windows because of its `javaw.exe` shutdown bug;
    Flutter preserves that source behavior by centering and not writing bounds.
    Android has no desktop window and is a no-op. Native close and tray Exit
    share the save-before-destroy path, and the desktop configuration UI exposes
    the Java toggle. Unit tests cover restore, centering, save/truncation,
    Windows exclusion, and Android no-op behavior.
- [x] Support log level, log save, popup, sound, URLs-only, album-title folders,
      descriptions, prefer MP4, SSL verification, URL history, retries, timeout,
      retry sleep, thread count, overwrite, and save order.
  - Completed: every reachable Java control is exposed and persists
    immediately. Java's exact log-level values configure global diagnostic
    filtering, and `log.save` writes `ripme.log` with 20 MB rolling
    `ripme.1.log.gz`/`ripme.2.log.gz` archives. Desktop logs use Java's current
    working directory; Android uses application documents because its process
    working directory is not a writable user location. Rip status messages are
    mirrored into the diagnostic logger, and focused tests cover level parsing,
    filtering, file output, rollover, and UI persistence.
  - Popup: the App settings persist Java's
    `download.show_popup` false-by-default preference and desktop rip starts
    use it to gate native notifications.
  - SSL: `ssl.verify.off` has Java's false default, persists
    immediately from the network configuration UI, and controls
    `HttpClient.badCertificateCallback` for the shared page/download client.
  - Intentional retirement: Java exposes `descriptions.save`, but the only
    description-hook override is `FuraffinityRipper`, whose
    `hasDescriptionSupport()` returns false. The source behavior is unreachable,
    so Flutter does not expose an ineffective setting.
  - CI artifacts for SSL verification:
    [Android](https://github.com/pantelb/ripme/actions/runs/27359734247/artifacts/7569889411),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27359734247/artifacts/7569824709),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27359734247/artifacts/7569814295),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27359734247/artifacts/7569775867).
- [x] Support or intentionally retire finish commands:
      `enable.finish.command` and `finish.command`.
  - Completed: after `RIP_COMPLETE`, Flutter substitutes every `%url%` and
    `%path%` occurrence, splits the configured command on literal single
    spaces like Java, runs it without a shell, captures output/errors, and
    waits for it before advancing to the next queued album. The command is
    disabled by default and defaults to `ls`, matching Java call-site defaults.
    Process execution is injected in tests so substitution, tokenization,
    output reporting, and queue ordering are deterministic.
- [x] Support or intentionally retire history deletion warning:
      `history.warn_before_delete`.
  - Completed: the setting defaults to true and is exposed in Configuration.
    Clearing all history uses Java's exact `Are you sure?`, `YES`, and `NO`
    confirmation text when enabled; disabling it clears immediately. Both paths
    clear album history and downloaded-URL history together like Java. Widget
    tests cover cancellation, confirmation, and the disabled-warning path.
- [x] Support or intentionally retire Java auto-update preference:
      `auto.update`.
  - Completed: Flutter does not self-replace application binaries. The
    configuration UI displays a disabled replacement notice and retains an
    actionable GitHub latest-release check; widget and update-checker tests
    cover both surfaces.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27358697881/artifacts/7569453251),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27358697881/artifacts/7569402980),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27358697881/artifacts/7569406272),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27358697881/artifacts/7569355209).
- [x] Support or intentionally retire window geometry keys:
      `window.position`, `window.x`, `window.y`, `window.w`, `window.h`.
  - Completed by the window-position item above: Linux and macOS restore and
    save Java integer bounds, invalid/disabled geometry centers the window,
    Windows preserves Java's explicit positioning exclusion, and Android is a
    no-op. `desktop_window_geometry_test.dart` covers every platform branch.

Required tests:

- [x] Defaults reconciliation test against Java `rip.properties`.
- [x] Config UI widget tests for every exposed setting.
  - Completed: every generic boolean, integer, and string control has a stable
    `config.<java-key>` widget key and is edited by the table-driven
    `configuration_controls_widget_test.dart`. Focused widget tests cover the
    save-directory picker, language reload, log-level dropdown, SSL toggle,
    history warning branches, and disabled auto-update replacement.
- [x] Persistence tests for settings changed in UI and CLI.
  - Completed: the table-driven configuration widget test reinitializes
    `Utils` after editing every generic control and verifies all values survive.
    `cli_controller_test.dart` applies Java CLI setting options through the real
    backend, reinitializes it, and verifies integer, boolean, and path settings.

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

- [x] Verify user-agent parity.
  - Verified: shared Flutter requests send the exact
    `AbstractRipper.USER_AGENT` string from Java, with request-level regression
    coverage.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27361556812/artifacts/7570602832),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27361556812/artifacts/7570587008),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27361556812/artifacts/7570526632),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27361556812/artifacts/7570488852).
- [x] Verify retry count and retry sleep behavior.
  - Completed for shared page/download HTTP requests: the configured retry
    value is the total attempt count and, matching Java `Http.response()`,
    positive `download.retry.sleep` is applied after every failed attempt,
    including the final failure.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27361077711/artifacts/7570398801),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27361077711/artifacts/7570351152),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27361077711/artifacts/7570330134),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27361077711/artifacts/7570309660).
- [x] Verify timeout behavior for pages and downloads.
  - Completed: page requests enforce `page.timeout`; file downloads enforce
    `download.timeout` for the full request and do not create a destination
    file after a timeout.
  - Intentional Flutter behavior: settings remain live per request so the
    immediate-persistence UI takes effect without an app restart, rather than
    freezing Java's `Http.TIMEOUT` when the class first loads.
  - Intentional Java bug fix: a timed-out file remains failed. Flutter does not
    reproduce `DownloadFileThread` falling through to `downloadCompleted`
    after catching `SocketTimeoutException`.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27364533194/artifacts/7571809225),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27364533194/artifacts/7571764591),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27364533194/artifacts/7571750926),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27364533194/artifacts/7571717528).
- [x] Verify skip-404 config key spelling and semantics against Java.
  - Completed: shared Java-style page requests terminate immediately on 404
    regardless of configuration. Source verification corrected the earlier
    audit assumption for files: `DownloadFileThread` returns from its general
    4xx branch before the later `HttpStatusException`/`errors.skip404` check,
    making that config branch unreachable for a normal 404 response. Both
    plural and singular keys are therefore inactive for shared downloads.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27362122787/artifacts/7570838538),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27362122787/artifacts/7570798660),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27362122787/artifacts/7570757479),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27362122787/artifacts/7570736941).
- [x] Verify max download size behavior.
  - Completed: `download.max_size` remains available for Java old-config
    validation compatibility but is intentionally not exposed or enforced,
    matching `DownloadFileThread`.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27362570203/artifacts/7571021966),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27362570203/artifacts/7570979490),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27362570203/artifacts/7570973388),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27362570203/artifacts/7570922222).
- [x] Verify configured domain cookies.
- [x] Verify Java configured-cookie lookup and parsing exactly: `cookies.<host>`
      lookup checks parent domains and parses semicolon-delimited key/value
      pairs through `RipUtils.getCookiesFromString`.
  - Completed: Flutter now selects the first non-empty exact/parent-domain
    property and preserves Java parser behavior for whitespace, extra equals
    signs, duplicate keys, trailing delimiters, and malformed pairs.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27363039987/artifacts/7571199444),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27363039987/artifacts/7571181430),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27363039987/artifacts/7571154696),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27363039987/artifacts/7571104243).
- [x] Verify per-download cookies and referer headers.
  - Completed: file requests preserve explicit referer/cookie maps, send Java's
    `Accept: */*` and empty-cookie defaults, and do not inject page-only
    configured-domain cookies.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27363447019/artifacts/7571378376),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27363447019/artifacts/7571376642),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27363447019/artifacts/7571310397),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27363447019/artifacts/7571299951).
- [x] Verify Java CLI/config proxy strings `[user:password]@host[:port]` through
      `proxy.http` and `proxy.socks`, including authenticated proxy behavior.
  - Completed: persisted `proxy.http` now has Java startup precedence over
    `proxy.socks` and Flutter UI fields, routes every shared page/download
    client, and installs optional basic credentials.
  - SOCKS strings use the same parser but fail explicitly because `dart:io`
    exposes no SOCKS proxy transport API.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27365151437/artifacts/7572067553),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27365151437/artifacts/7572018895),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27365151437/artifacts/7571992043),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27365151437/artifacts/7571966442).
- [x] Verify HTTP proxy host/port/auth.
- [x] Port SOCKS proxy support or explicitly mark not applicable.
  - Decision: not applicable to the current `dart:io` backend. Both CLI and
    persisted `proxy.socks` settings report an unsupported error rather than
    silently bypassing the requested proxy.
- [x] Verify SSL verification toggle behavior.
- [x] Verify Java SSL verification toggle actually disables/enables certificate
      and hostname verification for Jsoup calls.
  - Completed: `ssl.verify.off=false` leaves Dart's default certificate and
    hostname validation intact; `true` accepts bad-certificate callbacks,
    including hostname mismatch failures, for every shared page/download
    client. The setting and network UI are covered by unit/widget tests.
  - CI artifacts are recorded under the configuration-control checklist.
  - Audit reconciliation CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27365231955/artifacts/7572130733),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27365231955/artifacts/7572043580),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27365231955/artifacts/7572034108),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27365231955/artifacts/7572014113).
- [x] Verify content-type-tolerant JSON/HTML parsing.
  - Completed: shared JSON decoding and HTML parsing consume response bodies
    independently of the server's `Content-Type`, matching Java callers that
    opt into Jsoup `ignoreContentType()`. A local-server test returns both JSON
    and HTML as `text/plain`.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27365330404/artifacts/7572166281),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27365330404/artifacts/7572138221),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27365330404/artifacts/7572113807),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27365330404/artifacts/7572054717).
- [x] Verify Java `Http` chainable request APIs: `ignoreContentType`,
      `referrer`, `userAgent`, `header`, `cookies`, `data`, `method`, `post`,
      `getJSON`, and `getJSONArray`.
  - Completed: `Http.url(...)` now returns a Java-style request builder backed
    by the shared retry/timeout/proxy/SSL implementation. Tests cover chained
    request metadata, URL-encoded form POSTs, method override, per-request
    retries/timeouts, JSON objects, and JSON arrays.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27365791359/artifacts/7572350291),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27365791359/artifacts/7572307450),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27365791359/artifacts/7572285003),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27365791359/artifacts/7572248858).
- [x] Verify Java HTTP error messages: 401/403 cookie guidance, 404 file-not-found
      handling, and non-retriable/retriable status text.
  - Completed: shared page requests stop immediately with Java-compatible
    401/403 cookie guidance and 404 file-not-found messages. File downloads
    stop on 4xx with `Non-retriable status code ... while downloading ...`;
    5xx failures retain Java's `Retriable status code` text across retries.
  - CI artifacts for page errors:
    [Android](https://github.com/pantelb/ripme/actions/runs/27363974753/artifacts/7571591390),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27363974753/artifacts/7571559785),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27363974753/artifacts/7571508412),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27363974753/artifacts/7571496843).
  - CI artifacts for file status semantics:
    [Android](https://github.com/pantelb/ripme/actions/runs/27366309518/artifacts/7572584769),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27366309518/artifacts/7572521141),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27366309518/artifacts/7572531151),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27366309518/artifacts/7572479438).
- [x] Verify Java retry attempt counts. Page requests use exactly the configured
      number of total attempts, including Java's zero-attempt edge case. File
      downloads use one initial attempt plus `download.retries`, matching
      `DownloadFileThread`'s `tries > retries` boundary.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27360595539/artifacts/7570234747),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27360595539/artifacts/7570201084),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27360595539/artifacts/7570177253),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27360595539/artifacts/7570136070).
- [x] Verify rate-limit `Retry-After` handling.
  - Completed: Java does not inspect `Retry-After`. Flutter now ignores both
    delta-seconds and date forms and applies only `download.retry.sleep`.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27366748617/artifacts/7572784535),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27366748617/artifacts/7572735105),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27366748617/artifacts/7572688694),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27366748617/artifacts/7572662798).

Required tests:

- [x] HTTP unit tests for each checklist item.
  - Completed in `http_utils_test.dart`: user agent, request/file attempt counts,
    retry sleep, timeouts, inactive max size, interruption, headers/cookies,
    proxy/SSL behavior, content-type tolerance, request-builder APIs, Java
    status messages, zero attempts, and ignored `Retry-After` are all covered.
- [x] Proxy parsing tests for Java CLI strings.
  - Completed in `proxy_config_test.dart`: host-only, optional port,
    authenticated forms, last-`@` behavior, shared HTTP/SOCKS parsing, and
    malformed credentials/ports are covered.
- [x] Cookie precedence tests.
  - Completed in `http_utils_test.dart`: exact hosts win over parent domains,
    empty exact values fall back to parents, parser edge cases match Java,
    malformed pairs fail, and configured page cookies are not injected into
    Java-style download defaults.

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

- [x] Verify working directory naming and sanitization.
- [x] Verify Java `Utils.filesystemSafe`: remove characters outside
      `[a-zA-Z0-9-.,_ ]`, trim, and truncate names longer than 100 characters
      to 99.
- [x] Verify Java `Utils.filesystemSanitized`: replace characters outside
      `[a-zA-Z0-9.-]` with `_`.
- [x] Verify Java `Utils.sanitizeSaveAs`: replace `\\:*?"<>|` with `_` and
      preserve the Java filename-extension edge cases from `AbstractRipperTest`.
  - Completed: punctuation replacement matches Java `UtilsTest`, and
    `AbstractRipper.getFileName(...)` preserves the shipped `split(".")`
    regex behavior: URL extensions are not re-appended, while explicit
    extensions are.
  - CI: workflow `27384535469` succeeded. Artifacts: Android `7579670551`,
    Windows `7579663669`, macOS `7579637580`, Linux `7579623705`.
- [x] Verify Java case-preserving existing directory behavior from
      `Utils.getOriginalDirectory`.
  - Completed: shared working-directory setup applies exact Java sanitization
    and 99-character truncation, then reuses an existing case-insensitive name
    with its on-disk case on non-Windows platforms.
  - CI: workflow `27384277001` succeeded. Artifacts: Android `7579597902`,
    Windows `7579591011`, macOS `7579572130`, Linux `7579546510`.
- [x] Verify Java Windows path shortening behavior from `shortenSaveAsWindows`.
  - Completed: Flutter ports Java's path-length arithmetic and extension
    preservation, rejects a 260-character parent path, and applies shortening
    to shared Windows downloads whose absolute destination exceeds 259
    characters.
  - CI: workflow `27384794460` succeeded. Artifacts: Android `7579758072`,
    Windows `7579761782`, macOS `7579737660`, Linux `7579708950`.
- [x] Port or document `append-to-folder`.
  - Completed: Flutter retains Java's exact, untrimmed CLI suffix and resolves
    files beneath the working directory into the sibling
    `<workingDirName><suffix>` before preserving their relative subdirectory
    and filename. CLI parsing and shared path shaping have focused tests.
  - CI: workflow `27384846082` succeeded. Artifacts: Android `7579779942`,
    Windows `7579753290`, macOS `7579745619`, Linux `7579732614`.
- [x] Verify `album_titles.save` behavior.
  - Completed: Flutter matches Java's class-specific behavior. JSON and legacy
    album-style rippers fall back to `<host>_<gid>` when disabled, while HTML
    rippers continue using their concrete album title. Direct Flutter ports of
    Java JSON rippers (`InstagramRipper` and `ScrolllerRipper`) explicitly opt
    into the JSON behavior.
  - CI: workflow `27385130402` succeeded. Artifacts: Android `7579894984`,
    Windows `7579863420`, macOS `7579872892`, Linux `7579845113`.
- [x] Verify `descriptions.save` behavior.
  - Decision: intentionally retired. Java gates the shared description
    pipeline behind `hasDescriptionSupport()`, and no concrete ripper returns
    `true`; the only helper implementation, `FuraffinityRipper`, explicitly
    returns `false`. Flutter therefore matches the shipped no-output behavior
    without exposing an ineffective control.
  - CI: workflow `27385362429` succeeded. Artifacts: Android `7579971467`,
    Windows `7579935716`, macOS `7579953314`, Linux `7579909291`.
- [x] Verify URL-only output path and append behavior.
  - Completed: Flutter appends URLs with a platform line ending to the original
    `<workingDir>/urls.txt`, emits download-complete status, and skips URL
    history writes. Like Java, append-to-folder still resolves and creates the
    normal sibling/subdirectory parent as a side effect but does not relocate
    `urls.txt`. URL-only scheduling is serialized so entries retain the source
    list order instead of depending on concurrent worker start order.
  - CI: workflow `27385618025` succeeded. Artifacts: Android `7580053024`,
    Windows `7580020021`, macOS `7580002788`, Linux `7579995997`.
- [x] Verify duplicate URL suppression scope.
  - Completed: suppression remains per ripper across attempted URLs and covers
    pending, completed, and failed attempts. Imgur user mode is the only Java
    `allowDuplicates()` override; Eightmuses and Tsumino no longer mistake
    Java's `getFileExtFromMIME=true` argument for a duplicate bypass.
  - CI: workflow `27385862642` succeeded. Artifacts: Android `7580130083`,
    Windows `7580103306`, macOS `7580097992`, Linux `7580073088`.
- [x] Verify already-downloaded URL skip counter and stopping threshold.
  - Completed: only URL-history hits increment Java's cumulative counter;
    successful downloads, URL-only writes, and existing files do not reset or
    increment it. Flutter finishes the current scheduled page batch, then stops
    future work with `downloadCompleteHistory` for HTML rippers and
    `downloadComplete` for JSON/other rippers using Java's message text.
  - CI: workflow `27386357944` succeeded. Artifacts: Android `7580304774`,
    Windows `7580272544`, macOS `7580269885`, Linux `7580242670`.
- [x] Verify Java writes downloaded URL history before queueing a download and
      skips URL-history writes while `urls_only.save=true`.
  - Completed: Flutter serializes per-ripper history writes before existing-file
    checks and HTTP transfer, so failed and skipped downloads remain remembered
    like Java. URL-only mode still exits before the history write.
  - CI: workflow `27386074664` succeeded. Artifacts: Android `7580190715`,
    Windows `7580165001`, macOS `7580156080`, Linux `7580142423`.
- [x] Verify stop/interruption semantics.
  - Completed: Flutter prevents queued downloads from starting after stop and
    checks the ripper stop flag between streamed response chunks, matching
    Java's `DownloadFileThread` and `DownloadVideoThread` byte-loop checks.
    Interrupted active transfers emit `DOWNLOAD_ERRORED` with exact text
    `Download interrupted`.
  - CI: workflow `27386775040` succeeded. Artifacts: Android `7580458934`,
    Windows `7580422621`, macOS `7580404955`, Linux `7580400195`.
- [x] Verify progress percentage semantics.
  - Completed: Flutter now owns progress state in each ripper using Java's
    pending/completed/errored model, pre-registers scheduled batch items before
    workers start, truncates integer percentages like Java, and exposes the
    exact album status shape `<percent>% - Pending: <n>, Completed: <n>,
    Errored: <n>`. `RipManager` consumes the ripper percentage instead of
    reconstructing a denominator from `DOWNLOAD_STARTED` events.
  - CI: workflow `27387157948` succeeded. Artifacts: Android `7580603784`,
    Windows `7580568747`, macOS `7580568566`, Linux `7580544624`.
- [x] Verify Java byte-progress semantics for `AbstractSingleFileRipper` and
      `VideoRipper`, including human-readable text.
  - Completed: Flutter restores byte-progress inheritance for RulePorn,
    Spankbang, Xvideos, and Youporn; file downloads emit total bytes from the
    GET response followed by cumulative completed-byte events, while video
    downloads issue HEAD and emit total bytes before GET. Percentage truncation
    and `<percent>%  - <completed> / <total>` text use Java's two-decimal IEC
    formatting.
  - CI: workflow `27387539744` succeeded. Artifacts: Android `7580743930`,
    Windows `7580719693`, macOS `7580713023`, Linux `7580688212`.
- [x] Verify status text/log event text.
  - Completed: accepted events display the active ripper's Java-style status
    text before status-specific handling; `RIP_ERRORED` alone overrides it with
    `Error: <object>`. Log rendering preserves Java's `Downloading`,
    `Downloaded`, completion-history, warning, skip, and error text rules,
    while byte-only events update progress without adding log rows.
  - CI: workflow `27387796798` succeeded. Artifacts: Android `7580826027`,
    Windows `7580807897`, macOS `7580796805`, Linux `7580777754`.
- [x] Verify video download filename/referrer/cookie behavior.
  - Completed: concrete video rippers retain Java's explicit prefix-based
    filenames. Shared video transport ignores requested referrers/cookies,
    sends `Referer: <media-url>` for HEAD and GET, and omits the `Cookie`
    header, matching `VideoRipper` / `DownloadVideoThread`.
  - CI: workflow `27394170545` succeeded. Artifacts: Android `7583066315`,
    Windows `7583047323`, macOS `7583038660`, Linux `7583024709`.
- [x] Verify ignored extension behavior.
  - Completed: Flutter reads the comma-separated extension list, compares
    case-insensitively against only the final dot-delimited URL path suffix,
    ignores query/fragment text, and emits Java's exact
    `Skipping <url> - ignored extension` `DOWNLOAD_SKIP` message. Dots in
    parent path segments and extensions followed by another path segment do not
    match.
  - CI: workflow `27394484708` succeeded. Artifacts: Android `7583187368`,
    Windows `7583153637`, macOS `7583154249`, Linux `7583135268`.
- [x] Verify Java empty working-directory cleanup after a failed or empty rip.
  - Completed: GUI and CLI execution now wrap `rip()` with Java's final cleanup
    boundary. The album working directory is deleted non-recursively when its
    immediate listing is empty after either success or failure, while non-empty
    directories are preserved. Setup failures remain outside that boundary,
    matching `AbstractRipper.run()`.
  - CI: workflow `27394683535` succeeded. Artifacts: Android `7583247163`,
    Windows `7583232862`, macOS `7583221517`, Linux `7583203706`.
- [x] Verify Java gaussian jitter applied to ripper sleeps.
  - Completed: the shared ripper delay samples a normal distribution centered
    on the requested milliseconds with a 30% standard deviation, truncates to
    an integer like Java, and clamps to the same 47% minimum. Every implemented
    Dart counterpart of Java's `AbstractRipper.sleep(...)` uses the helper;
    direct Java `Thread.sleep(...)` counterparts remain unjittered. Tsumino's
    absent download sleep remains part of its separately documented missing
    object-file/download behavior.
  - CI: workflow `27395072262` failed on a timing-sensitive manual-range queue
    assertion unrelated to jitter. After stabilizing that assertion, workflow
    `27395306355` succeeded. Artifacts: Android `7583468855`, Windows
    `7583445445`, macOS `7583435982`, Linux `7583418985`.
- [x] Verify Java MIME/magic-number extension detection for
      `getFileExtFromMIME`.
  - Completed: opt-in downloads inspect the response stream before opening the
    output file, apply the JDK image signatures used by
    `URLConnection.guessContentTypeFromStream`, and fall back to RipMe's exact
    five-byte JPEG/PNG magic table. The detected extension is appended to the
    requested path and the resolved path is emitted on completion. Eightmuses
    and Tsumino now set the flag at the same call sites as Java.
  - CI: workflow `27395477474` succeeded. Artifacts: Android `7583518914`,
    Windows `7583508584`, macOS `7583501179`, Linux `7583484102`.

Required tests:

- [x] Abstract ripper directory naming tests.
- [x] Status/progress event tests.
- [x] Stop semantics tests.
  - Covered: queued work does not start after stop, an active response stream
    is interrupted, Java's `Download interrupted` status is emitted, and
    post-stop ripper events do not alter manager state.
- [x] Description support reachability audit; Java has no active runtime path
      requiring a Dart output test.
- [x] URL-only tests.

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

- [x] Verify log filtering, copying, clearing, and display order.
  - Completed: Java appends plain-text log lines chronologically to a
    non-editable `JTextPane` and moves the caret to the end; it has no dedicated
    filter, bulk-copy, or clear controls. Flutter preserves chronological
    plain-text order and intentionally extends the panel with case-insensitive
    filtering, copy-visible-lines, and manager-backed clear actions, all covered
    by widget tests.
  - CI: workflow `27395805822` failed only on the timing-sensitive manual-range
    queue assertion. Workflow `27396240053` succeeded after that assertion was
    synchronized. Artifacts: Android `7583796742`, Windows `7583775579`, macOS
    `7583759584`, Linux `7583749949`.
- [x] Verify history context actions.
  - Completed: Flutter now distinguishes transient table-row selection from the
    persisted checked-for-re-rip flag, matching Java. Bulk actions check all,
    check none, check selected rows, uncheck selected rows, and remove selected
    rows in descending index order. Warned clear and re-rip-checked dialogs are
    retained; Flutter's per-row copy/re-rip/remove menu remains an extension.
  - CI: workflow `27396424059` succeeded. Artifacts: Android `7583867026`,
    Windows `7583851001`, macOS `7583829790`, Linux `7583818860`.
- [x] Verify queue context actions.
  - Completed: Java's remove-selected action is represented by transient queue
    row selection plus a bulk remove control, and remove-all retains the
    `queue.validation` confirmation dialog. Flutter's per-row copy, reorder,
    and remove actions are retained as documented platform extensions.
  - CI: workflow `27396754424` succeeded. Artifacts: Android `7583978996`,
    Windows `7583954174`, macOS `7583943410`, Linux `7583930729`.
- [x] Verify text-field context action protections or Flutter equivalent.
  - Decision: Flutter's platform-adaptive `TextField` actions replace Java's
    URL-field-only Swing popup. The URL field adds an `UndoHistoryController`
    action ahead of Flutter's native cut/copy/paste/select-all items. Widget
    coverage verifies the native actions and the explicit undo configuration.
  - Intentional difference: Java popup paste calls `setText` and replaces the
    whole field, while Swing keyboard paste and Flutter native paste replace
    the active selection. Flutter retains native platform semantics rather than
    reproducing the popup-only inconsistency.
  - CI: workflow `27397109861` failed on the manual-range queue observation
    race. Workflow `27406920253` succeeded after synchronizing that assertion.
    Artifacts: Android `7588004071`, Windows `7587968645`, macOS `7587974684`,
    Linux `7587935374`.
- [x] Verify clipboard autorip duplicate handling.
- [x] Verify Java clipboard autorip polls every 1000 ms, matches only the first
      URL pattern in clipboard text, keeps a per-session `rippedURLs` set, and
      starts ripping immediately through `MainWindow.ripAlbumStatic`.
  - Completed: Flutter uses the exact anchored Java URL regex, accepts the same
    `http`, `https`, `ftp`, and `file` schemes, remembers each matched URL for
    the app autorip session, and polls every 1000 ms. New matches enter
    `RipManager.addUrlToQueue`, which starts immediately when idle.
  - CI: workflow `27407479399` exposed a remaining manual-range test race.
    Workflow `27408110876` succeeded after requiring active-rip state and
    consumed-first-item state. Artifacts: Android `7588505546`, Windows
    `7588462405`, macOS `7588449892`, Linux `7588423916`.
  - Follow-up CI: workflow `27409160339` showed the queue-listener assertion
    could still time out under Linux load. Workflow `27409927059` then showed
    an active seed could itself remain briefly pending. The test now uses a
    collecting `RipManager` subclass and validates expansion/order without any
    background queue consumer.
- [x] Verify tray icon/menu support or document platform-native replacement.
  - Completed: Windows, Linux, and macOS initialize a native tray icon on a
    best-effort basis. The menu mirrors Java's Show/Hide, About, Clipboard
    Autorip checkbox, separators, and Exit actions. Tray clicks restore and
    focus an inactive/hidden window or hide an active visible window.
  - Java parity: initialization failures remain non-fatal, localized tray
    labels come from `LabelsBundle*.properties`, and the autorip item persists
    `clipboard.autorip`. Android intentionally has no system-tray surface.
  - Validation: unit tests cover active-window hiding, inactive-window
    restoration/focus, About dispatch, autorip state dispatch, and Exit.
- [x] Verify popup notification behavior or document replacement.
  - Completed: Windows, Linux, and macOS display a native notification only
    when `download.show_popup` is enabled and the main window is hidden or
    inactive. The title is `Ripping - RipMe v<version>` and the body is
    `Started ripping <url>`, matching Java.
  - Notification setup and delivery failures are non-fatal. Android does not
    expose this Java desktop-only preference as an operating-system tray
    notification.
  - Validation: tests cover disabled, active-window, and inactive-window
    branches plus the exact notification text and the setup-notify-run order.
- [x] Verify open-folder button behavior after completion.
  - Completed: a successful desktop rip displays `Open <shortened path>` with
    the folder icon and launches the completed album directory through the
    platform shell. Starting the next rip hides the button, matching Java.
  - Path display uses Java's normalized first-12/last-12 shortening rule.
    Launch failures remain non-fatal. Android intentionally omits this
    `Desktop.open`-specific control.
  - Validation: manager tests cover the completed directory state; widget
    tests cover button visibility, label text, next-rip hiding, and path
    shortening.
- [x] Verify keyboard interactions.
  - Java registers only a URL-field Ctrl+V `KeyAdapter`; it replaces the whole
    field with the string clipboard flavor. Flutter now intercepts that exact
    chord, replaces the complete URL value, moves the caret to the end, and
    re-runs live URL validation.
  - Flutter retains native cut/copy/select-all/undo shortcuts and native
    Command-key behavior on macOS. Java has no registered mnemonic,
    accelerator, Enter, or Escape binding to reproduce.
  - Validation: widget tests exercise Ctrl+A/C/X and Ctrl+V without selecting
    the existing URL, proving full-field replacement.
- [x] Verify responsive layout across desktop and Android.
  - Flutter intentionally replaces Java's packed Swing window with adaptive
    Material layout: the command bar stacks below 720 px, status chips wrap,
    tables scroll horizontally, and configuration content scrolls vertically.
  - Validation: widget tests render and navigate Log, History, Queue, and
    Configuration at 360x800 Android and 1280x800 Windows viewport sizes with
    no framework or overflow exceptions.

Required tests:

- [x] Widget tests for log/history/queue actions.
  - Log filtering, copy, clear, and order are covered. History and queue tests
    cover Java bulk selection/removal and confirmation behavior.
- [x] Clipboard autorip tests.
- [x] Platform integration tests where practical.
  - Generated Flutter plugin metadata is tested to require `tray_manager`,
    `local_notifier`, `window_manager`, and the platform URL launcher on
    Windows, Linux, and macOS. Android is tested to retain its URL launcher
    without the Java desktop-only tray, notification, or window integrations.
  - Native tray and notification UI cannot be exercised reliably by headless
    unit tests. GitHub Actions release builds on Windows, Linux, macOS, and
    Android provide the native plugin registration and linkage integration
    boundary; focused Dart tests cover behavior before those native calls.

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

- [x] Verify every Java label key has a Flutter lookup or documented removal.
  - Flutter packages Java's complete default `LabelsBundle.properties` and
    exposes every key through `AppLocalizations.javaLabel`, including
    download-thread log messages that do not need dedicated typed UI getters.
  - The CI inventory now compares every default key from `origin/main` with
    the Flutter-packaged bundle instead of only checking Java source against
    Java's own bundle. A runtime asset test proves every packaged key is loaded
    into the generic lookup.
- [x] Verify locale list matches Java bundles.
  - Flutter exposes all 17 tags discovered by Java's
    `LabelsBundle_(?<lang>[A-Za-z_]+).properties` scan, including
    `fi-FI-porrisavo`, `in-ID`, and `kr-KR`.
  - Java `Locale.forLanguageTag("fi-FI-porrisavo")` resolves to ordinary
    `fi_FI` because the nine-character variant is not a valid BCP 47 variant.
    Flutter preserves the selector tag while using the same Finnish locale
    fallback. CI compares the shared Flutter catalog directly with bundle
    filenames on `origin/main`.
- [x] Verify Java bundle parity test behavior: non-default bundles may omit
      keys, but any keys they contain must exist in the default bundle.
  - The Dart inventory reproduces `LabelsBundlesTest.testKeyName`: partial
    translations are valid, while localized-only keys fail validation.
  - CI applies the rule to every localized bundle on `origin/main` and every
    corresponding Flutter-packaged asset. Focused tests lock both the allowed
    missing-key case and rejected extra-key case.
- [x] Verify language switching behavior.
  - Selecting a Java language tag immediately reloads Flutter localizations and
    persists the exact `lang` value for restart. Tests switch from English to
    Greek, verify translated configuration text, and reinitialize the
    configuration backend to prove persistence.
  - The selected tag is tracked separately from Flutter's `Locale`, preserving
    Java's visible `fi-FI-porrisavo` selector entry even though both runtimes
    resolve that invalid BCP 47 variant to ordinary Finnish.
  - Documented lifecycle difference: Java writes the selected combo value
    during window shutdown, while Flutter persists it when selected so mobile
    process termination cannot lose the preference.
- [x] Verify icon resources on Windows, Linux, macOS, and Android.
  - `assets/icon.png` and `assets/icon.ico` carry Java's exact source bytes.
    Windows embeds the Java ICO directly. macOS and Android use correctly sized
    transparent PNG derivatives of Java's small source icon.
  - Linux now ships a 256x256 `ripme.png` into the hicolor application icon
    directory referenced by `ripme.desktop`.
  - CI compares the source PNG/ICO with `origin/main`; Flutter tests decode
    every platform PNG, verify its required dimensions and visible pixels, and
    check Linux installation metadata.
- [x] Verify completion sound uses Java `camera.wav` or a documented platform
      replacement.
  - When `play.sound` is enabled, Flutter now plays the exact packaged Java
    `camera.wav` through `audioplayers` on Android, Windows, Linux, and macOS
    instead of substituting the operating system alert.
  - Playback remains asynchronous and failures remain non-fatal, matching
    Java. Existing manager tests cover enabled/disabled dispatch; an asset test
    validates the WAV structure and CI compares its bytes with `origin/main`.
  - Linux validation and release jobs install the GStreamer development
    packages required by the native `audioplayers` plugin.
- [x] Verify resource licensing/packaging.
  - Flutter packages the exact Java MIT `LICENSE.txt` on all targets. Linux and
    Windows additionally place it at the bundle root, macOS copies it into app
    resources, and Linux AppStream metadata declares MIT.
  - CI byte-compares all ten user-facing Java binary resources, requires every
    Java label bundle, and checks platform packaging declarations.

Required tests:

- [x] Localization key coverage test.
- [x] Asset existence test.
- [x] Platform metadata checks where scriptable.

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

- [x] Verify update check behavior against Java expectations.
  - Flutter now reproduces Java's fixed four-component comparison, including
    non-numeric components as zero and the exact-string inequality fallback
    after numeric equality.
  - GitHub's Flutter release tags are normalized only by removing their leading
    `v` before the Java comparison. GUI and CLI checks honor Java's hidden
    `testing.always_try_to_update` override.
- [x] Document replacement for Java self-update.
  - Java's `-j` downloads a jar, optionally verifies it, replaces the running
    jar through platform scripts/processes, and may relaunch it. Flutter does
    not mutate a running app bundle or APK.
  - GUI and CLI checks point to the GitHub Release containing native artifacts;
    README and CLI output explicitly require installation through the target
    platform's normal update process.
- [x] Document Java updater source of truth (`ripmeapp/ripme` `ripme.json`),
      changelist handling, SHA-256 update verification, and why jar replacement
      scripts are or are not applicable to Flutter.
  - Java reads `ripmeapp/ripme` `ripme.json`, stops its `changeList` at the
    running version, and verifies the downloaded jar against `currentHash`
    unless `security.check_update_hash` is disabled.
  - Flutter uses the configured GitHub Releases API instead. Release `body`
    text is returned as release notes to CLI callers, the GUI links to the same
    release page, and release CI publishes `SHA256SUMS.txt` for native artifacts.
  - `security.check_update_hash` remains retired because Flutter never downloads
    or replaces its own executable; Java batch/process replacement scripts do
    not apply to app bundles, APKs, or platform package managers.
- [x] Verify version display and build number.
  - Java embeds its `jgitver` result as `Implementation-Version` and prints that
    value through `-v`. Flutter keeps `pubspec.yaml` as the local default and
    guards the Dart version/build constants against it.
  - Release builds require a native-compatible `vMAJOR.MINOR.PATCH` tag, use the
    Actions run number as the numeric build identity, and inject both values
    into Dart plus Flutter's Android, Windows, and macOS build metadata.
  - CLI `--version` reports the semantic version like Java; the GUI additionally
    displays the platform build number as `<version>+<build>`.
- [x] Verify release artifact naming.
  - Java publishes `ripme-<version>.jar`. Flutter preserves the
    `ripme-<version>` prefix and appends an explicit native target:
    `linux-x64.tar.gz`, `windows-x64.zip`, `macos-universal.zip`,
    `android.apk`, or `android.aab`.
  - GitHub Actions artifact container names remain stable and version-neutral;
    release filenames use the normalized version without a duplicate leading
    `v`.
- [x] Verify Android permissions and storage behavior.
  - Android uses `path_provider` app-specific external storage with application
    documents fallback and creates the `rips` child before use. The manifest
    declares only network access; obsolete external-storage, media-read, and
    legacy-storage declarations were removed together with `permission_handler`.
  - Java's arbitrary filesystem directory chooser remains available on desktop.
    Android disables that control because its system picker returns a tree URI
    and the current ripper pipeline requires persistent filesystem paths.
    README documents scoped-storage behavior and uninstall data retention.
  - Validation: working-directory and configuration widget tests plus
    `tool/check_android_storage_policy.dart`, which is enforced by CI.
  - CI repair: workflow
    [27457012630](https://github.com/pantelb/ripme/actions/runs/27457012630)
    was terminated while `flutter test` remained in progress without a failed
    assertion or retrievable failure log. Later workflow `27457745643` ran the
    same suite successfully. CI now runs tests serially with expanded progress
    output and a 30-minute step timeout to prevent another silent worker hang.
- [x] Verify macOS entitlements and minimum OS behavior.
  - Java runs as an unrestricted Java 17 desktop process and stores ordinary
    filesystem paths for its executable-adjacent defaults, portable
    configuration, history, and selected rip directory. Flutter's prior App
    Sandbox entitlement could not preserve those paths across launches without
    security-scoped bookmarks, which the app and `file_picker 11.0.2` do not
    store. Debug/profile and release builds are therefore intentionally
    unsandboxed.
  - The user-selected read-write entitlement remains because the macOS
    `file_picker` implementation checks for it before opening a directory
    panel. Debug/profile also retains the Flutter JIT and local development
    server entitlements.
  - Xcode Debug/Profile/Release, CocoaPods, and `LSMinimumSystemVersion` all
    resolve to macOS 12.0. This is the documented native Flutter replacement
    for Java's Java-17-only platform requirement.
  - Validation: `test/macos_platform_metadata_test.dart` and
    `tool/check_macos_platform.dart`, enforced by CI.
- [x] Verify Linux metadata and executable packaging.
  - Java ships one executable fat jar with its dependencies and requires a Java
    17 runtime. Flutter replaces that with a relocatable native bundle whose
    root `ripme` executable resolves Flutter/plugin libraries through
    `$ORIGIN/lib` and includes Flutter assets under `data`.
  - CMake installs the exact MIT license, Java-derived 256px hicolor icon,
    `ripme.desktop`, and `com.rarchives.ripme.metainfo.xml`. Desktop and
    AppStream metadata consistently identify executable `ripme`, app id
    `com.rarchives.ripme`, and a non-terminal network/file-transfer app.
  - Both CI and release workflows run `tool/verify_linux_bundle.sh` against the
    actual release bundle before creating the tarball. The guard requires an
    executable root binary, Flutter runtime library/assets, license, desktop
    entry, icon, and AppStream metadata.
  - Validation: `test/linux_packaging_metadata_test.dart` and
    `tool/check_linux_packaging.dart`, enforced by CI.
- [x] Verify Windows metadata, icon, and executable packaging.
  - Java ships a Java-17 fat jar; Flutter replaces it with a native
    `ripme.exe` bundle whose Flutter/plugin DLLs, ICU data, AOT code/assets, and
    exact inherited MIT license remain adjacent in the release ZIP.
  - `Runner.rc` embeds the exact Java `icon.ico`, uses Flutter's injected
    semantic version and numeric build for native file/product versions, and
    identifies `ripme.exe`/RipMe consistently. The manifest declares
    per-monitor-v2 DPI awareness and Windows 10/11 compatibility.
  - Both CI and release workflows run `tool/verify_windows_bundle.ps1` against
    the actual Release directory before archiving. It requires all core runtime
    files and inspects the built executable's description, product,
    original-filename, and version resources.
  - Validation: `test/windows_packaging_metadata_test.dart` and
    `tool/check_windows_packaging.dart`, enforced by CI.
  - CI: workflow
    [27462687743](https://github.com/pantelb/ripme/actions/runs/27462687743)
    succeeded, including the built Windows bundle verifier. Artifacts:
    [Android 7609500509](https://github.com/pantelb/ripme/actions/runs/27462687743/artifacts/7609500509),
    [Windows 7609499336](https://github.com/pantelb/ripme/actions/runs/27462687743/artifacts/7609499336),
    [macOS 7609496501](https://github.com/pantelb/ripme/actions/runs/27462687743/artifacts/7609496501),
    [Linux 7609482433](https://github.com/pantelb/ripme/actions/runs/27462687743/artifacts/7609482433).
- [x] Verify workflow separation between CI and release.
  - Java's combined workflow built every branch and gave its Ubuntu/Java-17 job
    release-write authority to update a mutable `latest-<branch-slug>`
    prerelease. Flutter intentionally replaces that branch publication with
    read-only, retention-limited Actions artifacts from `flutter.yml`.
  - `flutter.yml` handles branch pushes and pull requests with
    `contents: read` and contains no release trigger/action. `release.yml` is
    entered only by a `v*` tag, explicit dispatch, or reusable call; its
    analyze/build jobs remain read-only and only `publish` receives
    `contents: write`.
  - The Java branch's `run-flutter-release.yml` manual wrapper is retained with
    its exact `tag`, `build_ref`, `draft`, and `prerelease` inputs and delegates
    to the reusable workflow on `Flutter`.
  - Validation: `test/workflow_separation_test.dart` and
    `tool/check_workflow_separation.dart`, enforced by CI.

Required tests:

- [x] Update checker tests.
- [x] Workflow/artifact verification by GitHub Actions.
- [x] Platform config lint or script checks where practical.

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
- [x] Verify each port has focused Dart tests.
- [x] Verify factory can resolve every supported Java URL shape used in tests.
- [x] Verify no placeholder/scaffold-only rippers remain.
- [x] Verify video-subpackage Java rippers are represented.
- [x] Verify helper classes such as `ChanSite` are represented.
  - `tool/check_ripper_reconciliation.dart` reads all Java production paths
    directly from `origin/main`, rather than deduplicating simple class names.
    It maps every path to exactly one Dart class and requires a declaration, a
    focused non-factory test, factory registration, and an asserted factory URL
    fixture for every ripper.
  - The path-aware mapping distinguishes Java's album/video duplicate names as
    `PornhubRipper`/`PornhubVideoRipper`, `VkRipper`/`VkVideoRipper`, and
    `YuvutuRipper`/`YuvutuVideoRipper`. All other `video/` classes retain their
    Java names.
  - `ripperhelpers/ChanSite.java` maps to the tested `ChanSite` implementation
    in `chan_ripper.dart` and is explicitly excluded from factory registration.
    The guard also rejects placeholder markers in every mapped implementation.

Required tests:

- [x] Catalog reconciliation test.
- [x] Factory coverage test.
- [x] Any missing helper behavior tests.

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

- [x] Flutter provides Java-compatible CLI/headless mode. Java
      enters CLI mode when the environment is headless or any CLI args are
      present, then supports URL ripping, URL-file ripping, history re-rip,
      selected-history re-rip, proxy flags, save-order flags, overwrite,
      skip-404, custom rips directory, no-property-file mode, append-to-folder,
      and updater mode.
  - Flutter routes every non-empty argument list before GUI startup. On Linux,
    an empty invocation with neither `DISPLAY` nor `WAYLAND_DISPLAY` also
    enters CLI mode and prints help, matching Java's no-argument headless path.
    Other platforms require explicit CLI arguments because Flutter exposes no
    cross-platform equivalent to AWT's `GraphicsEnvironment.isHeadless()`.
  - CI: [run 27463224052](https://github.com/pantelb/ripme/actions/runs/27463224052)
    passed with
    [Android](https://github.com/pantelb/ripme/actions/runs/27463224052/artifacts/7609684145),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27463224052/artifacts/7609671297),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27463224052/artifacts/7609668718),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27463224052/artifacts/7609659073)
    artifacts.
- [x] Java URL-file ripping skips lines beginning with `//` and `#`; Flutter
      has parser coverage for that exact pre-trim behavior.
- [x] Java CLI URL-file mode does not skip blank or whitespace-only lines:
      only raw lines starting with `//` or `#` are treated as comments, and
      every other line is trimmed and passed to `ripURL`.
- [x] Java `-n` / `--no-prop-file` behavior is treated as source-backed
      current behavior, not just help-text intent: `App.ripURL` receives but
      ignores its `saveConfig` argument, so history/config writes still follow
      the normal Java code paths. Flutter recognizes the option as the same
      tested no-op.
- [x] Java manual URL input rejects duplicate queue entries and expands
      `{start-end}` numeric ranges before enqueueing. `RipManager` matches both
      behaviors with focused duplicate, inclusive-range, multi-group, and
      malformed-range tests.
- [x] Java persists queue state through the `queue` config key on updates and
      restores it on startup. Flutter preserves ordered pending entries and
      restores them without automatically starting a rip.
- [x] Java queue persistence has a shipped empty-queue edge case:
      `MainWindow.updateQueue(...)` only calls `Utils.setConfigList("queue",
      ...)` and `Utils.saveConfig()` when `model.size() > 0`. Removing the last
      queued item or using the queue context menu's remove-all action updates
      the in-memory model/label but can leave stale persisted `queue` config
      entries for the next startup. Flutter intentionally matches this shipped
      behavior and has a regression test for the stale persisted value.
- [x] Java queue context menu supports remove selected and remove all with a
      confirmation dialog. Flutter covers both actions with widget tests.
- [x] Java `QueueMenuMouseListener` has no copy or reorder actions; it only
      removes selected queue entries or clears all entries after
      `queue.validation` confirmation. Flutter `QueueView` exposes copy,
      move-up, and move-down actions for individual queue rows, so the queue UI
      has intentional platform extensions beyond the Java menu.
- [x] Java `-a` appends text to the rip working-folder name through
      `App.stringToAppendToFoldername`; Flutter stores the exact untrimmed
      process suffix and applies it in shared download path resolution.
- [x] Java `-j` self-update replaces a jar on disk. Flutter intentionally
      replaces this with a GitHub Release check and manual platform-artifact
      installation; README and CLI output state that no in-place replacement
      occurs.
- [x] Java `ripAlbum` normalizes user input by converting `gonewild:<name>` to
      `http://gonewild.com/user/<name>` and prepending `http://` when no scheme
      is supplied. Flutter applies the same case-insensitive gonewild rewrite
      and case-sensitive `http` prefix check immediately before factory
      resolution, with bare-host and mixed-case gonewild tests.
- [x] Java URL-list file chooser in the GUI queues only trimmed lines starting
      with `http` and logs malformed lines; CLI URL-file mode has different
      comment-skipping behavior. Flutter's configuration action now preserves
      this separate GUI behavior, including duplicate valid lines and warning
      logs for blank/non-http lines.
  - CI: [run 27463556249](https://github.com/pantelb/ripme/actions/runs/27463556249)
    passed with
    [Android](https://github.com/pantelb/ripme/actions/runs/27463556249/artifacts/7609793219),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27463556249/artifacts/7609780583),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27463556249/artifacts/7609772031),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27463556249/artifacts/7609764222)
    artifacts.

### B. Configuration And Defaults

Java sources/resources read:

- `src/main/java/com/rarchives/ripme/utils/Utils.java`
- `src/main/resources/rip.properties`

Flutter files checked:

- `lib/config_defaults.dart`
- `lib/utils/utils.dart`
- `lib/main.dart`

Findings:

- [x] Java config file name is `rip.properties`; Flutter uses the existing Java
      file directly when it is executable-adjacent portable configuration.
      Outside portable mode, Flutter intentionally uses the platform-native
      SharedPreferences backend rather than automatically importing or
      rewriting Java's platform config file. Tests cover both backends,
      precedence, persistence, and reinitialization.
- [x] Java portable mode uses a `rip.properties` file next to the jar/current
      working directory. Flutter desktop startup detects the file beside the
      resolved executable, validates the same seven required Java keys, and
      uses it as the authoritative read/write backend. Android intentionally
      omits portable mode because an APK is not a writable portable directory.
- [x] Java config directory resolution is platform-specific:
      `%LOCALAPPDATA%/ripme` on Windows, `~/Library/Application Support/ripme`
      on macOS, `~/.config/ripme` on Unix. Flutter intentionally replaces those
      directories with each platform's SharedPreferences backend outside
      portable mode; persistence tests prove values survive utility
      reinitialization.
- [x] Java default working directory is the jar directory plus `rips/`, with the
      jar directory derived from `java.class.path` or `user.dir` and fallback to
      `user.home` when creation fails. Flutter desktop uses the resolved
      executable directory plus `rips`, falls back to the user home directory
      after creation failure, and keeps Android's writable external/app
      documents replacement. Cross-platform path and failure tests cover the
      distinction.
- [x] Java deletes and reloads old configs missing required keys such as
      `twitter.auth`, `tumblr.auth`, or `download.max_size`. Flutter applies the
      exact seven-key sentinel check to external desktop `rip.properties`,
      deletes obsolete files, and falls back to preferences plus bundled
      defaults. Focused tests remove each sentinel in turn.
  - Audit reconciliation CI:
    [run 27463723642](https://github.com/pantelb/ripme/actions/runs/27463723642)
    passed with
    [Android](https://github.com/pantelb/ripme/actions/runs/27463723642/artifacts/7609845817),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27463723642/artifacts/7609832650),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27463723642/artifacts/7609826772),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27463723642/artifacts/7609819264)
    artifacts.
- [x] Java `download.retry.sleep` is absent from `rip.properties` and has
      subsystem-specific fallbacks: `Http` page requests and the configuration
      field use `5000`, while `DownloadFileThread` uses `0`. Flutter no longer
      supplies a global default; page requests use `5000`, file downloads use
      `0`, and an explicitly configured value overrides both paths.
  - CI: [run 27463911894](https://github.com/pantelb/ripme/actions/runs/27463911894)
    passed with
    [Android](https://github.com/pantelb/ripme/actions/runs/27463911894/artifacts/7609903074),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27463911894/artifacts/7609892599),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27463911894/artifacts/7609884217),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27463911894/artifacts/7609878623)
    artifacts.
- [x] Java bundled `rip.properties` sets `threads.size=5`, while
      `DownloadThreadPool` uses `10` when an authoritative external config omits
      the key. Flutter preserves both cases: bundled/native preferences default
      to five, portable `rip.properties` is authoritative rather than layered
      over bundled defaults, and `AbstractRipper.downloadFiles(...)` uses the
      Java ten-thread call-site fallback.
  - CI: [run 27464068594](https://github.com/pantelb/ripme/actions/runs/27464068594)
    passed with
    [Android](https://github.com/pantelb/ripme/actions/runs/27464068594/artifacts/7609954392),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27464068594/artifacts/7609941230),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27464068594/artifacts/7609939675),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27464068594/artifacts/7609928154)
    artifacts.
- [x] Java ships `error.skip404=true`, while CLI and a late
      `DownloadFileThread` branch use `errors.skip404`; however, the earlier
      4xx branch returns before that late check. Flutter preserves both keys for
      configuration/CLI compatibility and matches the observable behavior:
      normal page and file 404 responses are non-retriable regardless of either
      value. CLI, widget, page, and file tests cover the split.
  - CI: [run 27467310203](https://github.com/pantelb/ripme/actions/runs/27467310203)
    passed with
    [Android](https://github.com/pantelb/ripme/actions/runs/27467310203/artifacts/7610981601),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27467310203/artifacts/7610964614),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27467310203/artifacts/7610956492),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27467310203/artifacts/7610948631)
    artifacts.
- [x] Java `Utils.getConfigStringArray(key)` returns `null` when
      `PropertiesConfiguration.getStringArray(key)` has length zero. Flutter
      intentionally exposes a non-null empty list for missing or blank values.
      All Java callers treat null and empty identically: ignored-extension
      filtering returns false and tag blacklist checks return null. Missing
      portable-key and empty-blacklist tests lock this equivalent Dart API.
  - CI: [run 27469057151](https://github.com/pantelb/ripme/actions/runs/27469057151)
    passed with
    [Android](https://github.com/pantelb/ripme/actions/runs/27469057151/artifacts/7611522674),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27469057151/artifacts/7611520500),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27469057151/artifacts/7611517269),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27469057151/artifacts/7611498185)
    artifacts.
- [x] Java `album_titles.save=false` changes `AbstractJSONRipper` and the
      deprecated `AlbumRipper`
      directory naming: `AbstractJSONRipper.setWorkingDir(...)` falls back to
      `super.getAlbumTitle(this.url)`, while `AbstractHTMLRipper.setWorkingDir(...)`
      always calls the concrete `getAlbumTitle(...)`.
  - Completed: shared setup now uses a class-level opt-in for the setting and a
    non-polymorphic `<host>_<gid>` fallback. JSON/album and HTML behavior is
    covered separately.
- [x] Java exposes `descriptions.save`, but current source has no reachable
      implementation: `FuraffinityRipper` is the only class overriding the
      description hooks and returns `false` from `hasDescriptionSupport()`.
      Flutter intentionally retires this ineffective control.
  - CI artifacts:
    [Android](https://github.com/pantelb/ripme/actions/runs/27357574894/artifacts/7568983184),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27357574894/artifacts/7568925684),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27357574894/artifacts/7568909737),
    [Linux](https://github.com/pantelb/ripme/actions/runs/27357574894/artifacts/7568869363).
- [x] Java bundled `rip.properties` sets `twitter.rip_retweets=false`, while
      `TwitterRipper` uses `true` when an authoritative external config omits
      the key. Flutter preserves both cases: native/bundled configuration
      defaults to false, portable configuration uses the Java call-site true
      fallback, and focused tests cover both values.
  - CI: [run 27469372085](https://github.com/pantelb/ripme/actions/runs/27469372085)
    passed with
    [Android](https://github.com/pantelb/ripme/actions/runs/27469372085/artifacts/7611619358),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27469372085/artifacts/7611606017),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27469372085/artifacts/7611606502),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27469372085/artifacts/7611592632)
    artifacts.
- [x] Java `history.location` controls downloaded-URL history
      (`url_history.txt`), not the album history JSON. Flutter uses the
      configured file when supplied and otherwise documents SharedPreferences
      as the replacement for Java's default config-dir file.
- [x] Java has config-driven log level and `log.save` file logging behavior.
      Flutter uses the exact four Java labels, mirrors rip status diagnostics,
      writes `ripme.log`, and rolls two gzip archives at 20 MB.
- [x] The mechanical source scan's Java-used-key findings are fully reconciled.
      The source-backed generator currently finds 71 keys, all represented by
      `ConfigDefaults.javaRuntimeKeys`; `ConfigParity` partitions them between
      separately tracked controls and explicit active, alias, sentinel,
      retired, or unsupported dispositions. The original finding's phrase
      "missing from Flutter defaults" meant absent from the typed bundled
      default maps, not absent from the parity inventory, and did not imply
      that credentials, optional values, or retired sentinels should acquire
      invented defaults.
- [x] Java-used keys already carrying Flutter defaults are explicitly tracked
      and behaviorally verified by their feature rows and focused tests:
      clipboard autorip, retry/timeouts, sound, Reddit filtering/subdirectories,
      and downloaded-URL history. The exhaustive parity test prevents a Java
      key from being silently omitted or classified twice.
- [x] Flutter-only configuration compatibility keys now have guarded mapping
      notes. `history.skip_downloaded_urls` is a legacy fallback for Java
      `remember.url_history`; `proxy.enabled`, `proxy.host`, `proxy.port`,
      `proxy.username`, and `proxy.password` provide a structured UI for Java
      `proxy.http`, while portable `proxy.http` retains precedence.
      The original scan incorrectly called `error.skip404` Flutter-only: it is
      the bundled Java resource/sentinel key, while Java CLI and a late download
      branch use `errors.skip404`; that discrepancy is tracked above.
  - CI: [run 27469648565](https://github.com/pantelb/ripme/actions/runs/27469648565)
    passed with
    [Android](https://github.com/pantelb/ripme/actions/runs/27469648565/artifacts/7611700209),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27469648565/artifacts/7611688120),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27469648565/artifacts/7611683488),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27469648565/artifacts/7611673045)
    artifacts.

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

- [x] Java album history fields are `url`, `title`, `dir`, `count`,
      `startDate`, `modifiedDate`, and `selected`. Flutter `HistoryEntry`
      carries all seven fields, preserves Java epoch-millisecond timestamps,
      updates only `modifiedDate` on repeated completion, and displays both
      dates and the count. Provider, manager, and table tests cover the full
      model and repeated-completion behavior.
- [x] Java writes `url`, `startDate`, `modifiedDate`, `title`, `count`, and
      `selected`, but does not write `dir` even though it reads `dir`.
      Flutter intentionally extends exported records with `dir` so its
      open-directory action survives export/import, and also retains the
      legacy Flutter `date` field for backward compatibility. Java ignores
      both additional properties on import; a format-extension test locks the
      complete output.
- [x] Java history import is strict for the core JSON shape:
      `History.fromJSON(...)` calls `getJSONObject(i)`, and
      `HistoryEntry.fromJSON(...)` requires `url`, `startDate`, and
      `modifiedDate` through `getString`/`getLong`; malformed entries make
      `fromFile(...)` throw an `IOException`. Flutter file import requires the
      same object/string/numeric core shape and reports `FormatException`;
      tolerant decoding remains limited to previously persisted Flutter-native
      preference records. Focused tests reject non-objects, missing fields, and
      string timestamps.
- [x] Java history table displays dates as `yyyy/MM/dd`. Flutter uses the same
      zero-padded format for separate created and modified columns, verified by
      a widget test.
- [x] Java history context actions support check all, uncheck all, check
      selected rows, and uncheck selected rows. Flutter exposes and persists
      all four operations, with row-selection and checked-state behavior
      covered by manager and widget tests.
- [x] Java CLI `-r` re-rips all history entries and `-R` re-rips selected
      entries. Flutter supports both short and long forms, preserves history
      order, skips malformed entries while reporting errors, delays after
      successful rips like Java, and distinguishes empty from unchecked
      history in focused CLI tests.
  - CI: [run 27469904095](https://github.com/pantelb/ripme/actions/runs/27469904095)
    passed with
    [Android](https://github.com/pantelb/ripme/actions/runs/27469904095/artifacts/7611779100),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27469904095/artifacts/7611766960),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27469904095/artifacts/7611761902),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27469904095/artifacts/7611751633)
    artifacts.
- [x] Java can reconstruct history candidates from existing rip directories via
      `RipUtils.urlFromDirectoryName`; Flutter now ports and tests the mapping.
- [x] Java fallback history guessing is narrower than its intent: `App.loadHistory`
      only scans the working directory when both `history.json` and legacy
      `download.history` are empty, and it passes each `Path.toString()` into
      `RipUtils.urlFromDirectoryName`, whose helpers mostly check for bare
      directory-name prefixes such as `imgur_`, `imagefap_`, and `deviantart_`.
      Flutter preserves and documents this current-source behavior.
- [x] Java `RipUtils.urlFromRedditDirectoryName(...)` appears unreachable for
      the intended `reddit_sub_*`, `reddit_user_*`, and `reddit_post_*`
      directory names: after confirming `dir.startsWith("reddit_")`, it splits
      on `_` and switches on `fields[0]`, which is still `reddit`, not `sub`,
      `user`, or `post`. Flutter preserves this shipped Reddit reconstruction
      bug and tests that these names remain non-candidates.
- [x] Java `RipUtils.urlFromImgurDirectoryName(...)` also has current-source
      edge cases that must not be silently smoothed over: it builds
      `List<String> fields = Arrays.asList(dir.split("_"))`, then the subreddit
      branch calls `fields.remove(...)`, which throws
      `UnsupportedOperationException` on the fixed-size list; short names such
      as `imgur_` can also fail at `fields.get(1)`. Flutter treats both as
      non-candidates rather than allowing malformed folders to abort startup.
- [x] Java `RipUtils.urlFromDeviantartDirectoryName(...)` accepts any directory
      starting with `deviantart`, then immediately calls
      `dir.substring("deviantart_".length())`; a bare `deviantart` directory can
      therefore throw before returning `null` or a URL. Directory names with a
      trailing underscore can also reach `fields[1]` after Java's split drops
      trailing empty fields. Flutter preserves Java splitting for valid names
      but ignores malformed candidates instead of aborting startup.
- [x] Java history clear deletes both album history and downloaded-URL history
      through `Utils.clearURLHistory()`, optionally after
      `history.warn_before_delete` confirmation. Flutter's UI clear action and
      focused provider tests now cover both stores.
- [x] Java history button behavior is selection-centric and dialog-backed, not
      per-entry only: `historyButtonRemove` removes the table's selected view
      rows after `convertRowIndexToModel`, `historyButtonClear` honors
      `history.warn_before_delete` by opening a separate `"Are you sure?"`
      `JFrame` with literal `YES`/`NO` buttons before clearing both
      `Utils.clearURLHistory()` and `HISTORY`, and `historyButtonRerip` queues
      only `HistoryEntry.selected` rows while showing `RipMe Error` dialogs for
      empty history (`history.load.none`) or no checked rows
      (`history.load.none.checked`).
  - Reconciled: Flutter has independent transient row selection and persisted
    checked state, descending bulk removal, all four Java check/uncheck actions,
    warned clear of both history stores, and the two Java error-dialog cases.

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

- [x] Java `Http` is a chainable Jsoup wrapper supporting timeout,
      `ignoreContentType`, referrer, user agent, retry count, headers, cookies,
      form data, method override, `post`, JSON object, and JSON array helpers.
      Flutter now exposes the equivalent surface through `Http.url(...)` while
      retaining its existing static convenience methods.
      Flutter has focused helpers but not the full API surface.
- [x] Java configured cookies use `cookies.<domain>` and check the exact host,
      then progressively remove the leftmost label while at least two labels
      remain. Flutter follows the same first-non-empty precedence, does not
      consult a bare top-level-domain key, and applies configured cookies to
      page requests but not Java-style file-download defaults. Focused HTTP
      tests cover exact/empty-parent lookup and request injection.
- [x] Java shared cookie parsing in `RipUtils.getCookiesFromString(...)` uses
      `pair.split("=")` with no split limit and no malformed-pair guard:
      `a=b=c` becomes `a -> b`, and a semicolon segment without `=` throws
      instead of being skipped. Flutter's configured-cookie parser now has the
      same truncation, whitespace, trailing-semicolon, and malformed-segment
      behavior; focused tests lock each edge case. Concrete rippers may still
      parse site-specific response cookies separately where Java does likewise.
  - CI: [run 27470106304](https://github.com/pantelb/ripme/actions/runs/27470106304)
    passed with
    [Android](https://github.com/pantelb/ripme/actions/runs/27470106304/artifacts/7611846042),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27470106304/artifacts/7611833488),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27470106304/artifacts/7611824663),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27470106304/artifacts/7611815984)
    artifacts.
- [x] Java proxy CLI/config accepts single strings such as
      `[user:password]@host[:port]` for HTTP and SOCKS. Flutter currently uses
      `proxy.enabled`, `proxy.host`, `proxy.port`, `proxy.username`, and
      `proxy.password`; persisted Java `proxy.http` is now mapped into the
      shared client and takes precedence, while `proxy.socks` is parsed and
      rejected explicitly as unsupported.
- [x] Java SOCKS proxy support sets `socksProxyHost`, `socksProxyPort`, and
      optional credentials globally. Flutter has no native SOCKS equivalent in
      `dart:io`, so this is an explicit unsupported platform capability.
- [x] Java proxy support mutates process-wide networking through
      `Authenticator.setDefault`, `http.proxyHost`, `http.proxyPort`,
      `http.proxyUser`, `http.proxyPassword`, `https.proxyHost`, and HTTPS
      equivalents. Flutter intentionally scopes proxy configuration to every
      client created by the shared HTTP layer; Dart does not expose Java-style
      process-global proxy system properties.
- [x] Java 401/403 page requests throw a cookie-oriented error message; 404 page
      requests throw file-not-found style messaging. Flutter currently raises
      matching `HttpException` text from the shared page path.
- [x] Audited per-ripper malformed URL/GID exception messages are
      Java-compatible and test-locked. Java rippers throw exact
      `MalformedURLException` strings, including source typos such as
      `MyhentaigalleryRipper` saying `Expected myhentaicomics.com URL format`
      and `PorncomixRipper` saying `Expected proncomix URL format`; several
      Dart ports use `FormatException` as the platform equivalent while
      preserving the exact Java message payload. A table-driven test guards all
      named strings.
- [x] The malformed-URL message audit includes additional concrete Java typos
      and copy/paste strings that Flutter now preserves and locks:
      `ErofusRipper` reuses the `8muses.com/index/category/albumname`
      expectation, `HentaiimageRipper` says `Expected hitomi URL format`,
      `JagodibujaRipper` says `hwww.jagodibuja.com/Comic name/`,
      `MrCongRipper` says `Expected misskon.com URL format`,
      `ReadcomicRipper` says `Expected view-comic URL format`, and
      `JabArchivesRipper` says `Expected javarchives.com URL format`.
  - CI: [run 27470338182](https://github.com/pantelb/ripme/actions/runs/27470338182)
    passed with
    [Android](https://github.com/pantelb/ripme/actions/runs/27470338182/artifacts/7611912910),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27470338182/artifacts/7611899829),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27470338182/artifacts/7611894526),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27470338182/artifacts/7611886468)
    artifacts.
- [x] Java `Http` retry loop attempts exactly the configured count. Flutter's
      shared page path now uses the same total-attempt boundary.
- [x] Java `Http.TIMEOUT` is a `static final` value read once from
      `Utils.getConfigInteger("page.timeout", 5 * 1000)` when `Http` is loaded,
      and every default Jsoup connection then uses that frozen timeout. Flutter
      `_getResponse(...)` reads `Utils.getConfigInteger(timeoutKey,
      defaultTimeoutMs)` on every request, so changing `page.timeout` after the
      first Java `Http` class load affects Flutter requests but not Java page
      requests. This is retained intentionally so Flutter's immediately
      persisted timeout control applies without restarting the app.
- [x] Java CLI `-4` sets `errors.skip404`, but source-order verification shows
      `DownloadFileThread` handles and returns for every 4xx before reaching
      the later `HttpStatusException` check that reads this key. Flutter now
      matches the observable behavior: normal page/file 404 responses are
      non-retriable regardless of either skip-404 key.
- [x] Java `Http.response()` does not inspect `Retry-After` on 429 or 503; it
      applies the configured `download.retry.sleep` delay between retries or
      retries immediately when that value is zero. Flutter now matches this
      behavior and has no header-specific delay path.
- [x] Java file download retry loop increments `tries` and fails when
      `tries > retries`; redirect handling can avoid counting the first redirect.
      Flutter now uses one initial file attempt plus the configured retry count;
      status tests lock the boundary. Redirect-resume behavior remains tracked
      with the broader download-engine item.
- [~] Java `DownloadFileThread` supports resume with Range headers when a ripper
      opts in, MIME/magic extension detection when requested, explicit
      non-retriable 4xx handling, retriable 5xx handling, and an Imgur
      503-byte-as-404 special case. The 4xx/5xx status handling is now matched;
      MIME/magic extension detection is also matched. Resume and the Imgur
      special case remain.
- [x] Java file downloads always set request properties `accept: */*`,
      `User-agent: <AbstractRipper.USER_AGENT>`, and `Cookie: <serialized map>`,
      with `Cookie` present even when the per-download cookie map is empty.
      Flutter now preserves that request shape and keeps configured-domain
      cookies scoped to page requests.
- [x] Java `DownloadFileThread` catches `SocketTimeoutException`, logs
      `timedout!`, breaks out of the retry loop, and then still falls through to
      `observer.downloadCompleted(url, saveAs.toPath())`. Flutter shared
      download/page requests intentionally surface timeout failures instead;
      tests lock the absence of a destination file rather than reproducing the
      shipped Java false-completion bug.
- [x] Java `download.max_size` is only used by config validation/update
      plumbing; `DownloadFileThread` does not compare response size against that
      key before saving. Flutter now retains the property for compatibility
      without exposing or enforcing the former Flutter-only global limit.
- [x] Java `DownloadVideoThread` first issues a HEAD request for total bytes,
      then downloads with no connect timeout and byte-progress events.
  - Completed: Flutter video downloads now perform HEAD without a request
    timeout, emit `TOTAL_BYTES`, then start GET and emit cumulative
    `COMPLETED_BYTES` updates using Java 32-bit integer behavior.
- [x] Java `DownloadVideoThread` gets total bytes through a separate HEAD
      request, then performs one initial GET plus `download.retries` retries
      with no connect/read timeout and no retry-sleep delay. It emits
      `DOWNLOAD_STARTED` for each attempt. Flutter's video policy now preserves
      those differences while retaining the shared file lifecycle; ordinary
      downloads keep their configured timeout and retry sleep. A deterministic
      HEAD/500/200 test verifies method order, attempt statuses, zero delay, and
      final bytes.
  - CI: [run 27470589176](https://github.com/pantelb/ripme/actions/runs/27470589176)
    passed with
    [Android](https://github.com/pantelb/ripme/actions/runs/27470589176/artifacts/7611980730),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27470589176/artifacts/7611977406),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27470589176/artifacts/7611977894),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27470589176/artifacts/7611962934)
    artifacts.
- [x] Java DASH manifest selection in `RedditRipper.parseRedditVideoMPD(...)`
      considers only the `height` attribute, treats a missing height as `0`,
      updates the candidate only when the height is strictly greater than the
      previous largest value, and then appends the selected `BaseURL` text to
      the original video URL. Flutter now uses a Reddit-specific parser that
      preserves those rules instead of the shared bandwidth-aware resolver.
      Tests cover bandwidth-only entries, Java's `/null` result when no height
      exceeds zero, literal leading-slash appends, and duplicate-height text
      that makes Java URI construction fail. Invalid numeric heights also
      preserve Java's uncaught number-format failure. Dart `Uri` normalizes
      explicit `..` path segments whereas Java `URL.toExternalForm()` preserves
      them; this platform URI representation difference is documented rather
      than misreported as exact textual parity.
  - CI: [run 27471021055](https://github.com/pantelb/ripme/actions/runs/27471021055)
    passed with
    [Android](https://github.com/pantelb/ripme/actions/runs/27471021055/artifacts/7612122316),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27471021055/artifacts/7612107808),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27471021055/artifacts/7612099928),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27471021055/artifacts/7612090829)
    artifacts.
- [x] Java `CliphunterRipper.rip()` schedules the decrypted video with
      `addURLToDownload(url, HOST + "_" + getGID(...))`; Java
      `VideoRipper.addURLToDownload(..., referrer, cookies, ...)` ignores
      referrers and cookies entirely.
  - Corrected: Cliphunter's request no longer supplies transport headers, and
    the shared video downloader applies only Java's media-URL `Referer` while
    omitting cookies.
- [x] Java `VideoRipper.addURLToDownload` has a test-only contract: when
      `markAsTest()` / `isThisATest()` is active and `urls_only.save` is false,
      it does not enqueue or download the video; it mutates `this.url` to the
      resolved video download URL and returns true. Java `VideoRippersTest`
      asserts that the ripper URL changes from the original page URL. Flutter
      now carries the Java global test marker and mutable ripper URL, resolves
      the media request, then mutates the URL without entering the download
      path. Tests verify no file/download request occurs and that
      `urls_only.save` still takes precedence by writing `urls.txt` while
      leaving the page URL unchanged.
  - CI: [run 27471253168](https://github.com/pantelb/ripme/actions/runs/27471253168)
    passed with
    [Android](https://github.com/pantelb/ripme/actions/runs/27471253168/artifacts/7612190633),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27471253168/artifacts/7612177712),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27471253168/artifacts/7612165136),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27471253168/artifacts/7612161942)
    artifacts.
- [x] Java SSL verification toggle globally disables/enables certificate and
      hostname checks for Jsoup.
  - Reconciled duplicate: the verified implementation and CI evidence are
    recorded in the HTTP/configuration section above. Every shared Flutter
    page, JSON, text, HEAD, and download client is created through
    `Http._createClient()`, which applies `ssl.verify.off` through
    `badCertificateCallback`; false restores Dart's default certificate and
    hostname validation. Unlike Java's process-global `HttpsURLConnection`
    mutation, Flutter evaluates the persisted setting for each new client, so
    changes take effect without constructing a new HTML ripper.
- [x] Java has two cookie parsers with different delimiters:
      `Http`/`RipUtils.getCookiesFromString` parse semicolon-delimited cookies,
      while `Utils.getCookies(host)` parses space-delimited pairs. Flutter's
      shared HTTP, E621, and Furaffinity paths now use one strict semicolon
      parser preserving Java's key-only trim, second-token value, and malformed
      pair failure. The dormant Java `Utils.getCookies(host)` API is retained
      as a separately tested space-delimited, first-`=` parser with the same
      per-host cache behavior; source search confirms Java has no production
      caller for that legacy helper.
  - CI repair included: run 27471517193 failed only because optional
    Microsoft apt repositories preinstalled on the Ubuntu runner returned 403
    during `apt-get update`. CI and release jobs now share a guarded Linux
    dependency installer that removes only those unrelated source files before
    updating Ubuntu repositories; a workflow test locks all four call sites.
  - CI: [run 27472195798](https://github.com/pantelb/ripme/actions/runs/27472195798)
    passed with
    [Android](https://github.com/pantelb/ripme/actions/runs/27472195798/artifacts/7612468033),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27472195798/artifacts/7612457113),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27472195798/artifacts/7612443771),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27472195798/artifacts/7612440747)
    artifacts, confirming the apt-source repair.

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

- [x] Java `filesystemSafe` removes every character outside
      `[a-zA-Z0-9-.,_ ]`, trims, and truncates names longer than 100 characters
      to 99. Reconciled duplicate: `Utils.filesystemSafe` implements all three
      operations, and `test/utils_test.dart` locks the 101-to-99 edge case.
- [x] Java `filesystemSanitized` replaces disallowed characters with `_`.
      Reconciled duplicate: Flutter exposes the separate
      `Utils.filesystemSanitized` helper with the exact
      `[^a-zA-Z0-9.-]` replacement rule and focused coverage.
- [x] Java `sanitizeSaveAs` replaces `\\:*?"<>|` and has test-backed filename
      edge cases: explicit file name plus extension yields `test.test`, explicit
      filename without extension yields `test`, query URL object yields `Object`,
      and `file.` stays `file.`.
  - Reconciled duplicate: `Utils.sanitizeSaveAs` and
    `AbstractRipper.getFileName` preserve these rules; punctuation tests live
    in `test/utils_test.dart` and all named filename overload cases live in
    `test/abstract_ripper_download_test.dart`.
- [x] Java working directory creation preserves an existing directory's
      original case on Unix/macOS through `getOriginalDirectory`.
  - Reconciled duplicate: non-Windows setup calls
    `Utils.getOriginalDirectory`, and a mixed-case on-disk fixture verifies the
    returned spelling.
- [x] Java `Utils.getWorkingDirectory()` creates the configured
      `rips.directory` when it does not exist.
  - Reconciled duplicate: Flutter creates the selected directory
    non-recursively like `Files.createDirectory`, falls back to the supplied
    user-home directory on failure, and has tests for both outcomes.
- [x] Java shortens Windows paths above 260 characters and long filenames above
      filesystem limits.
  - Reconciled duplicate: shared downloads invoke
    `Utils.shortenSaveAsWindows` above 259 absolute characters; fixture tests
    lock Java's extension-preserving arithmetic and exhausted-parent failure.
- [x] Java `getFileName` strips query, fragment, ampersand, and colon segments,
      adds prefix before extension handling, then sanitizes. Its URL-extension
      inference also uses `lastBit.split(".")`, where `"."` is a regex matching
      any character, so callers that pass an explicit `fileName` but no
      `extension` usually do not receive an inferred extension from the URL.
  - Reconciled duplicate: shared `AbstractRipper.getFileName` ports the shipped
    regex bug intentionally, and focused tests cover custom names with and
    without explicit extensions, query/fragment delimiters, and trailing dots.
  - CI: [run 27472470144](https://github.com/pantelb/ripme/actions/runs/27472470144)
    passed with
    [Android](https://github.com/pantelb/ripme/actions/runs/27472470144/artifacts/7612560231),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27472470144/artifacts/7612544034),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27472470144/artifacts/7612534968),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27472470144/artifacts/7612527030)
    artifacts.
- [x] Java writes downloaded URLs to URL history before handing a download to
      the thread pool.
  - Reconciled stale finding: Flutter writes history before checking an
    existing destination and before calling `Http.downloadFile`, so failures
    and interruptions retain the attempted URL like Java. The failed-download
    fixture in `test/abstract_ripper_download_test.dart` locks the ordering.
- [x] Java normalizes URL-history keys through overridable
      `AbstractRipper.normalizeUrl` before both history lookup and history
      write. Current Java overrides are `ArtStationRipper` (strips a terminal
      query word) and `DeviantartRipper` (uses the current offset URL).
  - Flutter now routes both operations through the same overridable hook.
    Exact base, ArtStation, and DeviantArt behavior is documented and tested in
    the ripper reconciliation findings below.
- [x] Java shared `AbstractRipper.addURLToDownload` rejects bare `http:` and
      `https:` download URLs and rewrites spaces in `url.toExternalForm()` to
      `%20` before save-path creation, history checks/writes, and queueing.
  - Flutter now applies the same guard at the shared `downloadFile` boundary
    before ignore, duplicate, history, URL-only, save-path, and transport
    handling. Dart `Uri` normally encodes spaces before this boundary, while
    the explicit text preflight preserves Java behavior for raw URL fixtures.
    Focused tests verify silent rejection leaves no history or URL-only output
    and lock literal-space replacement.
- [x] Java `urls_only.save=true` writes `urls.txt`, counts it as completed, and
      attempts to open `urls.txt` after rip completion.
  - Completed: Flutter writes and reports each URL as completed, preserves the
    original working-directory output path, and matches Java's path-creation
    side effects. Automatic opening is intentionally not copied: Java already
    catches the unreliable desktop-open failure, and a file URI is not a
    portable launch contract across Android and desktop targets.
- [x] Java duplicate suppression is per ripper pending/completed/errored maps
      unless `allowDuplicates()` is overridden. Flutter has a per-ripper
      attempted URL set.
  - Completed: the attempted set is retained across download outcomes, and the
    only Java override, Imgur user mode, passes the explicit duplicate opt-out.
- [x] Java shared download paths surface prior downloads and existing files as
      warning statuses: URL-history hits send `DOWNLOAD_WARN` with
      `Already downloaded <url>`, and `downloadExists(...)` sends
      `DOWNLOAD_WARN` with `<url> already saved as <file>` while marking the
      item completed.
  - Completed: Flutter emits warning statuses with Java text, and existing files
    no longer affect the URL-history counter.
- [x] Java `DownloadThreadPool.waitForThreads()` shuts down the fixed thread
      pool and waits at most 3600 seconds for termination. Flutter
      `AbstractRipper.downloadFiles` now waits at most the same 3600 seconds
      and returns while already-started workers continue, matching
      `awaitTermination` timeout behavior. Dart futures have no Java thread
      interruption equivalent; Java only logs an interrupted wait and emits no
      rip status. An overridable timeout provides deterministic focused
      coverage without weakening the production duration.
- [ ] Java `AbstractHTMLRipper`/`AbstractJSONRipper` wait on overridable
      `getThreadPool()` hooks, and concrete rippers can replace the default
      pool with per-ripper pools. Current Java overrides are
      `DeviantartRipper`, `E621Ripper`, `EHentaiRipper`, `FlickrRipper`,
      `FuraffinityRipper`, `HqpornerRipper`, `ImagebamRipper`,
      `ImagevenueRipper`, `ListalRipper`, `MotherlessRipper`, `NfsfwRipper`,
      `NhentaiRipper`, and `PornhubRipper`. Flutter uses the shared
      `AbstractRipper.downloadFiles` worker queue and has no verified
      per-ripper pool hook/coverage for these classes.
- [x] Java stops an HTML rip after `history.end_rip_after_already_seen` already
      downloaded URLs and sends `DOWNLOAD_COMPLETE_HISTORY`.
  - Completed: Flutter emits `downloadCompleteHistory` after the current
    scheduled page batch and stops future work.
- [x] Java stops a JSON rip after the same
      `history.end_rip_after_already_seen` threshold inside
      `AbstractJSONRipper.rip()` but sends `DOWNLOAD_COMPLETE` with
      `Already seen the last N images ending rip` before breaking.
  - Completed: Flutter emits `downloadComplete` with the same text after the
    current scheduled page batch.
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
- [ ] Java `DownloadFileThread.run()` sends `DOWNLOAD_STARTED` at the start of
      every download attempt before connection, status-code, redirect, and retry
      handling. Flutter `AbstractRipper.downloadFile(...)` emits
      `RipStatus.downloadStarted` before calling `Http.downloadFile(...)`, so a
      failed high-level download can produce one started event, but shared HTTP
      retries and redirects stay hidden inside `Http._getResponse(...)`.
      Multi-attempt failures therefore still do not produce Java-compatible
      per-attempt started status events.
- [ ] Java shared test mode is a static `AbstractRipper.thisIsATest` flag set by
      `markAsTest()`. `AbstractHTMLRipper` and `AbstractJSONRipper` remove all
      but one media URL per page, stop before fetching the next page, suppress
      history checks/writes, and `addURLToDownload(...)` stops later downloads
      after the first completion/error while test mode is active. Flutter has no
      equivalent shared test-mode surface, so Java live-test contracts and
      test-only side effects are not reproducible outside ad hoc Dart mocks.
- [ ] Java `DownloadFileThread.run()` has an additional test-only download
      shortcut: when `HttpURLConnection.getContentLength() / 1000000 >= 10`
      and `AbstractRipper.isThisATest()` is true, it logs that the file is over
      10 MB and does not read/write the response body. Flutter
      `Http.downloadFile(...)` always fetches the full response bytes before
      applying the normal `download.max_size` limit, and there is no shared
      test-mode flag or content-length-based skip path.
- [ ] Java concrete rippers also add subclass-specific `isThisATest()` branches
      outside the shared abstract loops: `ChanRipper`, `EightmusesRipper`,
      `ErofusRipper`, `FivehundredpxRipper`, `ImagefapRipper`,
      `MotherlessRipper`, `NatalieMuRipper`, `RedditRipper`, `TapasticRipper`,
      and `XhamsterRipper` break extraction or pagination early, while
      `MotherlessImageRunnable` ignores a stopped rip when test mode is active.
      Flutter has no shared flag for these concrete branches, and several ports
      currently expose only normal extraction helpers, so the Java live-test
      crawl limits and stopped/test interactions need focused Dart coverage or
      explicit retirement.
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
- [ ] Java `TwitchVideoRipper.rip()` only throws for an entirely absent
      `<script>` set; if scripts exist but none contain the `"source":"..."`
      regex, it queues nothing and calls `waitForThreads()` without adding a
      download. Flutter `TwitchVideoRipper.getVideoURLForRip(...)` throws when
      no source URLs are found, but concrete `rip()` builds an empty download
      list from `videoDownloadsFromDocument(...)` and still sends
      `ripComplete`. The "scripts present, no source marker" path is therefore
      not Java-compatible.
- [x] Java `ViddmeRipper.rip()` and `VidearnRipper.rip()` convert the extracted
      video string with `new URI(vidUrl).toURL()` before scheduling the
      download, so a present marker with an empty `content` / `file:""` value
      fails immediately as a malformed URL. Flutter now rejects empty or
      non-absolute extracted video strings in `videoUrlFromDocument(...)` /
      `videoUrlFromHtml(...)`, with focused Dart regression tests.
- [ ] Java `MotherlessVideoRipper.rip()` logs the hardcoded error message
      `WTF` whenever the fetched HTML contains the `__fileurl = '` marker, and
      then still extracts the first marker and schedules the download. Flutter
      `MotherlessVideoRipper.videoUrlFromHtml(...)` extracts the same marker
      without emitting that Java-visible diagnostic side effect.
- [x] Java deletes an empty working directory during cleanup.
  - Reconciled: `AbstractRipper.run()` performs the same final, non-recursive
    empty-directory deletion after success or failure, and both GUI and CLI
    execution use that lifecycle wrapper.
- [ ] Java `AbstractHTMLRipper` supports queue-only pages through
      `hasQueueSupport`, `pageContainsAlbums`, and `getAlbumsToQueue`, adding
      discovered album URLs to `MainWindow` queue. Flutter needs verification
      for rippers that depend on this pattern.
- [x] Java exposes dormant `descriptions.save` machinery in
      `AbstractHTMLRipper` through `hasDescriptionSupport`,
      `getDescriptionsFromPage`, `getDescription`, `saveText`, and
      `descSleepTime`, but the source scan found no current concrete ripper
      returning `hasDescriptionSupport() == true`. `FuraffinityRipper`
      implements description helpers and an overridden `saveText`, yet returns
      false.
  - Decision: Flutter intentionally retires this disabled path and preserves
    Java's effective behavior of producing no description files.
- [x] Java `-a` / `--append-to-folder` stores
      `App.stringToAppendToFoldername`, and `AbstractRipper.getFilePath`
      applies it by resolving the working directory to a sibling named
      `<workingDirName><appendString>` before adding subdirectories and file
      names.
  - Reconciled: `AbstractRipper.folderNameSuffix` and `resolveSavePath(...)`
    provide the equivalent path shaping, while `CliController` preserves the
    exact option value. Both behaviors have focused tests.
- [x] Java `AbstractSingleFileRipper` provides byte-progress status text and
      byte-progress percentage behavior for its subclasses: `RulePornRipper`,
      `SpankbangRipper`, `XvideosRipper`, and `YoupornRipper`. The Flutter
      ports now extend the restored `AbstractSingleFileRipper`, with focused
      inheritance, event-order, percentage, and status-text tests.
- [x] Java `SpankbangRipper.getURLsFromPage(...)` returns `null` when
      `.video-js > source` is absent, after logging that the embed code could
      not be found. Flutter `SpankbangRipper.videoUrlsFromDocument(...)`
      preserves that helper-level `null`, and the framework-facing
      `getURLsFromPage(...)` now throws the same missing-embed failure instead
      of converting it to an empty successful extraction.
- [x] Java single-file-style rippers still use `AbstractHTMLRipper.getPrefix(...)`
      when their concrete `downloadURL(...)` calls `addURLToDownload(url,
      getPrefix(index))`, so `download.save_order=false` disables ordered
      prefixes. Flutter `XvideosRipper.prefix(...)`,
      `YoupornRipper.prefix(...)`, and album `YuvutuRipper.prefix(...)`
      unconditionally return `NNN_`; their tests cover only the enabled prefix
      path, so these ports ignore Java's global no-save-order setting.
- [x] Java `XvideosRipper.getURLsFromPage(...)` returns raw
      `div.thumb > a` `href` strings for album pages, and
      `AbstractHTMLRipper.rip()` immediately converts each string with
      `new URI(imageURL).toURL()`. Relative album hrefs therefore fail before
      queueing in Java. Flutter `XvideosRipper.albumUrlsFromDocument(...)`
      still preserves raw hrefs, and `rip()` now uses a Java-style download URI
      conversion that rejects relative sources before building download requests.
- [ ] Java `XvideosRipper.getURLsFromPage(...)` breaks after the first
      `div.thumb > a` album link when `AbstractRipper.isThisATest()` is true.
      Flutter has no shared `markAsTest()` / `isThisATest()` equivalent and
      `albumUrlsFromDocument(...)` always returns every matching thumb link, so
      Java-compatible Xvideos album test-mode limiting is missing.
- [x] Java has package-distinct album and video rippers with duplicate simple
      class names: `rippers/PornhubRipper.java` and
      `rippers/video/PornhubRipper.java`, `rippers/VkRipper.java` and
      `rippers/video/VkRipper.java`, plus `rippers/YuvutuRipper.java` and
      `rippers/video/YuvutuRipper.java`. Flutter now represents each duplicate
      album/video pair with separate Dart routing/tests: `PornhubRipper` /
      `PornhubVideoRipper`, `VkRipper` / `VkVideoRipper`, and `YuvutuRipper` /
      `YuvutuVideoRipper`.
- [x] Java `rippers/video/PornhubRipper.canRip(...)` accepts
      `https?://[wm.]*pornhub.com/view_video.php?viewkey=...` after the album
      package scan fails to match non-album URLs. Flutter now has a separate
      `PornhubVideoRipper` with Java-compatible URL/GID parsing, reconstructed
      quality-variable video URL selection, Java-style quality/viewkey filename
      prefixing, and factory resolution tests.
- [x] Java `rippers/video/YuvutuRipper.canRip(...)` accepts
      `http://www.yuvutu.com/video/ID/SLUG` after the album package scan fails.
      Flutter now has a separate `YuvutuVideoRipper` route with Java-compatible
      URL/GID parsing, iframe/script `file: "..."` extraction, video filename
      prefixing, and factory resolution tests.
- [ ] Java album `YuvutuRipper.getURLsFromPage(...)` adds every
      `div#galleria > a > img` `src` value, including empty strings, and the
      shared `AbstractHTMLRipper.rip()` then converts each candidate with
      `new URI(imageURL).toURL()`. Empty or relative `src` values therefore fail
      immediately in Java. Flutter `YuvutuRipper.imageUrlsFromDocument(...)`
      also preserves empty strings, but `rip()` parses them as relative `Uri`
      download targets and builds `RipperDownload`s, changing the failure point
      and status path for malformed gallery images.
- [x] Java `AbstractRipper(URL)` rejects a candidate constructor whenever that
      class's `canRip(url)` is false before `AbstractRipper.getRipper(...)`
      tries the next album/video class. Flutter `RipperFactory.getRipper(...)`
      now mirrors that dispatch contract by scanning the ordered Dart ripper
      list, catching incompatible constructor/check failures, and returning a
      candidate only after its own `canRip(...)` accepts the URL. Focused tests
      cover strict Java rejects such as unsupported `CliphunterRipper` and
      `BatoRipper` paths.
- [x] The same Flutter factory constructor-guard bypass affected additional
      direct routes whose own Dart `canRip(...)` was stricter than the factory
      host predicate. The route table no longer returns from host predicates;
      every ported candidate is gated by its own `canRip(...)`. During
      implementation, the source check found that some examples previously
      listed here (`HentaifoxRipper`, `FitnakedgirlsRipper`, and several others)
      intentionally remain host-only at constructor time because the Java classes
      inherit `AbstractHTMLRipper.canRip(...)`; their stricter regexes are
      `getGID(...)` validation, not constructor dispatch validation.
- [x] Flutter `RipperFactory.getRipper(...)` also expanded several direct host
      routes by using `host.contains(...)` instead of Java's inherited
      `AbstractHTMLRipper.canRip(...)` `url.getHost().endsWith(getDomain())`
      guard. The factory no longer performs `contains` host dispatch. Focused
      tests cover spoof hosts such as `imgur.com.evil`, `reddit.com.evil`,
      `redgifs.com.evil`, `8muses.com.evil`, and Tumblr-style spoof subdomains
      being rejected by the candidate `canRip(...)` checks.
- [ ] Java dispatch is also host-case-sensitive: `java.net.URL.getHost()`
      preserves uppercase input such as `WWW.DRIBBBLE.COM`, and Java's
      inherited `canRip(...)` compares it with case-sensitive
      `endsWith(getDomain())`. Flutter `RipperFactory.getRipper(...)`
      lowercases `uri.host` before every direct route, and several Dart
      per-ripper `canRip(...)` methods also call `url.host.toLowerCase()`, so
      uppercase-host URLs route in Flutter where Java constructors would reject
      them.
- [ ] Java `Utils.getClassesForPackage(...)` discovers ripper constructors
      differently in filesystem versus packaged-JAR mode. Filesystem mode lists
      only direct `.class` files in the requested package, but JAR mode accepts
      any entry whose path starts with that package path, including
      `com/rarchives/ripme/ripper/rippers/video/*.class` while scanning
      `com.rarchives.ripme.ripper.rippers`. Because `VideoRipper` subclasses
      still extend `AbstractRipper`, packaged Java builds can expose video
      constructors during the first album-ripper pass before the explicit video
      pass. Flutter `RipperFactory` has one fixed hand-written order, so
      overlap/precedence parity for packaged Java dispatch is unproven.
- [x] Java `download.ignore_extensions` suppresses extension-matched URLs with
      `DOWNLOAD_SKIP`; exact match and nonmatch path cases are covered.
- [x] Java `sleep(milliseconds)` applies gaussian jitter with a minimum of 47%
      of requested time.
  - Reconciled: Flutter applies the same mean, 30% standard deviation, integer
    truncation, and minimum clamp through `sleepWithGaussianJitter(...)`, with
    deterministic tests for jitter and clamping.
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

- [x] Java `RipStatusMessage.toString()` renders display labels such as
      `Loading Resource: <value>`.
  - Completed: Flutter maps every shared status to the exact Java display label;
    its Flutter-only queue event uses `Queue Add`.
- [ ] Java status enum includes `NO_ALBUM_OR_USER`; Flutter still lacks that
      status. `DOWNLOAD_COMPLETE_HISTORY`, `TOTAL_BYTES`, and
      `COMPLETED_BYTES` are now represented.
- [ ] Java `RipStatusComplete` carries directory and count. Flutter history
      updates from `ripComplete` need exact count/directory parity.
- [ ] Java `MainWindow.handleEvent(...)` applies status-specific UI side effects
      that Flutter has not matched exactly: every non-stopped event first sets
      progress from `ripper.getCompletionPercentage()`, shows the progress bar,
      and displays `ripper.getStatusText()`; log append behavior is gated by the
      configured log level and Java colors (`BLACK`, `GREEN`, `RED`, `ORANGE`,
      `YELLOW`); `RIP_ERRORED` and `NO_ALBUM_OR_USER` both hide the open button,
      reset/hide progress, disable Stop, and set `Error: <object>`; and
      `RIP_COMPLETE` updates/adds a Java `HistoryEntry`, optionally plays
      `camera.wav`, saves history, hides progress, shows the open button as
      localized `open` plus `Utils.shortenPath(...)`, resets the title, and then
      may run the configured finish command. Flutter `RipManager` derives
      progress counters from observed log events and sets simpler status text,
      so the full Java status/UI contract needs parity tests or documented
      retirement.
- [ ] Java does not append duplicate album-history rows on repeated completion
      for the same source URL: GUI `MainWindow.handleEvent(...)` calls
      `HISTORY.containsURL(url)`, updates the existing entry's `count` and
      `modifiedDate`, and only creates a new `HistoryEntry` when the URL is
      absent; CLI/headless `App.rip(...)` uses the same URL lookup and updates
      the existing entry's `modifiedDate` instead of appending. Flutter
      `RipManager._addToHistory(...)` currently inserts a new `HistoryEntry` at
      index 0 for every `ripComplete`, so repeated rips of the same URL can
      duplicate history rows instead of following Java's update-in-place
      behavior.
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
- [~] Java tray icon, popup notifications, and open-folder button are desktop
      behaviors that need per-platform Flutter verification or documented
      replacements. The Java implementation uses `SystemTray`, `TrayIcon`,
      `TrayIcon.displayMessage`, tray About/Hide/Show/Exit/Autorip menu items,
      and `Desktop.getDesktop().open(...)` / `.browse(...)`.
  - Tray icon/menu, popup notification, and completion open-folder parity are
    implemented for Windows, Linux, and macOS.
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
- [x] Java stop action calls `ripper.stop()`, clears progress, disables stop,
      sets localized interrupted status, and appends `Download interrupted` to
      the log.
  - Completed: `RipManager.stop()` stops the active ripper, marks ripping false
    (disabling the bound stop control), clears progress counters, sets
    `Download interrupted`, and appends the same text to the log. Active
    streamed transfers also terminate between chunks with that error text.
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
- [x] Java completion sound is `camera.wav`; the Java blob
      `src/main/resources/camera.wav` is carried forward byte-identically as
      `assets/sounds/camera.wav` and played through the native `audioplayers`
      implementations on every supported platform.
- [x] Java logging file output is `ripme.log`, with rolling `ripme.%i.log.gz`
      output and a 20 MB size policy in log4j2. Flutter writes the same active
      filename and maintains `ripme.1.log.gz` and `ripme.2.log.gz`; tests use an
      injected small limit to prove compression and rollover deterministically.
- [x] Java icon assets include `icon.ico`, `icon.png`, and toolbar PNGs
      (`comment`, `folder`, `gear`, `list`, `stop`, `time`, `wrench`).
      All source assets are carried forward byte-identically under `assets/`;
      Windows embeds the exact Java ICO, while Android, macOS, and Linux use
      tested transparent derivatives of Java branding at native dimensions.
- [x] `pubspec.yaml` packages `src/main/resources/`, `assets/`, and
      `LICENSE.txt`. CI verifies every relocated user-facing binary resource,
      all Java label bundles, platform license declarations, and exact inherited
      MIT license bytes.
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
- [x] Add Dart tests for Java proxy string parsing for HTTP and SOCKS, even if
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
- [x] Java duplicate-download override is verified:
      `ImgurRipper.allowDuplicates` permits duplicate media URLs for user rips.
- [x] Java duplicate suppression is not disabled for `EightmusesRipper` or
      `TsuminoRipper`: neither class overrides `allowDuplicates()`, so their
      `addURLToDownload(...)` calls still use the shared pending/completed/
      errored URL maps.
  - Corrected: Flutter no longer treats Java's final
    `getFileExtFromMIME=true` call argument as `allowDuplicate=true`.
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
- [ ] Disabled Java `DeviantartRipperTest.testSanitizeURL` asserts that
      `https://www.deviantart.com/airgee`, `/airgee/`, and `/airgee/gallery/`
      all sanitize to `https://www.deviantart.com/airgee/gallery/`, but current
      Java `DeviantartRipper` does not override `sanitizeURL(...)` and inherits
      the identity implementation from `AbstractHTMLRipper`. Flutter should not
      treat this disabled assertion as current Java behavior until the stale test
      expectation is reconciled against source.
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
- [ ] Java `FuraffinityRipper.getURLsFromPage(...)` stops after the first
      gallery post when `AbstractRipper.isThisATest()` is true, because the loop
      breaks on `isStopped() || isThisATest()`. Flutter has no shared
      `markAsTest()` / `isThisATest()` path and iterates every post returned by
      `postUrlsFromPage(...)`, so Java-compatible FurAffinity test-mode crawl
      limiting is missing.
- [ ] Java `FuraffinityRipper.setCookies(...)` parses
      `furaffinity.cookies` through shared `RipUtils.getCookiesFromString(...)`
      and sends `DOWNLOAD_ERRORED` when the configured value equals the bundled
      shared account cookie string. Flutter reimplements cookie parsing locally
      in `FuraffinityRipper.parseCookies(...)`, so it needs proof that malformed
      cookie strings, repeated keys, whitespace, and empty values match the
      Java helper exactly before login/cookie parity can be claimed.
- [x] Java `FuraffinityRipper` overrides `hasDescriptionSupport()` to `false`
      but still implements `getDescriptionsFromPage(...)`, `getDescription(...)`,
      `descSleepTime()`, and `saveText(...)` with FurAffinity-specific title
      rewriting and text cleanup.
  - Decision: no Dart pipeline is added because the Java support flag makes
    every helper unreachable. Source scan evidence and the retired UI control
    lock this as intentional parity.
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
- [ ] Java sorted `ScrolllerRipper.getPostsSorted(...)` uses a
      Java-WebSocket subscription, stores every message string, and then
      blindly reads `postsJsonStrings.get(postsJsonStrings.size() - 1)` to build
      the iterator object. An empty WebSocket stream or a stream that closes
      before a message therefore fails through Java collection/JSON access,
      while Flutter `getPostsSorted(...)` returns a non-null object with
      `iterator: null` and an empty `posts` list. The sorted-request empty
      stream and malformed-message behavior needs Dart coverage separate from
      the unsorted GraphQL malformed-structure row above.
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
- [ ] Java `SankakuComplexRipper.downloadURL(...)` sleeps 8000 ms immediately
      before calling `addURLToDownload(...)`, so each discovered high-res URL is
      throttled and queued through the normal Java download-thread path one at a
      time. Flutter waits eight seconds inside `rip()` while collecting each
      page's `RipperDownload`s, then starts `downloadFiles(...)` only after the
      page batch has been built. The URL list can match while Java's throttling
      and queue-start timing do not.
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
- [ ] Java `EHentaiRipper.downloadURL(...)` queues an `EHentaiImageThread` into
      its dedicated `DownloadThreadPool` for each gallery image page, sleeps
      1500ms after queueing, and each worker schedules the final image download
      as soon as it resolves the image URL. Flutter `EHentaiRipper.rip()`
      awaits `downloadFromImagePage(...)` serially for every gallery entry,
      sleeps after each fetch, collects all resolved `RipperDownload`s, and only
      then calls `downloadFiles(...)`. E-Hentai image-page lookup, failure
      isolation, and final-download start timing are therefore not Java
      equivalent.
- [ ] Java `EHentaiRipper.getAlbumTitle(...)` returns
      `"e-hentai_" + elems.first().text()` whenever `#gn` exists, even when the
      title text is empty, yielding `e-hentai_`. Flutter
      `EHentaiRipper.getAlbumTitle(...)` treats missing or empty `#gn` text as
      a fallback case and returns the inherited `e-hentai_GID`, so empty-title
      gallery pages no longer match Java's working-directory name.
- [ ] Java `ImagebamRipper.getURLsFromPage(...)` selects
      `div > a[class=thumbnail]:not(.footera)`, which requires the `class`
      attribute to be exactly `thumbnail` before the `:not(.footera)` filter.
      Flutter uses `div > a.thumbnail:not(.footera)`, so links with additional
      non-`footera` classes are included by Flutter but skipped by Java.
- [ ] Java `ImagebamRipper.getURLsFromPage(...)` adds `thumb.attr("href")`
      for every matched thumbnail, including missing or empty `href`
      attributes; those empty strings are then handed to
      `ImagebamImageThread` for URL conversion/logging. Flutter
      `imagePageUrlsFromDocument(...)` filters empty `href` values before the
      image-page step, so malformed thumbnail anchors are silently dropped.
- [ ] Java `ImagebamRipper.getAlbumTitle(...)` reads `[id=gallery-name]` from
      `getCachedFirstPage()`, so title lookup and the later rip loop share the
      same first-page response. Flutter `ImagebamRipper.getAlbumTitle(...)`
      performs a fresh `Http.get(url)` during setup, so request counts, cookies,
      and working-directory names can diverge when the setup fetch and rip fetch
      return different content.
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
- [ ] Java `PicstatioRipper.getNextPage(...)` checks
      `doc.select("a.next_page") != null`, which is always true for jsoup's
      `Elements`, then fetches `https://www.picstatio.com` plus the selected
      `href` before returning; an absent next link therefore still attempts the
      site root and request failures escape through the HTML loop. Flutter
      `PicstatioRipper.nextPageUrl(...)` only returns the constructed URI
      (`https://www.picstatio.com` when absent) and `rip()` later catches fetch
      failures as quiet pagination completion.
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
- [ ] Java `WordpressComicRipper.getURLsFromPage(...)` handles
      `freeadultcomix.com` only through the jsoup selector
      `div.post-texto > p > noscript > img[class*=aligncenter]`, adding each
      matched element's `src` directly. Flutter runs the same outer selector
      and then additionally parses every matching `noscript` element's text as
      HTML to find nested `img[class*=aligncenter]` entries, which can discover
      or duplicate image URLs that Java's current source would not schedule.
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
- [ ] Java `FapDungeonRipper.downloadURL(...)` sleeps 1000 ms and then queues
      the URL through `addURLToDownload(url, getPrefix(index))`, preserving the
      shared Java download-thread behavior after the throttle. Flutter
      `FapDungeonRipper.rip()` sleeps before each item and then awaits
      `downloadFile(...)` directly, making FapDungeon serial per-file downloads
      instead of Java's queued worker path.
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
- [ ] Java `PahealRipper.getNextPage(...)` only follows paginator anchors whose
      text `equalsIgnoreCase("next")` without trimming, then immediately fetches
      `e.absUrl("href")` with the age-gate cookie map. Flutter
      `PahealRipper.nextPageUrlFromPage(...)` trims the link text, returns a URI
      instead of fetching, and returns `null` for missing/empty `href`, so
      whitespace-padded labels and malformed next links no longer follow Java's
      exact pagination/failure path.
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
- [ ] Java non-tag `MrCongRipper.getFirstPage(...)` builds the root gallery URL
      with `url.toExternalForm().replaceAll("(|/|/[0-9]+/?)$", "/")`. Because
      the empty alternative can match at the end, Java turns
      `https://misskon.com/gallery/` and paged URLs such as
      `https://misskon.com/gallery/2/` into `https://misskon.com/gallery//`.
      Flutter `MrCongRipper.rootGalleryUrl(...)` removes the page segment and
      collapses the result to one trailing slash, so first-page fetch URLs are
      not Java-compatible for those inputs.
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
- [x] Java `HentaifoxRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any
      host ending in `hentaifox.com` is accepted before `getGID(...)` checks the
      strict `https://hentaifox.com/gallery/ID` shape. Flutter
      `HentaifoxRipper.canRip(...)` directly uses the strict gallery regex,
      narrowing Java's domain-level support. Flutter now uses Java's host suffix
      check while keeping strict `getGID(...)` parsing, with Dart coverage for
      both behaviors.
- [x] Java `HentaifoxRipper.getAlbumTitle(...)` derives the title from
      `getCachedFirstPage().select("div.info > h1").first().text()` and returns
      `hentaifox__GID` when the selected `h1` exists but has empty text.
      Flutter `HentaifoxRipper.getAlbumTitle(...)` fetches the page again
      during setup and `albumTitleFromPage(...)` treats missing or empty title
      text as `null`, falling back to `hentaifox_GID`; cached-response and
      empty-title working-directory parity were added with Dart tests.
- [x] Java `HypnohubRipper.ripPost(...)` uses
      `doc.selectFirst("a:matchesOwn(^Original image$")`, a malformed jsoup
      selector, for the Original-image fallback in both string and document
      variants. Flutter `HypnohubRipper.imageUrlFromPostDocument(...)` instead
      scans `a[href]` text and successfully supports the Original-image fallback,
      so post pages without `img#image` no longer follow Java's selector-failure
      behavior. Flutter now evaluates the same malformed selector after
      `img#image` misses, with Dart tests covering Original-image and
      `og:image` documents.
- [ ] Java `HypnohubRipper.ripPost(...)` logs
      `No image found on post page...` / `No image found in document...` when
      all image selectors fail, and pool rips log `Failed to rip post...` for
      per-post `IOException`s before continuing. Flutter returns `null` or
      catches the fetch failure with a comment-only silent skip, so those
      Hypnohub missing-image and per-post failure diagnostics disappear from the
      Java-compatible log/status surface.
- [x] Java `MultpornRipper.getGID(...)` may rewrite the instance `url` to the
      canonical `/node/ID/...` simple-mode URL, and `downloadURL(...)` passes
      that `this.url.toExternalForm()` as the download referrer via
      `addURLToDownload(...)`. Flutter uses the canonical URL for loading the
      page, but its `RipperDownload` path does not carry Java's canonical
      Multporn referrer into each image download. Flutter now attaches the
      canonical source URL as the `Referer` header for each image download, with
      Dart coverage for the generated download request.
- [x] Java `PorncomixRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any
      host ending in `porncomix.info` is accepted before `getGID(...)` checks
      the strict `www.porncomix.info/SLUG` pattern. Flutter
      `PorncomixRipper.canRip(...)` directly uses the strict GID regex,
      narrowing Java's domain-level support. Flutter now uses Java's host suffix
      check while keeping strict `getGID(...)` parsing, with Dart coverage for
      both behaviors.
- [x] Java `ShesFreakyRipper` and `TsuminoRipper` inherit
      `AbstractHTMLRipper.canRip(...)`, so any host ending in
      `shesfreaky.com` or `tsumino.com` is accepted before their strict
      `getGID(...)` regexes run. Flutter `ShesFreakyRipper.canRip(...)` and
      `TsuminoRipper.canRip(...)` use those strict regexes directly; additionally,
      `RipperFactory` only routes exact `www.tsumino.com` hosts and constructs
      `TsuminoRipper` without calling its `canRip(...)`, so Tsumino dispatch does
      not match Java's domain-level constructor guard. Flutter now uses Java's
      host suffix checks for both rippers, keeps strict `getGID(...)` parsing,
      and routes Tsumino suffix hosts through `RipperFactory`, with Dart coverage
      for those paths.
- [x] Java `ReadcomicRipper` and `ViewcomicRipper` inherit
      `AbstractHTMLRipper.canRip(...)`, so any host ending in `read-comic.com`
      or `view-comic.com` is accepted before their strict slug-only
      `getGID(...)` regexes run. Flutter `ReadcomicRipper.canRip(...)` and
      `ViewcomicRipper.canRip(...)` use those strict regexes directly. Flutter
      now uses Java's host suffix checks for both rippers while keeping strict
      `getGID(...)` parsing, with Dart coverage for suffix-host acceptance and
      strict parse rejection.
- [x] Java `ReadcomicRipper.getURLsFromPage(...)` and
      `ViewcomicRipper.getURLsFromPage(...)` add each selected image `src`,
      including the empty string when `src` is absent. Flutter helpers return
      the same empty strings, but both `rip()` implementations skip empty image
      URLs before scheduling downloads, removing Java's empty-URL download path.
      Flutter now passes empty image URLs into the download queue for both
      rippers, with Dart harness coverage proving missing `src` values are not
      filtered out.
- [x] Java `ViewcomicRipper.getAlbumTitle(...)`, inherited by
      `ReadcomicRipper`, only catches `IOException`; a cached page with no
      `<title>` element can null-dereference at `.first().text()`. Flutter
      title extraction treats a missing `<title>` as an empty string and returns
      `view-comic_`/`read-comic_` rather than surfacing Java's failure. Flutter
      now only falls back on `IOException` and lets missing-title failures
      surface, with Dart coverage for both rippers.
- [x] Java `ArtstnRipper.getFinalUrl(...)` follows `location` redirects by
      constructing `new URI(response.header("location")).toURL()`, so relative
      redirect locations fail URL conversion instead of being resolved against
      the short URL. Flutter `ArtstnRipper.redirectTarget(...)` uses
      `source.resolve(location)`, so relative ArtStation short-link redirects
      are accepted rather than following Java's failure path. Flutter now rejects
      relative redirect targets and keeps Dart coverage for the failure path.
- [x] Java `ArtstnRipper.getGID(...)` logs redirect-resolution failures and then
      calls `super.getGID(artStationUrl)` even if `artStationUrl` is still
      `null`, allowing the Java failure to surface through the superclass/null
      path. Flutter throws `FormatException('Could not resolve ArtStation short URL...')`
      as soon as the final URL is unresolved, changing the observable error.
      Flutter now lets unresolved short URLs surface through its null path, with
      Dart coverage for that Java-compatible failure behavior.
- [x] Java `FemjoyhunterRipper` inherits `AbstractHTMLRipper.canRip(...)`, so
      any host ending in `femjoyhunter.com` is accepted before `getGID(...)`.
      Flutter `FemjoyhunterRipper.canRip(...)` requires a `www.femjoyhunter.com`
      URL that matches the GID regex, narrowing Java's domain-level acceptance.
      Flutter now uses Java's host suffix `canRip(...)`, with Dart coverage for
      suffix-host acceptance and strict GID rejection.
- [x] Java `FemjoyhunterRipper.getGID(...)` uses `Matcher.matches()` with
      `https?://www.femjoyhunter.com/SLUG/?`, so the whole URL must match.
      Flutter uses `RegExp.hasMatch`/`firstMatch` with the same unanchored
      pattern, accepting longer URLs whose prefix matches where Java would throw.
      Flutter now anchors the GID regex and covers longer-path rejection in Dart.
- [x] Java `FitnakedgirlsRipper` inherits `AbstractHTMLRipper.canRip(...)`, so
      any host ending in `fitnakedgirls.com` is accepted before its gallery
      regex runs. Flutter `FitnakedgirlsRipper.canRip(...)` requires the strict
      `/photos/gallery/...` pattern up front, narrowing Java's URL acceptance.
      Flutter now uses Java's host suffix check while keeping strict
      `getGID(...)` parsing, with Dart coverage for accepted invalid paths and
      strict GID rejection.
- [x] Java `XcartxRipper` and `XlecxRipper` inherit domain-level
      `AbstractHTMLRipper.canRip(...)`, then rely on `getGID(...)` to reject
      non-matching `.html` pages. Flutter also uses domain-level `canRip(...)`,
      but Dart `XcartxRipper.getGID(...)` anchors and escapes `.html` more
      strictly than Java's `^https?://xcartx.com/SLUG.html` `matches()` pattern,
      changing which xcartx URLs are rejected at GID time.
      Flutter now preserves Java's full-match behavior while keeping the
      unescaped-dot `SLUG.html` quirk, with Dart coverage for slash-as-dot
      acceptance and trailing-extra rejection.
- [x] Java `XlecxRipper` inherits `XcartxRipper.getURLsFromPage(...)`, whose
      image URL construction calls virtual `getDomain()`, so Xlecx image URLs
      are prefixed with `https://xlecx.org`. Flutter `XlecxRipper` inherits
      Dart `XcartxRipper.imageUrlsFromDocument(...)`, which hard-codes
      `https://xcartx.com`, so Xlecx downloads are pointed at the wrong host.
      Flutter now lets the shared extraction helper receive the virtual domain,
      and Xlecx Dart coverage verifies inherited URLs use `https://xlecx.org`.
- [x] Java `ChanRipper.getURLsFromPage(...)` sends non-self-hosted links through
      `RipUtils.getFilesFromURL(...)`, which expands redgifs/gifdeliverynetwork
      pages, preserves `v.redd.it` URLs, handles `i.reddituploads.com`, and
      returns generic direct media URLs in addition to Imgur, Vidble, Erome, and
      Soundgasm. Flutter `ChanRipper` delegates that branch to
      `RedditRipper.expandNonDirectUrl(...)`, which currently covers only the
      latter subset, so several Java-expanded Chan links now disappear.
      Flutter now preserves Java's zero-network passthrough cases for
      `v.redd.it`, `i.reddituploads.com`, and generic direct
      `jpg/jpeg/gif/png/mp4` URLs, with shared Reddit helper coverage and
      Chan explicit-archive coverage. Re-reading `origin/main` showed that
      Java enters the Redgifs branch for both `redgifs.com` and
      `gifdeliverynetwork.com`, but `RedgifsRipper.getVideoURL(...)` only
      matches `redgifs.com/watch/...`; gifdeliverynetwork therefore returns an
      empty list through Java's caught exception path. Flutter now mirrors that
      by expanding Redgifs singleton pages through the Redgifs API helper and
      preserving the current-source empty gifdeliverynetwork helper behavior,
      with fake-API Dart coverage for Reddit shared expansion and Chan
      explicit-archive extraction.
- [x] Java `ChanRipper.canRip(...)` accepts baked-in or configured chan domains
      without validating a board/thread path, and `getHost()` later reads
      `this.url.toExternalForm().split("/")[3]`. A bare accepted domain can
      therefore fail with the Java split/index behavior. Flutter
      `ChanRipper.getHost()` uses `url.pathSegments.isNotEmpty ? first : ''`,
      returning an empty board instead of matching the Java malformed-path
      failure. Flutter now derives the board from a Java-style slash split
      after dropping trailing empty pieces, with Dart coverage for normal board
      extraction and bare-domain/trailing-slash `RangeError` behavior.
- [x] Java `ChanRipper` parses `chans.chan_sites` into the static
      `user_give_explicit_domains` field at class-load time and then
      `canRip(...)` appends that frozen list into the static `explicit_domains`
      collection. Flutter `ChanRipper.explicitDomains()` calls
      `Utils.getConfigString('chans.chan_sites', null)` and reparses on every
      lookup, so config changes after first Java class load are visible in
      Flutter but not Java, and repeated Java `canRip(...)` calls mutate a
      shared static list while Dart rebuilds a fresh one. Flutter now caches
      configured Chan sites on first explicit-domain lookup, including the
      absent-config case, and appends into a shared static list on every lookup,
      with Dart coverage for frozen config changes and repeated-list growth.
- [x] Java `ChanSite` constructors throw `IllegalArgumentException("Domains")`
      when the selected constructor receives an empty domain string/list and
      `IllegalArgumentException("CdnDomains")` when it receives an empty CDN
      list/string. Re-reading `origin/main` corrected an audit overstatement:
      `[]` and empty comma segments fail during config parsing, but `site[]`
      is accepted by `ChanRipper.getChansFromConfig(...)` because Java passes a
      one-element CDN list containing `""`. Flutter now throws `ArgumentError`
      with Java-compatible messages for empty domain/list constructor cases and
      empty config domain entries, while preserving the current-source
      `site[] -> [""]` CDN behavior with Dart coverage.
- [x] Java `NsfwXxxRipper.getNextPage(...)` strictly reads
      `doc.getInt("page")`, requires `nextPage.getJSONArray("items")`, and
      throws `IOException("No more pages")` when that array is empty. Flutter
      returns `null` when `page` is absent/non-integer or when `items` is
      absent/empty, and `entriesFromJson(...)` returns an empty list when the
      first page has no `items`. This changes malformed JSON and no-next-page
      behavior into nullable completion instead of Java's exception contracts.
      Flutter now requires an integer `page`, requires next-page `items` to be
      a list, throws a dedicated `No more pages` exception for empty next-page
      items, and keeps that no-more-pages exception as a normal pagination stop
      in `parseJSON(...)`, with fake-API Dart coverage.
- [x] Java `NsfwXxxRipper.getURLsFromJSON(...)` maps every array element with
      `items.getJSONObject(i)`, requires `author` and `title` via
      `getString(...)`, and when `src` is absent requires the video `html`
      field to contain a `src="..."` match before `matches.group(1)` is read.
      Flutter `entriesFromJson(...)` skips non-map entries, converts missing
      `author`/`title` to the literal string `"null"` through `.toString()`,
      and then stores those titles in `descriptions` for filename prefixes.
      Malformed item handling and title-to-download alignment are therefore not
      proven Java-compatible. Flutter now requires `items` to be present as a
      list, requires every item to be an object, requires `author` and `title`,
      and requires `html` plus a `src="..."` match when `src` is absent, with
      Dart coverage for the Java-compatible failure paths.
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
- [x] Java `TsuminoRipper.downloadURL(...)` sleeps, then schedules each
      `Image/Object?name=...` URL with `getPrefix(index)` and
      `getFileExtFromMIME=true`, explicitly relying on the downloader to choose
      the saved extension because Tsumino object URLs do not contain one.
  - Reconciled: Flutter applies the Java gaussian one-second sleep, keeps the
    `NNN_Object` / `Object` base name, passes the page referrer and cookies, and
    opts into shared stream-signature extension detection.
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
- [ ] Java `NatalieMuRipper.getURLsFromPage(...)` checks `isThisATest()` inside
      the thumbnail loop and stops after the first matching gallery image in
      Java test mode; it also checks `isStopped()` while parsing the page.
      Flutter `NatalieMuRipper.imageUrlsFromDocument(...)` is a static full-page
      extractor with no test-mode limit and no stopped-rip check, so
      Java-compatible test limiting and parser-time stop behavior are not
      preserved.
- [ ] Java `NsfwAlbumRipper.getURLsFromPage(...)` writes
      `<n> elements (thumbnails) found.` to stdout before URL conversion.
      Flutter `NsfwAlbumRipper.imageUrlsFromDocument(...)` has no matching
      stdout, log, or status diagnostic, so source-visible CLI/debug output
      parity is missing for this ripper.
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
- [x] Java `EightmusesRipper.getURLsFromPage(...)` schedules discovered picture
      tiles immediately through `addURLToDownload(..., getPrefixShort(i), "",
      null, true)`, so the downloader uses `getFileExtFromMIME=true` and can
      replace the saved extension from response content/magic-number detection.
  - Reconciled: Eightmuses download metadata now opts into the shared
    stream-signature detector while preserving its Java referrer, cookies,
    subdirectory, and short prefix.
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
- [ ] Java `EromeRipper.getAlbumTitle(...)` treats a present
      `meta[property=og:title]` with a missing/empty `content` attribute as a
      valid title: Jsoup `attr("content")` returns `""`, `substring(...)`
      succeeds, and the folder name becomes `erome_<gid>_` with a trailing
      underscore. Flutter checks the nullable `content` attribute and returns
      `erome_<gid>` when it is absent, so malformed Erome title metadata changes
      the working-directory name.
- [ ] Java `GirlsOfDesireRipper.getAlbumTitle(...)` first tries `.albumName`,
      but if that selector is absent it falls through to
      `AbstractRipper.getAlbumTitle(...)`; the inherited call then uses Java's
      broken `getGID(...)` regex against `url.toExternalForm()` and throws for
      normal `http://www.girlsofdesire.org/galleries/.../` URLs. Flutter fixed
      the URL regex, so the same missing-title page falls back to
      `GirlsOfDesire_<gid>` instead of Java's setup-time failure.
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
- [ ] Java album `VkRipper.getURLsFromJSON(...)` for `/videos...` strictly reads
      `page.getJSONArray("all")`, then `videos.getJSONArray(i)` and
      `jsonVideo.getInt(1)` for every row. If resolving one video's page throws
      `IOException`, Java logs `Error while ripping video id: <id>` and returns
      the URLs collected so far. Flutter `VkRipper.videoUrlsFromJsonPage(...)`
      returns an empty list when `all` is absent/non-list, skips malformed rows,
      coerces IDs through `_toInt(...)`, and propagates `getVideoURLAtPage(...)`
      failures, so malformed video JSON and per-video fetch failures are not
      Java-compatible.
- [ ] Java album `VkRipper.downloadURL(...)` for video-list rips calls
      `addURLToDownload(...)` first and only then sleeps 500 ms before the next
      video URL is scheduled. Flutter `_ripVideos()` builds a list of
      `RipperDownload`s, waits 500 ms after each list append, and starts
      `downloadFiles(...)` only after all video URLs are resolved, changing the
      Java queue-start/throttle timing.
- [ ] Java `VkRipper.getPage(...)` collects photo IDs in a `HashSet`, then
      iterates that set when fetching each photo JSON object, so album image
      request/download order is hash-set dependent rather than document order.
      Flutter `VkRipper.photoIdsFromAnchors(...)` uses Dart's insertion-ordered
      set and returns IDs in page order, changing Java's ordering behavior.
- [ ] Java `VkRipper.getNextPage(...)` stops pagination immediately when
      `AbstractRipper.isThisATest()` is true, returning `null` before calling
      `getPage()`. Flutter has no shared `markAsTest()` / `isThisATest()`
      equivalent for VK and `_ripImages()` keeps paginating until the remote
      response has no `<div>` or no images, so Java-compatible VK test-mode
      limiting is missing.
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
- [ ] Java `TumblrRipper.getApiKey()` first checks
      `AbstractRipper.isThisATest()` and returns the dedicated test key
      `UHpRFx16HFIRgQjtjJKgfVIcwIeb71BYwOQXTMtiCvdSEPjV7N` before reading
      config or choosing a random default key. Flutter has no shared
      `markAsTest()` / `isThisATest()` equivalent for Tumblr and uses the
      normal configured/default-key path in tests, so Java-compatible Tumblr
      test authentication behavior is missing.
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
- [ ] Java `NfsfwRipper.downloadURL(...)` starts a `NfsfwImageThread` in the
      dedicated `DownloadThreadPool` for each image page; the worker fetches the
      image page with `Http.url(this.url).referrer(this.url).get()`, logs
      missing `.gbBlock img` or parse failures, and schedules the final image
      download immediately via `addURLToDownload(...)`. Flutter resolves image
      pages serially in `rip()`, catches image-page fetch failures as `null`,
      collects `RipperDownload`s, and only then calls `downloadFiles(...)`.
      NFSFW image lookup concurrency, logging, failure isolation, and final
      download start timing are not Java-equivalent.
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
- [ ] Java `XhamsterRipper.getNextPage(...)` first checks for any
      `a.prev-next-list-link`, then immediately dereferences
      `a.prev-next-list-link--next`. If the generic previous/next link exists
      but the next-specific link is absent, Java throws via that dereference;
      if the next href exists but does not start with `http`, Java falls through
      to `IOException("No more pages")`. Flutter `nextPageUrl(...)` returns
      `null` for both cases, converting Java failure/end-state behavior into
      normal pagination completion.
- [ ] Java `XhamsterRipper.getURLsFromPage(...)` old-gallery handling fetches
      each `.clearfix > div > a.slided` page and adds
      `select("a > img#photoCurr").attr("src")` even when that selector is
      missing, producing an empty-string download attempt through
      `downloadFile("")` and logging only malformed URL failures there. Flutter
      `imageFromOldImagePage(...)` returns `null` for missing/empty `src` and
      skips the item, so malformed old gallery pages no longer exercise Java's
      empty-download/logging path.
- [x] Java downloaded-URL history normalization is per-ripper:
      `AbstractRipper.normalizeUrl(...)` returns the original URL unchanged,
      while `ArtStationRipper` strips only a terminal `?\w+` suffix and
      `DeviantartRipper` replaces the URL with `urlWithParams(offset)`.
      Flutter now preserves the base URL unchanged and routes both history
      lookup and writes through overridable `AbstractRipper.normalizeUrl(...)`.
      Validation: `download_history_provider_test.dart` and
      `abstract_ripper_download_test.dart`.
- [x] Java `ArtStationRipper.normalizeUrl(...)` uses the narrow regex
      `url.replaceAll("\\?\\w+$", "")`, so query strings containing `=`, `&`,
      or non-word characters are preserved in downloaded-URL history. Flutter's
      Flutter now applies the same terminal-query regex while preserving query
      strings containing `=`, `&`, or non-word characters. Validation:
      `artstation_ripper_test.dart`.
- [x] Java `DeviantartRipper.normalizeUrl(...)` records
      `urlWithParams(this.offset).toExternalForm()` for every downloaded URL,
      tying history entries to the ripper's current pagination offset instead
      of the actual downloaded deviation URL. Flutter records the media URL
      through the ripper's current `urlWithParams(offset)` value. Validation:
      `deviantart_ripper_test.dart`.
  - CI: [run 27485761691](https://github.com/pantelb/ripme/actions/runs/27485761691)
    passed with
    [Android](https://github.com/pantelb/ripme/actions/runs/27485761691/artifacts/7616653436),
    [Windows](https://github.com/pantelb/ripme/actions/runs/27485761691/artifacts/7616641993),
    [macOS](https://github.com/pantelb/ripme/actions/runs/27485761691/artifacts/7616636704),
    and
    [Linux](https://github.com/pantelb/ripme/actions/runs/27485761691/artifacts/7616629443)
    artifacts.
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
- `settings.gradle.kts`
- `gradle/wrapper/gradle-wrapper.properties`
- `gradle/wrapper/gradle-wrapper.jar`
- `gradlew`
- `gradlew.bat`
- `.github/workflows/gradle.yml`
- `.github/workflows/run-flutter-release.yml`
- `ripme.json`
- `.gitignore`
- `README.md`
- `src/main/java/com/rarchives/ripme/ui/UpdateUtils.java`

Flutter files checked:

- `pubspec.yaml`
- `.github/workflows/release.yml`
- Android, Linux, macOS, and Windows platform metadata files
- `README.md`

Findings:

- [x] Java derives build versions with `jgitver` from tag/base version/commit
      metadata and embeds `Implementation-Version` in the jar manifest. Flutter
      uses a semantic release tag as its cross-platform app version and the
      immutable Actions run number as its native/Dart build identity. CI guards
      local defaults and release injection across platform metadata.
- [x] Java README documents semantic version strings with commit count, short
      SHA, and branch suffix. Flutter documents its native-compatible semantic
      release tag plus numeric Actions build identity and no longer claims
      unconditional complete parity while this audit remains open.
- [x] Java CI builds a fat jar on Linux, Windows, and macOS and uploads the Java
      17 Ubuntu jar artifact. Flutter release CI builds Android APK/AAB,
      Windows, macOS, and Linux artifacts. This is a documented platform
      expansion: release files preserve Java's version-first prefix and add the
      native target/format rather than pretending to be jar-name equivalents.
- [x] Java release automation creates/updates prereleases named
      `latest-<branch-slug>` with jar artifacts. Flutter release automation
      publishes tag-driven releases through `softprops/action-gh-release`.
      Mutable branch releases are intentionally retired: read-only CI uploads
      per-run native artifacts, while only explicit tag/manual release runs can
      write repository releases.
- [x] `origin/main` also contains `.github/workflows/run-flutter-release.yml`,
      a manual `workflow_dispatch` wrapper that accepts `tag`, `build_ref`,
      `draft`, and `prerelease` inputs and calls
      `pantelb/ripme/.github/workflows/release.yml@Flutter`. The wrapper is now
      carried on the Flutter branch with the same inputs and permissions.
- [ ] Java root developer scripts are part of the source workflow:
      `build.sh` and `build.bat` both run `./gradlew clean build -x test`, while
      `remote-branch.sh` and `remote-merge.sh` add a user remote, fetch a branch,
      create a local `<user>-<branch>` branch, and optionally merge it into
      `origin/main`. Flutter has no equivalent root helper scripts or documented
      replacement workflow, so contributor/build workflow parity is not fully
      accounted for.
- [ ] Java includes a root Gradle wrapper pinned by
      `gradle/wrapper/gradle-wrapper.properties` to Gradle `8.10.2` plus
      `gradlew` / `gradlew.bat` entrypoints. Flutter has Android-scoped Gradle
      wrapper metadata pinned to Gradle `8.14` and no root Gradle wrapper, so
      Java build-tool bootstrap behavior must be recorded as retired or replaced
      by Flutter tooling rather than silently disappearing.
- [ ] Java `.gitignore` explicitly protects app/runtime artifacts such as
      `ripme.log`, `rips/`, `.history`, `ripme.jar.update`, `history.json`,
      generated jars/archives, and keeps `LabelsBundle*.properties` tracked
      despite `*.properties`-style resource handling. Flutter `.gitignore` is a
      generic Flutter ignore file and does not explicitly cover several
      Java-era runtime outputs, so source hygiene for generated rip/config/update
      artifacts needs a migration-specific decision.
- [ ] Java build excludes `flaky` and `slow` JUnit tags by default and exposes
      `testAll`, `testFlaky`, `testSlow`, and `testTagged` Gradle tasks.
      Flutter currently runs one `flutter test` suite. Dart test metadata needs
      an equivalent policy for network/slow/flaky parity tests.
- [ ] Java docs require contributors to run source-compatible targeted tests
      such as `testAll --tests XhamsterRipperTest.testXhamster2Album`.
      Flutter README needs migration-specific test instructions that include
      `flutter analyze --no-pub`, targeted tests, and expanded reporter full
      suite.
- [x] Java updater reads `ripme.json`, compares versions component-by-component,
      verifies SHA-256 by default through `security.check_update_hash`, downloads
      the new jar, and installs by platform script. Flutter intentionally uses
      GitHub release metadata/notes, external platform installation, and a
      release-published `SHA256SUMS.txt`; in-process self-update is retired.
- [x] Java `UpdateUtils.isNewerVersion` has a string-inequality fallback after
      the first four numeric components compare equal: if `latestVersion` and
      `getThisJarVersion()` are not exactly equal, Java treats the latest string
      as newer. Flutter now preserves that behavior and adapts only the leading
      `v` used by its GitHub release workflow before comparison.
- [ ] Java updater installation uses runtime process behavior:
      `Runtime.getRuntime().exec`, `ProcessBuilder`, a shutdown hook, a Windows
      batch file, `Files.move`, and optional `java -jar` restart. Flutter must
      decide whether each desktop/Android platform has a native self-update
      equivalent, an external release flow, or a documented retirement.
- [ ] Java `ripme.json` is a bundled/public changelog source. Flutter has no
      verified equivalent changelog feed, release notes parser, or
      app-visible recent changes text.
- [x] Java uses `LICENSE.txt` and README links to MIT licensing. Flutter carries
      the exact Java license as a Flutter asset, installs it at the Linux and
      Windows bundle roots, copies it into macOS app resources, and declares
      MIT in Linux AppStream metadata.
- [ ] Android support is new relative to Java desktop. Permissions, scoped
      storage, and directory picking now have explicit replacement notes:
      downloads use app-specific storage without broad permissions, and the
      unreliable raw-path tree picker is disabled. Background downloads and
      notification behavior still need explicit parity/replacement notes for
      every desktop-only Java behavior.
- [ ] Flutter Android release configuration currently uses the debug signing
      config for release builds. Final Android artifact evidence must distinguish
      CI-build availability from production-signing/readiness and either add a
      real signing flow or document the migration limitation.
- [x] Windows resource versioning, Linux metadata/bundle contents, macOS
      entitlements/minimum OS, and all platform app icons are source-guarded;
      Linux and Windows workflows additionally inspect built bundle contents
      before archiving.
- [x] Linux packaging metadata declares `ripme.desktop`,
      `Icon=ripme`, app id `com.rarchives.ripme`, and summary
      `Cross-platform media album ripper`; CMake installs the tested
      Java-derived `ripme` icon and exact inherited license.
- [x] macOS relies on its AppIcon asset catalog, whose complete native size set
      is generated from and tested against visible Java branding.
- [x] Windows `Runner.rc` embeds the exact Java
      `src/main/resources/icon.ico` bytes.
- [x] Android launcher icons are tested Java-derived resources at every
      required density.
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
- `CONTRIBUTING.md`
- `SECURITY.md`
- `.github/ISSUE_TEMPLATE.md`
- `.github/PULL_REQUEST_TEMPLATE.md`

Flutter files checked:

- `README.md`
- `CONTRIBUTING.md`
- `SECURITY.md`
- `.github/ISSUE_TEMPLATE.md`
- `.github/PULL_REQUEST_TEMPLATE.md`
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
- [ ] Java `CONTRIBUTING.md` is carried forward unchanged and still tells
      contributors to base work on `master`, verify with `gradlew test`, and
      use Java ripper-test examples such as
      `src/test/java/com/rarchives/ripme/tst/ripper/rippers/ImgurRipperTest.java`.
      Flutter needs contributor instructions for branch `Flutter`, Dart/Flutter
      tests, generated platform code, and migration audit rules.
- [ ] Java `SECURITY.md` is also carried forward unchanged and still lists
      supported versions as `2.1.x`, `1.7.x`, and `< 1.7`, with vulnerability
      reporting tied to the Java-era project. Flutter release/version/security
      support policy needs a migration-specific update before user-facing docs
      can be considered parity-complete.
- [ ] Java `.github/ISSUE_TEMPLATE.md` and
      `.github/PULL_REQUEST_TEMPLATE.md` are carried forward unchanged. The
      issue template still asks for `Java version` / `java -version`, and the
      PR template still requires `gradlew test`. Flutter issue/PR templates need
      platform-specific fields for Android/desktop, Flutter version/build
      artifacts, and the Dart analyze/test commands before repository workflow
      docs are migration-complete.

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
- [ ] The exact Java `@Disabled` inventory is source-backed and must be mapped
      before parity can be claimed: `ArtstnRipperTest.testUserPortfolio`
      (Cloudflare), `BatoRipperTest.testRip`, `BatoRipperTest.testGetAlbumTitle`,
      six `DeviantartRipperTest` methods marked `Broken ripper`,
      `FivehundredpxRipperTest.test500pxAlbum`,
      `FuskatorRipperTest.testFuskatorAlbum`,
      `FuskatorRipperTest.testUrlsWithTiled`,
      `HentainexusRipperTest.testHentaiNexusJson`,
      `HitomiRipperTest.testRip`, `ImagevenueRipperTest.testImagevenueRip`,
      `InstagramRipperTest.testInstagramSingle`,
      `JagodibujaRipperTest.testJagodibujaRipper`,
      `KingcomixRipperTest.testRip`, `LusciousRipperTest.testLusciousRipper`,
      `NfsfwRipperTest.testNfsfwRip`, both disabled
      `PhotobucketRipperTest` methods, `RedditRipperTest.testRedditPostRip`,
      both disabled `SankakuComplexRipperTest` methods,
      `ShesFreakyRipperTest.testShesFreakyRip`, both disabled `StaRipperTest`
      methods, `TapasticRipperTest.testTapasticRip`, both disabled
      `ThechiveRipperTest` GIF methods, both disabled `TsuminoRipperTest`
      methods, four disabled `TumblrRipperTest` methods,
      `TwodgalleriesRipperTest.testTwodgalleriesRip`, disabled
      `VideoRippersTest` Twitch/Pornhub methods,
      `ViewcomicRipperTest.testViewcomicRipper`, `WebtoonsRipperTest.testGetGID`,
      `XcartxRipperTest.testAlbum`, and `XlecxRipperTest.testAlbum`. Several
      Flutter tests exercise static parser helpers for these rippers despite
      Java marking the live ripper/test broken or unavailable, so the audit must
      distinguish "ported parser contract" from "Java live-test parity".
- [ ] Java flaky/slow risk is concentrated in specific test classes, not a
      generic suite-level concern. Class-level tag inventory: `Allporncomic` 2
      flaky, `ArtStation` 2, `Artstn` 1, `Baraag` 1, `Booru` 1, `Chan` 2,
      `Chevereto` 2, `CoomerParty` 1, `Danbooru` 1, `Dynastyscans` 1, `E621`
      5, `Eightmuses` 1, `Erofus` 2, `Erome` 4 slow, `Fapwiz` 3,
      `Femjoyhunter` 1, `Flickr` 1 slow, `Furaffinity` 1 flaky and 2 slow,
      `GirlsOfDesire` 1, `Hentai2read` 1, `Hentaifoundry` 3,
      `Hentainexus` 1, `Imagebam` 1, `Imagefap` 2, `Imgbox` 1, `Imgur` 4,
      `Instagram` 1, `Listal` 2, `Mangadex` 2, `Mastodon` 1,
      `MastodonXyz` 1, `Motherless` 1, `Myhentaicomics` 2,
      `Myhentaigallery` 1, `Newgrounds` 1, `Nhentai` 1, `NsfwXxx` 1,
      `Pawoo` 1, `Pichunter` 2, `Porncomixinfo` 1, `Pornhub` 1, `Reddit` 7,
      `Redgifs` 1, `RipButtonHandlerTest` 1, `Rule34` 1, `RulePorn` 1,
      `Sinfest` 1, `Smutty` 1, `Soundgasm` 2, `SpankBang` 1, `Teenplanet` 1,
      `Thechive` 3, `Theyiffgallery` 1, `Twitter` 2, `UIContextMenuTests` 6,
      `Vk` 3, `Vsco` 2, `Webtoons` 2, `WordpressComic` 9, `Xhamster` 7,
      `Xvideos` 3, `Youporn` 1, `Yuvutu` 1, and `Zizki` 2. Flutter currently
      has no equivalent class-level flaky/slow tagging scheme, so these classes
      need explicit fake fixture coverage, opt-in live tests, or documented
      retirement decisions.
- [ ] Exact Java `@Tag("slow")` inventory is source-backed and must be mapped:
      `EromeRipperTest.testVideoAlbumWithSingleItemRip`,
      `EromeRipperTest.testVideoAlbumWithMultipleItemsRip`,
      `EromeRipperTest.testAlbumWithBothVideoLastRip`,
      `EromeRipperTest.testAlbumWithBothVideoFirstRip`,
      `FlickrRipperTest.testFlickrAlbum`,
      `FuraffinityRipperTest.testFuraffinityAlbum`, and
      `FuraffinityRipperTest.testFuraffinityScrap`.
- [ ] Exact Java `@Tag("flaky")` inventory is source-backed and must be mapped
      at method level. Grouped by class: `AllporncomicRipperTest`
      (`testAlbum1`, `testAlbum2`), `ArtStationRipperTest`
      (`testArtStationProjects`, `testArtStationUserProfiles`),
      `ArtstnRipperTest` (`testSingleProject`), `BaraagRipperTest`
      (`testRip`), `BooruRipperTest` (`testRip`), `ChanRipperTest`
      (`testChanURLPasses`, `testChanRipper`), `CheveretoRipperTest`
      (`testSubdirAlbum1`, `testSubdirAlbum2`), `CoomerPartyRipperTest`
      (`testRip`), `DanbooruRipperTest` (`testRip`),
      `DynastyscansRipperTest` (`testRip`), `E621RipperTest`
      (`testFlashOrWebm`, `testGetNextPage`, `testOldRip`,
      `testOldFlashOrWebm`, `testOldGetNextPage`), `EightmusesRipperTest`
      (`testEightmusesAlbum`), `ErofusRipperTest` (`testRip`, `testGetGID`),
      `FapwizRipperTest` (`testGetNextPage_NoNextPage`,
      `testGetNextPage_HasNextPage`, `testRipPostWithEmojiInLongUrlAtEnd`),
      `FemjoyhunterRipperTest` (`testRip`), `FuraffinityRipperTest`
      (`testLogin`), `GirlsOfDesireRipperTest` (`testGirlsofdesireAlbum`),
      `Hentai2readRipperTest` (`testHentai2readAlbum`),
      `HentaifoundryRipperTest` (`testHentaifoundryRip`,
      `testHentaifoundryGetGID`, `testHentaifoundryPdfRip`),
      `HentainexusRipperTest` (`testHentaiNexusJson`), `ImagebamRipperTest`
      (`testImagebamRip`), `ImagefapRipperTest` (`testImagefapAlbums`,
      `testImagefapGetAlbumTitle`), `ImgboxRipperTest` (`testImgboxRip`),
      `ImgurRipperTest` (`testImgurAlbums`, `testImgurUserAccount`,
      `testImgurAlbumWithMoreThan20Pictures`,
      `testImgurAlbumWithMoreThan100Pictures`), `InstagramRipperTest`
      (`testInstagramAlbums`), `ListalRipperTest` (`testPictures`,
      `testRipListType`), `MangadexRipperTest` (`testRip`, `test2`),
      `MastodonRipperTest` (`testRip`), `MastodonXyzRipperTest` (`testRip`),
      `MotherlessRipperTest` (`testMotherlessVideoRip`),
      `MyhentaicomicsRipperTest` (`testMyhentaicomicsAlbum`,
      `testGetAlbumsToQueue`), `MyhentaigalleryRipperTest`
      (`testMyhentaigalleryAlbum`), `NewgroundsRipperTest`
      (`testNewgroundsRip`), `NhentaiRipperTest` (`testTagBlackList`),
      `NsfwXxxRipperTest` (`testNsfwXxxUser`), `PawooRipperTest`
      (`testRip`), `PichunterRipperTest` (`testPichunterModelPageRip`,
      `testPichunterGalleryRip`), `PorncomixinfoRipperTest` (`testRip`),
      `PornhubRipperTest` (`testGetNextPage`), `RedditRipperTest`
      (`testRedditSubredditRip`, `testRedditSubredditTopRip`,
      `testRedditGfyGoodURL`, `testSelfPostRip`, `testSelfPostAuthorRip`,
      `testRedditGfyBadURL`, `testRedditGallery`), `RedgifsRipperTest`
      (`testRedditRedgifs`), `RipButtonHandlerTest` (`duplicateUrlTestCase`),
      `Rule34RipperTest` (`testShesFreakyRip`), `RulePornRipperTest`
      (`testRip`), `SinfestRipperTest` (`testRip`), `SmuttyRipperTest`
      (`testRip`), `SoundgasmRipperTest` (`testSoundgasmURLs`,
      `testRedditSoundgasmURL`), `SpankBangRipperTest` (`testSpankBangVideo`),
      `TeenplanetRipperTest` (`testTeenplanetRip`), `ThechiveRipperTest`
      (`testTheChiveRip`, `testTheChiveGif`, `testIDotThechive`),
      `TheyiffgalleryRipperTest` (`testTheyiffgallery`), `TwitterRipperTest`
      (`testTwitterUserRip`, `testTwitterSearchRip`), `UIContextMenuTests`
      (`class`, `testCut`, `testCopy`, `testPaste`, `testSelectAll`,
      `testUndo`), `VkRipperTest` (`testVkAlbumHttpRip`, `testVkPhotosRip`,
      `testFindJSONObjectContainingPhotoID`), `VscoRipperTest`
      (`testSingleImageRip`, `testHyphenatedRip`), `WebtoonsRipperTest`
      (`testWebtoonsAlbum`, `testWedramabtoonsType`),
      `WordpressComicRipperTest` (`test_totempole666`, `test_buttsmithy`,
      `test_themonsterunderthebed`, `test_konradokonski_1`,
      `test_konradokonski_2`, `test_freeadultcomix`, `test_delvecomic`,
      `test_spyingwithlana_download`, `test_pepsaga`), `XhamsterRipperTest`
      (`testXhamsterAlbum1`, `testXhamster2Album`, `testXhamsterAlbum2`,
      `testXhamsterAlbumDesiDomain`, `testXhamsterVideo`,
      `testBrazilianXhamster`, `testGetNextPage`), `XvideosRipperTest`
      (`testXvideosVideo1`, `testXvideosAmateursAlbum`,
      `testXvideosProfilesAlbum`), `YoupornRipperTest`
      (`testYoupornRipper`), `YuvutuRipperTest` (`testYuvutuAlbum1`), and
      `ZizkiRipperTest` (`testRip`, `testAlbumTitle`).
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
      resources using Git blob IDs. Java toolbar PNGs, both source icons, and
      `camera.wav` are carried forward byte-identically; Windows embeds the
      exact ICO and Android/macOS/Linux use tested Java-derived native sizes.
      CI also verifies label-bundle presence and exact MIT license packaging.
- [x] Re-scanned Java TODO/disabled/test-tag surfaces and Flutter skipped/live
      tests. The Java suite has 119 flaky tags, 7 slow tags, and 44 disabled
      annotations, while Flutter currently exposes only two environment-gated
      live smoke tests; the test-policy parity gap is recorded in section L.
- [x] Inspected desktop runner argument plumbing for Windows, Linux, and macOS.
      Windows and Linux explicitly forward launch arguments into Dart. A later
      embedding-source check confirmed macOS `FlutterDartProject` also derives
      Dart entrypoint arguments from `ProcessInfo.arguments`; the runner now
      constructs and passes that project explicitly, and `lib/main.dart`
      accepts the resulting argument list.
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
      through Flutter's restored `AbstractSingleFileRipper`, including shared
      byte-progress behavior and focused tests.
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
      `UpdateChecker.isNewerVersion`. Flutter now preserves Java's exact-string
      fallback after equal numeric components, with focused Java-fixture tests.
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
- [x] Java CLI/headless mode from `App.java` is verified as ported, with
      explicit platform replacements for SOCKS proxying and self-update.
- [x] Java command-line options are mapped to tested Flutter behavior.

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
- `-n` / `--no-prop-file`: accepted no-op because Java never reads the
  `saveConfig` argument
- `-s` / `--socks-server`: use SOCKS proxy
- `-p` / `--proxy-server`: use HTTP proxy
- `-j` / `--update`: run updater
- `-a` / `--append-to-folder`: append a string to output folder names
- `-H` / `--history`: set history file location

First findings:

- Java chooses CLI/headless mode when either the environment is headless or any
  CLI args are present. Flutter branches before GUI construction for all
  arguments and for no-display Linux sessions; no-argument headless mode prints
  help like Java.
- Java supports persisted queue restoration through the `queue` config key in
  `MainWindow`; Flutter now restores and updates the same key, including Java's
  non-empty update edge case.
- Java rejects duplicate manual queue entries and expands numeric URL ranges
  using `{start-end}` syntax in `RipButtonHandler`; Flutter now matches both
  behaviors with deterministic queue tests.
- Java validates the current URL while typing and shows detected ripper host;
  Flutter command bar now performs the same live validation and host status.

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
- [x] Java `append-to-folder` behavior is ported and tested through exact CLI
      suffix preservation and sibling working-directory path resolution.
- [x] Java description saving behavior is source-audited and intentionally
      retired because no concrete Java ripper enables the shared pipeline.
- [x] Java popup/tray notification behavior is implemented for Windows, Linux,
      and macOS with Java-equivalent config, window-state, text, and lifecycle
      gating. Android intentionally has no desktop tray replacement.

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
- [x] HTTP retries, timeouts, Java-compatible retry-after ignoring, configured
      cookies, and HTTP proxy support exist.
- [x] Album history and downloaded URL history have Flutter providers.
- [x] History JSON import/export preserves Java dates and selected flags;
      downloaded-history file-location behavior is separately ported and tested.
- [~] HTTP proxy support exists; SOCKS proxy parity is not yet verified.
- [x] Java `history.location` / `-H` behavior is ported and tested, including
      the shipped separator-free append bug and album-history separation.
- [x] Java fallback history guessing from existing rip folders is ported and
      tested, including the shipped full-path and parser edge-case limitations.

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
- [x] Completion sound behavior plays the exact Java `camera.wav`.
- [x] Exact Java `camera.wav` sound-resource parity is source-audited and
      guarded by runtime dispatch, asset, and CI byte-comparison tests.
- [x] Java icon/resource parity is source-audited and guarded by
      platform-by-platform provenance, dimension, and packaging tests.
- [x] Logging file output parity uses tested Java-compatible `ripme.log` naming,
      filtering, gzip rotation, and size policy through the Dart logger.

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

- [x] Port or explicitly replace Java CLI/headless mode.
- [x] Add Dart tests for CLI parsing/config side effects.
- [x] Queue persistence, duplicate enqueue behavior, and `{start-end}` URL range
      expansion are implemented and tested.
- [x] Selected-history re-rip behavior uses a persisted selected-history model
      and is covered in CLI/provider/widget tests.
- [x] Open-folder and tray/popup behavior is implemented for Windows, Linux,
      and macOS, with Android intentionally excluding Java desktop shell
      surfaces.

### Pass 2: Low-Mention Rippers And Runtime Hooks

Started: 2026-06-05

Mode: audit-discovery only. No implementation changes were kept from this pass.

Sources re-read:

- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/ModelmayhemRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/MyreadingmangaRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/VidbleRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/DribbbleRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/KingcomixRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/MultpornRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/NudeGalsRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/SoundgasmRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/FitnakedgirlsRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/OglafRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/GirlsOfDesireRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/HentaifoxRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/HitomiRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/NhentaiRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/ZizkiRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/video/ViddmeRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/video/VidearnRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/video/MotherlessVideoRipper.java`
- Matching Flutter files under `lib/ripper/rippers/`
- Matching focused Dart tests under `test/`

Mechanical scans re-run:

- Java ripper list versus Flutter ripper file list.
- Audit mention counts for every Java `*Ripper.java`, prioritizing classes with
      the fewest exact mentions.
- Constructor-time URL sanitation and `this.url` mutation sites.
- Java override surfaces for `getFirstPage`, `getNextPage`,
      `getURLsFromPage`, `getURLsFromJSON`, `getAlbumTitle`,
      `getAlbumsToQueue`, `pageContainsAlbums`, `hasASAPRipping`,
      `getThreadPool`, `sanitizeURL`, and `normalizeUrl`.
- Java platform/runtime API use for process exit, shutdown hooks, desktop open,
      tray, dialogs, clipboard, sound, file/path APIs, and finish-command
      execution.

Confirmed existing findings, no new distinct row added:

- `DribbbleRipper.getNextPage(...)` exact `IOException("No more pages")`,
      `https://www.dribbble.com` concatenation, and null/empty-href drift are
      already recorded in section I.
- Java constructor/sanitize URL behavior, including Soundgasm and other
      constructor-time normalization risks, is already recorded in section E.
- Java per-ripper thread-pool overrides and ASAP-ripping hooks are already
      recorded in section E.
- `ZizkiRipper.getAlbumTitle(...)` malformed-DOM exception behavior is already
      recorded in section I.
- `GirlsOfDesireRipper.getGID(...)` scheme-less Java regex behavior is already
      recorded in section I.
- `HitomiRipper` category-as-gallery-id behavior and strict JSON/name handling
      are already recorded in section I.
- Video-ripper marker extraction and `MotherlessVideoRipper`'s hardcoded `WTF`
      log behavior are already recorded in section E.

Open work:

- [ ] Continue the low-mention ripper sweep beyond the classes above until a
      full pass across every Java ripper produces no new source-backed gaps.
- [ ] Convert the ad hoc mechanical scans from this pass into checked-in audit
      scripts/tests before any final parity claim.
- [ ] Keep the audit status open; this pass increases confidence but does not
      prove that every parity gap has been found.

Continuation: 2026-06-05

Additional sources re-read:

- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/Jpg3Ripper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/ImgboxRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/MyhentaigalleryRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/PorncomixRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/SmuttyRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/TeenplanetRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/FreeComicOnlineRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/HentaiimageRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/HentaiNexusRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/HypnohubRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/MangadexRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/NatalieMuRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/video/CliphunterRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/video/TwitchVideoRipper.java`
- Matching Flutter files under `lib/ripper/rippers/`
- Matching focused Dart tests under `test/`

Additional confirmed existing findings, no new distinct row added:

- `Jpg3Ripper.getNextPage(...)` nullable/exception drift and constructor
      `sanitizeURL(...)` behavior are already recorded in section I and tested
      in the focused Dart file.
- `ImgboxRipper.getURLsFromPage(...)` malformed empty/missing `src` behavior is
      already recorded in section I.
- `TeenplanetRipper` direct `System.out` image-count diagnostic is already
      recorded in section G's non-localized diagnostic string inventory.
- `CliphunterRipper` decrypted-video download referrer drift is already
      recorded in section E.
- `FreeComicOnlineRipper.getNextPage(...)` strict second-link access and
      nullable Flutter drift are already recorded in section I.
- `HentaiimageRipper.getNextPage(...)` `IOException("No more pages")` contract
      versus Flutter `null` is already recorded in section I.
- `HentaiNexusRipper.getURLsFromJSON(...)` strict JSON key/object access is
      already recorded in section I.
- `MangadexRipper.getURLsFromJSON(...)` strict chapter/manga JSON behavior and
      one-second per-download delay are already recorded in section I and
      focused Dart tests.
- `NatalieMuRipper.getURLsFromPage(...)` `isThisATest()` early-break behavior
      is already recorded in section I.

Still open:

- [ ] Continue the same low-mention sweep with the remaining count-4 and count-5
      rippers, then repeat from a different mechanical angle before claiming
      the discovery pass is exhausted.

Continuation: 2026-06-05, count-4/count-5 sweep

Additional sources re-read:

- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/NsfwAlbumRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/PornpicsRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/SpankbangRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/XlecxRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/AllporncomicRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/BaraagRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/DanbooruRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/FemjoyhunterRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/ImagevenueRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/MastodonXyzRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/PawooRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/PichunterRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/ShesFreakyRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/SinfestRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/TwodgalleriesRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/XcartxRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/YoupornRipper.java`
- Matching Flutter files under `lib/ripper/rippers/`
- Matching focused Dart tests under `test/`

Additional confirmed existing findings, no new distinct row added:

- `NsfwAlbumRipper` thumbnail-count `System.out` behavior is already recorded in
      section G's direct diagnostic inventory.
- `PornpicsRipper` broad inherited `canRip(...)` behavior and empty `a.rel-link`
      handling are already recorded in section I.
- `SpankbangRipper` missing embed behavior is already recorded in section E and
      covered by focused Dart parser tests.
- `XcartxRipper` / `XlecxRipper` inherited domain/GID and virtual-domain image
      construction behavior is already recorded in section I and reflected in
      focused Dart tests.
- `AllporncomicRipper` empty image/queue URL filtering drift is already recorded
      in section I.
- Mastodon subclass behavior for `BaraagRipper`, `MastodonXyzRipper`, and
      `PawooRipper` remains covered by the shared `MastodonRipper` rows in
      section I plus the constructor-guard rows in section E.
- `DanbooruRipper` strict JSON access and OkHttp/mobile-header behavior are
      already recorded in sections I and J.
- `FemjoyhunterRipper` inherited `canRip(...)` behavior and exact `getGID(...)`
      regex behavior are already recorded in section I.
- `ImagevenueRipper` empty target-link handling and per-image fetch/continue
      behavior are already recorded in section I.
- `PichunterRipper` inherited host guard, last-arrow pagination dereference, and
      empty-href pagination behavior are already recorded in section I.
- `ShesFreakyRipper` broad host guard is already recorded in section I.
- `SinfestRipper` inherited host guard and `getNextPage(...)` null/exception
      behavior are already recorded in section I.
- `TwodgalleriesRipper` offset pagination, login token/cookie behavior, and
      next-page empty-result exception are already recorded in section I.
- `YoupornRipper` is covered by the video/single-file forced-prefix inventory in
      section E and focused Dart extraction tests.

Still open:

- [ ] Continue the low-mention sweep with the remaining count-6 and count-7
      rippers, then re-run a cross-cutting scan for hooks, config keys,
      diagnostics, and malformed-input behavior before any exhaustion claim.

Continuation: 2026-06-05, count-6/count-7 and cross-cutting sweep

Additional sources re-read or mechanically compared:

- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/ArtstnRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/BooruRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/DerpiRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/FreeComicOnlineRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/HentaiimageRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/HentaiNexusRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/JagodibujaRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/ListalRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/MangadexRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/MyhentaicomicsRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/NatalieMuRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/OglafRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/PahealRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/PicstatioRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/PorncomixinfoRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/ReadcomicRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/Rule34Ripper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/RulePornRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/StaRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/VscoRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/CfakeRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/DynastyscansRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/ErofusRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/Hentai2readRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/HentaifoxRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/LusciousRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/NhentaiRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/TheyiffgalleryRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/AbstractSingleFileRipper.java`
- `origin/main:src/main/resources/rip.properties`
- Matching Flutter files under `lib/ripper/rippers/`, `lib/ripper/`,
      `lib/utils/`, `lib/config_defaults.dart`, `lib/ripper/ripper_factory.dart`,
      and `lib/ripper/ripper_migration_catalog.dart`
- Matching focused Dart tests under `test/`

Additional confirmed existing findings, no new distinct row added:

- `BooruRipper` strict `<posts>` / `offset` / `count` parsing and empty
      `file_url` behavior are already recorded in section I.
- `FreeComicOnlineRipper`, `HentaiimageRipper`, `MyhentaicomicsRipper`,
      `OglafRipper`, `PicstatioRipper`, `PorncomixinfoRipper`, `Rule34Ripper`,
      `CfakeRipper`, `DynastyscansRipper`, `Hentai2readRipper`, and
      `TheyiffgalleryRipper` strict Java pagination exception behavior is
      already recorded in the section I pagination inventory.
- `HentaiNexusRipper` and `MangadexRipper` strict JSON field access are already
      recorded in section I.
- `JagodibujaRipper`, `ListalRipper`, `NatalieMuRipper`, `PahealRipper`,
      `StaRipper`, `VscoRipper`, `ErofusRipper`, `HentaifoxRipper`,
      `LusciousRipper`, and `NhentaiRipper` each already have source-backed
      class-specific rows for the observed drift points.
- `RulePornRipper` is covered by the shared `AbstractSingleFileRipper`
      byte-progress/status row plus the video/single-file forced-prefix
      inventory.
- Java `rip.properties` / `Utils.getConfig*` keys absent from Flutter or mapped
      differently are already covered by the config inventory: descriptions,
      finish command, downloaded history location, warning-before-delete,
      proxy key model, language, log/window persistence, rips directory,
      update/security toggles, SSL verification, and the `errors.skip404` typo.
- Java ripper catalog coverage is mechanically complete at this checkpoint:
      116 Java ripper classes, 116 Dart ripper files, and every Java class name
      appears in the Flutter factory/catalog text. The remaining simple
      snake-case filename differences (`EHentaiRipper`, `RulePornRipper`, etc.)
      are naming aliases, not missing ports.
- Focused Dart test coverage is mechanically complete at the name level: every
      Java ripper has either an obvious focused Dart test file or class-name
      coverage in the test tree. This does not prove behavior parity and does
      not close any existing behavioral rows.

Still open:

- [ ] Continue audit-discovery from a different mechanical angle: Java test
      method inventory versus Dart assertion coverage, inherited superclass
      override matrix, parser strictness/error-surface scan, and UI/CLI/runtime
      feature inventory. Do not mark audit mode complete until these independent
      scans stop producing candidates.

Continuation: 2026-06-05, Java test-method inventory

Mechanical result:

- Java `origin/main` currently exposes 120 `@Test` methods under
      `src/test/java`.
- A method-name pass found 75 Java `@Test` methods whose exact method names are
      not named in this audit file yet. Some are already behavior-covered by
      focused Dart tests or broader audit rows, but method-level parity has not
      been fully dispositioned.

Open method-level disposition queue:

- `Base64Test.java`: `testDecode`
- `BooruRipperTest.java`: `testGetDomain`, `testGetHost`
- `ChanRipperTest.java`: `testChanStringParsing`
- `CoomerPartyRipperTest.java`: `testUrlParsing`
- `DanbooruRipperTest.java`: `testGetHost`
- `DribbbleRipperTest.java`: `testDribbbleRip`
- `EhentaiRipperTest.java`: `testEHentaiAlbum`
- `EightmusesRipperTest.java`: `testGetSubdir`, `testGID`
- `EromeRipperTest.java`: `testEmptyPageDoesNotContainAlbums`,
      `testGetGIDAlbum`, `testGetGIDProfilePage`,
      `testGetURLsFromPhotoAlbumPage`, `testPageContainsAlbums`,
      `testPhotoAlbumRip`
- `FapDungeonRipperTest.java`: `testFapDungeon1`, `testFapDungeon2`,
      `testFapDungeon3`
- `FapwizRipperTest.java`: `testPostGetGID1_Simple`,
      `testPostGetGID2_WithEmojiInLongUrlInTheMiddle`,
      `testRipPostWithEmojiInLongUrlInTheMiddle`,
      `testRipPostWithEmojiInShortUrl`, `testRipPostWithNumbersInUsername1`,
      `testUserGetGID1_Simple`, `testUserGetGID2_Numbers`,
      `testUserGetGID3_HyphensAndNumbers`, `testUserGetGID4_Underscores`
- `FreeComicOnlineRipperTest.java`: `testFreeComicOnlineChapterAlbum`
- `HqpornerRipperTest.java`: `testFlyFlvVideoHost`,
      `testGetURLsFromPage`, `testMyDaddyVideoHost`, `testUnknownVideoHost`
- `HypnohubRipperTest.java`: `testRipPoolAndPost`
- `ImgurRipperTest.java`: `testImgurSingleImage`, `testImgurURLFailures`,
      `testImgurVideoFromGetFilesFromURL`
- `InstagramRipperTest.java`: `testInstagramGID`
- `ListalRipperTest.java`: `testRipFolderType`
- `ModelmayhemRipperTest.java`: `testModelmayhemRip`
- `MotherlessRipperTest.java`: `testMotherlessAlbumRip`
- `MrCongRipperTest.java`: `testMrCongAlbumRip1`, `testMrCongAlbumRip2`,
      `testMrCongAlbumRip3`, `testMrCongTagRip`
- `MyhentaicomicsRipperTest.java`: `testPageContainsAlbums`
- `NsfwAlbumRipperTest.java`: `testNsfwAlbum1`, `testNsfwAlbum2`
- `NudeGalsRipperTest.java`: `testAlbumRip`, `testGetAlbumGID`,
      `testGetVideoGID`, `testVideoRip`
- `PahealRipperTest.java`: `testPahealRipper`
- `PicstatioRipperTest.java`: `testGID`
- `PornhubRipperTest.java`: `testPornhubAlbumRip`,
      `testPornhubMultiPageAlbumRip`
- `RedditRipperTest.java`: `testRedditGfycatRedirectURL`
- `RedgifsRipperTest.java`: `testRedgifsBadRL`, `testRedgifsGoodURL`,
      `testRedgifsProfile`, `testRedgifsSearch`, `testRedgifsTags`
- `SankakuComplexRipperTest.java`: `testgetSubDomain`
- `ScrolllerRipperTest.java`: `testScrolllerFilterRegex`, `testScrolllerGID`
- `TumblrRipperTest.java`: `testTumblrAudioRip`
- `VidbleRipperTest.java`: `testVidbleRip`
- `VkRipperTest.java`: `testGetBestSourceUrl`
- `WordpressComicRipperTest.java`: `test_Eightmuses_download`,
      `test_Eightmuses_getAlbumTitle`, `test_konradokonski_getAlbumTitle`,
      `test_prismblush`, `test_spyingwithlana_getAlbumTitle`
- `XvideosRipperTest.java`: `testXvideosVideo2`
- `YuvutuRipperTest.java`: `testYuvutuAlbum2`

Still open:

- [ ] For each method above, classify as one of: behavior already proved by a
      Dart test, behavior already represented by an audit gap row, Java test is
      flaky/live-only and needs an offline equivalent, or new missing
      behavior/gap row required.

Continuation: 2026-06-05, inherited override matrix

Mechanical result:

- Java ripper class count checked: 116.
- Dart ripper file count checked: 116.
- Queue-support override mismatch count: 0.
- Description-support/helper mismatch count: 1, `FuraffinityRipper`; already
      recorded in section E / section I as Java helper methods with
      `hasDescriptionSupport() == false`.
- `canRip(...)` inheritance mismatch count: 81. These are classes where Java
      does not override `canRip(...)` in the concrete ripper class, so it
      inherits the broad superclass host/domain check, while Flutter defines a
      concrete Dart `canRip(...)` override. Many of these already have
      class-specific rows, but the matrix confirms this remains a broad
      behavioral surface rather than isolated one-offs.

Still open:

- [ ] Expand or cross-reference the inherited-`canRip(...)` inventory so every
      one of the 81 classes is explicitly dispositioned as already row-covered,
      Dart-compatible despite the override, or requiring a new parity gap row.

Continuation: 2026-06-05, parser strictness/error-surface scan

Mechanical scan started:

- Java searched for jsoup/JSON strict access patterns:
      `.attr("...")`, `getString(...)`, `getInt(...)`, `getLong(...)`,
      `getDouble(...)`, `getJSONArray(...)`, and `getJSONObject(...)` in
      `origin/main:src/main/java/com/rarchives/ripme/ripper/` and
      `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/`.
- Flutter searched for nullable DOM/JSON guards and masking patterns:
      `attributes[...]`, `querySelector(...)`, `querySelectorAll(...)`,
      `json[...]`, `is! Map`, `is! List`, `tryParse`, `??`, `continue`,
      `return null`, and `return const []` under `lib/ripper/` and `lib/utils/`.

Immediate result:

- The scan still produces a broad candidate surface rather than an exhaustion
      result. Top candidates overlap heavily with existing section I rows:
      `BooruRipper`, `CfakeRipper`, `DynastyscansRipper`, `EightmusesRipper`,
      `FuraffinityRipper`, `FreeComicOnlineRipper`, `MangadexRipper`,
      `MyhentaicomicsRipper`, `PicstatioRipper`, `Rule34Ripper`,
      `WordpressComicRipper`, and related JSON rippers.
- Because the command output is intentionally capped and candidate-heavy, this
      scan is not complete and must continue as smaller class buckets with each
      strict Java access point dispositioned against Dart behavior.

Still open:

- [ ] Bucket strict parser candidates by class and record one of: existing audit
      row covers it, Dart has Java-compatible strictness, or new malformed-input
      parity gap row needed.

Continuation: 2026-06-05, parser strictness bucket A/B

HTML/pagination-heavy classes dispositioned:

- `BooruRipper`: existing section I rows cover strict `<posts>` dereference,
      integer parsing, broad `canRip(...)`, and empty `file_url` behavior.
- `CfakeRipper`: existing section I rows cover strict next-page exception
      variants, inherited `canRip(...)`, and malformed/empty thumbnail `src`.
- `FreeComicOnlineRipper`: existing section I rows cover inherited
      `canRip(...)` and strict second pagination-link access.
- `WordpressComicRipper`: existing section I rows cover strict next-page,
      theme-specific dereferences, malformed comic image/title handling, and
      download filename fallthrough.
- `EightmusesRipper`: existing section I rows cover subalbum recursion,
      subalbum warning/status behavior, ASAP scheduling, inherited
      `canRip(...)`, strict tile/image dereferences, and title fallback drift.
- `FuraffinityRipper`: existing section I rows cover next-page exceptions,
      inherited `canRip(...)`, post/image fetch behavior, cookie parsing, and
      disabled-but-present description helpers.
- `PicstatioRipper`: existing section I rows cover inherited `canRip(...)`,
      parent-href assumptions, full-size download-page lookup, and next-page
      behavior.
- `MyhentaicomicsRipper`: existing section I rows cover queue URL construction
      and next-page dereference/exception behavior.
- `Rule34Ripper`: existing section I rows cover API no-more-pages behavior and
      empty `file_url` handling.
- `DynastyscansRipper`: existing section I rows cover strict next-page
      exception behavior and strict pages-JSON parsing.

JSON-heavy classes dispositioned:

- `ArtStationRipper`, `CoomerPartyRipper`, `DanbooruRipper`, `DerpiRipper`,
      `FivehundredpxRipper`, `FlickrRipper`, `MangadexRipper`, `NsfwXxxRipper`,
      `PhotobucketRipper`, `RedditRipper`, `RedgifsRipper`, `VkRipper`,
      `LusciousRipper`, and `FuskatorRipper` were spot-checked against Java
      strict JSON access and Dart null/empty-list guards.
- No new distinct row was added from this bucket. The apparent
      `LusciousRipper` GraphQL strictness candidate is already covered by the
      existing Luscious row that mentions Java's strict
      `data.picture.list.items` / `info.total_pages` walk and Flutter's empty
      malformed-response completion path.

Still open:

- [ ] Continue parser strictness bucketing for the remaining rippers not in
      bucket A/B, especially mixed HTML/API rippers and video helper classes.

Continuation: 2026-06-05, video helper bucket

Video package sources re-read:

- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/video/CliphunterRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/video/ViddmeRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/video/VidearnRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/video/PornhubRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/video/VkRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/video/YuvutuRipper.java`
- Matching Flutter files under `lib/ripper/rippers/` and focused tests under
      `test/`

Disposition:

- `CliphunterRipper` decrypted-video referrer drift and broad factory host
      dispatch are already recorded in sections D/E.
- `ViddmeRipper` and `VidearnRipper` missing-marker exception behavior and
      Java video filename construction are covered by existing audit rows and
      focused Dart tests.
- Java `rippers/video/PornhubRipper.java`, `rippers/video/VkRipper.java`, and
      `rippers/video/YuvutuRipper.java` duplicate/standalone video-route
      behavior is already recorded in section E/I, including the missing
      Flutter routes for Pornhub and Yuvutu video URLs and the missing individual
      VK `/video...` route.

Still open:

- [ ] Continue with inherited-`canRip(...)` matrix disposition and the remaining
      mixed parser buckets; do not treat video helper review as exhaustive for
      all video-adjacent album rippers.

Continuation: 2026-06-05, inherited `canRip(...)` exact list

Mechanical list of 81 concrete rippers where Java inherits superclass
`canRip(...)` but Dart defines a concrete `canRip(...)` override:

- `AllporncomicRipper`, `ArtStationRipper`, `CfakeRipper`,
      `DanbooruRipper`, `DerpiRipper`, `DeviantartRipper`,
      `DribbbleRipper`, `DynastyscansRipper`, `E621Ripper`,
      `EHentaiRipper`, `EightmusesRipper`, `ErofusRipper`, `EromeRipper`,
      `FapwizRipper`, `FemjoyhunterRipper`, `FitnakedgirlsRipper`,
      `FivehundredpxRipper`, `FlickrRipper`, `FreeComicOnlineRipper`,
      `FuraffinityRipper`, `FuskatorRipper`, `GirlsOfDesireRipper`,
      `Hentai2readRipper`, `HentaifoundryRipper`, `HentaifoxRipper`,
      `HentaiNexusRipper`, `HitomiRipper`, `HqpornerRipper`,
      `HypnohubRipper`, `ImagebamRipper`, `ImagefapRipper`,
      `ImagevenueRipper`, `ImgboxRipper`, `InstagramRipper`,
      `JabArchivesRipper`, `JagodibujaRipper`, `Jpg3Ripper`,
      `KingcomixRipper`, `ListalRipper`, `LusciousRipper`,
      `MastodonRipper`, `ModelmayhemRipper`, `MrCongRipper`,
      `MultpornRipper`, `MyhentaicomicsRipper`, `MyhentaigalleryRipper`,
      `MyreadingmangaRipper`, `NewgroundsRipper`, `NfsfwRipper`,
      `NhentaiRipper`, `NsfwAlbumRipper`, `NsfwXxxRipper`,
      `NudeGalsRipper`, `OglafRipper`, `PahealRipper`,
      `PhotobucketRipper`, `PichunterRipper`, `PicstatioRipper`,
      `PorncomixinfoRipper`, `PorncomixRipper`, `PornpicsRipper`,
      `ReadcomicRipper`, `RulePornRipper`, `SankakuComplexRipper`,
      `ScrolllerRipper`, `ShesFreakyRipper`, `SinfestRipper`,
      `SoundgasmRipper`, `StaRipper`, `TapasticRipper`,
      `TeenplanetRipper`, `ThechiveRipper`, `TheyiffgalleryRipper`,
      `TsuminoRipper`, `TwitterRipper`, `TwodgalleriesRipper`,
      `VidbleRipper`, `ViewcomicRipper`, `XcartxRipper`,
      `XlecxRipper`, and `ZizkiRipper`.

Still open:

- [ ] Cross-reference the 81-class list against existing class-specific rows,
      then add missing rows for classes currently covered only by broad
      inherited-`canRip(...)` wording.

Continuation: 2026-06-05, audit-completion correction and low-mention
inherited-`canRip(...)` sweep

Operator correction:

- Audit-discovery mode is not complete. A bucket disposition means only that the
      checked bucket has not produced a new source-backed gap yet; it is not a
      proof that all parity gaps have been found.
- The active working posture remains audit-discovery only: keep verifying
      Java behavior from `origin/main` against Flutter/Dart and keep this file
      open until repeated independent sweeps stop producing new evidence.

Low-mention inherited-`canRip(...)` sources re-read:

- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/VidbleRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/SoundgasmRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/FitnakedgirlsRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/NudeGalsRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/MyreadingmangaRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/KingcomixRipper.java`
- `origin/main:src/main/java/com/rarchives/ripme/ripper/rippers/ModelmayhemRipper.java`
- Matching Flutter files under `lib/ripper/rippers/`

Disposition:

- `VidbleRipper`, `SoundgasmRipper`, `MyreadingmangaRipper`,
      `KingcomixRipper`, and `ModelmayhemRipper` currently line up with Java
      on strict GID regexes, extraction selectors, and ordered filename prefix
      construction. No new class-specific gap was proven in this pass.
- `FitnakedgirlsRipper` currently preserves Java's slow-site one-second delay,
      referrer header, and `data-src`/`src` fallback behavior. Its inherited
      `canRip(...)` strictness gap remains covered by the existing row.
- `NudeGalsRipper` currently preserves Java's album/video GID split, URL
      construction, space-to-`%20` replacement, and referrer header. No new
      class-specific gap was proven in this pass.

Still open:

- [ ] Continue the 81-class inherited-`canRip(...)` matrix beyond the
      low-mention subset above, especially classes where Dart uses a strict
      URL-pattern `canRip(...)` while Java inherited only `host.endsWith`.
- [ ] Continue parser strictness/error-surface sweeps for mixed HTML/API
      rippers and any route-helper rippers not covered by the video-helper
      bucket.
- [ ] Do not mark audit-discovery complete without a final mechanical inventory
      proving that every Java ripper, helper route, superclass behavior, and
      Java test method has a recorded disposition.

Continuation: 2026-06-05, inherited `canRip(...)` strict/custom classification

Generated strict/custom Dart `canRip(...)` bucket from the 81 Java-inherited
classes:

- `CfakeRipper`, `EightmusesRipper`, `FapwizRipper`,
      `FreeComicOnlineRipper`, `FuraffinityRipper`, `FuskatorRipper`,
      `GirlsOfDesireRipper`, `Hentai2readRipper`, `HentaifoundryRipper`,
      `HentaiNexusRipper`, `HitomiRipper`, `HqpornerRipper`,
      `LusciousRipper`, `MastodonRipper`, `MrCongRipper`,
      `NewgroundsRipper`, `NfsfwRipper`, `PhotobucketRipper`,
      `PichunterRipper`, `PicstatioRipper`, `PorncomixinfoRipper`,
      `PornpicsRipper`, `SankakuComplexRipper`, `ScrolllerRipper`,
      `SinfestRipper`, `StaRipper`, `TapasticRipper`, `ThechiveRipper`,
      `TheyiffgalleryRipper`, `TwitterRipper`, and `ZizkiRipper`.

New findings from this classification:

- [x] Java `ThechiveRipper` inherits `AbstractHTMLRipper.canRip(...)`, so any
      host ending in `thechive.com` is accepted before `getGID(...)` separates
      post URLs from `i.thechive.com` user URLs. Flutter
      `ThechiveRipper.canRip(...)` applies the post/user regexes directly, so
      other `thechive.com` paths fail at `canRip(...)` instead of Java's later
      GID/error path.
- [x] Java `TwitterRipper` inherits `AbstractJSONRipper.canRip(...)`, so any
      host ending in `twitter.com` is accepted by the superclass host guard
      before `sanitizeURL(...)` recognizes only account/search URL shapes.
      Flutter `TwitterRipper.canRip(...)` delegates to `classifyUrl(...)`,
      rejects non-account/non-search `twitter.com` paths earlier than Java, and
      also accepts `x.com` account/search URLs that Java's superclass guard
      would reject before Twitter-specific parsing.

Disposition:

- The other strict/custom candidates above already have source-backed rows or
      shared-family rows in this file for the inherited-guard mismatch and/or
      adjacent Java behavior. This statement is a bucket disposition only, not a
      completion claim.

Still open:

- [ ] Continue classifying the remaining host-suffix candidates for subtler
      differences such as factory dispatch, case/host normalization,
      constructor URL mutation, and superclass download/runtime hooks.
- [ ] Continue parser strictness/error-surface sweeps after inherited
      `canRip(...)` matrix disposition.
