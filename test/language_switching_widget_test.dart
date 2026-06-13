import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/l10n/app_localizations.dart';
import 'package:ripme/main.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('language selection persists and relocalizes immediately',
      (tester) async {
    SharedPreferences.setMockInitialValues({'lang': 'en-US'});
    await Utils.init();
    await tester.pumpWidget(const _LanguageHost(initialTag: 'en-US'));
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButton<String>>(
      find.byKey(const Key('config.lang')),
    );
    dropdown.onChanged!('el-GR');
    await tester.pumpAndSettle();

    expect(Utils.getConfigString('lang', null), 'el-GR');
    expect(find.text('Τρέχουσα έκδοση'), findsOneWidget);

    await Utils.init();
    expect(Utils.getConfigString('lang', null), 'el-GR');

    await Utils.setConfigString('lang', 'fi-FI-porrisavo');
    await tester.pumpWidget(
      const _LanguageHost(
        key: ValueKey('finnish-variant'),
        initialTag: 'fi-FI-porrisavo',
      ),
    );
    await tester.pumpAndSettle();

    final variantDropdown = tester.widget<DropdownButton<String>>(
      find.byKey(const Key('config.lang')),
    );

    expect(variantDropdown.value, 'fi-FI-porrisavo');
    expect(
      Localizations.localeOf(tester.element(find.byType(LanguageSelector))),
      const Locale('fi'),
    );
  });
}

class _LanguageHost extends StatefulWidget {
  const _LanguageHost({super.key, required this.initialTag});

  final String initialTag;

  @override
  State<_LanguageHost> createState() => _LanguageHostState();
}

class _LanguageHostState extends State<_LanguageHost> {
  late String tag;

  @override
  void initState() {
    super.initState();
    tag = widget.initialTag;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: AppLocalizations.localeFromLanguageTag(tag),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Column(
          children: [
            Builder(
              builder: (context) =>
                  Text(AppLocalizations.of(context).currentVersion),
            ),
            LanguageSelector(
              selectedLanguageTag: tag,
              onLanguageChanged: (value) => setState(() => tag = value),
            ),
          ],
        ),
      ),
    );
  }
}
