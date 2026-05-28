import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/natalie_mu_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('NatalieMuRipper matches Java URL detection, host, domain, and GIDs',
      () async {
    final newsUrl = Uri.parse('http://cdn2.natalie.mu/music/news/140411');
    final galleryUrl = Uri.parse(
      'http://cdn2.natalie.mu/music/gallery/show/news_id/140411/image_id/369655',
    );
    final ripper = NatalieMuRipper(newsUrl);

    expect(ripper.canRip(newsUrl), isTrue);
    expect(ripper.canRip(galleryUrl), isTrue);
    expect(
        ripper.canRip(Uri.parse('http://natalie.mu/music/gallery/')), isFalse);
    expect(ripper.getHost(), 'natalie_music');
    expect(ripper.getDomain(), 'cdn2.natalie.mu');
    expect(await ripper.getGID(newsUrl), '140411');
    expect(await ripper.getGID(galleryUrl), '140411');
  });

  test('NatalieMuRipper extracts and normalizes gallery thumbnails like Java',
      () {
    final page = html.parse('''
      <div class="NA_articleGallery">
        <span style="background-image: url(//cdn.example/list_thumb_inbox/photo1.jpg);"></span>
        <span style="BACKGROUND-IMAGE: url(/media/list_thumb_inbox/photo2.jpg);"></span>
        <span style="background-image: url(http://cdn.example/list_thumb_inbox/photo1.jpg);"></span>
        <span style="background-image: url(/media/ignored/photo3.jpg);"></span>
        <span></span>
      </div>
    ''');

    expect(
      NatalieMuRipper.imageUrlsFromDocument(
        page,
        Uri.parse('http://cdn2.natalie.mu/music/news/140411'),
      ),
      [
        'http://cdn.example/xlarge/photo1.jpg',
        'http://cdn2.natalie.mu/media/xlarge/photo2.jpg',
      ],
    );
  });

  test('NatalieMuRipper uses Java-style ordered filenames', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(NatalieMuRipper.prefixForIndex(4), '004_');
    expect(
      NatalieMuRipper.fileNameForUrl(
        Uri.parse('http://cdn.example/xlarge/photo1.jpg'),
        prefix: NatalieMuRipper.prefixForIndex(4),
      ),
      '004_photo1.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(NatalieMuRipper.prefixForIndex(4), '');
  });

  test('NatalieMuRipper uses the source page as Java download referrer', () {
    final source = Uri.parse('http://cdn2.natalie.mu/music/news/140411');

    expect(NatalieMuRipper.downloadHeadersForPage(source), {
      'Referer': 'http://cdn2.natalie.mu/music/news/140411',
    });
  });
}
