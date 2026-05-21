import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exposes Java bundle locale set to Flutter', () {
    expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
    expect(AppLocalizations.supportedLocales, contains(const Locale('el')));
    expect(
        AppLocalizations.supportedLocales, contains(const Locale('pt', 'BR')));
    expect(
        AppLocalizations.supportedLocales, contains(const Locale('zh', 'CN')));
  });

  test('falls back to migrated English UI labels', () async {
    final strings = await AppLocalizations.delegate.load(const Locale('en'));

    expect(strings.enterUrlToRip, 'Enter URL to rip');
    expect(strings.clearDownloadedUrlHistory, 'Clear downloaded URL history');
    expect(strings.historyImportFailed('bad data'),
        'History import failed: bad data');
    expect(strings.range(1, 5), 'Range: 1-5');
  });

  test('loads restored Java label bundles for matching keys', () async {
    final strings = await AppLocalizations.delegate.load(const Locale('el'));

    expect(strings.history, 'Ιστορικό');
    expect(strings.queue, 'Ουρά');
    expect(strings.config, 'Ρυθμίσεις');
  });
}
