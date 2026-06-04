import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/hentaifox_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHentaifoxRipper extends HentaifoxRipper {
  _FakeHentaifoxRipper(super.url, this.page);

  final Document page;
  int fetches = 0;

  @override
  Future<Document> fetchFirstPage() async {
    fetches++;
    return page;
  }
}

void main() {
  test('matches Java host, domain, URL support, and GIDs', () async {
    final ripper =
        HentaifoxRipper(Uri.parse('https://hentaifox.com/gallery/38544/'));

    expect(ripper.canRip(ripper.url), isTrue);
    expect(
      ripper.canRip(Uri.parse('http://hentaifox.com/gallery/38544/')),
      isFalse,
    );
    expect(ripper.getHost(), 'hentaifox');
    expect(ripper.getDomain(), 'hentaifox.com');
    expect(await ripper.getGID(ripper.url), '38544');
  });

  test('extracts album title from div.info h1 like Java', () {
    final page = parse('<div class="info"><h1>Gallery Title</h1></div>');

    expect(HentaifoxRipper.albumTitleFromPage(page), 'Gallery Title');
    expect(
      HentaifoxRipper.albumTitleFromPage(
        parse('<div class="info"><h1></h1></div>'),
      ),
      '',
    );
    expect(HentaifoxRipper.albumTitleFromPage(parse('<main></main>')), isNull);
  });

  test('builds album title with empty h1 text like Java', () async {
    final ripper = _FakeHentaifoxRipper(
      Uri.parse('https://hentaifox.com/gallery/38544/'),
      parse('<div class="info"><h1></h1></div>'),
    );

    expect(await ripper.getAlbumTitle(ripper.url), 'hentaifox__38544');
    expect(ripper.fetches, 1);
  });

  test('caches first page like Java AbstractHTMLRipper', () async {
    final ripper = _FakeHentaifoxRipper(
      Uri.parse('https://hentaifox.com/gallery/38544/'),
      parse('<div class="info"><h1>Gallery Title</h1></div>'),
    );

    expect(await ripper.getFirstPage(), same(await ripper.getFirstPage()));
    expect(ripper.fetches, 1);
  });

  test('normalizes preview thumbnails to full image URLs like Java', () {
    final page = parse('''
      <div class="preview_thumb"><a><img data-src="//i.hentaifox.com/001t.jpg"></a></div>
      <div class="preview_thumb"><a><img data-src="//i.hentaifox.com/002t.jpg"></a></div>
    ''');

    expect(HentaifoxRipper.imageUrlsFromPage(page), [
      'https://i.hentaifox.com/001.jpg',
      'https://i.hentaifox.com/002.jpg',
    ]);
  });

  test('builds Java-compatible ordered filenames by default', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();

    expect(
      HentaifoxRipper.fileNameForUrl(
        Uri.parse('https://i.hentaifox.com/001.jpg'),
        7,
      ),
      '007_001.jpg',
    );
  });

  test('omits ordered filename prefixes when disabled', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();

    expect(
      HentaifoxRipper.fileNameForUrl(
        Uri.parse('https://i.hentaifox.com/001.jpg'),
        7,
      ),
      '001.jpg',
    );
  });
}
