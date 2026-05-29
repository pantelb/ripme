import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/ruleporn_ripper.dart';

void main() {
  test('RulePornRipper matches Java host support, domain, and GID', () async {
    final url = Uri.parse('https://ruleporn.com/tosh/');
    final ripper = RulePornRipper(url);

    expect(ripper.getHost(), 'ruleporn');
    expect(ripper.getDomain(), 'ruleporn.com');
    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(Uri.parse('http://www.ruleporn.com/anything')),
      isTrue,
    );
    expect(ripper.canRip(Uri.parse('https://example.com/tosh/')), isFalse);

    expect(await ripper.getGID(url), 'tosh');
    expect(
        await ripper.getGID(Uri.parse('https://www.ruleporn.com/a/b/')), 'a/b');
    await expectLater(
      ripper.getGID(Uri.parse('http://ruleporn.com/tosh/')),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      ripper.getGID(Uri.parse('https://ruleporn.com/tosh')),
      throwsA(isA<FormatException>()),
    );
  });

  test('RulePornRipper extracts the first mp4 source like Java', () {
    final page = html.parse('''
      <video>
        <source type="video/mp4" src="https://cdn.example.com/first.mp4">
        <source type="video/webm" src="https://cdn.example.com/skip.webm">
        <source type="video/mp4" src="https://cdn.example.com/second.mp4">
      </video>
    ''');

    expect(RulePornRipper.videoUrlsFromDocument(page), [
      'https://cdn.example.com/first.mp4',
    ]);
  });

  test('RulePornRipper returns an empty source entry like Java attr()', () {
    final page = html.parse('<video></video>');

    expect(RulePornRipper.videoUrlsFromDocument(page), ['']);
  });

  test('RulePornRipper uses Java-style ordered filenames', () {
    expect(
      RulePornRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/path/video.mp4'),
        prefix: RulePornRipper.prefixForIndex(2),
      ),
      '002_video.mp4',
    );
  });
}
