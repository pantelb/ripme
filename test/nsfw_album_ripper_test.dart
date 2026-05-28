import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/nsfw_album_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('NsfwAlbumRipper matches Java host, domain, support, and GIDs',
      () async {
    final url = Uri.parse('https://nsfwalbum.com/album/905816');
    final ripper = NsfwAlbumRipper(url);

    expect(ripper.canRip(url), isTrue);
    expect(ripper.canRip(Uri.parse('https://www.nsfwalbum.com/album/850951')),
        isTrue);
    expect(ripper.getHost(), 'nsfwalbum');
    expect(ripper.getDomain(), 'nsfwalbum.com');
    expect(await ripper.getGID(url), '905816');
    expect(
      await ripper.getGID(Uri.parse('https://nsfwalbum.com/album/850951')),
      '850951',
    );
    await expectLater(
      ripper.getGID(Uri.parse('https://nsfwalbum.com/album/no-digits')),
      throwsA(isA<FormatException>()),
    );
  });

  test('NsfwAlbumRipper rewrites supported thumbnails like Java', () {
    expect(
      NsfwAlbumRipper.fullResolutionUrl(
        'https://imgspice.com/example/path/photo_t.jpg',
      ),
      'https://imgspice.com/example/path/photo.jpg',
    );
    expect(
      NsfwAlbumRipper.fullResolutionUrl(
        'https://imagetwist.com/th/123/photo.jpg',
      ),
      'https://imagetwist.com/i/123/photo.jpg',
    );
    expect(
      NsfwAlbumRipper.fullResolutionUrl(
        'https://t1.pixhost.com/thumbs/123/456_photo.jpg',
      ),
      'https://img1.pixhost.com/images/123/456_photo.jpg',
    );
    expect(
      NsfwAlbumRipper.fullResolutionUrl('https://imx.to/t/abc/photo.jpg'),
      'https://imx.to/i/abc/photo.jpg',
    );
    expect(
        NsfwAlbumRipper.fullResolutionUrl('https://example.com/a.jpg'), isNull);
  });

  test('NsfwAlbumRipper extracts .album data-src images in page order', () {
    final page = html.parse('''
      <div class="album">
        <img data-src="https://imgspice.com/a/photo_t.jpg">
        <img data-src="https://imagetwist.com/th/1/two.jpg">
        <img src="https://imgspice.com/ignored_t.jpg">
        <img data-src="https://example.com/ignored.jpg">
      </div>
    ''');

    expect(NsfwAlbumRipper.imageUrlsFromDocument(page), [
      'https://imgspice.com/a/photo.jpg',
      'https://imagetwist.com/i/1/two.jpg',
    ]);
  });

  test('NsfwAlbumRipper uses Java-style ordered filenames', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(NsfwAlbumRipper.prefixForIndex(5), '005_');
    expect(
      NsfwAlbumRipper.fileNameForUrl(
        Uri.parse('https://imgspice.com/a/photo.jpg'),
        prefix: NsfwAlbumRipper.prefixForIndex(5),
      ),
      '005_photo.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(NsfwAlbumRipper.prefixForIndex(5), '');
  });
}
