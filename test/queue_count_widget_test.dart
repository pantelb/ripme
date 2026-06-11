import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ripme/main.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/ripper/abstract_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _BlockingQueueRipper extends AbstractRipper {
  _BlockingQueueRipper(super.url, this.release);

  final Future<void> release;

  @override
  Future<void> setup() async {}

  @override
  bool canRip(Uri url) => true;

  @override
  Future<String> getGID(Uri url) async => 'queue';

  @override
  String getHost() => 'Queue';

  @override
  Future<void> rip() => release;
}

void main() {
  testWidgets('Queue tab shows Java-style pending count',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    final release = Completer<void>();
    addTearDown(() {
      if (!release.isCompleted) release.complete();
    });
    final manager = RipManager(
      ripperResolver: (uri) => _BlockingQueueRipper(uri, release.future),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: manager,
        child: const RipMeApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Queue'), findsOneWidget);
    manager.addUrlToQueue('https://example.com/current');
    manager.addUrlToQueue('https://example.com/two');
    manager.addUrlToQueue('https://example.com/three');
    await tester.pump();

    expect(find.text('Queue(2)'), findsOneWidget);

    manager.removeFromQueue(0);
    await tester.pump();
    expect(find.text('Queue(1)'), findsOneWidget);

    manager.clearQueue();
    await tester.pump();
    expect(find.text('Queue'), findsOneWidget);
  });
}
