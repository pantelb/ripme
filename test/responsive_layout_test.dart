import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ripme/main.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('all main tabs adapt from Android phone to desktop width',
      (tester) async {
    await _pumpAtSize(
      tester,
      size: const Size(360, 800),
      platform: TargetPlatform.android,
    );

    await _verifyTabs(tester);

    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pump(const Duration(seconds: 1));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
    expect(tester.takeException(), isNull);
    await _verifyTabs(tester);
  });
}

Future<void> _pumpAtSize(
  WidgetTester tester, {
  required Size size,
  required TargetPlatform platform,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  debugDefaultTargetPlatformOverride = platform;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  SharedPreferences.setMockInitialValues({});
  await Utils.init();

  try {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => RipManager()..init(),
        child: const RipMeApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
  expect(tester.takeException(), isNull);
}

Future<void> _verifyTabs(WidgetTester tester) async {
  expect(find.byType(Tab), findsNWidgets(4));
  for (var index = 0; index < 4; index++) {
    await tester.tap(find.byType(Tab).at(index));
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.takeException(),
      isNull,
      reason: 'Tab $index overflowed at ${tester.view.physicalSize}',
    );
  }
}
