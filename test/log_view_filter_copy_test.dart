import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ripme/l10n/app_localizations.dart';
import 'package:ripme/main.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/ui/rip_status_message.dart';
import 'package:ripme/utils/utils.dart';

void main() {
  testWidgets('LogView filters and copies only visible lines', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    final manager = RipManager();
    addTearDown(manager.dispose);
    final logs = [
      RipStatusMessage(RipStatus.downloadComplete, '/tmp/one.jpg'),
      RipStatusMessage(RipStatus.downloadWarn, 'Retrying request'),
      RipStatusMessage(RipStatus.downloadComplete, '/tmp/two.jpg'),
    ];
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: LogView(logs: logs, ripManager: manager)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('log_filter_field')),
      'DOWNLOADED',
    );
    await tester.pump();

    final text = tester.widget<SelectableText>(
      find.byKey(const Key('log_text_block')),
    );
    expect(text.data, 'Downloaded /tmp/one.jpg\nDownloaded /tmp/two.jpg');

    await tester.tap(find.byKey(const Key('log_copy_button')));
    await tester.pump();
    expect(clipboardText, text.data);
  });
}
