import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ripme/main.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/ripper/abstract_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _BlockingQueueActionRipper extends AbstractRipper {
  _BlockingQueueActionRipper(super.url, this.release);

  final Future<void> release;

  @override
  Future<void> setup() async {}

  @override
  bool canRip(Uri url) => true;

  @override
  Future<String> getGID(Uri url) async => 'queue-actions';

  @override
  String getHost() => 'Queue actions';

  @override
  Future<void> rip() => release;
}

void main() {
  testWidgets('queue removal and confirmed clear match Java actions',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    final release = Completer<void>();
    addTearDown(() {
      if (!release.isCompleted) release.complete();
    });
    final manager = RipManager(
      ripperResolver: (uri) => _BlockingQueueActionRipper(uri, release.future),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: manager,
        child: const RipMeApp(),
      ),
    );
    await tester.pumpAndSettle();

    manager.addUrlToQueue('https://example.com/current');
    manager.addUrlToQueue('https://example.com/two');
    manager.addUrlToQueue('https://example.com/three');
    manager.addUrlToQueue('https://example.com/four');
    await tester.pump();
    await tester.tap(find.text('Queue(3)'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('queue_row_select_0')));
    await tester.drag(find.byType(ListView), const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('queue_row_select_2')));
    await tester.pump();
    expect(manager.selectedQueueRows, {0, 2});

    await tester.tap(find.byKey(const Key('queue_remove_selected')));
    await tester.pumpAndSettle();
    expect(manager.queue, ['https://example.com/three']);
    expect(manager.selectedQueueRows, isEmpty);

    manager.addUrlToQueue('https://example.com/five');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from queue'));
    await tester.pumpAndSettle();
    expect(manager.queue, ['https://example.com/five']);

    await tester.tap(find.byKey(const Key('queue_remove_all')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Are you sure you want to remove all elements from the queue?',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(manager.queue, ['https://example.com/five']);

    await tester.tap(find.byKey(const Key('queue_remove_all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(manager.queue, isEmpty);
  });
}
