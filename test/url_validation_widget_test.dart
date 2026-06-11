import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ripme/main.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/ripper/abstract_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DetectedRipper extends AbstractRipper {
  _DetectedRipper(super.url);

  @override
  bool canRip(Uri url) => true;

  @override
  Future<String> getGID(Uri url) async => 'detected';

  @override
  String getHost() => 'Detected';

  @override
  Future<void> rip() async {}
}

void main() {
  testWidgets('URL field reports detected and unsupported ripper hosts',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    final manager = RipManager(
      ripperResolver: (uri) =>
          uri.host == 'supported.example' ? _DetectedRipper(uri) : null,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: manager,
        child: const RipMeApp(),
      ),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    field.onChanged!('supported.example/album');
    await tester.pump();
    expect(find.text('Detected album detected'), findsOneWidget);

    field.onChanged!('https://unsupported.example/album');
    await tester.pump();
    expect(find.text("Can't rip this URL: No ripper found"), findsOneWidget);
  });
}
