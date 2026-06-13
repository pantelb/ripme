# RipMe (Flutter)

A unified cross-platform application for ripping albums from various websites, built with Flutter.

## Supported Platforms
- Windows
- Linux
- macOS
- Android

## Features
- Java-compatible behavior across the audited migration surface.
- Multi-threaded ripping engine.
- Local history and configuration persistence.
- Cross-platform directory picking.
- Dark mode support.

## Getting Started
To build and run the application, you need to have [Flutter](https://flutter.dev/docs/get-started/install) installed on your system.

```bash
flutter pub get
flutter run
```

## Running Tests
```bash
flutter test
```

## Android Storage

Android downloads are stored in RipMe's app-specific external `rips` directory,
with the app documents directory as a fallback. This location does not require
legacy storage, media-read, or all-files permissions. Android removes
app-specific files when the application is uninstalled, so move downloads that
must be retained before uninstalling.

Arbitrary save-directory selection remains available on Windows, Linux, and
macOS. It is intentionally disabled on Android: the system tree picker grants
URI access, while RipMe's Java-compatible ripping engine writes through
filesystem paths. Converting the selected URI to a raw path would not provide
reliable scoped-storage access across restarts.

## Updates And Releases

RipMe checks the latest release in `pantelb/ripme` and opens its GitHub release
page. The Flutter application does not replace its running executable in place.
Install the appropriate Android, Windows, macOS, or Linux release artifact
using that platform's normal installation or replacement process.

The `-j` / `--update` CLI option performs the same release check and prints the
release notes and URL; it does not download, install, or launch an update.
Every Flutter release also publishes `SHA256SUMS.txt` for manual artifact
verification. This replaces Java's `currentHash` check, which applied to the
jar downloaded by the in-process updater.

Release tags provide the semantic app version, and GitHub Actions supplies the
numeric build number. Both values are embedded in Android, Windows, macOS, and
the Dart UI/CLI from the same release build invocation.

Release files preserve Java's `ripme-<version>` prefix and add the native target:
`linux-x64.tar.gz`, `windows-x64.zip`, `macos-universal.zip`, `android.apk`, and
`android.aab`.
