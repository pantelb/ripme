import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all Java-derived runtime resources exist and are non-empty', () {
    const paths = <String>[
      'LICENSE.txt',
      'assets/comment.png',
      'assets/folder.png',
      'assets/gear.png',
      'assets/icon.ico',
      'assets/icon.png',
      'assets/list.png',
      'assets/sounds/camera.wav',
      'assets/stop.png',
      'assets/time.png',
      'assets/wrench.png',
      'src/main/resources/LabelsBundle.properties',
      'src/main/resources/LabelsBundle_ar_AR.properties',
      'src/main/resources/LabelsBundle_de_DE.properties',
      'src/main/resources/LabelsBundle_el_GR.properties',
      'src/main/resources/LabelsBundle_en_US.properties',
      'src/main/resources/LabelsBundle_es_ES.properties',
      'src/main/resources/LabelsBundle_fi_FI.properties',
      'src/main/resources/LabelsBundle_fi_FI_porrisavo.properties',
      'src/main/resources/LabelsBundle_fr_CH.properties',
      'src/main/resources/LabelsBundle_in_ID.properties',
      'src/main/resources/LabelsBundle_it_IT.properties',
      'src/main/resources/LabelsBundle_kr_KR.properties',
      'src/main/resources/LabelsBundle_nl_NL.properties',
      'src/main/resources/LabelsBundle_pl_PL.properties',
      'src/main/resources/LabelsBundle_pt_BR.properties',
      'src/main/resources/LabelsBundle_pt_PT.properties',
      'src/main/resources/LabelsBundle_ru_RU.properties',
      'src/main/resources/LabelsBundle_zh_CN.properties',
    ];

    for (final path in paths) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      expect(file.lengthSync(), greaterThan(0), reason: path);
    }
  });

  test('license is declared in every platform package', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final linux = File('linux/CMakeLists.txt').readAsStringSync();
    final windows = File('windows/CMakeLists.txt').readAsStringSync();
    final macos =
        File('macos/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final metadata =
        File('linux/com.rarchives.ripme.metainfo.xml').readAsStringSync();

    expect(pubspec, contains('- LICENSE.txt'));
    expect(linux, contains('../LICENSE.txt'));
    expect(windows, contains('../LICENSE.txt'));
    expect(macos, contains('LICENSE.txt in Resources'));
    expect(metadata, contains('<project_license>MIT</project_license>'));
  });
}
