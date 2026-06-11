import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ripme/main.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('history row actions and warned clear match Java',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'history.warn_before_delete': true,
    });
    await Utils.init();
    final manager = RipManager(ripperResolver: (uri) => null);
    await manager.init();
    await manager.replaceHistory([
      HistoryEntry(
        url: 'https://example.com/actions',
        dir: '/tmp/actions',
        date: DateTime(2026),
      ),
    ]);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: manager,
        child: const RipMeApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Re-rip Checked'));
    await tester.pumpAndSettle();
    expect(find.text('RipMe Error'), findsOneWidget);
    expect(
      find.textContaining("No history entries have been 'Checked'"),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text('Copy URL'), findsOneWidget);
    expect(find.text('Rip again'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);

    await tester.tap(find.text('Copy URL'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear history'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure?'), findsOneWidget);
    await tester.tap(find.text('NO'));
    await tester.pumpAndSettle();
    expect(manager.history, hasLength(1));

    await tester.tap(find.text('Clear history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('YES'));
    await tester.pumpAndSettle();
    expect(manager.history, isEmpty);
  });
}
