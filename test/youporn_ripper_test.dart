import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/youporn_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java Youporn URL support and GID parsing', () async {
    final uri = Uri.parse(
      'https://www.youporn.com/watch/13158849/smashing-star-slut-part-2/',
    );
    final ripper = YoupornRipper(uri);

    expect(ripper.getHost(), 'youporn');
    expect(ripper.getDomain(), 'youporn.com');
    expect(ripper.canRip(uri), isTrue);
    expect(
      ripper.canRip(Uri.parse('https://www.youporn.com/watch/foo/example/')),
      isFalse,
    );
    expect(await ripper.getGID(uri), '13158849');
  });

  test('extracts first video src and missing-video errors like Java', () {
    final page = parse('''
      <video src="https://cdn.example/video.mp4"></video>
      <video src="https://cdn.example/ignored.mp4"></video>
    ''');

    expect(YoupornRipper.videoUrlsFromDocument(page), [
      'https://cdn.example/video.mp4',
    ]);
    expect(
      () => YoupornRipper.videoUrlsFromDocument(parse('<main></main>')),
      throwsA(isA<StateError>()),
    );
  });

  test('uses Java-style ordered filenames', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    expect(
      YoupornRipper.fileNameForUrl(
        Uri.parse('https://cdn.example/path/video.mp4'),
        prefix: YoupornRipper.prefix(12),
      ),
      '012_video.mp4',
    );
  });

  test('honors Java download.save_order prefix setting', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();

    expect(YoupornRipper.prefix(12), '');
    expect(
      YoupornRipper.fileNameForUrl(
        Uri.parse('https://cdn.example/path/video.mp4'),
        prefix: YoupornRipper.prefix(12),
      ),
      'video.mp4',
    );
  });
}
