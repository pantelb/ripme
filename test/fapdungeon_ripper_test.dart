import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/fapdungeon_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java URL detection, host, domain, GID, and album title',
      () async {
    final ripper = FapDungeonRipper(Uri.parse(
        'https://fapdungeon.com/white/thegorillagrip-busty-cutie-onlyfans-nudes/'));
    final mobile = Uri.parse(
        'https://m.fapdungeon.com/asian/joythailia-sexy-asian-petite-onlyfans-nudes/');

    expect(ripper.canRip(ripper.url), isTrue);
    expect(ripper.canRip(mobile), isTrue);
    expect(ripper.getHost(), 'fapdungeon');
    expect(ripper.getDomain(), 'fapdungeon.com');
    expect(await ripper.getGID(ripper.url), 'white');
    expect(
      await ripper.getAlbumTitle(ripper.url),
      'fapdungeon_white_thegorillagrip-busty-cutie-onlyfans-nudes/',
    );
  });

  test('selects largest srcset image and falls back to src like Java', () {
    expect(
      FapDungeonRipper.largestImageUrlFromSrcset(
        'https://cdn.fapdungeon.com/fallback.jpg',
        'https://cdn.fapdungeon.com/small.jpg 320w, '
            'https://cdn.fapdungeon.com/large.jpg 1280w, '
            'https://cdn.fapdungeon.com/medium.jpg 640w',
      ),
      'https://cdn.fapdungeon.com/large.jpg',
    );
    expect(
      FapDungeonRipper.largestImageUrlFromSrcset(
        'https://cdn.fapdungeon.com/fallback.jpg',
        '',
      ),
      'https://cdn.fapdungeon.com/fallback.jpg',
    );
  });

  test('extracts entry-content images and videos in Java order', () {
    final page = parse('''
      <div class="outside"><img src="https://cdn.example/ignore.jpg"></div>
      <div class="entry-content">
        <img src="https://cdn.example/fallback.jpg"
             srcset="https://cdn.example/small.jpg 300w, https://cdn.example/big.jpg 900w">
        <img src="https://cdn.example/no-srcset.jpg">
        <video>
          <source src="https://cdn.example/video.mp4">
        </video>
      </div>
    ''');

    expect(FapDungeonRipper.mediaFromPage(page), [
      'https://cdn.example/big.jpg',
      'https://cdn.example/no-srcset.jpg',
      'https://cdn.example/video.mp4',
    ]);
  });

  test('uses Java-style ordered filenames', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      FapDungeonRipper.fileNameForUrl(
        Uri.parse('https://cdn.fapdungeon.com/path/image.jpg?size=large'),
        12,
      ),
      '012_image.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      FapDungeonRipper.fileNameForUrl(
        Uri.parse('https://cdn.fapdungeon.com/path/video.mp4'),
        12,
      ),
      'video.mp4',
    );
  });
}
