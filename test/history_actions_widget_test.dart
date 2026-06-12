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
      HistoryEntry(
        url: 'https://example.com/keep',
        dir: '/tmp/keep',
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

    Future<void> selectCheckAction(String label) async {
      await tester.tap(find.byKey(const Key('history_check_actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    await selectCheckAction('Check All');
    expect(manager.history.every((entry) => entry.selected), isTrue);
    await selectCheckAction('Check None');
    expect(manager.history.every((entry) => !entry.selected), isTrue);

    await tester.tap(find.byKey(const Key('history_row_select_0')));
    await tester.pumpAndSettle();
    await selectCheckAction('Check Selected');
    expect(manager.history[0].selected, isTrue);
    expect(manager.history[1].selected, isFalse);
    await selectCheckAction('Uncheck Selected');
    expect(manager.history.every((entry) => !entry.selected), isTrue);

    await tester.tap(find.byKey(const Key('history_remove_selected')));
    await tester.pumpAndSettle();
    expect(manager.history, hasLength(1));
    expect(manager.history.single.url, 'https://example.com/keep');

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
    expect(find.text('Remove'), findsNWidgets(2));

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
