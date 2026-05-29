import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/vsco_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java VSCO host support and GID parsing', () async {
    final media = Uri.parse(
      'https://vsco.co/jolly-roger/media/590359c4ade3041f2658f407',
    );
    final profile = Uri.parse('https://vsco.co/jolly-roger/gallery');
    final rootProfile = Uri.parse('https://vsco.co/jolly-roger/');
    final store = Uri.parse('https://vsco.co/store/example');

    expect(VscoRipper(media).canRip(media), isTrue);
    expect(VscoRipper(profile).canRip(profile), isTrue);
    expect(VscoRipper(store).canRip(store), isTrue);
    expect(
      VscoRipper(Uri.parse('https://example.com/jolly-roger'))
          .canRip(Uri.parse('https://example.com/jolly-roger')),
      isFalse,
    );
    expect(await VscoRipper(media).getGID(media), 'jolly-roger/59035');
    expect(await VscoRipper(profile).getGID(profile), 'jolly-roger');
    expect(await VscoRipper(rootProfile).getGID(rootProfile), 'jolly-roger');
  });

  test('keeps Java strict GID regex behavior', () async {
    final withWww = Uri.parse('https://www.vsco.co/jolly-roger/gallery');
    final withQuery = Uri.parse('https://vsco.co/jolly-roger/gallery?x=1');

    expect(VscoRipper(withWww).canRip(withWww), isTrue);
    await expectLater(
      VscoRipper(withWww).getGID(withWww),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      VscoRipper(withQuery).getGID(withQuery),
      throwsA(isA<FormatException>()),
    );
  });

  test('extracts single media og:image and strips height query like Java', () {
    final page = parse('''
      <html>
        <meta property="og:title" content="ignored">
        <meta property="og:image"
            content="https://image.vsco.co/abc/def/photo.jpg?h=900">
        <meta property="og:image"
            content="https://image.vsco.co/abc/def/ignored.jpg?h=900">
      </html>
    ''');

    expect(
      VscoRipper.imageUrlFromMediaPage(page),
      'https://image.vsco.co/abc/def/photo.jpg',
    );
    expect(VscoRipper.imageUrlFromMediaPage(parse('<html></html>')), isNull);
  });

  test('expands profile responsive URLs like Java', () {
    expect(
      VscoRipper.profileImageUrls({
        'total': 2,
        'media': [
          {'responsive_url': 'image.vsco.co/one.jpg'},
          {'responsive_url': 'image.vsco.co/two.jpg'},
          {'missing': 'ignored'},
        ],
      }),
      [
        'https://image.vsco.co/one.jpg',
        'https://image.vsco.co/two.jpg',
      ],
    );
  });

  test('uses Java-style configurable ordered filenames', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      VscoRipper.fileNameForUrl(
        Uri.parse('https://image.vsco.co/a/photo.jpg?token=1'),
        2,
      ),
      '002_photo.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      VscoRipper.fileNameForUrl(
        Uri.parse('https://image.vsco.co/a/photo.jpg'),
        2,
      ),
      'photo.jpg',
    );
  });
}
