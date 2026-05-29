import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/nsfw_xxx_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('NsfwXxxRipper sanitizes Java user URL forms', () {
    expect(
      NsfwXxxRipper.sanitizeUrl(
        Uri.parse('https://nsfw.xxx/user/kelly-kat/foo'),
      ).toString(),
      'https://nsfw.xxx/user/kelly-kat',
    );
    expect(
      NsfwXxxRipper.sanitizeUrl(
        Uri.parse('http://nsfw.xxx/user/kelly-kat'),
      ).toString(),
      'https://nsfw.xxx/user/kelly-kat',
    );
    expect(
      () => NsfwXxxRipper.sanitizeUrl(Uri.parse('https://nsfw.xxx/posts')),
      throwsA(isA<FormatException>()),
    );
  });

  test('NsfwXxxRipper matches Java host, domain, support, GID, and API URL',
      () async {
    final ripper = NsfwXxxRipper(
      Uri.parse('https://nsfw.xxx/user/smay3991/extra'),
    );

    expect(ripper.url.toString(), 'https://nsfw.xxx/user/smay3991');
    expect(ripper.canRip(ripper.url), isTrue);
    expect(ripper.getHost(), 'nsfw_xxx');
    expect(ripper.getDomain(), 'nsfw.xxx');
    expect(await ripper.getGID(ripper.url), 'smay3991');
    expect(
      (await ripper.getPage(2)).toString(),
      'https://nsfw.xxx/slide-page/2?nsfw%5B%5D=0&types%5B%5D=image&types%5B%5D=video&types%5B%5D=gallery&slider=1&jsload=1&user=smay3991',
    );

    await expectLater(
      ripper.getGID(Uri.parse('https://www.nsfw.xxx/user/smay3991')),
      throwsA(isA<FormatException>()),
    );
  });

  test('NsfwXxxRipper extracts image src and video HTML sources like Java', () {
    final entries = NsfwXxxRipper.entriesFromJson({
      'page': 1,
      'items': [
        {
          'src': 'https://cdn.nsfw.xxx/images/photo.jpg',
          'author': 'alice',
          'title': 'Photo Title',
        },
        {
          'html':
              '<video><source src="https://cdn.nsfw.xxx/video.mp4?x=1&amp;y=2"></video>',
          'author': 'bob',
          'title': 'Video Title',
        },
      ],
    });

    expect(entries.map((entry) => entry.srcUrl), [
      'https://cdn.nsfw.xxx/images/photo.jpg',
      'https://cdn.nsfw.xxx/video.mp4?x=1&y=2',
    ]);
    expect(entries.map((entry) => entry.title), ['Photo Title', 'Video Title']);
  });

  test('NsfwXxxRipper stores descriptions in JSON extraction order', () {
    final ripper = NsfwXxxRipper(Uri.parse('https://nsfw.xxx/user/smay3991'));

    expect(
      ripper.getURLsFromJSON({
        'page': 1,
        'items': [
          {
            'src': 'https://cdn.nsfw.xxx/a.jpg',
            'author': 'alice',
            'title': 'One',
          },
          {
            'src': 'https://cdn.nsfw.xxx/b.jpg',
            'author': 'bob',
            'title': 'Two',
          },
        ],
      }),
      ['https://cdn.nsfw.xxx/a.jpg', 'https://cdn.nsfw.xxx/b.jpg'],
    );
    expect(ripper.descriptions, ['One', 'Two']);
  });

  test('NsfwXxxRipper uses Java-style title filename prefixes', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();

    expect(NsfwXxxRipper.prefixForIndex(7), '007_');
    expect(
      NsfwXxxRipper.downloadFileName(
        Uri.parse('https://cdn.nsfw.xxx/path/video.mp4?token=1'),
        7,
        'My Title',
      ),
      '007_My Title_video.mp4',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(NsfwXxxRipper.prefixForIndex(7), '');
    expect(
      NsfwXxxRipper.downloadFileName(
        Uri.parse('https://cdn.nsfw.xxx/path/photo.jpg'),
        7,
        'My Title',
      ),
      'My Title_photo.jpg',
    );
  });
}
