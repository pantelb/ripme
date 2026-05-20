import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ripme/main.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/utils/utils.dart';

void main() {
  testWidgets('RipMe app shows primary rip controls', (WidgetTester tester) async {
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
    expect(find.text('Config'), findsOneWidget);
  });
}
