import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ripme/main.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('404 switch persists Java plural runtime key', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'errors.skip404': false,
      'error.skip404': true,
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
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    await tester.tap(
      find.ancestor(
        of: find.text('Skip retries after 404'),
        matching: find.byType(SwitchListTile),
      ),
    );
    await tester.pumpAndSettle();

    expect(Utils.getConfigBoolean('errors.skip404', false), isTrue);
    expect(Utils.getConfigBoolean('error.skip404', false), isTrue);
  });
}
