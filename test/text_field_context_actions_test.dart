import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ripme/main.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _sendControlShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

void main() {
  testWidgets('URL field exposes native context actions and undo',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    String clipboardText = '';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        switch (call.method) {
          case 'Clipboard.getData':
            return <String, dynamic>{'text': clipboardText};
          case 'Clipboard.setData':
            clipboardText =
                (call.arguments as Map<dynamic, dynamic>)['text'] as String;
            return null;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => RipManager(),
        child: const RipMeApp(),
      ),
    );
    await tester.pumpAndSettle();

    final fieldFinder = find.byType(TextField).first;
    final field = tester.widget<TextField>(fieldFinder);
    expect(field.undoController, isNotNull);
    expect(field.contextMenuBuilder, isNotNull);
    String fieldText() => tester
        .widget<EditableText>(
          find.descendant(
            of: fieldFinder,
            matching: find.byType(EditableText),
          ),
        )
        .controller
        .text;
    await tester.tap(fieldFinder);
    await tester.enterText(fieldFinder, 'https://example.com/original');

    await _sendControlShortcut(tester, LogicalKeyboardKey.keyA);
    await _sendControlShortcut(tester, LogicalKeyboardKey.keyC);
    expect(clipboardText, 'https://example.com/original');

    await _sendControlShortcut(tester, LogicalKeyboardKey.keyX);
    expect(fieldText(), isEmpty);

    clipboardText = 'https://example.com/replacement';
    await tester.enterText(fieldFinder, 'https://example.com/original');
    await _sendControlShortcut(tester, LogicalKeyboardKey.keyA);
    await _sendControlShortcut(tester, LogicalKeyboardKey.keyV);
    expect(fieldText(), 'https://example.com/replacement');
  });
}
