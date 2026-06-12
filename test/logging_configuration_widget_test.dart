import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ripme/main.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('logging controls persist Java configuration values',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'log.level': 'Log level: Debug',
      'log.save': false,
    });
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
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log level: Debug'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log level: Warn').last);
    await tester.pumpAndSettle();
    expect(
      Utils.getConfigString('log.level', null),
      'Log level: Warn',
    );

    await tester.tap(
      find.ancestor(
        of: find.text('Save logs'),
        matching: find.byType(SwitchListTile),
      ),
    );
    await tester.pumpAndSettle();
    expect(Utils.getConfigBoolean('log.save', false), isTrue);
  });
}
