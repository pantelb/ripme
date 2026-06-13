import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/l10n/app_localizations.dart';
import 'package:ripme/main.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _configuration({
  required Future<String?> Function() directoryPicker,
  required bool isAndroid,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ConfigurationView(
        directoryPicker: directoryPicker,
        isAndroid: isAndroid,
      ),
    ),
  );
}

void main() {
  testWidgets('desktop save directory selection and cancellation',
      (tester) async {
    String? selectedDirectory = '/selected/rips';
    var pickerCalls = 0;
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    await tester.pumpWidget(
      _configuration(
        directoryPicker: () async {
          pickerCalls++;
          return selectedDirectory;
        },
        isAndroid: false,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(Utils.getConfigString('rips.directory', null), '/selected/rips');
    expect(find.text('/selected/rips'), findsOneWidget);
    expect(pickerCalls, 1);

    selectedDirectory = null;
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(Utils.getConfigString('rips.directory', null), '/selected/rips');
    expect(find.text('/selected/rips'), findsOneWidget);
    expect(pickerCalls, 2);
  });
}
