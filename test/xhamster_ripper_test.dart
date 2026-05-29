import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/xhamster_ripper.dart';

void main() {
  test('matches Java Xhamster URL support and GID parsing', () async {
    final ripper = XhamsterRipper(
      Uri.parse(
          'https://xhamster.com/photos/gallery/sexy-preggo-girls-9026608'),
    );

    expect(ripper.getHost(), 'xhamster');
    expect(ripper.getDomain(), 'xhamster.com');
    expect(ripper.canRip(ripper.url), isTrue);
    expect(
      ripper.canRip(
        Uri.parse('https://xhamster5.desi/photos/gallery/dolls-7254664'),
      ),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://pt.xhamster.com/users/name/photos')),
      isTrue,
    );
    expect(
      ripper.canRip(
        Uri.parse('https://xhamster.com/videos/example-video-1492828'),
      ),
      isTrue,
    );

    expect(await ripper.getGID(ripper.url), '9026608');
    expect(
      await ripper.getGID(
        Uri.parse('https://xhamster5.desi/photos/gallery/dolls-7254664'),
      ),
      '7254664',
    );
    expect(
      await ripper.getGID(Uri.parse('https://xhamster.com/users/alice/photos')),
      'user_',
    );
    expect(
      await ripper
          .getGID(Uri.parse('https://xhamster2.com/users/alice/photos')),
      'user_2',
    );
    expect(
      await ripper.getGID(
        Uri.parse('https://xhamster.com/videos/example-video-1492828'),
      ),
      'example-video-1492828',
    );
  });

  test('sanitizes non-video URLs to mobile like Java', () {
    expect(
      XhamsterRipper.sanitizeUrl(
        Uri.parse('https://xhamster.com/photos/gallery/example-1'),
      ),
      Uri.parse('https://m.xhamster.com/photos/gallery/example-1'),
    );
    expect(
      XhamsterRipper.sanitizeUrl(
        Uri.parse('https://pt.xhamster.com/photos/gallery/example-1'),
      ),
      Uri.parse('https://m.xhamster.com/photos/gallery/example-1'),
    );
    expect(
      XhamsterRipper.sanitizeUrl(
        Uri.parse('https://xhamster5.desi/photos/gallery/example-1'),
      ),
      Uri.parse('https://m.xhamster5.desi/photos/gallery/example-1'),
    );
    final video = Uri.parse('https://xhamster.com/videos/example-1492828');
    expect(XhamsterRipper.sanitizeUrl(video), video);
  });

  test('extracts user queue albums like Java', () {
    final page = parse('''
      <div class="item-container"><a class="item" href="https://xhamster.com/photos/gallery/one-1"></a></div>
      <div class="item-container"><a class="item" href="/photos/gallery/two-2"></a></div>
    ''');

    expect(XhamsterRipper.albumUrlsFromDocument(page), [
      'https://xhamster.com/photos/gallery/one-1',
      '/photos/gallery/two-2',
    ]);
  });

  test('extracts old and new gallery URLs like Java', () {
    final oldPage = parse('''
      <div class="picture_view"><div class="pictures_block"><div class="items">
        <div class="item-container"><a class="item"></a></div>
      </div></div></div>
      <div class="clearfix"><div><a class="slided" href="https://xhamster.com/photos/view/1"></a></div></div>
    ''');
    final imagePage =
        parse('<a><img id="photoCurr" src="https://cdn.example/1.jpg"></a>');

    expect(XhamsterRipper.usesOldGalleryStructure(oldPage), isTrue);
    expect(XhamsterRipper.oldImagePageUrlsFromDocument(oldPage), [
      'https://m.xhamster.com/photos/view/1',
    ]);
    expect(XhamsterRipper.imageFromOldImagePage(imagePage),
        'https://cdn.example/1.jpg');

    final newPage = parse('''
      <div id="photo-slider"><div id="photo_slider">
        <a href="https://xhamster.com/photos/view/2.jpg"></a>
      </div></div>
    ''');
    expect(XhamsterRipper.usesOldGalleryStructure(newPage), isFalse);
    expect(XhamsterRipper.newGalleryUrlsFromDocument(newPage), [
      'https://m.xhamster.com/photos/view/2.jpg',
    ]);
  });

  test('extracts video href, next page, album title, and filenames', () {
    final videoPage = parse(
        '<div class="player-container"><a href="https://video.example/file.mp4"></a></div>');
    expect(XhamsterRipper.videoUrlsFromDocument(videoPage), [
      'https://video.example/file.mp4',
    ]);

    final nextPage = parse('''
      <a class="prev-next-list-link" href="https://xhamster.com/photos/gallery/example-1"></a>
      <a class="prev-next-list-link--next" href="https://xhamster.com/photos/gallery/example-1/2"></a>
    ''');
    expect(
      XhamsterRipper.nextPageUrl(nextPage),
      Uri.parse('https://m.xhamster.com/photos/gallery/example-1/2'),
    );

    final titlePage = parse('<a class="author">alice</a>');
    expect(
      XhamsterRipper.albumTitleFromDocument(
        titlePage,
        Uri.parse('https://m.xhamster.com/photos/gallery/example-1'),
      ),
      'xhamster_alice_example-1',
    );
    expect(
      XhamsterRipper.fileNameForUrl(
        Uri.parse('https://cdn.example/path/photo.jpg'),
        prefix: XhamsterRipper.prefix(7),
      ),
      '007_photo.jpg',
    );
  });
}
