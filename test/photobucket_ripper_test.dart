import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;
import 'package:ripme/ripper/rippers/photobucket_ripper.dart';

void main() {
  test('PhotobucketRipper sanitizes Java gallery URL forms', () {
    expect(
      PhotobucketRipper.sanitizeUri(
        Uri.parse(
          'http://s732.photobucket.com/user/doublesix66/library/Army%20Painter%20examples?sort=3&page=1',
        ),
      ).toString(),
      'http://s732.photobucket.com/user/doublesix66/library/Army%20Painter%20examples/',
    );
    expect(
      PhotobucketRipper.sanitizeUri(
        Uri.parse(
          'http://s844.photobucket.com/user/SpazzySpizzy/library/Album%20Covers',
        ),
      ).toString(),
      'http://s844.photobucket.com/user/SpazzySpizzy/library/Album%20Covers/',
    );
  });

  test('PhotobucketRipper matches Java host, domain, support, and GIDs',
      () async {
    final ripper = PhotobucketRipper(
      Uri.parse(
        'http://s732.photobucket.com/user/doublesix66/library/Army%20Painter%20examples?sort=3&page=1',
      ),
    );

    expect(ripper.getHost(), 'photobucket');
    expect(ripper.getDomain(), 'photobucket.com');
    expect(
      ripper.canRip(
        Uri.parse(
          'http://s732.photobucket.com/user/doublesix66/library/Army%20Painter%20examples/Painting%20examples?page=1&sort=3',
        ),
      ),
      isTrue,
    );
    expect(
      await ripper.getGID(
        Uri.parse(
          'http://s732.photobucket.com/user/doublesix66/library/Army%20Painter%20examples?sort=3&page=1',
        ),
      ),
      'doublesix66',
    );
    expect(
      await ripper.getGID(
        Uri.parse(
          'http://s844.photobucket.com/user/SpazzySpizzy/library/Album%20Covers',
        ),
      ),
      'SpazzySpizzy',
    );
    expect(
      await ripper.getGID(
        Uri.parse('http://s844.photobucket.com/user/SpazzySpizzy/library'),
      ),
      'SpazzySpizzy',
    );
  });

  test('PhotobucketRipper constructs Java metadata API URLs', () {
    expect(
      PhotobucketRipper.albumMetadataApiUrl(
        'http://s732.photobucket.com/user/doublesix66/library/Army%20Painter%20examples/',
        subAlbums: 24,
      ).toString(),
      'http://s732.photobucket.com/api/user/doublesix66/album/Army%20Painter%20examples/get?subAlbums=24&json=1',
    );
    expect(
      PhotobucketRipper.albumMetadataApiUrl(
        'http://s1255.photobucket.com/user/mimajki/library/Movie%20gifs/',
        subAlbums: 48,
      ).toString(),
      'http://s1255.photobucket.com/api/user/mimajki/album/Movie%20gifs/get?subAlbums=48&json=1',
    );
  });

  test('PhotobucketRipper parses album metadata like Java', () {
    final album = PhotobucketAlbumMetadata.fromJson({
      'url': 'http://s1255.photobucket.com/user/mimajki/library/Movie%20gifs',
      'location': 'Movie gifs/Sub album',
      'sortOrder': 6,
    });

    expect(album.location, 'Movie_gifs/Sub_album');
    expect(
      album.currentPageUrl().toString(),
      'http://s1255.photobucket.com/user/mimajki/library/Movie%20gifs?sort=6&page=1',
    );

    expect(
      PhotobucketRipper.subAlbumJsons({
        'subAlbums': [
          {
            'url': 'http://s.example.invalid/user/u/library/child',
            'location': 'child',
            'sortOrder': 3,
          },
        ],
      }).single['location'],
      'child',
    );
    expect(PhotobucketRipper.numPagesForTotal(0), 0);
    expect(PhotobucketRipper.numPagesForTotal(1), 1);
    expect(PhotobucketRipper.numPagesForTotal(24), 1);
    expect(PhotobucketRipper.numPagesForTotal(25), 2);
  });

  test('PhotobucketRipper extracts Java collectionData fullsize URLs', () {
    final page = html.parse(r'''
      <html><body>
        <script type="text/javascript">
          window.libraryAlbumsPageCollectionData = true;
          collectionData: {"total":25,"items":{"objects":[
            {"fullsizeUrl":"http://img.example.com/one.jpg"},
            {"fullsizeUrl":"http://img.example.com/two.png"}
          ]}}
        </script>
      </body></html>
    ''');

    final collectionData = PhotobucketRipper.collectionDataFromDocument(page);

    expect(collectionData?['total'], 25);
    expect(PhotobucketRipper.imageUrlsFromCollectionData(collectionData!), [
      'http://img.example.com/one.jpg',
      'http://img.example.com/two.png',
    ]);
  });

  test('PhotobucketRipper creates Java download metadata', () {
    final download = PhotobucketRipper.downloadForMedia(
      Uri.parse('http://img.example.com/folder/photo%201.jpg'),
      index: 7,
      albumLocation: 'Movie_gifs/Sub_album',
      pageUrl:
          'http://s1255.photobucket.com/user/mimajki/library/Movie%20gifs?sort=6&page=1',
      cookies: {'session': 'abc'},
      workingDir: Directory('/tmp/ripme_photobucket_test'),
    );

    expect(
      download.saveAs.path,
      p.join(
        '/tmp/ripme_photobucket_test',
        'Movie_gifs',
        'Sub_album',
        '007_photo 1.jpg',
      ),
    );
    expect(download.headers, {
      'Referer':
          'http://s1255.photobucket.com/user/mimajki/library/Movie%20gifs?sort=6&page=1',
    });
    expect(download.cookies, {'session': 'abc'});
  });
}
