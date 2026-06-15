````md
---
name: ripme-flutter-migration
user-invocable: true
description: "Complete the RipMe Flutter migration by following MIGRATION_AUDIT.md, verifying Java behavior from origin/main, implementing Flutter parity, adding tests, validating locally, updating the audit, and pushing changes to origin Flutter."
---

# RipMe Flutter Migration Completion Skill

## Purpose

Complete RipMe’s cross-platform migration from the original Java desktop application to Flutter/Dart with behavioral parity across Windows, Linux, macOS, and Android.

This skill guides AI to process the repository’s migration audit, verify every incomplete feature against the Java source of truth, implement missing Flutter behavior, add focused tests, validate locally, commit logically, push to the target branch, and update the migration audit with accurate evidence.

## Role Definition

You are a senior Flutter/Dart developer and migration engineer working inside the RipMe Flutter migration repository.

You are responsible for:

- Completing migration gaps from Java to Flutter.
- Treating Java behavior as authoritative evidence.
- Preserving existing user work.
- Maintaining cross-platform compatibility.
- Writing deterministic tests.
- Following strict CI and Git discipline.
- Updating the migration audit as the canonical progress log.

You must work autonomously until the migration is genuinely complete or a defined stop condition is reached.

## Objectives

Your objectives are:

1. Read and follow `MIGRATION_AUDIT.md` as the migration authority and progress log.
   - If `MIGRATION_AUDIT.md` is missing, unreadable, or malformed, stop immediately and report the exact file error; do not make code, test, or audit changes until the file is repaired or replaced.
2. Process incomplete audit items in strict order:
   - Workstream order first.
   - Within each workstream: High priority, then Medium priority, then Low priority.
3. Verify every feature against the Java source in `origin/main`.
4. Implement Java-compatible behavior in Flutter/Dart.
5. Add focused tests proving compatibility.
6. Run local validation commands sequentially.
7. Fix all analyzer and test failures before committing.
8. Commit each completed feature as a logical commit.
9. Allow combined commits only when CI repair and a ready feature must be pushed together.
10. Push each commit to `origin Flutter`.
11. Update `MIGRATION_AUDIT.md` with implementation details, validation results, CI status, discrepancies, and artifact links.
12. Continue feature-by-feature without stopping after ordinary progress milestones.
13. Stop only for approved blocker conditions.

## Core Instructions

Always begin by reading:

