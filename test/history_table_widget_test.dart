import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ripme/main.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('history displays Java table columns and date format',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    final manager = RipManager();
    await manager.init();
    await manager.replaceHistory([
      HistoryEntry(
        url: 'https://example.com/history',
        dir: '/tmp/history',
        date: DateTime(2026, 6, 11),
        startDate: DateTime(2026, 5, 9),
        modifiedDate: DateTime(2026, 6, 10),
        count: 7,
        selected: true,
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

    expect(find.text('URL'), findsOneWidget);
    expect(find.text('created'), findsOneWidget);
    expect(find.text('modified'), findsOneWidget);
    expect(find.text('#'), findsOneWidget);
    expect(find.text('https://example.com/history'), findsOneWidget);
    expect(find.text('2026/05/09'), findsOneWidget);
    expect(find.text('2026/06/10'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    final selectedCheckbox = tester.widget<Checkbox>(
      find.byKey(const Key('history_entry_checked_0')),
    );
    expect(selectedCheckbox.value, isTrue);
    final rowSelectionCheckbox = tester.widget<Checkbox>(
      find.byKey(const Key('history_row_select_0')),
    );
    expect(rowSelectionCheckbox.value, isFalse);
  });
}
