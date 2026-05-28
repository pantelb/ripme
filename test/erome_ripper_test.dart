import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/erome_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, URL sanitization, support, and GIDs',
      () async {
    final album = EromeRipper(Uri.parse('https://erome.com/a/KbDAM1XT'));
    final wwwAlbum = EromeRipper(Uri.parse('https://www.erome.com/a/P0x5Ambn'));
    final imageAlbum = EromeRipper(Uri.parse('https://www.erome.com/i/ABC123'));
    final profile = EromeRipper(Uri.parse('https://www.erome.com/Jay-Jenna'));

    expect(album.url.toString(), 'https://www.erome.com/a/KbDAM1XT');
    expect(album.canRip(album.url), isTrue);
    expect(album.getHost(), 'erome');
    expect(album.getDomain(), 'erome.com');
    expect(await album.getGID(album.url), 'KbDAM1XT');
    expect(await wwwAlbum.getGID(wwwAlbum.url), 'P0x5Ambn');
    expect(await imageAlbum.getGID(imageAlbum.url), 'ABC123');
    expect(await profile.getGID(profile.url), 'Jay-Jenna');
  });

  test('matches Java queue detection and album link extraction', () async {
    final profile = EromeRipper(Uri.parse('https://www.erome.com/Jay-Jenna'));
    final album = EromeRipper(Uri.parse('https://www.erome.com/a/KbDAM1XT'));
    final page = parse('''
      <div id="albums">
        <div class="album"><a href="https://www.erome.com/a/one">one</a></div>
        <div class="album"><a href="/a/two">two</a></div>
      </div>
    ''');

    expect(profile.hasQueueSupport(), isTrue);
    expect(profile.pageContainsAlbums(profile.url), isTrue);
    expect(album.pageContainsAlbums(album.url), isFalse);
    expect(await profile.getAlbumsToQueue(page), [
      'https://www.erome.com/a/one',
      '/a/two',
    ]);
  });

  test('extracts lazy images and HD/SD video sources in Java order', () {
    final page = parse('''
      <img class="img-front" data-src="https://cdn.erome.com/lazy.jpg">
      <img class="img-front" src="//cdn.erome.com/front.jpg">
      <img class="img-front" src="https://cdn.erome.com/full.jpg">
      <video>
        <source label="SD" src="//cdn.erome.com/video-sd.mp4">
        <source label="HD" src="https://cdn.erome.com/video-hd.mp4">
      </video>
    ''');

    expect(EromeRipper.mediaFromPage(page), [
      'https://cdn.erome.com/lazy.jpg',
      'https://cdn.erome.com/front.jpg',
      'https://cdn.erome.com/full.jpg',
      'https://cdn.erome.com/video-hd.mp4',
      'https://cdn.erome.com/video-sd.mp4',
    ]);
  });

  test('loads optional laravel_session auth cookie only when configured',
      () async {
    SharedPreferences.setMockInitialValues({'erome.laravel_session': ''});
    await Utils.init();
    final empty = EromeRipper(Uri.parse('https://www.erome.com/a/KbDAM1XT'));
    empty.setAuthCookie();
    expect(empty.cookiesForTesting, isEmpty);

    SharedPreferences.setMockInitialValues({'erome.laravel_session': 'abc123'});
    await Utils.init();
    final configured =
        EromeRipper(Uri.parse('https://www.erome.com/a/KbDAM1XT'));
    configured.setAuthCookie();
    expect(configured.cookiesForTesting, {'laravel_session': 'abc123'});
  });

  test('uses Java-style ordered filenames', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      EromeRipper.fileNameForUrl(
        Uri.parse('https://cdn.erome.com/path/video.mp4?download=1'),
        7,
      ),
      '007_video.mp4',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      EromeRipper.fileNameForUrl(
        Uri.parse('https://cdn.erome.com/path/front.jpg'),
        7,
      ),
      'front.jpg',
    );
  });
}
