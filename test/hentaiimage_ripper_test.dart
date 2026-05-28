import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/hentaiimage_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java URL support, host, domain, and GID quirks', () async {
    final ripper = HentaiimageRipper(
      Uri.parse('https://hentai-img-xxx.com/image/afrobull-gerudo-ongoing-12/'),
    );

    expect(ripper.canRip(ripper.url), isTrue);
    expect(
      ripper.canRip(Uri.parse('http://hentai-img-xxx.com/image/example/')),
      isFalse,
    );
    expect(
      ripper.canRip(Uri.parse('https://abc.hentai-img-xxx.com/image/example/')),
      isFalse,
    );
    expect(
      ripper.canRip(Uri.parse('https://aa.hentai-comic.com/image/example/')),
      isTrue,
    );
    expect(ripper.getHost(), 'hentai-img-xxx.com');
    expect(ripper.getDomain(), 'hentai-img-xxx.com');
    expect(await ripper.getGID(ripper.url), 'img-xxx');
    expect(
      await HentaiimageRipper(
        Uri.parse('https://hentai-image.com/image/example/'),
      ).getGID(Uri.parse('https://hentai-image.com/image/example/')),
      'image',
    );
    expect(
      await HentaiimageRipper(
        Uri.parse('https://hentai-comic.com/image/example/'),
      ).getGID(Uri.parse('https://hentai-comic.com/image/example/')),
      'comic',
    );
  });

  test('extracts icon-overlay image src attributes like Java', () {
    final page = parse('''
      <div class="icon-overlay"><a><img src="https://cdn.example/one.jpg"></a></div>
      <div class="icon-overlay"><a><img src="https://cdn.example/two.png"></a></div>
      <div><a><img src="https://cdn.example/ignored.jpg"></a></div>
    ''');

    expect(HentaiimageRipper.imageUrlsFromPage(page), [
      'https://cdn.example/one.jpg',
      'https://cdn.example/two.png',
    ]);
  });

  test('finds next paginator span using Java selector and label', () {
    final page = parse('''
      <div id="paginator">
        <span><a href="/image/example/2">1</a></span>
        <span><a href="/image/example/2">next&gt;</a></span>
      </div>
    ''');

    expect(
      HentaiimageRipper.nextPageFromDocument(page, 'hentai-img-xxx.com'),
      Uri.parse('https://hentai-img-xxx.com/image/example/2'),
    );
    expect(
      HentaiimageRipper.nextPageFromDocument(
        parse(
            '<div id="paginator"><span><a href="/last">last</a></span></div>'),
        'hentai-img-xxx.com',
      ),
      isNull,
    );
  });

  test('uses Java-style ordered filename prefixes', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      HentaiimageRipper.fileNameForUrl(
        Uri.parse('https://cdn.example/path/image.jpg'),
        prefix: HentaiimageRipper.prefixForIndex(3),
      ),
      '003_image.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      HentaiimageRipper.fileNameForUrl(
        Uri.parse('https://cdn.example/path/image.jpg'),
        prefix: HentaiimageRipper.prefixForIndex(3),
      ),
      'image.jpg',
    );
  });
}
