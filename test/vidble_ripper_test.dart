import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/vidble_ripper.dart';

void main() {
  test('matches Java host, domain, broad support, and album GID', () async {
    final url = Uri.parse('https://vidble.com/album/cGEFr8zi');
    final ripper = VidbleRipper(url);

    expect(ripper.getHost(), 'vidble');
    expect(ripper.getDomain(), 'vidble.com');
    expect(ripper.canRip(url), isTrue);
    expect(ripper.canRip(Uri.parse('https://www.vidble.com/anything')), isTrue);
    expect(await ripper.getGID(url), 'cGEFr8zi');

    await expectLater(
      ripper.getGID(Uri.parse('https://vidble.com/image/abc')),
      throwsA(isA<FormatException>()),
    );
  });

  test('extracts content images with Java absUrl and thumbnail stripping', () {
    final pageUrl = Uri.parse('https://vidble.com/album/cGEFr8zi');
    final page = html.parse('''
      <div id="ContentPlaceHolder1_divContent">
        <img src="/uploads/photo_abc.jpg">
        <img src="//cdn.vidble.com/path/image_thumb.png">
        <img src="https://cdn.vidble.com/path/image_abcdef.jpg">
        <span><img src="nested_small.gif"></span>
      </div>
      <img src="https://cdn.vidble.com/outside_thumb.jpg">
    ''');

    expect(VidbleRipper.imageUrlsFromDocument(page, pageUrl), [
      'https://vidble.com/uploads/photo.jpg',
      'https://cdn.vidble.com/path/image.png',
      'https://cdn.vidble.com/path/imagef.jpg',
      'https://vidble.com/album/nested.gif',
    ]);
  });

  test('uses Java-style ordered filenames', () {
    expect(VidbleRipper.prefixForIndex(12), '012_');
    expect(
      VidbleRipper.fileNameForUrl(
        Uri.parse('https://cdn.vidble.com/path/image.jpg'),
        prefix: '012_',
      ),
      '012_image.jpg',
    );
  });
}
