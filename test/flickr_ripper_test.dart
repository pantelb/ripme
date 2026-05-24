import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/flickr_ripper.dart';

void main() {
  test('FlickrRipper matches Java URL sanitization and GID behavior', () async {
    final photoset =
        Uri.parse('https://www.flickr.com/photos/user_name/sets/721576/');
    final user = Uri.parse('https://www.flickr.com/photos/115858035@N04/');
    final group = Uri.parse('https://www.flickr.com/groups/example/');
    final ripper = FlickrRipper(photoset);

    expect(ripper.canRip(photoset), isTrue);
    expect(await ripper.getGID(photoset), 'user_name_721576');
    expect(await ripper.getGID(user), '115858035@N04');
    expect(await ripper.getGID(group), 'groups-example');
    expect(
      FlickrRipper.sanitizeUrl(Uri.parse('https://secure.flickr.com/groups/g')),
      Uri.parse('http://www.flickr.com/groups/g/pool'),
    );
  });

  test('FlickrRipper classifies Java API-supported URL types', () {
    final set = FlickrRipper.classifyUrl(
        Uri.parse('https://www.flickr.com/photos/user/albums/12345/'));
    final user = FlickrRipper.classifyUrl(
        Uri.parse('https://www.flickr.com/photos/user_123/'));

    expect(set.type, FlickrAlbumType.photoset);
    expect(set.id, '12345');
    expect(user.type, FlickrAlbumType.user);
    expect(user.id, 'user_123');
    expect(
      () => FlickrRipper.classifyUrl(
          Uri.parse('https://www.flickr.com/groups/example/pool')),
      throwsA(isA<FormatException>()),
    );
  });

  test('FlickrRipper extracts API key from page JavaScript with fallback', () {
    final page = html.parse('''
      <html><body>
        <script>root.YUI_config.flickr.api.site_key = "abc123XYZ";</script>
      </body></html>
    ''');
    final fallbackPage = html.parse('<html></html>');

    expect(FlickrRipper.apiKeyFromDocument(page), 'abc123XYZ');
    expect(FlickrRipper.apiKeyFromDocument(fallbackPage),
        FlickrRipper.fallbackApiKey);
  });

  test('FlickrRipper builds Java-compatible listing API URLs', () {
    final url = FlickrRipper.apiUrl(
      const FlickrAlbum(FlickrAlbumType.photoset, '721576'),
      '2',
      'key',
    );

    expect(url, contains('method=flickr.photosets.getPhotos'));
    expect(url, contains('photoset_id=721576'));
    expect(url, contains('per_page=100&page=2'));
    expect(url, contains('api_key=key'));
    expect(url, contains('format=json&hermes=1&hermesClient=1'));
  });

  test('FlickrRipper extracts paginated photo ids from photoset and user JSON',
      () {
    final setListing = FlickrRipper.photoIdsFromListJson({
      'photoset': {
        'pages': 3,
        'photo': [
          {'id': 'one'},
          {'id': 2},
        ],
      },
    });
    final userListing = FlickrRipper.photoIdsFromListJson({
      'photos': {
        'pages': '1',
        'photo': [
          {'id': 'three'},
        ],
      },
    });

    expect(setListing?.totalPages, 3);
    expect(setListing?.photoIds, ['one', '2']);
    expect(userListing?.totalPages, 1);
    expect(userListing?.photoIds, ['three']);
  });

  test('FlickrRipper picks largest source from getSizes response', () {
    final largest = FlickrRipper.largestImageUrlFromSizesJson({
      'sizes': {
        'size': [
          {
            'width': '100',
            'height': '100',
            'source': 'https://live.staticflickr.com/small.jpg'
          },
          {
            'width': 200,
            'height': 150,
            'source': 'https://live.staticflickr.com/large.jpg'
          },
        ],
      },
    });

    expect(largest.toString(), 'https://live.staticflickr.com/large.jpg');
  });

  test('FlickrRipper derives set titles like Java', () {
    final page = html.parse('''
      <html><head>
        <meta name="description" content="Album Title">
      </head></html>
    ''');

    expect(
      FlickrRipper.albumTitleFromDocument(
          Uri.parse('https://www.flickr.com/photos/user/sets/123/'), page),
      'flickr_user_Album Title',
    );
  });
}
