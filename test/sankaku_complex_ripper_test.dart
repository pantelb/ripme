import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/sankaku_complex_ripper.dart';

void main() {
  test('SankakuComplexRipper matches Java URL detection, host, domain, and GID',
      () async {
    final url = Uri.parse(
      'https://idol.sankakucomplex.com/?tags=meme_%28me%21me%21me%21%29_%28cosplay%29',
    );
    final ripper = SankakuComplexRipper(url);

    expect(ripper.getHost(), 'sankakucomplex');
    expect(ripper.getDomain(), 'sankakucomplex.com');
    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(
        Uri.parse('http://chan.sankakucomplex.com/?tags=cleavage'),
      ),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://sankakucomplex.com/?tags=abc')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://idol.sankakucomplex.com/posts')),
      isFalse,
    );

    expect(await ripper.getGID(url), 'idol._meme_(me!me!me!)_(cosplay)');
    expect(ripper.getSubDomain(url), 'idol.');
  });

  test('SankakuComplexRipper keeps Java malformed URL error text', () async {
    final ripper = SankakuComplexRipper(
      Uri.parse('https://idol.sankakucomplex.com/posts'),
    );

    expect(
      () => ripper.getGID(ripper.url),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('idol.sankakucomplex.com?...&tags=something...'),
        ),
      ),
    );
  });

  test('SankakuComplexRipper extracts highres URLs from thumbnail post pages',
      () async {
    final ripper = _SankakuHarness(
      Uri.parse('https://chan.sankakucomplex.com/?tags=cleavage'),
      {
        'https://chan.sankakucomplex.com/post/show/1': html.parse(
          '<div id="stats"><ul><li><a id="highres" href="//cs.sankakucomplex.com/data/one.jpg">high</a></li></ul></div>',
        ),
        'https://chan.sankakucomplex.com/post/show/2': html.parse(
          '<div id="stats"><ul><li><a id="highres" href="//cs.sankakucomplex.com/data/two.png">high</a></li></ul></div>',
        ),
      },
    );
    final page = html.parse('''
      <div class="content"><div>
        <span class="thumb"><a href="/post/show/1"><img></a></span>
        <span class="thumb"><a href="https://chan.sankakucomplex.com/post/show/2"><img></a></span>
      </div></div>
    ''');

    expect(await ripper.getURLsFromPage(page), [
      'https://cs.sankakucomplex.com/data/one.jpg',
      'https://cs.sankakucomplex.com/data/two.png',
    ]);
  });

  test('SankakuComplexRipper parses highres attr like Java Elements.attr', () {
    final page = html.parse(
      '<div id="stats"><ul><li><a id="highres" href="//img.example/file.jpg"></a></li></ul></div>',
    );

    expect(
      SankakuComplexRipper.highresUrlFromPostPage(page),
      'https://img.example/file.jpg',
    );
    expect(
      SankakuComplexRipper.highresUrlFromPostPage(html.parse('')),
      'https:',
    );
  });

  test('SankakuComplexRipper paginates with next-page-url and stops at page 26',
      () async {
    final ripper = SankakuComplexRipper(
      Uri.parse('https://idol.sankakucomplex.com/?tags=abc&page=24'),
    );

    expect(
      (await ripper.getNextPage(
        html.parse(
          '<div class="pagination" next-page-url="/?tags=abc&page=25"></div>',
        ),
      ))
          .toString(),
      'https://idol.sankakucomplex.com/?tags=abc&page=25',
    );
    expect(
      await ripper.getNextPage(
        html.parse(
          '<div class="pagination" next-page-url="/?tags=abc&page=26"></div>',
        ),
      ),
      isNull,
    );
    expect(await ripper.getNextPage(html.parse('<div></div>')), isNull);
  });

  test('SankakuComplexRipper parses response cookies for subsequent pages', () {
    expect(
      SankakuComplexRipper.cookiesFromHeaders({
        'set-cookie': 'a=one; Path=/, b=two; HttpOnly',
      }),
      {'a': 'one', 'b': 'two'},
    );
  });

  test('SankakuComplexRipper uses Java-style ordered filenames', () {
    expect(
      SankakuComplexRipper.fileNameForUrl(
        Uri.parse('https://img.example.com/path/image.jpg'),
        prefix: SankakuComplexRipper.prefixForIndex(7),
      ),
      '007_image.jpg',
    );
  });
}

class _SankakuHarness extends SankakuComplexRipper {
  final Map<String, Document> pages;

  _SankakuHarness(super.url, this.pages);

  @override
  Future<Document> getPostPage(Uri postUri) async {
    final page = pages[postUri.toString()];
    if (page == null) throw const HttpException('missing post page');
    return page;
  }
}
