import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ripme/main.dart';
import 'package:ripme/l10n/app_localizations.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/ui/rip_status_message.dart';
import 'package:ripme/utils/utils.dart';

void main() {
  testWidgets('LogView renders Java-style plain text lines instead of rows',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    final manager = RipManager();
    final logs = [
      RipStatusMessage(
        RipStatus.downloadStarted,
        'https://example.com/one.jpg',
      ),
      RipStatusMessage(RipStatus.downloadComplete, '/tmp/one.jpg'),
      RipStatusMessage(RipStatus.downloadWarn, 'Retrying request'),
      RipStatusMessage(RipStatus.ripComplete, '/tmp/rips/example'),
    ];

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: manager,
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: LogView(logs: logs, ripManager: manager)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('log_text_block')), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(find.byType(PopupMenuButton<String>), findsNothing);

    final text = tester.widget<SelectableText>(
      find.byKey(const Key('log_text_block')),
    );
    expect(text.data, contains('Downloading https://example.com/one.jpg'));
    expect(text.data, contains('Downloaded /tmp/one.jpg'));
    expect(text.data, contains('Retrying request'));
    expect(text.data, contains('Rip complete, saved to /tmp/rips/example'));
  });
}
