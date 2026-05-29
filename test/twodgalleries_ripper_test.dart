import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/twodgalleries_ripper.dart';

void main() {
  test('matches Java host, domain, support, and artist GID parsing', () async {
    final cases = {
      'http://www.2dgalleries.com/artist/regis-loisel-6477':
          'regis-loisel-6477',
      'https://en.2dgalleries.com/artist/Artist-123?offset=24': 'Artist-123',
    };

    for (final entry in cases.entries) {
      final uri = Uri.parse(entry.key);
      final ripper = TwodgalleriesRipper(uri);
      expect(ripper.getHost(), '2dgalleries');
      expect(ripper.getDomain(), '2dgalleries.com');
      expect(ripper.canRip(uri), isTrue, reason: entry.key);
      expect(await ripper.getGID(uri), entry.value, reason: entry.key);
    }

    final notArtist = Uri.parse('http://www.2dgalleries.com/gallery/123');
    expect(TwodgalleriesRipper(notArtist).canRip(notArtist), isTrue);
    await expectLater(
      TwodgalleriesRipper(notArtist).getGID(notArtist),
      throwsA(isA<FormatException>()),
    );
  });

  test('builds Java AJAX gallery URLs', () {
    expect(
      TwodgalleriesRipper.pageUrlForUser('regis-loisel-6477', 24).toString(),
      'http://en.2dgalleries.com/artist/regis-loisel-6477'
      '?timespan=4&order=1&catid=2&offset=24&ajx=1&pager=1',
    );
  });

  test('extracts login token and Java Base64 login form data', () {
    final page = html.parse(
      '<form><input name="ctoken" value="abc123"></form>',
    );

    expect(TwodgalleriesRipper.loginTokenFromPage(page), 'abc123');
    expect(TwodgalleriesRipper.loginPostData('abc123'), {
      'user[login]': 'ripme',
      'user[password]': 'ripper',
      'rememberme': '1',
      'ctoken': 'abc123',
    });
  });

  test('rewrites thumbnail image URLs like Java', () {
    final page = html.parse('''
      <div class="hcaption"><img src="//cdn.2dgalleries.com/200H/one.jpg"></div>
      <div class="hcaption"><img src="/img/200H/two.png"></div>
      <div class="hcaption"><img src="http://other.example/200H/three.gif"></div>
    ''');

    expect(TwodgalleriesRipper.imageUrlsFromPage(page), [
      'http://cdn.2dgalleries.com/one.jpg',
      'http://en.2dgalleries.com/img/two.png',
      'http://other.example/three.gif',
    ]);
  });

  test('next document increments offset and stops on empty image pages',
      () async {
    final ripper = _FakeTwodgalleriesRipper(
      Uri.parse('http://www.2dgalleries.com/artist/regis-loisel-6477'),
      {
        TwodgalleriesRipper.pageUrlForUser('regis-loisel-6477', 24).toString():
            '<div class="hcaption"><img src="/img/200H/two.png"></div>',
        TwodgalleriesRipper.pageUrlForUser('regis-loisel-6477', 48).toString():
            '<main></main>',
      },
    );

    final next = await ripper.getNextDocument();
    expect(TwodgalleriesRipper.imageUrlsFromPage(next), [
      'http://en.2dgalleries.com/img/two.png',
    ]);

    await expectLater(
      ripper.getNextDocument(),
      throwsA(isA<HttpException>()),
    );
  });

  test('uses Java-style configurable ordered filenames', () {
    expect(TwodgalleriesRipper.prefixForIndex(7), '007_');
    expect(
      TwodgalleriesRipper.javaDownloadFileName(
        Uri.parse('http://cdn.example.com/artwork.jpg'),
        '007_',
      ),
      '007_artwork.jpg',
    );
  });
}

class _FakeTwodgalleriesRipper extends TwodgalleriesRipper {
  final Map<String, String> pages;

  _FakeTwodgalleriesRipper(super.url, this.pages);

  @override
  Future<Document> getPage(Uri uri) async {
    final body = pages[uri.toString()];
    if (body == null) {
      throw HttpException('Unexpected URL $uri');
    }
    return html.parse(body, sourceUrl: uri.toString());
  }
}
