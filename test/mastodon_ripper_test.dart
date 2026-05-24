import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/baraag_ripper.dart';
import 'package:ripme/ripper/rippers/mastodon_ripper.dart';
import 'package:ripme/ripper/rippers/mastodon_xyz_ripper.dart';

void main() {
  test('Mastodon-family rippers match Java host/domain GID behavior', () async {
    final mastodon = MastodonRipper(
      Uri.parse('https://mastodon.social/@alice'),
    );
    final baraag = BaraagRipper(Uri.parse('https://baraag.net/@artist'));
    final xyz = MastodonXyzRipper(Uri.parse('https://mastodon.xyz/@bob/media'));

    expect(mastodon.getHost(), 'mastodon');
    expect(
      await mastodon.getGID(Uri.parse('https://mastodon.social/@alice')),
      'mastodon.social@alice',
    );
    expect(
      await mastodon.getGID(Uri.parse('https://mastodon.social/@alice/media')),
      'mastodon.social@alice',
    );

    expect(baraag.getHost(), 'baraag');
    expect(
      await baraag.getGID(Uri.parse('https://baraag.net/@artist')),
      'baraag.net@artist',
    );

    expect(xyz.getHost(), 'mastodonxyz');
    expect(
      await xyz.getGID(Uri.parse('https://mastodon.xyz/@bob/media')),
      'mastodon.xyz@bob',
    );
  });

  test('MastodonRipper appends /media unless URL is already media page', () {
    expect(
      MastodonRipper.firstPageUrl(
        Uri.parse('https://mastodon.social/@alice'),
        'mastodon.social',
      ).toString(),
      'https://mastodon.social/@alice/media',
    );
    expect(
      MastodonRipper.firstPageUrl(
        Uri.parse('https://mastodon.social/@alice/media'),
        'mastodon.social',
      ).toString(),
      'https://mastodon.social/@alice/media',
    );
  });

  test(
    'MastodonRipper extracts gallery media URLs and IDs from data-props',
    () {
      final page = html.parse(r'''
      <html><body>
        <div data-component="MediaGallery"
             data-props='{"media":[{"id":"one","url":"https://cdn.example.com/one.jpg"},{"id":"two","url":"https://cdn.example.com/two.png"}]}'></div>
      </body></html>
    ''');

      final media = MastodonRipper.mediaFromDocument(page);

      expect(media.map((item) => item.id), ['one', 'two']);
      expect(media.map((item) => item.url.toString()), [
        'https://cdn.example.com/one.jpg',
        'https://cdn.example.com/two.png',
      ]);
    },
  );

  test('MastodonRipper finds Java load-more pagination link', () {
    final page = html.parse('''
      <html><body>
        <div class="h-entry"></div>
        <div class="entry"><a class="load-more load-gap" href="https://mastodon.social/@alice/media?max_id=1"></a></div>
        <div class="h-entry"></div>
        <div class="entry"><a class="load-more load-gap" href="https://mastodon.social/@alice/media?max_id=2"></a></div>
      </body></html>
    ''');

    expect(
      MastodonRipper.nextPageUrl(page).toString(),
      'https://mastodon.social/@alice/media?max_id=2',
    );
  });
}
