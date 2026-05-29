import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/pornhub_ripper.dart';

void main() {
  test('PornhubRipper matches Java host, domain, support, and album GIDs',
      () async {
    final url = Uri.parse('https://www.pornhub.com/album/15680522?page=2');
    final ripper = PornhubRipper(url);

    expect(ripper.getHost(), 'Pornhub');
    expect(ripper.getDomain(), 'pornhub.com');
    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(Uri.parse('https://sub.pornhub.com/album/15680522')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://www.pornhub.com/view_video.php')),
      isFalse,
    );
    expect(await ripper.getGID(url), '15680522');
    expect(
      await ripper.getGID(Uri.parse('http://www.pornhub.com/album/15680522')),
      '15680522',
    );
  });

  test('PornhubRipper strips query strings from album start URLs like Java',
      () {
    expect(
      PornhubRipper.sanitizeUrl(
        Uri.parse('https://www.pornhub.com/album/15680522?page=2'),
      ).toString(),
      'https://www.pornhub.com/album/15680522',
    );
    expect(
      PornhubRipper.sanitizeUrl(
        Uri.parse('https://www.pornhub.com/album/15680522'),
      ).toString(),
      'https://www.pornhub.com/album/15680522',
    );
  });

  test('PornhubRipper extracts photo page URLs from thumbnails like Java', () {
    final page = html.parse('''
      <ul class="photoBlockBox">
        <li><div class="photoAlbumListBlock"><a href="/photo/111"></a></div></li>
        <li><div class="photoAlbumListBlock"><a href="/photo/222"></a></div></li>
      </ul>
      <a href="/photo/outside"></a>
    ''');

    expect(PornhubRipper.imagePageUrlsFromDocument(page), [
      'https://pornhub.com/photo/111',
      'https://pornhub.com/photo/222',
    ]);
  });

  test('PornhubRipper discovers direct image URLs from photo pages', () {
    final imagePageUrl = Uri.parse('https://www.pornhub.com/photo/111');
    final page = html.parse('''
      <div id="photoImageSection">
        <img src="/img/full-size.jpg">
      </div>
    ''');

    expect(
      PornhubRipper.directImageUrlFromDocument(page, imagePageUrl).toString(),
      'https://www.pornhub.com/img/full-size.jpg',
    );
  });

  test('PornhubRipper resolves next pages against sanitized album URL', () {
    final albumUrl = Uri.parse('https://www.pornhub.com/album/39341891');
    final page =
        html.parse('<li class="page_next"><a href="?page=2"></a></li>');
    final noNextPage = html.parse('<html><body></body></html>');

    expect(
      PornhubRipper.nextPageUrl(page, albumUrl).toString(),
      'https://www.pornhub.com/album/39341891?page=2',
    );
    expect(PornhubRipper.nextPageUrl(noNextPage, albumUrl), isNull);
  });

  test('PornhubRipper uses Java-style referrers and ordered filenames', () {
    final pageUrl = Uri.parse('https://www.pornhub.com/photo/111');
    final imageUrl = Uri.parse('https://cdn.example.com/full-size.jpg?cache=1');

    expect(PornhubRipper.referrerHeaders(pageUrl), {
      'Referer': 'https://www.pornhub.com/photo/111',
    });
    expect(
      PornhubRipper.fileNameForUrl(
        imageUrl,
        prefix: PornhubRipper.prefixForIndex(7),
      ),
      '007_full-size.jpg',
    );
  });
}
