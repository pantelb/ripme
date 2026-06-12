import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:ripme/l10n/app_localizations.dart';
import 'package:ripme/main.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/utils/utils.dart';

void main() {
  testWidgets('completion shows Java open-folder button until the next rip',
      (tester) async {
    final directory = p.join('abcdefghijkl', 'album', 'qrstuvwxyz12');
    final manager = _StatusRipManager(directory);

    await tester.pumpWidget(_testApp(manager));
    await tester.pump();

    expect(find.byKey(const Key('open_completed_directory')), findsOneWidget);
    expect(
      find.text('Open ${Utils.shortenPath(directory)}'),
      findsOneWidget,
    );

    await tester.pumpWidget(_testApp(_StatusRipManager(null)));

    expect(find.byKey(const Key('open_completed_directory')), findsNothing);
  });

  test('shortens completion paths with Java twelve-character ends', () {
    expect(Utils.shortenPath('short/path'), p.normalize('short/path'));
    final longPath = p.normalize(
      p.join('abcdefghijkl', 'middle', 'qrstuvwxyz12'),
    );
    expect(
      Utils.shortenPath(longPath),
      '${longPath.substring(0, 12)}...'
      '${longPath.substring(longPath.length - 12)}',
    );
  });
}

class _StatusRipManager extends RipManager {
  _StatusRipManager(this._directory);

  final String? _directory;

  @override
  String? get completedDirectory => _directory;

  @override
  int get progressPercent => 0;

  @override
  double get progressValue => 0;

  @override
  String get statusText => 'Inactive';
}

Widget _testApp(RipManager manager) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: ProgressStrip(ripManager: manager)),
  );
}
