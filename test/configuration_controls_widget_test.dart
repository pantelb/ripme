import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/l10n/app_localizations.dart';
import 'package:ripme/main.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _switchKeys = <String>[
  'file.overwrite',
  'download.save_order',
  'album_titles.save',
  'urls_only.save',
  'prefer.mp4',
  'errors.skip404',
  'proxy.enabled',
  'ssl.verify.off',
  'twitter.rip_retweets',
  'twitter.exclude_replies',
  'remember.url_history',
  'history.skip_downloaded_urls',
  'history.warn_before_delete',
  'reddit.rip_by_upvote',
  'reddit.use_sub_dirs',
  'clipboard.autorip',
  'play.sound',
  'download.show_popup',
  'log.save',
  'window.position',
];

const _integerValues = <String, int>{
  'threads.size': 7,
  'download.retries': 7,
  'download.retry.sleep': 7000,
  'page.timeout': 7000,
  'download.timeout': 7000,
  'proxy.port': 7000,
  'twitter.max_requests': 7,
  'history.end_rip_after_already_seen': 7,
  'reddit.min_upvotes': 7,
  'reddit.max_upvotes': 7000,
};

const _stringKeys = <String>[
  'download.ignore_extensions',
  'proxy.host',
  'proxy.username',
  'proxy.password',
  'cookies.reddit.com',
  'cookies.imgur.com',
  'cookies.erome.com',
  'cookies.soundgasm.net',
  'cookies.vidble.com',
  'twitter.auth',
  'tumblr.auth',
  'gw.api',
  'erome.laravel_session',
];

Widget _configuration() {
  return const MaterialApp(
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: ConfigurationView()),
  );
}

Future<void> _showControl(WidgetTester tester, String key) async {
  await tester.scrollUntilVisible(
    find.byKey(Key('config.$key')),
    500,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollToTop(WidgetTester tester) async {
  tester
      .state<ScrollableState>(find.byType(Scrollable).last)
      .position
      .jumpTo(0);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every generic configuration control persists its Java key',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      for (final key in _switchKeys) key: false,
    });
    await Utils.init();
    await tester.pumpWidget(_configuration());
    await tester.pumpAndSettle();

    for (final key in _switchKeys) {
      await _showControl(tester, key);
      await tester.tap(find.byKey(Key('config.$key')));
      await tester.pumpAndSettle();
      expect(
        Utils.getConfigBoolean(key, false),
        isTrue,
        reason: 'Configuration switch did not persist $key',
      );
    }

    await _scrollToTop(tester);
    for (final entry in _integerValues.entries) {
      await _showControl(tester, entry.key);
      await tester.tap(find.byKey(Key('config.${entry.key}')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), entry.value.toString());
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        Utils.getConfigInteger(entry.key, -1),
        entry.value,
        reason: 'Configuration integer did not persist ${entry.key}',
      );
    }

    await _scrollToTop(tester);
    for (var index = 0; index < _stringKeys.length; index++) {
      final key = _stringKeys[index];
      final value = 'configured-$index';
      await _showControl(tester, key);
      await tester.tap(find.byKey(Key('config.$key')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), value);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        Utils.getConfigString(key, null),
        value,
        reason: 'Configuration string did not persist $key',
      );
    }
  });
}
