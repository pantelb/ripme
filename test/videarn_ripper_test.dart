import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/videarn_ripper.dart';

void main() {
  test('matches Java Videarn URL detection and GID parsing', () async {
    final cases = {
      'https://videarn.com/example-title/12345': '12345',
      'http://www.videarn.com/example-title/98765?x=1': '98765',
      'https://m.videarn.com/a-b-c/1/more': '1',
    };

    for (final entry in cases.entries) {
      final uri = Uri.parse(entry.key);
      final ripper = VidearnRipper(uri);
      expect(ripper.canRip(uri), isTrue, reason: entry.key);
      expect(await ripper.getGID(uri), entry.value, reason: entry.key);
    }

    final invalid = Uri.parse('https://videarn.com/example-title/notnumeric');
    expect(VidearnRipper(invalid).canRip(invalid), isFalse);
    await expectLater(
      VidearnRipper(invalid).getGID(invalid),
      throwsA(isA<FormatException>()),
    );
  });

  test('extracts the first file URL like Java Utils.between', () {
    final pageUrl = Uri.parse('https://videarn.com/example-title/12345');
    const source = '''
      player.setup({file:"https://cdn.example.com/first.mp4?token=1"});
      player.setup({file:"https://cdn.example.com/second.mp4"});
    ''';

    expect(
      VidearnRipper.videoUrlFromHtml(source, pageUrl).toString(),
      'https://cdn.example.com/first.mp4?token=1',
    );
    expect(
      () => VidearnRipper.videoUrlFromHtml('<html></html>', pageUrl),
      throwsA(isA<HttpException>()),
    );
  });

  test('builds Java Videarn video download filenames', () {
    expect(
      VidearnRipper.javaDownloadFileName(
        Uri.parse('https://cdn.example.com/video.mp4?token=1'),
        '12345',
      ),
      'videarn_12345video.mp4',
    );
    expect(
      VidearnRipper.javaDownloadFileName(
        Uri.parse('https://cdn.example.com/video:bad.mp4'),
        '98765',
      ),
      'videarn_98765video',
    );
  });
}
