import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/imgur_ripper.dart';

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

  test('ImgurRipper album title generation', () async {
    final ripper = ImgurRipper(Uri.parse('https://imgur.com/a/G058j5F'));
    final title =
        await ripper.getAlbumTitle(Uri.parse('https://imgur.com/a/G058j5F'));
    expect(title, startsWith('imgur_G058j5F'));
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
}