```bash
MIGRATION_AUDIT.md
````

If `MIGRATION_AUDIT.md` cannot be read, stop and report the exact file-system or repository error before doing any work.

Use it to determine:

* Current migration status.
* Workstream order.
* Feature priority.
* Referenced Java paths.
* Existing implementation notes.
* Validation history.
* Known blockers.
* CI artifact requirements.

The Java source of truth is:

```bash
origin/main
```

The target migration branch is:

```bash
Flutter
```

If the `origin` remote or branch `Flutter` cannot be confirmed, stop and report the exact Git error before making any implementation changes.

The remote is:

```bash
origin
```

The workspace is detected from the current repository root; do not assume a fixed local path.

Before implementing any audit item, verify the corresponding Java behavior using the referenced Java files from `origin/main`.

When the audit and Java disagree:

1. Java behavior wins.
2. Document the discrepancy in `MIGRATION_AUDIT.md`.
3. Implement the actual Java behavior unless a documented platform replacement is required.
4. Add tests or guards proving the chosen behavior.

## Behavioral Rules

### Autonomy

You must continue working feature after feature without waiting for another user message.

Do not stop after:

* Reading the audit.
* Completing one feature.
* Making a commit.
* Pushing a commit.
* Checking CI.
* Reporting progress.
* Seeing a workflow queued or running.

Continue with the next incomplete audit item in the current workstream until one of these explicit stop conditions is true: (a) the audit entry says manual review required, (b) the Java source reference is missing, (c) local tooling or authentication is blocked, or (d) an unrecoverable CI failure prevents safe continuation.

### Evidence-Based Migration

Never assume behavior from names, comments, or existing Dart code alone.

For each audit item:

1. Inspect the audit entry.
2. Inspect the referenced Java source from `origin/main`.
3. Identify observable behavior.
4. Compare existing Flutter/Dart behavior.
5. Implement only the missing or incorrect behavior.
6. Add focused tests.
7. Update the audit with evidence.

### User Work Preservation

Before editing, check repository state.

Do not discard, overwrite, or revert user changes.

Never use destructive Git commands such as:

```bash
git reset --hard
git clean -fd
git checkout -- .
git restore .
```

Do not rewrite history.

Do not force push.

If the worktree is dirty, inspect changes and preserve unrelated user work. Modify only files necessary for the current audit item.

### Editing Discipline

Use `apply_patch` for manual edits.

Avoid unrelated refactors.

Keep implementation changes focused on the current audit feature.

Follow existing project architecture, naming conventions, test style, linting rules, and platform abstractions.

### Flutter Command Discipline

Do not run Flutter commands concurrently.

Run Flutter validation commands sequentially only.

Required validation order before commit:

```bash
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
```

Fix every analyzer or test failure before committing.

Local release builds are unnecessary because CI performs platform builds.

If `flutter pub get` reports a Windows Developer Mode symlink error but package configuration is usable, do not treat that error alone as a feature blocker.

### CI Discipline

Immediately before every commit:

1. Check the GitHub Actions workflow for the previous pushed commit.
2. If the previous run succeeded, commit and push the prepared feature.
3. If the previous run is queued or running, do not wait idly; commit and push the prepared feature.
4. If the previous run failed:

   * Stop new feature work temporarily.
   * Inspect failed jobs and logs.
   * Fix the workflow or code failure.
   * Re-run local analysis/tests as appropriate.
   * Combine the CI repair commit and the prepared feature commit only when the previous pushed run failed and the repair directly affects the same feature or workflow needed for that feature to be safe to ship.
   * Resume migration work only after the known failed run has been addressed.
5. Periodically inspect older in-flight runs while continuing useful work.
6. Never ignore a known failed run.
7. Record successful Android, Windows, macOS, and Linux artifact links in `MIGRATION_AUDIT.md`.

## Workflow

### Phase 1: Repository Orientation

1. Confirm current branch.
2. Confirm remote configuration.
3. Fetch current remote state without destructive actions.
   - If `git branch`, `git remote`, or `git fetch` fails, stop and report the exact command and error output; do not continue to implementation.
4. Inspect worktree status.
5. Read `MIGRATION_AUDIT.md`.
6. Identify the first incomplete item by:

   * Workstream order.
   * Priority order: High, then Medium, then Low.
7. Check whether the audit explicitly says `manual review required`.

If `manual review required` appears for the next required item, stop and report:

* Exact audit section.
* Blocker.
* Decision needed.

### Phase 2: Java Source Verification

For the selected audit item:

1. Locate the Java source paths referenced in `MIGRATION_AUDIT.md`.
   - If a referenced Java path does not exist in `origin/main`, stop and report the missing path and audit section. Do not guess or search unrelated files.
2. Inspect those files from `origin/main`.
3. Determine Java behavior from implementation, tests, constants, defaults, side effects, error handling, and UI behavior where relevant.
4. Compare Java behavior with audit notes.
5. If audit and Java disagree:

   * Document the discrepancy.
   * Treat Java as authoritative.
6. Identify the smallest Dart/Flutter change needed for parity.

Use Git source inspection patterns such as:

```bash
git show origin/main:path/to/File.java
```

or other non-destructive Git inspection commands.

If `git show origin/main:path` fails or the path is missing, stop and report the missing Java path and audit section; do not substitute assumptions from comments or unrelated files.

### Phase 3: Flutter/Dart Implementation

Implement the missing behavior in the Flutter branch.

Prioritize:

* Behavioral parity.
* Cross-platform correctness.
* Deterministic execution.
* Compatibility with existing architecture.
* Minimal, focused changes.

Avoid:

* Broad rewrites.
* Unrelated cleanup.
* Cosmetic-only changes.
* New dependencies unless clearly necessary.
* Platform-specific assumptions without guards.

For platform differences, document intentional replacements in the audit.

### Phase 4: Testing

Add focused Dart tests proving Java-compatible behavior.

Tests should be:

* Deterministic.
* Small and targeted.
* Compatible with existing test conventions.
* Independent of asynchronous queue timing where avoidable.
* Based on captured state through test subclasses, dependency injection, or explicit state inspection.

Prefer testing:

* Inputs and outputs.
* State transitions.
* Error handling.
* Defaults and configuration behavior.
* Ordering and filtering logic.
* Platform guard behavior.
* Java-compatible edge cases.

Do not rely on timing when state can be observed directly.

### Phase 5: Local Validation

Run commands sequentially:

```bash
flutter analyze --no-pub
```

Then:

```bash
flutter test --no-pub --reporter expanded
```

Do not run them concurrently.

If either fails:

1. If the analyzer or tests fail because of missing SDK, permission, network, or environment setup, report the blocker explicitly and stop; do not treat environment failures as normal code failures.
2. Inspect the failure.
3. Fix code or tests.
4. Re-run the failing command.
5. Continue until both pass.

Do not commit while analyzer or tests are failing.

### Phase 6: Audit Update

Update `MIGRATION_AUDIT.md` for the completed feature.

Include:

* Feature name.
* Audit section.
* Java source files inspected.
* Actual Java behavior confirmed.
* Flutter/Dart files changed.
* Tests added or updated.
* Local validation outcome.
* CI status.
* Discrepancies between audit and Java, if any.
* Intentional platform replacements, if any.
* Artifact links for Android, Windows, macOS, and Linux when available.
* Remaining follow-up items, if any.

Do not mark an item complete without implementation, a test/guard, or a clearly documented intentional platform replacement.

### Phase 7: CI Check Before Commit

Immediately before committing:

1. Check workflow status for the previous pushed commit.
2. If it succeeded, proceed.
3. If it is queued or running, proceed without idle waiting.
4. If it failed:

   * Inspect logs.
   * Fix failure.
   * Re-run local validation as needed.
   * Combine the CI repair commit and the prepared feature commit only when the previous pushed run failed and the repair directly affects the same feature or workflow needed for that feature to be safe to ship.
   * Update audit with repair details.

### Phase 8: Commit and Push

Commit the completed feature.

Commit message must name the audit feature.

Preferred commit style:

```text
Complete <audit feature name>
```

For combined CI repair plus feature:

```text
Complete <audit feature name> and repair CI
```

Push to:

```bash
origin Flutter
```

After push:

1. Confirm push succeeded.
2. Continue to the next incomplete audit item.
3. Do not stop merely because CI is running.

### Phase 9: Repeat Until Complete

Repeat phases 2 through 8 for each incomplete audit item in strict order.

Stop only when:

* All audit items are complete.
* The audit explicitly says `manual review required`.
* Local tooling or authentication is blocked.
* An unrecoverable CI failure prevents safe continuation.
* A required Java source reference is missing and behavior cannot be verified.

## Input Requirements

The skill expects access to:

* Local repository workspace.
* Git command line.
* Flutter SDK.
* Dart tooling.
* Network access to `origin`.
* GitHub Actions visibility through available tooling or browser.
* Permission to commit and push to `origin Flutter`.

If Flutter SDK, Dart tooling, Git, or required permissions are unavailable, stop and report the exact missing tool or permission error; do not continue with implementation guesses.

Required repository files include:

* `MIGRATION_AUDIT.md`
* Flutter/Dart source files
* Flutter/Dart tests
* Git remote reference `origin/main`
* Git branch `Flutter`

## Processing Logic

For every incomplete audit item, execute this checklist in order:

1. Confirm the next required audit item by workstream and priority.
   - If the audit entry says `manual review required`, stop and report the exact audit section and blocker.
2. Verify the referenced Java source for that audit item.
   - If a referenced Java path is missing or unreadable, stop immediately and report the exact path and audit section. Do not search unrelated Java files unless the audit explicitly names a nearby fallback path.
3. Implement the smallest Dart/Flutter change needed for parity.
4. Add focused deterministic tests that prove the behavior.
5. Run local validation.
6. Update `MIGRATION_AUDIT.md`.
7. Check the previous pushed CI status.
8. Commit and push if the feature is safe and the previous CI state does not block new work.

Precedence rule: do not proceed to the next step until the current step is complete and any blockers are resolved.

## Output Rules

During execution, provide concise progress updates that include:

* Current audit feature.
* Java source inspected.
* Implementation summary.
* Test summary.
* Validation result.
* Commit hash when available.
* Push status.
* CI status when available.
* Stop reason when blocked.

When stopped, report:

* Exact audit section.
* Exact blocker.
* What was completed before stopping.
* What decision or credential is needed.
* Current local validation state.
* Current Git status summary.

Do not report only a plan when implementation is possible.

## Formatting Rules

Use clear structured updates.

When updating `MIGRATION_AUDIT.md`, use the audit’s existing format and style.

When adding new audit notes, include precise evidence such as:

```md
- Java verification: inspected `path/to/File.java` from `origin/main`; confirmed behavior ...
- Flutter implementation: updated `path/to/file.dart`.
- Tests: added `test/path/file_test.dart`.
- Validation: `flutter analyze --no-pub` passed; `flutter test --no-pub --reporter expanded` passed.
- CI: pending/succeeded/failed; artifact links: ...
```

Do not invent artifact links.

Only record artifact links after confirming they exist.

## Hard Rules

You must not:

* Run destructive Git commands.
* Force push.
* Discard or overwrite user changes.
* Run Flutter commands concurrently.
* Ignore known failed CI runs.

## Operational Guidelines

You should also avoid:

* Marking audit items complete without proof.
* Substituting assumptions for Java verification.
* Performing unrelated refactors.
* Adding unnecessary dependencies.
* Stopping merely because CI is queued or running.
* Waiting idly for workflows.
* Asking the user before every routine implementation decision.
* Continuing past a defined blocker without reporting it.

You may:

* Make independent code organization decisions using project conventions.
* Add tests and helpers where appropriate.
* Use combined commits for CI repair plus a prepared feature.
* Document intentional platform replacements.
* Continue working while older workflows are queued or running.
* Inspect CI periodically while doing useful work.

## Edge Cases

### Audit and Java Disagree

Behavior:

1. Java wins.
2. Implement Java behavior.
3. Update audit with discrepancy.
4. Add a test proving the Java-compatible behavior.

### Existing Dart Code Appears Complete

Do not assume completion.

Verify against Java.

If complete, add or confirm test coverage, update audit, validate, commit if audit/test changes were made.

### Missing Java Source Reference

Search only within clearly related Java source if safe.

If behavior cannot be confidently verified, stop and report:

* Audit section.
* Missing path.
* Attempted verification.
* Decision needed.

### Dirty Worktree

Inspect changes.

Do not overwrite unrelated user changes.

Modify only necessary files.

If unrelated changes make safe implementation impossible, stop and report the conflict.

### CI Running

Do not wait idly.

Proceed with the prepared commit and continue work unless a known failure exists.

### CI Failed

Stop new feature work temporarily.

Inspect logs.

Fix the failure.

Run local validation.

Commit and push the repair, combined with the prepared feature when appropriate.

Update audit.

Resume migration.

### Flutter Pub Get Symlink Error

If the only issue is the known Windows Developer Mode symlink error and package configuration is usable, do not treat it as a feature blocker.

Document only if relevant.

### Async Queue Behavior

Do not write timing-dependent tests.

Use injected dependencies, test subclasses, captured state, or explicit synchronization points.

### Platform-Specific Behavior

When Java desktop behavior does not map directly to Flutter or Android:

1. Preserve intent.
2. Implement a platform-appropriate replacement.
3. Add guards/tests.
4. Document the replacement in the audit.

## Error Handling

When a command fails:

1. Capture the exact failing command.
2. Read the relevant error output.
3. Determine whether the failure is code, test, tool, dependency, CI, network, auth, or platform related.
4. Fix code/test failures directly.
5. For tooling/authentication blockers, stop and report the required action.
6. Re-run appropriate validation commands after fixes.
7. Update the audit when the failure affects migration status.

For analyzer failures:

* Fix lint, type, import, null-safety, and API issues.
* Avoid suppressions unless already conventional and justified.

For test failures:

* Determine whether the test or implementation is wrong by comparing to Java behavior.
* Fix the incorrect side.
* Keep tests deterministic.

For CI failures:

* Inspect failed jobs and logs.
* Fix workflow or code failures.
* Do not ignore known failed CI.
* Record repair details in the audit.

## Safety Rules

* Preserve user changes.
* Do not delete files unless clearly required and safe.
* Do not expose secrets, tokens, or credentials.
* Do not commit generated credentials or local machine artifacts.
* Do not make network calls beyond repository, dependency, or CI needs.
* Do not invent successful validation or CI outcomes.
* Do not fabricate artifact links.
* Do not claim parity without evidence.
* Do not continue when a required stop condition is reached.

## Examples

### Example Input

```text
Next incomplete audit item:
Workstream 2 / High Priority / URL Queue Behavior

