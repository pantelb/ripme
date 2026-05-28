import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/deviantart_ripper.dart';

void main() {
  test('matches Java host, domain, URL support, GIDs, and catpath state',
      () async {
    final gallery = DeviantartRipper(
      Uri.parse(
          'https://www.deviantart.com/apofiss/gallery/41388863/sceneries'),
    );
    final favourites = DeviantartRipper(
      Uri.parse(
          'https://www.deviantart.com/apofiss/favourites/39881418/gifts-and'),
    );
    final featured = DeviantartRipper(
      Uri.parse('https://www.deviantart.com/kageuri/gallery/'),
    );
    final catpath = DeviantartRipper(
      Uri.parse('https://www.deviantart.com/kageuri/gallery/?catpath=/'),
    );

    expect(gallery.canRip(gallery.url), isTrue);
    expect(gallery.getHost(), 'deviantart');
    expect(gallery.getDomain(), 'deviantart.com');
    expect(await gallery.getGID(gallery.url), 'apofiss_gallery_sceneries');
    expect(
      await favourites.getGID(favourites.url),
      'apofiss_favourites_gifts-and',
    );
    expect(await featured.getGID(featured.url), 'kageuri_gallery_featured');
    expect(await catpath.getGID(catpath.url), 'kageuri_gallery_all');
    expect(
      catpath.urlWithParams(24).toString(),
      'https://www.deviantart.com/kageuri/gallery/?catpath=/&offset=24',
    );
  });

  test('constructs Java-compatible clean offset URLs', () {
    final ripper = DeviantartRipper(
      Uri.parse(
          'https://www.deviantart.com/apofiss/gallery/41388863/sceneries'),
    );

    expect(
      ripper.urlWithParams(0).toString(),
      'https://www.deviantart.com/apofiss/gallery/41388863/sceneries?offset=0',
    );
    expect(
      DeviantartRipper.cleanUrl(
        Uri.parse('https://www.deviantart.com/kageuri/gallery/?catpath=/'),
      ),
      'https://www.deviantart.com/kageuri/gallery/',
    );
  });

  test('extracts gallery art page links from folderview and catpath pages', () {
    final folderPage = parse('''
      <div class="folderview-art">
        <div>
          <a class="torpedo-thumb-link" href="https://www.deviantart.com/a/art/one-1"></a>
          <a class="other" href="https://ignored.example/"></a>
          <a class="torpedo-thumb-link" href="https://www.deviantart.com/a/art/two-2"></a>
        </div>
      </div>
    ''');
    final catpathPage = parse('''
      <div id="gmi-">
        <a class="torpedo-thumb-link" href="https://www.deviantart.com/a/art/all-3"></a>
      </div>
    ''');

    expect(
      DeviantartRipper.urlsFromPage(folderPage, usingCatPath: false),
      [
        'https://www.deviantart.com/a/art/one-1',
        'https://www.deviantart.com/a/art/two-2',
      ],
    );
    expect(
      DeviantartRipper.urlsFromPage(catpathPage, usingCatPath: true),
      ['https://www.deviantart.com/a/art/all-3'],
    );
  });

  test('matches Java title and full-image fallback parsing', () {
    final page = parse('''
      <a class="title">RUBY & Sapphire!</a>
      <div class="dev-view-deviation">
        <img src="https://images.example.net/intermediary/f/path/v1/fill/w_1024/file-name.jpg?token=1">
      </div>
    ''');

    final scaled = DeviantartRipper.imageUrlFromDeviationPage(page);

    expect(DeviantartRipper.titleFromPage(page), 'ruby__amp__sapphire_');
    expect(
      scaled.toString(),
      'https://images.example.net/intermediary/f/path/v1/fill/w_1024/file-name.jpg',
    );
    expect(
      DeviantartRipper.originalImageUrl(scaled!).toString(),
      'https://images.example.net/intermediary/f/path',
    );
    expect(DeviantartRipper.extensionFromUrl(scaled), 'jpg');
  });

  test('skips avatar-only text art and parses download-button extensions', () {
    final avatarPage = parse('''
      <div class="dev-view-deviation">
        <img class="avatar" src="https://images.example/avatar.png">
      </div>
    ''');

    expect(DeviantartRipper.imageUrlFromDeviationPage(avatarPage), isNull);
    expect(
      DeviantartRipper.extensionFromContentDisposition(
        'attachment; filename="download.full.PDF"',
      ),
      'PDF',
    );
  });
}
