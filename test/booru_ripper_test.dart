import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/booru_ripper.dart';

void main() {
  test('BooruRipper matches Java URL detection, host, domain, and GID',
      () async {
    final xbooru =
        Uri.parse('https://xbooru.com/index.php?page=post&s=list&tags=furry');
    final gelbooru = Uri.parse(
      'https://gelbooru.com/index.php?page=post&s=list&tags=animal_ears',
    );

    final xbooruRipper = BooruRipper(xbooru);
    final gelbooruRipper = BooruRipper(gelbooru);

    expect(xbooruRipper.canRip(xbooru), isTrue);
    expect(gelbooruRipper.canRip(gelbooru), isTrue);
    expect(xbooruRipper.getHost(), 'xbooru');
    expect(gelbooruRipper.getHost(), 'gelbooru');
    expect(xbooruRipper.getDomain(), 'xbooru.com');
    expect(gelbooruRipper.getDomain(), 'gelbooru.com');
    expect(await xbooruRipper.getGID(xbooru), 'furry');
    expect(await gelbooruRipper.getGID(gelbooru), 'animal_ears');
  });

  test('BooruRipper constructs Java-compatible DAPI page URLs', () {
    final ripper = BooruRipper(
      Uri.parse('https://xbooru.com/index.php?page=post&s=list&tags=furry'),
    );

    expect(
      ripper.getPage(0).toString(),
      'http://xbooru.com/index.php?page=dapi&s=post&q=index&pid=0&tags=&tags=furry',
    );
    expect(
      ripper.getPage(2).toString(),
      'http://xbooru.com/index.php?page=dapi&s=post&q=index&pid=2&tags=&tags=furry',
    );
  });

  test('BooruRipper paginates using posts offset and count like Java',
      () async {
    final ripper = BooruRipper(
      Uri.parse('https://xbooru.com/index.php?page=post&s=list&tags=furry'),
    );

    final first = html.parse('<posts count="250" offset="100"></posts>');
    final last = html.parse('<posts count="150" offset="100"></posts>');

    expect(
      (await ripper.getNextPage(first)).toString(),
      'http://xbooru.com/index.php?page=dapi&s=post&q=index&pid=2&tags=&tags=furry',
    );
    expect(await ripper.getNextPage(last), isNull);
  });

  test('BooruRipper extracts file_url values and preserves post ids', () async {
    final ripper = BooruRipper(
      Uri.parse('https://gelbooru.com/index.php?page=post&s=list&tags=cat'),
    );
    final page = html.parse('''
      <posts count="2" offset="0">
        <post id="10" file_url="https://img.example.com/full/one.jpg" />
        <post id="11" file_url="//img.example.com/full/two.png" />
        <post id="12" file_url="/images/three.gif" />
      </posts>
    ''');

    expect(await ripper.getURLsFromPage(page), [
      'https://img.example.com/full/one.jpg#10',
      'http://img.example.com/full/two.png#11',
      'http://gelbooru.com/images/three.gif#12',
    ]);
  });

  test('BooruRipper uses Java post-id filename prefixes', () {
    expect(BooruRipper.prefixForPostId('123'), '123-');
    expect(
      BooruRipper.fileNameForUrl(
        Uri.parse('https://img.example.com/path/image.jpg'),
        prefix: '123-',
      ),
      '123-image.jpg',
    );
  });
}