Referenced Java paths:
- src/main/java/com/rarchives/ripme/ui/MainWindow.java
- src/main/java/com/rarchives/ripme/utils/Utils.java

Current Flutter status:
Partial implementation exists but retry behavior is incomplete.
```

### Example Output

```text
Current audit item: Workstream 2 / High Priority / URL Queue Behavior.

Java verification:
Inspected `MainWindow.java` and `Utils.java` from `origin/main`.
Confirmed Java preserves queue order, ignores blank URLs, trims whitespace, and retries failed URLs once before marking failed.

Implementation:
Updated Flutter queue parsing and retry state handling.

Tests:
Added deterministic queue tests covering whitespace trimming, blank URL rejection, order preservation, and single retry behavior.

Validation:
`flutter analyze --no-pub` passed.
`flutter test --no-pub --reporter expanded` passed.

Audit:
Updated `MIGRATION_AUDIT.md` with Java verification, implementation notes, test evidence, and CI status.

Commit:
`Complete URL Queue Behavior`

Push:
Pushed to `origin Flutter`.
```

### Example Stop Output

```text
Stopped at:
Workstream 4 / Medium Priority / Native File Association Handling

Blocker:
The audit explicitly marks this section as `manual review required`.

Decision needed:
Confirm whether Flutter should implement Java desktop file association behavior directly on Windows/macOS/Linux, or document it as an intentional platform replacement.

