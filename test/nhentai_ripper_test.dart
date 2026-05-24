import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/nhentai_ripper.dart';

void main() {
  test('NhentaiRipper matches Java host, GID, and tag-page detection',
      () async {
    final gallery = Uri.parse('https://nhentai.net/g/159174/');
    final tag = Uri.parse('https://nhentai.net/tag/example-tag/');
    final ripper = NhentaiRipper(gallery);

    expect(ripper.canRip(gallery), isTrue);
    expect(await ripper.getGID(gallery), '159174');
    expect(ripper.pageContainsAlbums(tag), isTrue);
    await expectLater(ripper.getGID(tag), throwsA(isA<FormatException>()));
  });

  test('NhentaiRipper derives Java album title and tags', () {
    final page = html.parse('''
      <html><body>
        <div id="info"><h1> Example Title </h1></div>
        <a class="tag" href="/tag/english/">English</a>
        <a class="tag" href="/tag/full-color/">Full Color</a>
      </body></html>
    ''');

    expect(
        NhentaiRipper.albumTitleFromDocument(page), 'nhentai Example Title ');
    expect(NhentaiRipper.getTags(page), ['english', 'full-color']);
    expect(
      NhentaiRipper.firstBlacklistedTag(
          ['full-color'], NhentaiRipper.getTags(page)),
      'full-color',
    );
  });

  test('NhentaiRipper queues gallery URLs from tag pages', () async {
    final ripper = NhentaiRipper(Uri.parse('https://nhentai.net/tag/example/'));
    final page = html.parse('''
      <html><body>
        <a class="cover" href="/g/1/"></a>
        <a class="cover" href="/g/2/"></a>
      </body></html>
    ''');

    expect(await ripper.getAlbumsToQueue(page), [
      'https://nhentai.net/g/1/',
      'https://nhentai.net/g/2/',
    ]);
  });

  test('NhentaiRipper converts gallery thumbnails like Java', () {
    expect(
      NhentaiRipper.thumbnailToImageUrl(
          'https://t.nhentai.net/galleries/12345/1t.jpg'),
      'https://i.nhentai.net/galleries/12345/1.jpg',
    );

    final page = html.parse('''
      <html><body>
        <a class="gallerythumb">
          <img data-src="https://t.nhentai.net/galleries/12345/1t.jpg">
        </a>
        <a class="gallerythumb">
          <img src="https://t.nhentai.net/galleries/12345/2t.png">
        </a>
      </body></html>
    ''');

    expect(NhentaiRipper.imageUrlsFromDocument(page), [
      'https://i.nhentai.net/galleries/12345/1.jpg',
    ]);
  });
}
