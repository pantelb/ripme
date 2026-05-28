import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/myhentaicomics_ripper.dart';

void main() {
  test('MyhentaicomicsRipper matches Java host, domain, support, and GIDs',
      () async {
    final comicUrl =
        Uri.parse('http://myhentaicomics.com/index.php/Nienna-Lost-Tales');
    final ripper = MyhentaicomicsRipper(comicUrl);

    expect(ripper.canRip(comicUrl), isTrue);
    expect(ripper.canRip(Uri.parse('https://www.myhentaicomics.com/')), isTrue);
    expect(ripper.getHost(), 'myhentaicomics');
    expect(ripper.getDomain(), 'myhentaicomics.com');
    expect(await ripper.getGID(comicUrl), 'Nienna-Lost-Tales');
    expect(
      await ripper.getGID(
        Uri.parse('http://myhentaicomics.com/index.php/search?q=test'),
      ),
      'test',
    );
    expect(
      await ripper.getGID(
        Uri.parse('http://myhentaicomics.com/index.php/tag/2409/'),
      ),
      '2409',
    );
  });

  test('MyhentaicomicsRipper detects search and tag queue pages like Java', () {
    expect(
      MyhentaicomicsRipper.isQueuePage(
        Uri.parse('https://myhentaicomics.com/index.php/tag/3167/'),
      ),
      isTrue,
    );
    expect(
      MyhentaicomicsRipper.isQueuePage(
        Uri.parse('https://myhentaicomics.com/index.php/search?q=test'),
      ),
      isTrue,
    );
    expect(
      MyhentaicomicsRipper.isQueuePage(
        Uri.parse('https://myhentaicomics.com/index.php/Nienna-Lost-Tales'),
      ),
      isFalse,
    );
  });

  test('MyhentaicomicsRipper extracts album links from queue pages', () {
    final page = html.parse('''
      <div class="g-album"><a href="/index.php/One-Comic">One</a></div>
      <div class="g-album"><a href="/index.php/Two-Comic">Two</a></div>
    ''');

    expect(MyhentaicomicsRipper.albumUrlsFromDocument(page), [
      'https://myhentaicomics.com/index.php/One-Comic',
      'https://myhentaicomics.com/index.php/Two-Comic',
    ]);
  });

  test('MyhentaicomicsRipper extracts relative images and expands thumbs', () {
    final page = html.parse('''
      <img src="/uploads/thumbs/page1.jpg">
      <img src="/uploads/pages/page2.png">
      <img src="https://cdn.example.com/logo.png">
      <img>
    ''');

    expect(MyhentaicomicsRipper.imageUrlsFromDocument(page), [
      'https://myhentaicomics.com/uploads/resizes/page1.jpg',
      'https://myhentaicomics.com/uploads/pages/page2.png',
      'https://myhentaicomics.com',
    ]);
  });

  test('MyhentaicomicsRipper follows Java single-digit next-page rule', () {
    final valid = html.parse(
      '<a class="ui-icon-right" href="/index.php/Nienna-Lost-Tales?page=2">Next</a>',
    );
    final multiDigit = html.parse(
      '<a class="ui-icon-right" href="/index.php/Nienna-Lost-Tales?page=12">Next</a>',
    );
    final different = html.parse(
      '<a class="ui-icon-right" href="/other?page=2">Next</a>',
    );

    expect(
      MyhentaicomicsRipper.nextPageUrlFromDocument(valid).toString(),
      'https://myhentaicomics.com/index.php/Nienna-Lost-Tales?page=2',
    );
    expect(MyhentaicomicsRipper.nextPageUrlFromDocument(multiDigit), isNull);
    expect(MyhentaicomicsRipper.nextPageUrlFromDocument(different), isNull);
  });

  test('MyhentaicomicsRipper uses Java-style ordered filenames', () {
    expect(MyhentaicomicsRipper.prefixForIndex(7), '007_');
    expect(
      MyhentaicomicsRipper.fileNameForUrl(
        Uri.parse('https://myhentaicomics.com/uploads/resizes/page1.jpg?x=1'),
        prefix: '007_',
      ),
      '007_page1.jpg',
    );
  });
}