Completed before stopping:
All prior High and Medium priority items through Workstream 4 were implemented, tested, validated, committed, and pushed.

Current validation:
Last completed feature passed:
- `flutter analyze --no-pub`
- `flutter test --no-pub --reporter expanded`

Current Git status:
No uncommitted migration changes.
```

## Advanced Enhancements

Use a self-check before each commit:

```text
Migration Self-Check:
- Is this the next required audit item?
- Was Java source from `origin/main` inspected?
- Was any audit/Java discrepancy documented?
- Is the Dart change focused?
- Are tests deterministic?
- Did analyzer pass?
- Did tests pass?
- Was previous pushed CI checked?
- Is the commit message tied to the audit feature?
- Was `MIGRATION_AUDIT.md` updated?
```

Use a parity checklist for each feature:

```text
Parity Checklist:
- Inputs match Java behavior.
- Outputs match Java behavior.
- Defaults match Java behavior.
- Error handling matches Java behavior.
- Ordering matches Java behavior.
- Persistence behavior matches Java behavior where applicable.
- UI-visible behavior matches Java behavior where applicable.
- Platform differences are documented.
```

Use a CI checklist:

```text
CI Checklist:
- Previous pushed commit checked.
- Known failed runs investigated.
- Failed jobs/logs inspected.
- CI repairs committed when needed.
- Platform artifacts recorded only after confirmation.
- Queued/running workflows did not block useful work.
```

## Optional Modes

### Normal Migration Mode

Use for ordinary audit feature completion.

Behavior:

* Process one audit item at a time.
* Implement focused change.
* Add tests.
* Validate.
* Commit and push.
* Continue.

### CI Repair Mode

Use when a known GitHub Actions run failed.

Behavior:

* Pause new feature work.
* Inspect CI logs.
* Fix workflow or code issue.
* Re-run local validation.
* Commit and push repair, combined with prepared feature when appropriate.
* Resume migration.

### Audit Reconciliation Mode

Use when audit and Java disagree.

Behavior:

* Treat Java as authoritative.
* Update audit discrepancy notes.
* Implement Java-compatible behavior.
* Add focused tests.
* Validate and commit.

### Platform Replacement Mode

Use when Java desktop behavior cannot map directly to Flutter or Android.

Behavior:

* Preserve user-facing intent.
* Implement platform-appropriate behavior.
* Add guards/tests.
* Document rationale in audit.

## Suggested Improvements

Future improvements may include:

* A structured audit status table with machine-readable completion flags.
* Dedicated parity test fixtures based on Java examples.
* CI artifact index links grouped by platform.
* A migration dashboard generated from `MIGRATION_AUDIT.md`.
* A reusable command checklist script for validation and CI inspection.
* Additional integration tests for platform-specific behavior.
* Golden tests for UI parity where stable and useful.

## Completion Definition

The migration is genuinely complete only when:

1. `MIGRATION_AUDIT.md` contains no incomplete migration gaps.
2. Every audit item has Java verification or documented platform replacement.
3. Every implemented behavior has focused Dart test coverage or a documented guard.
4. Local validation passes:

   * `flutter analyze --no-pub`
   * `flutter test --no-pub --reporter expanded`
5. Known CI failures are resolved or explicitly documented as blocked.
6. Successful Android, Windows, macOS, and Linux artifact links are recorded when available.
7. The final state is committed and pushed to `origin Flutter`.
8. No defined stop condition remains unresolved.

```
```
