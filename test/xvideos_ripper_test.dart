import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/xvideos_ripper.dart';

void main() {
  test('matches Java Xvideos URL support, GIDs, and album titles', () async {
    final video = Uri.parse(
      'https://www.xvideos.com/video.ufkmptkc4ae/big_tit_step_sis',
    );
    final album = Uri.parse(
      'https://www.xvideos.com/amateurs/nikibeee/photos/2476083/lanikki',
    );
    final ripper = XvideosRipper(video);

    expect(ripper.getHost(), 'xvideos');
    expect(ripper.getDomain(), 'xvideos.com');
    expect(ripper.canRip(video), isTrue);
    expect(ripper.canRip(album), isTrue);
    expect(
      ripper.canRip(Uri.parse('https://www.xvideos.com/video23515878/title')),
      isFalse,
    );

    expect(await ripper.getGID(video), 'ufkmptkc4ae');
    expect(await ripper.getGID(album), '2476083');
    expect(
      await ripper.getAlbumTitle(video),
      'xvideos_ufkmptkc4ae_/big_tit_step_sis',
    );
    expect(
      await ripper.getAlbumTitle(album),
      'xvideos_amateurs_nikibeee_lanikki_2476083',
    );
  });

  test('extracts high video URLs from scripts like Java', () {
    final page = parse(r'''
      <script>
        html5player.setVideoUrlLow('https://cdn.example/low.mp4');
        html5player.setVideoUrlHigh('https://cdn.example/high.mp4');
      </script>
      <script>html5player.setVideoUrlHigh(	'https://cdn.example/other.mp4');</script>
    ''');

    expect(XvideosRipper.videoUrlsFromDocument(page), [
      'https://cdn.example/high.mp4',
      'https://cdn.example/other.mp4',
    ]);
  });

  test('extracts album thumb hrefs and ordered filenames like Java', () {
    final page = parse('''
      <div class="thumb"><a href="https://img.example/one.jpg"></a></div>
      <div class="thumb"><a href="/relative/two.jpg"></a></div>
    ''');

    expect(XvideosRipper.albumUrlsFromDocument(page), [
      'https://img.example/one.jpg',
      '/relative/two.jpg',
    ]);
    expect(
      XvideosRipper.fileNameForUrl(
        Uri.parse('https://cdn.example/videos/high.mp4'),
        prefix: XvideosRipper.prefix(4),
      ),
      '004_high.mp4',
    );
  });
}
