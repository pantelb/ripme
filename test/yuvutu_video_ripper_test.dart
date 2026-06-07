import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/yuvutu_video_ripper.dart';

void main() {
  test('matches Java Yuvutu video URL support and GID parsing', () async {
    final uri = Uri.parse('http://www.yuvutu.com/video/12345/example-slug');
    final ripper = YuvutuVideoRipper(uri);

    expect(ripper.getHost(), 'yuvutu');
    expect(ripper.canRip(uri), isTrue);
    expect(
      ripper.canRip(Uri.parse('https://www.yuvutu.com/video/12345/example')),
      isFalse,
    );
    expect(
      ripper.canRip(
        Uri.parse(
          'http://www.yuvutu.com/modules.php?name=YuGallery&action=view&set_id=12345',
        ),
      ),
      isFalse,
    );
    expect(await ripper.getGID(uri), 'example-slug');
  });

  test('extracts iframe src and Java file marker', () {
    final page = parse('<iframe src="/embed/12345"></iframe>');
    final iframePage = parse('''
      <script>var player = { file: "https://cdn.example/video.mp4?token=abc" };</script>
    ''');

    expect(
      YuvutuVideoRipper.iframeSrcFromDocument(
        page,
        Uri.parse('http://www.yuvutu.com/video/12345/example-slug'),
      ),
      '/embed/12345',
    );
    expect(
      YuvutuVideoRipper.videoUrlFromDocument(
        iframePage,
        Uri.parse('http://www.yuvutu.com/video/12345/example-slug'),
      ).toString(),
      'https://cdn.example/video.mp4?token=abc',
    );
  });

  test('keeps Java missing iframe and script errors', () {
    final pageUrl = Uri.parse('http://www.yuvutu.com/video/12345/example-slug');

    expect(
      () => YuvutuVideoRipper.iframeSrcFromDocument(
          parse('<main></main>'), pageUrl),
      throwsA(isA<HttpException>()),
    );
    expect(
      () => YuvutuVideoRipper.videoUrlFromDocument(
          parse('<main></main>'), pageUrl),
      throwsA(isA<HttpException>()),
    );
  });

  test('builds Java-style prefixed video filenames', () {
    expect(
      YuvutuVideoRipper.javaDownloadFileName(
        Uri.parse('https://cdn.example/path/movie.mp4?token=abc'),
        'example-slug',
      ),
      'yuvutu_example-slugmovie.mp4',
    );
  });
}
