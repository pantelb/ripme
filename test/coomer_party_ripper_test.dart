import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/coomer_party_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java URL detection and GID parsing', () async {
    final urls = [
      'https://coomer.su/onlyfans/user/soogsx',
      'http://coomer.su/onlyfans/user/soogsx',
      'https://coomer.su/onlyfans/user/soogsx/',
      'https://coomer.su/onlyfans/user/soogsx?whatever=abc',
      'https://coomer.party/onlyfans/user/soogsx',
    ];

    for (final urlText in urls) {
      final uri = Uri.parse(urlText);
      final ripper = CoomerPartyRipper(uri);
      expect(ripper.canRip(uri), isTrue);
      expect(await ripper.getGID(uri), 'onlyfans_soogsx');
      expect(ripper.postsApiUrl(0),
          'https://coomer.su/api/v1/onlyfans/user/soogsx?o=0');
      expect(ripper.postsApiUrl(50),
          'https://coomer.su/api/v1/onlyfans/user/soogsx?o=50');
    }
  });

  test('extracts Java-compatible file and attachment URLs', () {
    final urls = CoomerPartyRipper.urlsFromPosts([
      {
        'file': {'path': '/ab/cd/photo.JPG'},
        'attachments': [
          {
            'file': {'path': '/ef/gh/clip.mp4'}
          },
          {
            'file': {'path': '/ij/kl/animation.webp'}
          },
          {'path': '/ignored/direct.jpg'},
        ],
      },
      {
        'file': {'path': '/mn/op/archive.zip'},
      },
      {
        'attachments': [
          {
            'file': {'path': '/qr/st/movie.M4V'}
          },
        ],
      },
    ]);

    expect(urls, [
      'https://c3.coomer.su/data/ab/cd/photo.JPG',
      'https://c1.coomer.su/data/ef/gh/clip.mp4',
      'https://c3.coomer.su/data/ij/kl/animation.webp',
      'https://c1.coomer.su/data/qr/st/movie.M4V',
    ]);
  });

  test('uses Java-style ordered filename prefixes', () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'download.save_order': true,
    });
    await Utils.init();

    expect(
      CoomerPartyRipper.downloadFileName(
        Uri.parse('https://c3.coomer.su/data/ab/cd/photo.jpg?token=1'),
        7,
      ),
      '007_photo.jpg',
    );

    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'download.save_order': false,
    });
    await Utils.init();

    expect(
      CoomerPartyRipper.downloadFileName(
        Uri.parse('https://c1.coomer.su/data/ab/cd/video.mp4'),
        8,
      ),
      'video.mp4',
    );
  });
}
