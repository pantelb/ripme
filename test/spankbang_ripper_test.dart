import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/spankbang_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('SpankbangRipper matches Java URL detection, host, domain, and GID',
      () async {
    final url = Uri.parse('https://spankbang.com/2a7fh/video/mdb901');
    final ripper = SpankbangRipper(url);

    expect(ripper.getHost(), 'spankbang');
    expect(ripper.getDomain(), 'spankbang.com');
    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(Uri.parse('http://www.spankbang.com/abc/video/title')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://m.spankbang.com/a/b/video/title')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://spankbang.com/abc/not-video/title')),
      isFalse,
    );
    expect(ripper.canRip(Uri.parse('https://example.com/abc/video/title')),
        isFalse);

    expect(await ripper.getGID(url), 'mdb901');
    expect(
      await ripper.getGID(
        Uri.parse('http://www.spankbang.com/abc/video/title?x=1'),
      ),
      'title?x=1',
    );
    expect(
      await ripper.getGID(Uri.parse('https://m.spankbang.com/a/b/video/title')),
      'title',
    );

    await expectLater(
      ripper.getGID(Uri.parse('https://spankbang.com/abc/not-video/title')),
      throwsA(isA<FormatException>()),
    );
  });

  test('SpankbangRipper extracts .video-js source src like Java', () {
    final page = html.parse('''
      <video class="video-js">
        <source src="https://cdn.example.com/first.mp4">
        <source src="https://cdn.example.com/second.mp4">
      </video>
    ''');

    expect(SpankbangRipper.videoUrlsFromDocument(page), [
      'https://cdn.example.com/first.mp4',
    ]);
  });

  test('SpankbangRipper keeps Java missing and empty source behavior', () {
    expect(SpankbangRipper.videoUrlsFromDocument(html.parse('<video></video>')),
        isNull);
    expect(
      SpankbangRipper.videoUrlsFromDocument(
        html.parse('<video class="video-js"><source></video>'),
      ),
      [''],
    );
  });

  test('SpankbangRipper uses Java-style configurable ordered filenames',
      () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      SpankbangRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/path/video.mp4?token=1'),
        9,
      ),
      '009_video.mp4',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      SpankbangRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/path/video.mp4'),
        9,
      ),
      'video.mp4',
    );
  });
}
