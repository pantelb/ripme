import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/eightmuses_ripper.dart';
import 'package:ripme/ripper/rippers/flickr_ripper.dart';
import 'package:ripme/ripper/rippers/imagefap_ripper.dart';
import 'package:ripme/ripper/rippers/imgur_ripper.dart';
import 'package:ripme/ripper/rippers/instagram_ripper.dart';
import 'package:ripme/ripper/rippers/motherless_ripper.dart';
import 'package:ripme/ripper/rippers/nhentai_ripper.dart';
import 'package:ripme/ripper/rippers/tumblr_ripper.dart';
import 'package:ripme/ripper/rippers/twitter_ripper.dart';

void main() {
  test('unfinished HTML ripper scaffolds advertise Java-compatible hosts',
      () async {
    final cases = [
      (
        ImgurRipper(Uri.parse('https://imgur.com/a/G058j5F')),
        Uri.parse('https://imgur.com/a/G058j5F'),
        'imgur',
        'G058j5F'
      ),
      (
        FlickrRipper(Uri.parse('https://www.flickr.com/photos/u/')),
        Uri.parse('https://www.flickr.com/photos/u/'),
        'flickr',
        'u'
      ),
      (
        InstagramRipper(Uri.parse('https://www.instagram.com/p/SHORTCODE/')),
        Uri.parse('https://www.instagram.com/p/SHORTCODE/'),
        'instagram',
        'post_SHORTCODE'
      ),
      (
        NhentaiRipper(Uri.parse('https://nhentai.net/g/123456/')),
        Uri.parse('https://nhentai.net/g/123456/'),
        'nhentai',
        '123456'
      ),
      (
        EightmusesRipper(
            Uri.parse('https://www.8muses.com/comics/album/example')),
        Uri.parse('https://www.8muses.com/comics/album/example'),
        '8muses',
        'example'
      ),
      (
        ImagefapRipper(Uri.parse('https://www.imagefap.com/gallery/abcdef12')),
        Uri.parse('https://www.imagefap.com/gallery/abcdef12'),
        'imagefap',
        'abcdef12'
      ),
      (
        MotherlessRipper(Uri.parse('https://motherless.com/GABCDEF1')),
        Uri.parse('https://motherless.com/GABCDEF1'),
        'motherless',
        'ABCDEF1'
      ),
    ];

    for (final item in cases) {
      final ripper = item.$1;
      final url = item.$2;

      expect(ripper.canRip(url), isTrue, reason: url.toString());
      expect(ripper.getHost(), item.$3, reason: url.toString());
      expect(await ripper.getGID(url), item.$4, reason: url.toString());
    }
  });

  test('unfinished JSON ripper scaffolds advertise Java-compatible hosts',
      () async {
    final tumblr = TumblrRipper(Uri.parse('https://example.tumblr.com/post/1'));
    expect(
        tumblr.canRip(Uri.parse('https://example.tumblr.com/post/1')), isTrue);
    expect(tumblr.getHost(), 'tumblr');
    expect(await tumblr.getGID(Uri.parse('https://example.tumblr.com/post/1')),
        'example.tumblr.com_post_1');

    final twitter = TwitterRipper(Uri.parse('https://x.com/user/status/123'));
    expect(twitter.canRip(Uri.parse('https://twitter.com/user/status/123')),
        isTrue);
    expect(twitter.canRip(Uri.parse('https://x.com/user/status/123')), isTrue);
    expect(twitter.getHost(), 'twitter');
    expect(await twitter.getGID(Uri.parse('https://x.com/user/status/123')),
        'account_user');
  });

  test('Imgur parser extracts i.imgur.com images and normalizes protocol',
      () async {
    final ripper = ImgurRipper(Uri.parse('https://imgur.com/a/G058j5F'));
    final page = html.parse('''
      <html><body>
        <img src="//i.imgur.com/one.jpg">
        <img src="https://i.imgur.com/two.png">
        <img src="https://example.com/not-imgur.jpg">
      </body></html>
    ''');

    expect(await ripper.getURLsFromPage(page), [
      'https://i.imgur.com/one.jpg',
      'https://i.imgur.com/two.png',
    ]);
  });

  test('Nhentai parser converts thumbnail URLs to full image URLs', () async {
    final ripper = NhentaiRipper(Uri.parse('https://nhentai.net/g/123456/'));
    final page = html.parse('''
      <html><body>
        <a class="gallerythumb">
          <img data-src="https://t.nhentai.net/galleries/12345/1t.jpg">
        </a>
        <a class="gallerythumb">
          <img data-src="https://t.nhentai.net/galleries/12345/2t.png">
        </a>
      </body></html>
    ''');

    expect(await ripper.getURLsFromPage(page), [
      'https://i.nhentai.net/galleries/12345/1.jpg',
      'https://i.nhentai.net/galleries/12345/2.png',
    ]);
  });

  test('8muses parser converts picture thumbnails to full image URLs',
      () async {
    final ripper = EightmusesRipper(
        Uri.parse('https://www.8muses.com/comics/album/example'));
    final page = html.parse('''
      <html><body>
        <a class="c-tile" href="/comics/picture/example/1">
          <img data-src="/pictures/th/example/1.jpg">
        </a>
      </body></html>
    ''');

    expect(await ripper.getURLsFromPage(page),
        ['https://comics.8muses.com/pictures/fl/example/1.jpg']);
  });

  test('Imagefap parser finds Java-style next page links', () async {
    final ripper =
        ImagefapRipper(Uri.parse('https://www.imagefap.com/gallery/abcdef12'));
    final page = html.parse('''
      <html><body>
        <a class="link3" href="/gallery/abcdef12?page=2">next</a>
      </body></html>
    ''');

    expect(
        (await ripper.getNextPage(page)).toString(),
        'https://www.imagefap.com/pictures/abcdef12/random-string'
        '/gallery/abcdef12?page=2');
  });

  test('Motherless parser finds rel=next pagination links', () async {
    final ripper =
        MotherlessRipper(Uri.parse('https://motherless.com/GABCDEF1'));
    final page = html.parse('''
      <html><head>
        <link rel="next" href="https://motherless.com/GABCDEF1?page=2">
      </head></html>
    ''');

    expect((await ripper.getNextPage(page)).toString(),
        'https://motherless.com/GABCDEF1?page=2');
  });
}
