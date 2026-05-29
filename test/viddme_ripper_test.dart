import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/viddme_ripper.dart';

void main() {
  test('matches Java vid.me URL detection and GID parsing', () async {
    final cases = {
      'https://vid.me/abc123': 'abc123',
      'http://www.vid.me/ABC123?x=1': 'ABC123',
      'https://m.vid.me/a1b2/path': 'a1b2',
    };

    for (final entry in cases.entries) {
      final uri = Uri.parse(entry.key);
      final ripper = ViddmeRipper(uri);
      expect(ripper.canRip(uri), isTrue, reason: entry.key);
      expect(await ripper.getGID(uri), entry.value, reason: entry.key);
    }

    final invalid = Uri.parse('https://vid.me/');
    expect(ViddmeRipper(invalid).canRip(invalid), isFalse);
    await expectLater(
      ViddmeRipper(invalid).getGID(invalid),
      throwsA(isA<FormatException>()),
    );
  });

  test('extracts twitter player stream content like Java', () {
    final pageUrl = Uri.parse('https://vid.me/abc123');
    final page = html.parse('''
      <meta name="twitter:player:stream"
          content="https://cdn.example.com/video.mp4?token=1&amp;quality=hd">
    ''');

    expect(
      ViddmeRipper.videoUrlFromDocument(page, pageUrl).toString(),
      'https://cdn.example.com/video.mp4?token=1&quality=hd',
    );

    expect(
      () => ViddmeRipper.videoUrlFromDocument(
          html.parse('<html></html>'), pageUrl),
      throwsA(isA<HttpException>()),
    );
  });

  test('builds Java Viddme video download filenames', () {
    expect(
      ViddmeRipper.javaDownloadFileName(
        Uri.parse('https://cdn.example.com/video.mp4?token=1'),
        'abc123',
      ),
      'vid_abc123video.mp4',
    );
    expect(
      ViddmeRipper.javaDownloadFileName(
        Uri.parse('https://cdn.example.com/video:bad.mp4'),
        'ABC123',
      ),
      'vid_ABC123video',
    );
  });
}
