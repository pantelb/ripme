import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/picstatio_ripper.dart';

void main() {
  test('PicstatioRipper matches Java URL detection, host, domain, and GID',
      () async {
    final ripper = PicstatioRipper(
      Uri.parse('https://www.picstatio.com/aerial-view-wallpapers'),
    );

    expect(ripper.getHost(), 'picstatio');
    expect(ripper.getDomain(), 'picstatio.com');
    expect(
      ripper.canRip(
        Uri.parse('https://www.picstatio.com/aerial-view-wallpapers'),
      ),
      isTrue,
    );
    expect(ripper.canRip(Uri.parse('https://www.picstatio.com/')), isTrue);
    expect(
      ripper.canRip(Uri.parse('https://www.picstatio.com/wallpaper/example')),
      isFalse,
    );
    expect(
      ripper.canRip(Uri.parse('https://picstatio.com/aerial-view-wallpapers')),
      isFalse,
    );

    expect(
      await ripper.getGID(
        Uri.parse('https://www.picstatio.com/aerial-view-wallpapers'),
      ),
      'aerial-view-wallpapers',
    );
  });

  test('PicstatioRipper extracts wallpaper slugs from img parents like Java',
      () {
    final page = html.parse('''
      <html><body>
        <a href="/wallpaper/first-wallpaper"><img class="img" src="/thumbs/1.jpg"></a>
        <a href="/wallpaper/second_wallpaper"><img class="img" src="/thumbs/2.jpg"></a>
        <a href="/not-enough"><img class="img" src="/thumbs/3.jpg"></a>
      </body></html>
    ''');

    expect(PicstatioRipper.wallpaperSlugsFromDocument(page), [
      'first-wallpaper',
      'second_wallpaper',
    ]);
  });

  test('PicstatioRipper builds download pages and extracts full-size hrefs',
      () async {
    final requested = <Uri>[];
    final imageUrl = await PicstatioRipper.fullSizedImageFromFileName(
      'first-wallpaper',
      pageFetcher: (uri) async {
        requested.add(uri);
        return html.parse('''
          <html><body>
            <p class="text-center"><span><a href="https://cdn.example.com/full.jpg">download</a></span></p>
          </body></html>
        ''');
      },
    );

    expect(requested.single.toString(),
        'https://www.picstatio.com/wallpaper/first-wallpaper/download');
    expect(imageUrl, 'https://cdn.example.com/full.jpg');
  });

  test('PicstatioRipper resolves gallery images through download pages',
      () async {
    final page = html.parse('''
      <html><body>
        <a href="/wallpaper/first-wallpaper"><img class="img" src="/thumbs/1.jpg"></a>
        <a href="/wallpaper/second-wallpaper"><img class="img" src="/thumbs/2.jpg"></a>
      </body></html>
    ''');
    final ripper = PicstatioRipper(
      Uri.parse('https://www.picstatio.com/aerial-view-wallpapers'),
      downloadPageFetcher: (uri) async {
        final slug = uri.pathSegments[1];
        return html.parse('''
          <p class="text-center"><span><a href="https://cdn.example.com/$slug.jpg">download</a></span></p>
        ''');
      },
    );

    expect(await ripper.getURLsFromPage(page), [
      'https://cdn.example.com/first-wallpaper.jpg',
      'https://cdn.example.com/second-wallpaper.jpg',
    ]);
  });

  test('PicstatioRipper builds Java-style next page URLs', () {
    final page = html.parse('''
      <html><body>
        <a class="next_page" href="/aerial-view-wallpapers?page=2">Next</a>
      </body></html>
    ''');
    final emptyPage = html.parse('<html><body></body></html>');

    expect(
      PicstatioRipper.nextPageUrl(page).toString(),
      'https://www.picstatio.com/aerial-view-wallpapers?page=2',
    );
    expect(
      PicstatioRipper.nextPageUrl(emptyPage).toString(),
      'https://www.picstatio.com',
    );
  });

  test('PicstatioRipper uses Java-style ordered filenames', () {
    expect(
      PicstatioRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/full-image.jpg'),
        prefix: PicstatioRipper.prefixForIndex(7),
      ),
      '007_full-image.jpg',
    );
  });
}
