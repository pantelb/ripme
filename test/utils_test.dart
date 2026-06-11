import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:ripme/utils/utils.dart';

void main() {
  test('Utils filesystemSafe', () {
    expect(Utils.filesystemSafe('hello/world?'), equals('helloworld'));
    expect(Utils.filesystemSafe('valid-name_123'), equals('valid-name_123'));
    final longName = List.filled(101, 'a').join();
    expect(
      Utils.filesystemSafe('$longName!'),
      equals(List.filled(99, 'a').join()),
    );
  });

  test('Utils filesystemSanitized matches Java replacement rules', () {
    expect(
      Utils.filesystemSanitized('Album name_1,2/3'),
      equals('Album_name_1_2_3'),
    );
  });

  test('Utils getOriginalDirectory preserves existing directory case',
      () async {
    final parent = await Directory.systemTemp.createTemp('ripme_case_test');
    addTearDown(() => parent.delete(recursive: true));
    await Directory(p.join(parent.path, 'Mixed Case')).create();

    final resolved = await Utils.getOriginalDirectory(
      p.join(parent.path, 'mixed case'),
      caseSensitivePlatform: true,
    );

    expect(p.basename(resolved), 'Mixed Case');
  });

  test('Utils sanitizeSaveAs', () {
    expect(Utils.sanitizeSaveAs('file*name.jpg'), equals('file_name.jpg'));
    expect(
      Utils.sanitizeSaveAs('This is a " !<? test'),
      equals('This is a _ !__ test'),
    );
  });

  test('Utils shortenSaveAsWindows matches Java path fixture', () {
    final filename = '${List.filled(254, 'f').join()}.png';

    final shortened = Utils.shortenSaveAsWindows(
      'D:/rips/test/reddit/deep',
      filename,
    );

    expect(
      shortened.replaceAll(r'\', '/'),
      'D:/rips/test/reddit/deep/'
          '${List.filled(208, 'f').join()}.png',
    );
    expect(shortened.length, 237);
  });

  test('Utils shortenSaveAsWindows rejects an exhausted parent path', () {
    expect(
      () => Utils.shortenSaveAsWindows(
        List.filled(260, 'x').join(),
        'file.png',
      ),
      throwsA(isA<FileSystemException>()),
    );
  });
}
