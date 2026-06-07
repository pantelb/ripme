import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/pornhub_video_ripper.dart';

void main() {
  test('matches Java Pornhub video URL support and GID parsing', () async {
    final uri =
        Uri.parse('https://www.pornhub.com/view_video.php?viewkey=abc123');
    final ripper = PornhubVideoRipper(uri);

    expect(ripper.getHost(), 'pornhub');
    expect(ripper.canRip(uri), isTrue);
    expect(
      ripper.canRip(
          Uri.parse('http://m.pornhub.com/view_video.php?viewkey=abc123')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://www.pornhub.com/album/15680522')),
      isFalse,
    );
    expect(
      ripper.canRip(
          Uri.parse('https://www.pornhub.com/view_video.php?viewkey=ABC123')),
      isFalse,
    );
    expect(await ripper.getGID(uri), 'abc123');
  });

  test('reconstructs Java quality variables and selects highest quality', () {
    final source = PornhubVideoRipper.bestVideoFromHtml(
      r'''<body>var raA="https:\/\/cdn.example\/";var raB="low.mp4?token=1";var quality_240 = raA raB;flashvars={};var raC="https:\/\/cdn.example\/";var raD="high" + ".mp4?token=2";var quality_720 = raC raD;</body>''',
      Uri.parse('https://www.pornhub.com/view_video.php?viewkey=abc123'),
    );

    expect(source.quality, 720);
    expect(source.url.toString(), 'https://cdn.example/high.mp4?token=2');
  });

  test('throws Java-style missing encrypted video errors', () {
    expect(
      () => PornhubVideoRipper.bestVideoFromHtml(
        '<body>no encrypted variables</body>',
        Uri.parse('https://www.pornhub.com/view_video.php?viewkey=abc123'),
      ),
      throwsA(isA<HttpException>()),
    );
  });

  test('builds Java-style quality and viewkey filename prefix', () {
    expect(
      PornhubVideoRipper.javaDownloadFileName(
        Uri.parse('https://cdn.example/path/high.mp4?token=2'),
        'abc123',
        720,
      ),
      'pornhub_720p_abc123high.mp4',
    );
  });
}
