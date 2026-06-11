import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ripme/main.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('language selection persists and reloads localized UI',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'lang': 'en-US'});
    await Utils.init();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => RipManager()..init(),
        child: const RipMeApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configuration'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Language'),
      500,
      scrollable: find.byType(Scrollable).last,
    );

    await tester.tap(find.text('en-US'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('el-GR').last);
    await tester.pumpAndSettle();

    expect(Utils.getConfigString('lang', null), 'el-GR');
    expect(find.text('Ρυθμίσεις'), findsOneWidget);
  });
}
