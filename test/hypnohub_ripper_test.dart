import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/hypnohub_ripper.dart';

void main() {
  test('matches Java host, domain, broad URL support, and GIDs', () async {
    final poolUrl = Uri.parse(
      'https://hypnohub.net/index.php?page=pool&s=show&id=6717',
    );
    final postUrl = Uri.parse(
      'https://hypnohub.net/index.php?page=post&s=view&id=234499&pool_id=6717',
    );
    final ripper = HypnohubRipper(poolUrl);

    expect(ripper.getHost(), 'hypnohub');
    expect(ripper.getDomain(), 'hypnohub.net');
    expect(ripper.canRip(poolUrl), isTrue);
    expect(ripper.canRip(Uri.parse('https://hypnohub.net/post?tags=spiral')),
        isTrue);
    expect(ripper.canRip(Uri.parse('https://example.com/index.php?page=pool')),
        isFalse);
    expect(await ripper.getGID(poolUrl), '6717');
    expect(
      await ripper.getGID(postUrl),
      'post&s=view&id=234499&pool_id=6717',
    );
    await expectLater(
      ripper.getGID(Uri.parse('https://hypnohub.net/index.php')),
      throwsA(isA<FormatException>()),
    );
  });

  test('extracts post image using Java fallback order and URL normalization',
      () {
    expect(
      HypnohubRipper.imageUrlFromPostDocument(
        html.parse('<img id="image" src="//cdn.hypnohub.net/sample.jpg">'),
      ),
      'https://cdn.hypnohub.net/sample.jpg',
    );
    expect(
      HypnohubRipper.imageUrlFromPostDocument(
        html.parse('<img id="image" src="/data/sample.jpg">'),
      ),
      'https://hypnohub.net/data/sample.jpg',
    );
    expect(
      HypnohubRipper.imageUrlFromPostDocument(
        html.parse('<a href="/data/original.png">Original image</a>'),
      ),
      'https://hypnohub.net/data/original.png',
    );
    expect(
      HypnohubRipper.imageUrlFromPostDocument(
        html.parse(
            '<meta property="og:image" content="https://cdn.example/post.webp">'),
      ),
      'https://cdn.example/post.webp',
    );
    expect(HypnohubRipper.imageUrlFromPostDocument(html.parse('<html></html>')),
        isNull);
  });

  test('expands pool thumbnails by fetching each post like Java', () async {
    final page = html.parse('''
      <span class="thumb"><a href="index.php?page=post&s=view&id=1">one</a></span>
      <span class="thumb"><a href="/index.php?page=post&s=view&id=2">two</a></span>
      <span class="thumb"><a href="https://hypnohub.net/index.php?page=post&s=view&id=3">three</a></span>
      <span class="thumb"><a href="index.php?page=pool&id=6717">pool</a></span>
    ''');
    final fetched = <String>[];

    final urls = await HypnohubRipper.imageUrlsFromPoolDocument(
      page,
      fetchPost: (postUrl) async {
        fetched.add(postUrl);
        return 'https://cdn.example/${fetched.length}.jpg';
      },
    );

    expect(fetched, [
      'https://hypnohub.net/index.php?page=post&s=view&id=1',
      'https://hypnohub.net//index.php?page=post&s=view&id=2',
      'https://hypnohub.net/index.php?page=post&s=view&id=3',
    ]);
    expect(urls, [
      'https://cdn.example/1.jpg',
      'https://cdn.example/2.jpg',
      'https://cdn.example/3.jpg',
    ]);
  });

  test('uses Java-style ordered filenames', () {
    expect(HypnohubRipper.prefixForIndex(7), '007_');
    expect(
      HypnohubRipper.fileNameForUrl(
        Uri.parse('https://hypnohub.net/data/sample image.jpg'),
        prefix: '007_',
      ),
      '007_sample image.jpg',
    );
  });
}
