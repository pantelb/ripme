import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/motherless_video_ripper.dart';

void main() {
  test('matches Java direct video URL detection and GID parsing', () async {
    final cases = {
      'https://motherless.com/0D2D897': '0D2D897',
      'http://www.motherless.com/ABC123?foo=bar': 'ABC123',
      'https://m.motherless.com/ABCDEF1/more': 'ABCDEF1',
      'https://motherless.com/GI471FFFF': 'GI471FFFF',
    };

    for (final entry in cases.entries) {
      final uri = Uri.parse(entry.key);
      final ripper = MotherlessVideoRipper(uri);
      expect(ripper.canRip(uri), isTrue, reason: entry.key);
      expect(await ripper.getGID(uri), entry.value, reason: entry.key);
    }

    final lowercase = Uri.parse('https://motherless.com/abc123');
    final wrongHost = Uri.parse('https://example.com/ABC123');
    expect(MotherlessVideoRipper(lowercase).canRip(lowercase), isFalse);
    expect(MotherlessVideoRipper(wrongHost).canRip(wrongHost), isFalse);

    await expectLater(
      MotherlessVideoRipper(lowercase).getGID(lowercase),
      throwsA(isA<FormatException>()),
    );
  });

  test('extracts the first Java __fileurl video URL', () {
    final page = Uri.parse('https://motherless.com/0D2D897');
    const html = """
      <script>var __fileurl = 'https://cdn.example.com/first.mp4';</script>
      <script>var __fileurl = 'https://cdn.example.com/second.mp4';</script>
    """;

    expect(
      MotherlessVideoRipper.videoUrlFromHtml(html, page).toString(),
      'https://cdn.example.com/first.mp4',
    );

    expect(
      () => MotherlessVideoRipper.videoUrlFromHtml('<html></html>', page),
      throwsA(isA<HttpException>()),
    );
  });

  test('builds Java Motherless video download filenames', () {
    expect(
      MotherlessVideoRipper.javaDownloadFileName(
        Uri.parse('https://cdn.example.com/video.mp4?token=1'),
        '0D2D897',
      ),
      'motherless_0D2D897video.mp4',
    );
    expect(
      MotherlessVideoRipper.javaDownloadFileName(
        Uri.parse('https://cdn.example.com/video:bad.mp4'),
        'ABC123',
      ),
      'motherless_ABC123video',
    );
  });
}
