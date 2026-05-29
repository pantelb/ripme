import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/nude_gals_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('NudeGalsRipper matches Java host, domain, support, and GIDs', () async {
    final albumUrl =
        Uri.parse('https://nude-gals.com/photoshoot.php?photoshoot_id=5541');
    final videoUrl = Uri.parse('https://nude-gals.com/video.php?video_id=1277');
    final ripper = NudeGalsRipper(albumUrl);

    expect(ripper.canRip(albumUrl), isTrue);
    expect(ripper.canRip(videoUrl), isTrue);
    expect(ripper.getHost(), 'Nude-Gals');
    expect(ripper.getDomain(), 'nude-gals.com');
    expect(await ripper.getGID(albumUrl), 'album_5541');
    expect(await ripper.getGID(videoUrl), 'video_1277');

    await expectLater(
      ripper.getGID(
        Uri.parse(
            'https://nude-gals.com/photoshoot.php?photoshoot_id=5541&p=2'),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('NudeGalsRipper extracts album thumbnails like Java', () {
    final page = html.parse('''
      <img class="thumbnail" src="thumbs/th_sets/A Nice Photo.jpg">
      <img class="thumbnail" src="gallery/Already Full.jpg">
    ''');

    expect(NudeGalsRipper.albumUrlsFromPage(page), [
      'http://nude-gals.com/sets/A%20Nice%20Photo.jpg',
      'http://nude-gals.com/gallery/Already%20Full.jpg',
    ]);
  });

  test('NudeGalsRipper extracts video sources like Java', () {
    final page = html.parse('''
      <video>
        <source src="videos/My Clip 720p.mp4">
        <source src=" videos/My Clip 1080p.mp4 ">
      </video>
    ''');

    expect(NudeGalsRipper.videoUrlsFromPage(page), [
      'http://nude-gals.com/videos/My%20Clip%20720p.mp4',
      'http://nude-gals.com/videos/My%20Clip%201080p.mp4',
    ]);
  });

  test('NudeGalsRipper uses source page referrer and ordered filenames',
      () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();

    final sourcePage =
        Uri.parse('https://nude-gals.com/video.php?video_id=1277');
    expect(NudeGalsRipper.downloadHeaders(sourcePage),
        {'Referer': sourcePage.toString()});
    expect(
      NudeGalsRipper.downloadFileName(
        Uri.parse('http://nude-gals.com/videos/My%20Clip.mp4'),
        4,
      ),
      '004_My%20Clip.mp4',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      NudeGalsRipper.downloadFileName(
        Uri.parse('http://nude-gals.com/photos/image.jpg'),
        4,
      ),
      'image.jpg',
    );
  });
}
