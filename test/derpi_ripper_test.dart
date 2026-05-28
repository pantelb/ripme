import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/derpi_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('sanitizes Java URL forms into Derpibooru JSON endpoints', () async {
    SharedPreferences.setMockInitialValues({'remember.url_history': false});
    await Utils.init();

    expect(
      DerpiRipper.sanitizeUrl(
        Uri.parse('https://derpibooru.org/search?q=twilight+sparkle'),
      ).toString(),
      'https://derpibooru.org/search.json?q=twilight+sparkle',
    );
    expect(
      DerpiRipper.sanitizeUrl(
        Uri.parse('https://derpibooru.org/tags/rainbow_dash/'),
      ).toString(),
      'https://derpibooru.org/tags/rainbow_dash.json?',
    );
    expect(
      DerpiRipper.sanitizeUrl(
        Uri.parse('https://derpibooru.org/galleries/my-gallery/123'),
      ).toString(),
      'https://derpibooru.org/galleries/my-gallery/123.json?',
    );
    expect(
      DerpiRipper.sanitizeUrl(Uri.parse('https://derpibooru.org/456'))
          .toString(),
      'https://derpibooru.org/456.json?',
    );
  });

  test('appends configured API key like Java sanitizeURL', () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'derpi.key': 'secret',
    });
    await Utils.init();

    expect(
      DerpiRipper.sanitizeUrl(
        Uri.parse('https://derpibooru.org/search?q=applejack'),
      ).toString(),
      'https://derpibooru.org/search.json?q=applejack&key=secret',
    );
    expect(
      DerpiRipper.sanitizeUrl(Uri.parse('https://derpibooru.org/456'))
          .toString(),
      'https://derpibooru.org/456.json?&key=secret',
    );
  });

  test('matches Java host, domain, and sanitized GIDs', () async {
    SharedPreferences.setMockInitialValues({'remember.url_history': false});
    await Utils.init();

    final search = DerpiRipper(
      Uri.parse('https://derpibooru.org/search?q=twilight+sparkle'),
    );
    final tag =
        DerpiRipper(Uri.parse('https://derpibooru.org/tags/fluttershy'));
    final gallery = DerpiRipper(
      Uri.parse('https://derpibooru.org/galleries/favorites/99'),
    );
    final image = DerpiRipper(Uri.parse('https://derpibooru.org/12345'));

    expect(
        search.canRip(Uri.parse('https://derpibooru.org/search?q=x')), isTrue);
    expect(search.getHost(), 'DerpiBooru');
    expect(search.getDomain(), 'derpibooru.org');
    expect(await search.getGID(search.url), 'search_twilight+sparkle');
    expect(await tag.getGID(tag.url), 'tags_fluttershy');
    expect(await gallery.getGID(gallery.url), 'galleries_favorites_99');
    expect(await image.getGID(image.url), 'image_12345');
  });

  test('extracts image URLs from images, search, and single-image JSON', () {
    expect(
      DerpiRipper.urlsFromJson({
        'images': [
          {
            'representations': {'full': '//derpicdn.net/img/one.png'}
          },
          {
            'representations': {'full': '//derpicdn.net/img/two.jpg'}
          },
        ],
      }),
      [
        'https://derpicdn.net/img/one.png',
        'https://derpicdn.net/img/two.jpg',
      ],
    );
    expect(
      DerpiRipper.urlsFromJson({
        'search': [
          {
            'representations': {'full': '//derpicdn.net/img/legacy.gif'}
          },
        ],
      }),
      ['https://derpicdn.net/img/legacy.gif'],
    );
    expect(
      DerpiRipper.urlsFromJson({
        'representations': {'full': '//derpicdn.net/img/single.webm'},
      }),
      ['https://derpicdn.net/img/single.webm'],
    );
  });

  test('does not add ordered filename prefixes', () {
    expect(
      DerpiRipper.downloadFileName(
        Uri.parse(
            'https://derpicdn.net/img/2024/1/2/123456/full.png?download=1'),
        27,
      ),
      'full.png',
    );
  });
}
