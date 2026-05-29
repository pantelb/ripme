import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/paheal_ripper.dart';

void main() {
  test('PahealRipper matches Java host, domain, support, terms, and GIDs',
      () async {
    final url = Uri.parse('http://rule34.paheal.net/post/list/bimbo/1');
    final encoded =
        Uri.parse('https://www.rule34.paheal.net/post/list/cute%20tag/2#top');
    final ripper = PahealRipper(url);

    expect(ripper.canRip(url), isTrue);
    expect(ripper.canRip(encoded), isTrue);
    expect(ripper.getHost(), 'paheal');
    expect(ripper.getDomain(), 'rule34.paheal.net');
    expect(PahealRipper.termFromUrl(url), 'bimbo');
    expect(PahealRipper.termFromUrl(encoded), 'cute%20tag');
    expect(await ripper.getGID(url), 'bimbo');
    expect(await ripper.getGID(encoded), 'cute tag');

    await expectLater(
      ripper.getGID(Uri.parse('http://rule34.paheal.net/post/view/123')),
      throwsA(isA<FormatException>()),
    );
  });

  test('PahealRipper builds Java first-page URL and listing cookies', () {
    final ripper = PahealRipper(
      Uri.parse('https://rule34.paheal.net/post/list/cute+tag/9'),
    );

    expect(
      ripper.firstPageUrl().toString(),
      'http://rule34.paheal.net/post/list/cute+tag/1',
    );
    expect(PahealRipper.listingCookies, {'ui-tnc-agreed': 'true'});
  });

  test('PahealRipper extracts thumbnail links like Java', () {
    final page = html.parse('''
      <span class="shm-thumb thumb"><a href="/post/view/1">one</a></span>
      <span class="shm-thumb thumb"><a class="shm-thumb-link" href="/post/view/skip">skip</a></span>
      <span class="shm-thumb thumb"><a href="https://rule34.paheal.net/post/view/2">two</a></span>
    ''');

    expect(PahealRipper.urlsFromPage(page), [
      'http://rule34.paheal.net/post/view/1',
      'https://rule34.paheal.net/post/view/2',
    ]);
  });

  test('PahealRipper finds Java next paginator link', () {
    final page = html.parse('''
      <div id="paginator">
        <a href="/post/list/bimbo/1">previous</a>
        <a href="/post/list/bimbo/3">NeXt</a>
      </div>
    ''');
    final noNext = html.parse('''
      <div id="paginator"><a href="/post/list/bimbo/1">last</a></div>
    ''');

    expect(
      PahealRipper.nextPageUrlFromPage(page),
      Uri.parse('http://rule34.paheal.net/post/list/bimbo/3'),
    );
    expect(PahealRipper.nextPageUrlFromPage(noNext), isNull);
  });

  test('PahealRipper uses Java download filenames without order prefixes', () {
    expect(
      PahealRipper.downloadFileName(
        Uri.parse('https://rule34.paheal.net/_images/hash/foo%20bar.jpeg?x=1'),
      ),
      'foo bar.jpeg',
    );
    expect(
      PahealRipper.downloadFileName(
        Uri.parse('https://rule34.paheal.net/_images/hash/no_extension'),
      ),
      'no_extension.png',
    );
    expect(
      PahealRipper.downloadFileName(
        Uri.parse('https://rule34.paheal.net/_images/hash/weird%3Aname.gif'),
      ),
      'weirdname.gif',
    );
  });
}
