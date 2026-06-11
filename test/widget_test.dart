import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ripme/main.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/utils/utils.dart';

void main() {
  testWidgets('RipMe app shows primary rip controls',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => RipManager()..init(),
        child: const RipMeApp(),
      ),
    );

    await tester.pump();

    expect(find.text('RipMe'), findsOneWidget);
    expect(find.text('Enter URL to rip'), findsOneWidget);
    expect(find.text('Rip'), findsOneWidget);
    expect(find.text('Log'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Queue'), findsOneWidget);
    expect(find.text('Configuration'), findsOneWidget);

    await tester.tap(find.text('Configuration'));
    await tester.pumpAndSettle();

    expect(find.text('Save URLs only'), findsOneWidget);
    expect(find.text('Prefer MP4 over GIF'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Prefer MP4 over GIF'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Prefer MP4 over GIF'));
    await tester.pumpAndSettle();
    expect(Utils.getConfigBoolean('prefer.mp4', false), isTrue);

    await tester.scrollUntilVisible(
      find.text('Maximum download threads:'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Maximum download threads:'), findsOneWidget);
    expect(find.text('Retry download count:'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Ignored extensions'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Ignored extensions'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Remember URL history'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Remember URL history'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Warn before deleting history'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Warn before deleting history'));
    await tester.pumpAndSettle();
    expect(
      Utils.getConfigBoolean('history.warn_before_delete', true),
      isFalse,
    );

    await tester.scrollUntilVisible(
      find.text('Filter by upvotes'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Filter by upvotes'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Auto-update has been replaced by GitHub releases'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    final retiredAutoUpdate = tester.widget<SwitchListTile>(
      find.widgetWithText(
        SwitchListTile,
        'Auto-update has been replaced by GitHub releases',
      ),
    );
    expect(retiredAutoUpdate.value, isFalse);
    expect(retiredAutoUpdate.onChanged, isNull);
    expect(
      tester
          .widget<ListTile>(find.widgetWithText(ListTile, 'Check for updates'))
          .onTap,
      isNotNull,
    );
  });
}
