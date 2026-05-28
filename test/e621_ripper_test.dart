import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/e621_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, URL support, term parsing, and GIDs',
      () async {
    SharedPreferences.setMockInitialValues({'remember.url_history': false});
    await Utils.init();

    final posts = E621Ripper(Uri.parse('https://e621.net/posts?tags=beach'));
    final old = E621Ripper(Uri.parse('https://e621.net/post/index/1/beach'));
    final pool = E621Ripper(Uri.parse('https://e621.net/pools/123'));
    final oldPool = E621Ripper(Uri.parse('https://e621.net/pool/show/456'));

    expect(posts.canRip(posts.url), isTrue);
    expect(posts.getHost(), 'e621');
    expect(posts.getDomain(), 'e621.net');
    expect(E621Ripper.termFromUrl(posts.url), 'beach');
    expect(E621Ripper.termFromUrl(old.url), 'beach');
    expect(E621Ripper.termFromUrl(pool.url), '123');
    expect(E621Ripper.termFromUrl(oldPool.url), '456');
    expect(await posts.getGID(posts.url), 'beach');
    expect(await pool.getGID(pool.url), 'pool_123');
  });

  test('sanitizes old post search URLs like Java', () {
    expect(
      E621Ripper.sanitizeUrl(
        Uri.parse('https://e621.net/post/search?tags=gif+rating:s'),
      ).toString(),
      'https://e621.net/post/index/1/gif%20rating:s',
    );
    expect(
      E621Ripper.sanitizeUrl(Uri.parse('https://e621.net/posts?tags=gif'))
          .toString(),
      'https://e621.net/posts?tags=gif',
    );
  });

  test('extracts post links and next page URLs', () async {
    final page = parse('''
      <article><a href="/posts/1">one</a></article>
      <article><a href="https://e621.net/posts/2">two</a></article>
      <a id="paginator-next" href="/posts?tags=beach&page=2">next</a>
    ''');
    final ripper = E621Ripper(Uri.parse('https://e621.net/posts?tags=beach'));

    expect(
      E621Ripper.postUrlsFromPage(page),
      ['https://e621.net/posts/1', 'https://e621.net/posts/2'],
    );
    expect(
      (await ripper.getNextPage(page)).toString(),
      'https://e621.net/posts?tags=beach&page=2',
    );
    expect(await ripper.getNextPage(parse('<main></main>')), isNull);
  });

  test('extracts full-size image URLs from post pages', () {
    expect(
      E621Ripper.fullSizedImageFromPage(
        parse(
            '<div id="image-download-link"><a href="/data/full.webm">Download</a></div>'),
      ),
      'https://e621.net/data/full.webm',
    );
    expect(E621Ripper.fullSizedImageFromPage(parse('<main></main>')), isNull);
  });

  test('parses configured cookies and uses Java-style ordered filenames',
      () async {
    expect(
      E621Ripper.parseCookies('cf_clearance=abc; remember=token; bad; a=b=c'),
      {'cf_clearance': 'abc', 'remember': 'token', 'a': 'b=c'},
    );

    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'download.save_order': true,
    });
    await Utils.init();

    expect(
      E621Ripper.downloadFileName(
        Uri.parse('https://static.e621.net/data/file.jpg?download=1'),
        9,
      ),
      '009_file.jpg',
    );

    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'download.save_order': false,
    });
    await Utils.init();

    expect(
      E621Ripper.downloadFileName(
        Uri.parse('https://static.e621.net/data/file.jpg'),
        9,
      ),
      'file.jpg',
    );
  });
}
