import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/imgur_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('ImgurRipper getHost', () {
    final ripper = ImgurRipper(Uri.parse('https://imgur.com/a/G058j5F'));
    expect(ripper.getHost(), equals('imgur'));
  });

  test('ImgurRipper canRip', () {
    final ripper = ImgurRipper(Uri.parse('https://imgur.com/a/G058j5F'));
    expect(ripper.canRip(Uri.parse('https://imgur.com/a/G058j5F')), isTrue);
    expect(
        ripper.canRip(Uri.parse('https://imgur.com/gallery/abc123')), isTrue);
    expect(ripper.canRip(Uri.parse('https://imgur.com/user/john')), isTrue);
    expect(ripper.canRip(Uri.parse('https://john.imgur.com')), isTrue);
    expect(ripper.canRip(Uri.parse('https://john.imgur.com/all')), isTrue);
    expect(ripper.canRip(Uri.parse('https://imgur.com/r/memes')), isTrue);
    expect(
        ripper.canRip(Uri.parse('https://imgur.com/r/memes/top/all')), isTrue);
    expect(ripper.canRip(Uri.parse('https://imgur.com/abcde')), isTrue);
    expect(ripper.canRip(Uri.parse('https://google.com')), isFalse);
    expect(
        ripper.canRip(Uri.parse('https://www.imgur.com')), isFalse); // homepage
  });

  test('ImgurRipper getGID for album URLs', () async {
    final ripper = ImgurRipper(Uri.parse('https://imgur.com/a/G058j5F'));
    expect(await ripper.getGID(Uri.parse('https://imgur.com/a/G058j5F')),
        'G058j5F');
    expect(await ripper.getGID(Uri.parse('https://imgur.com/gallery/G058j5F')),
        'G058j5F');
    expect(
        await ripper.getGID(Uri.parse('https://imgur.com/a/abc123')), 'abc123');
    expect(
        await ripper.getGID(Uri.parse('https://imgur.com/t/xyz789')), 'xyz789');
  });

  test('ImgurRipper getGID for user URLs', () async {
    final ripper = ImgurRipper(Uri.parse('https://imgur.com/user/john'));
    expect(await ripper.getGID(Uri.parse('https://imgur.com/user/john')),
        'user_john');
    final ripper2 = ImgurRipper(Uri.parse('https://john.imgur.com'));
    expect(
        await ripper2.getGID(Uri.parse('https://john.imgur.com')), 'user_john');
  });

  test('ImgurRipper getGID for user images URLs', () async {
    final ripper = ImgurRipper(Uri.parse('https://john.imgur.com/all'));
    expect(await ripper.getGID(Uri.parse('https://john.imgur.com/all')),
        'john_images');
  });

  test('ImgurRipper getGID for user album URLs', () async {
    final ripper = ImgurRipper(Uri.parse('https://john.imgur.com/myalbum'));
    expect(await ripper.getGID(Uri.parse('https://john.imgur.com/myalbum')),
        'john-myalbum');
  });

  test('ImgurRipper getGID for subreddit URLs', () async {
    final ripper = ImgurRipper(Uri.parse('https://imgur.com/r/memes'));
    expect(
        await ripper.getGID(Uri.parse('https://imgur.com/r/memes')), 'memes');
    final ripper2 = ImgurRipper(Uri.parse('https://imgur.com/r/memes/top/all'));
    expect(await ripper2.getGID(Uri.parse('https://imgur.com/r/memes/top/all')),
        'memes_top_all');
  });

  test('ImgurRipper getGID for single image URLs', () async {
    final ripper = ImgurRipper(Uri.parse('https://imgur.com/abcde'));
    expect(await ripper.getGID(Uri.parse('https://imgur.com/abcde')), 'abcde');
  });

  test('ImgurRipper getGID for subreddit album URLs', () async {
    final ripper = ImgurRipper(Uri.parse('https://imgur.com/r/memes/abc123'));
    expect(await ripper.getGID(Uri.parse('https://imgur.com/r/memes/abc123')),
        'r_memes_abc123');
  });

  test('ImgurRipper throws FormatException for invalid URLs', () async {
    final ripper = ImgurRipper(Uri.parse('https://imgur.com'));
    expect(() => ripper.getGID(Uri.parse('https://imgur.com')),
        throwsA(isA<FormatException>()));
  });

  test('ImgurRipper album title parsing follows Java fallback behavior', () {
    final titled = html.parse('''
      <html><head>
        <meta property="og:title" content="Album Title">
      </head></html>
    ''');
    expect(ImgurRipper.albumTitleFromDocument(titled), 'Album Title');

    final fallback = html.parse('''
      <html><head>
        <meta property="og:title" content="Imgur: The magic of the Internet">
        <title>Fallback Title</title>
      </head></html>
    ''');
    expect(ImgurRipper.albumTitleFromDocument(fallback), 'Fallback Title');
  });

  test('ImgurRipper allowDuplicates', () async {
    final ripperUser = ImgurRipper(Uri.parse('https://john.imgur.com'));
    await ripperUser.getGID(Uri.parse('https://john.imgur.com'));
    expect(ripperUser.allowDuplicates(), isTrue);

    final ripperAlbum = ImgurRipper(Uri.parse('https://imgur.com/a/G058j5F'));
    await ripperAlbum.getGID(Uri.parse('https://imgur.com/a/G058j5F'));
    expect(ripperAlbum.allowDuplicates(), isFalse);

    final ripperSingle = ImgurRipper(Uri.parse('https://imgur.com/abcde'));
    await ripperSingle.getGID(Uri.parse('https://imgur.com/abcde'));
    expect(ripperSingle.allowDuplicates(), isFalse);
  });

  test('ImgurRipper extracts album API images like Java', () {
    final images = ImgurRipper.albumImagesFromApiJson({
      'data': {
        'images': [
          {'link': 'https://i.imgur.com/one.jpg'},
          {'link': 'https://i.imgur.com/two.png?1'},
          {'ignored': true},
        ],
      },
    });

    expect(images.map((image) => image.url.toString()), [
      'https://i.imgur.com/one.jpg',
      'https://i.imgur.com/two.png?1',
    ]);
    expect(images[1].saveAs, 'two.png');
  });

  test('ImgurRipper parses noscript fallback images and prefer.mp4', () async {
    SharedPreferences.setMockInitialValues({'prefer.mp4': true});
    await Utils.init();

    final doc = html.parse('''
      <html><body>
        <div class="image"><a class="zoom" href="//i.imgur.com/one.gif"></a></div>
        <div class="image"><img src="//i.imgur.com/two.jpg"></div>
        <div class="image"></div>
      </body></html>
    ''');

    expect(
      ImgurRipper.albumImagesFromNoscript(doc)
          .map((image) => image.url.toString()),
      [
        'http://i.imgur.com/one.mp4',
        'http://i.imgur.com/two.jpg',
      ],
    );
  });

  test('ImgurRipper builds single media URL from post API JSON', () async {
    SharedPreferences.setMockInitialValues({'prefer.mp4': true});
    await Utils.init();

    expect(
      ImgurRipper.extractImageUrlFromJson({'id': 'abcde', 'ext': 'gif'})
          .toString(),
      'https://i.imgur.com/abcde.mp4',
    );
    expect(
      ImgurRipper.extractImageUrlFromJson({'id': 'abcde', 'ext': '.jpg'})
          .toString(),
      'https://i.imgur.com/abcde.jpg',
    );
  });

  test('ImgurRipper parses user ajax image pages', () {
    final parsed = ImgurRipper.userImagesFromAjaxJson({
      'data': {
        'count': 2,
        'images': [
          {'hash': 'one', 'ext': '.jpg'},
          {'hash': 'two', 'ext': '.png'},
        ],
      },
    });

    expect(parsed.total, 2);
    expect(parsed.images.map((image) => image.url.toString()), [
      'https://i.imgur.com/one.jpg',
      'https://i.imgur.com/two.png',
    ]);
  });

  test('ImgurRipper converts album ids to Java page URLs', () {
    expect(ImgurRipper.albumPageUrl('abc123').toString(),
        'https://imgur.com/a/abc123');
    expect(ImgurRipper.albumPageUrl('r_memes_abc123').toString(),
        'https://imgur.com/r/memes/abc123');
  });
}
