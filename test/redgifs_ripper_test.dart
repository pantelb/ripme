import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/redgifs_ripper.dart';

void main() {
  tearDown(() {
    RedgifsRipper.getJsonForTesting = null;
    RedgifsRipper.resetAuthTokenForTesting();
  });

  test('sanitizes legacy Redgifs URL forms', () {
    expect(
      RedgifsRipper.sanitizeUrl(
              Uri.parse('https://thumbs.redgifs.com/watch/example/amp'))
          .toString(),
      'https://redgifs.com/watch/example',
    );
    expect(
      RedgifsRipper.sanitizeUrl(
              Uri.parse('https://www.gifdeliverynetwork.com/exampleid'))
          .toString(),
      'https://www.redgifs.com/watch/exampleid',
    );
    expect(
      RedgifsRipper.sanitizeUrl(
              Uri.parse('https://www.redgifs.com/gifs/detail/exampleid'))
          .toString(),
      'https://www.redgifs.com/watch/exampleid',
    );
  });

  test('extracts Redgifs GIDs for singleton, profile, search, and tags',
      () async {
    expect(
        await RedgifsRipper(
                Uri.parse('https://www.redgifs.com/watch/exampleid-extra'))
            .getGID(Uri.parse('https://www.redgifs.com/watch/exampleid-extra')),
        'exampleid');
    expect(
        await RedgifsRipper(
                Uri.parse('https://www.redgifs.com/users/example_user'))
            .getGID(Uri.parse('https://www.redgifs.com/users/example_user')),
        'example_user');
    expect(
        await RedgifsRipper(
                Uri.parse('https://www.redgifs.com/search?query=take+a+shot'))
            .getGID(
                Uri.parse('https://www.redgifs.com/search?query=take+a+shot')),
        'take-a-shot');
    expect(
        await RedgifsRipper(
                Uri.parse('https://www.redgifs.com/gifs/funny,safe?tab=gifs'))
            .getGID(
                Uri.parse('https://www.redgifs.com/gifs/funny,safe?tab=gifs')),
        'funny_safe');
  });

  test('getVideoUrl follows Java static helper auth and hd URL behavior',
      () async {
    final requests = <Uri>[];
    final headersByRequest = <Uri, Map<String, String>?>{};

    RedgifsRipper.getJsonForTesting = (url, {headers}) async {
      requests.add(url);
      headersByRequest[url] = headers;
      if (url.toString() == 'https://api.redgifs.com/v2/auth/temporary') {
        return {'token': 'test-token'};
      }
      if (url.toString() == 'https://api.redgifs.com/v2/gifs/exampleid') {
        return {
          'gif': {
            'gallery': null,
            'urls': {'hd': 'https://media.redgifs.com/exampleid.mp4'},
          },
        };
      }
      fail('Unexpected Redgifs request: $url');
    };

    final videoUrl = await RedgifsRipper.getVideoUrl(
      Uri.parse('https://www.redgifs.com/watch/exampleid-extra'),
    );

    expect(videoUrl, 'https://media.redgifs.com/exampleid.mp4');
    expect(requests.map((url) => url.toString()), [
      'https://api.redgifs.com/v2/auth/temporary',
      'https://api.redgifs.com/v2/gifs/exampleid',
    ]);
    expect(
      headersByRequest[Uri.parse('https://api.redgifs.com/v2/gifs/exampleid')],
      {'Authorization': 'Bearer test-token'},
    );
  });

  test('getVideoUrl rejects gallery responses like Java helper', () async {
    RedgifsRipper.getJsonForTesting = (url, {headers}) async {
      if (url.toString() == 'https://api.redgifs.com/v2/auth/temporary') {
        return {'token': 'test-token'};
      }
      if (url.toString() == 'https://api.redgifs.com/v2/gifs/exampleid') {
        return {
          'gif': {
            'gallery': 'galleryid',
            'urls': {'hd': 'https://media.redgifs.com/exampleid.mp4'},
          },
        };
      }
      fail('Unexpected Redgifs request: $url');
    };

    expect(
      RedgifsRipper.getVideoUrl(
        Uri.parse('https://www.redgifs.com/watch/exampleid'),
      ),
      throwsFormatException,
    );
  });
}
