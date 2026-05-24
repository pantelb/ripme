import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/imagefap_ripper.dart';

void main() {
  test('ImagefapRipper matches Java GID formats and URL sanitization',
      () async {
    final cases = {
      'https://www.imagefap.com/gallery.php?pgid=abcdef12': 'abcdef12',
      'https://www.imagefap.com/gallery.php?gid=12345': '12345',
      'https://www.imagefap.com/gallery/abcdef12': 'abcdef12',
      'https://www.imagefap.com/pictures/abcdef12/title': 'abcdef12',
    };

    for (final entry in cases.entries) {
      final uri = Uri.parse(entry.key);
      final ripper = ImagefapRipper(uri);
      expect(ripper.canRip(uri), isTrue);
      expect(await ripper.getGID(uri), entry.value);
      expect(ImagefapRipper.sanitizeUrl(uri).toString(),
          'https://www.imagefap.com/pictures/${entry.value}/random-string');
    }
  });

  test('ImagefapRipper derives Java album titles', () {
    expect(
      ImagefapRipper.albumTitleFromPageTitle(
          'Example Gallery Porn Pics & Porn GIFs', 'abcdef12'),
      'imagefap_Example_Gallery_abcdef12',
    );
  });

  test('ImagefapRipper extracts full-size image href from image page', () {
    final page = html.parse('''
      <html><body>
        <img id="mainPhoto" data-src="https://cdn.imagefap.com/path/full.jpg?token=1">
        <ul class="thumbs">
          <li><a framed="https://cdn.imagefap.com/path/full.jpg?other=2" href="https://cdn.imagefap.com/fullsize.jpg"></a></li>
        </ul>
      </body></html>
    ''');

    expect(ImagefapRipper.fullSizedImageFromDocument(page),
        'https://cdn.imagefap.com/fullsize.jpg');
  });

  test('ImagefapRipper finds Java-style next page links', () async {
    final ripper =
        ImagefapRipper(Uri.parse('https://www.imagefap.com/gallery/abcdef12'));
    final page = html.parse('''
      <html><body>
        <a class="link3" href="?page=2">next</a>
      </body></html>
    ''');

    expect((await ripper.getNextPage(page)).toString(),
        'https://www.imagefap.com/pictures/abcdef12/random-string?page=2');
  });

  test('ImagefapRipper requires src and width thumbnails like Java', () async {
    final ripper = _ImagefapParserHarness(
        Uri.parse('https://www.imagefap.com/gallery/abcdef12'));
    final page = html.parse('''
      <html><body>
        <div id="gallery">
          <a href="/photo/1"><img src="thumb.jpg" width="100"></a>
          <a href="/photo/2"><img src="thumb2.jpg"></a>
        </div>
      </body></html>
    ''');

    expect(
        await ripper.getURLsFromPage(page), ['https://cdn.example.com/1.jpg']);
    expect(ripper.requestedPages, ['https://www.imagefap.com/photo/1']);
  });
}

class _ImagefapParserHarness extends ImagefapRipper {
  final requestedPages = <String>[];

  _ImagefapParserHarness(super.url);

  @override
  Future<String?> getFullSizedImage(Uri pageUrl) async {
    requestedPages.add(pageUrl.toString());
    return 'https://cdn.example.com/1.jpg';
  }
}
