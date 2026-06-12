import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ripme/l10n/app_localizations.dart';
import 'package:ripme/main.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/utils/utils.dart';

void main() {
  testWidgets('LogView clear action removes manager logs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    final manager = RipManager();
    addTearDown(manager.dispose);
    manager.stop();
    expect(manager.logs, hasLength(1));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: manager,
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer<RipManager>(
              builder: (context, value, child) =>
                  LogView(logs: value.logs, ripManager: value),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('log_text_block')), findsOneWidget);

    await tester.tap(find.byKey(const Key('log_clear_button')));
    await tester.pumpAndSettle();

    expect(manager.logs, isEmpty);
    expect(find.byKey(const Key('log_text_block')), findsNothing);
  });
}
