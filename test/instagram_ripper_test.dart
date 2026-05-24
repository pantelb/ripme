import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/instagram_ripper.dart';

void main() {
  test('InstagramRipper matches Java URL classification and GIDs', () async {
    final cases = {
      'https://www.instagram.com/explore/tags/rachelc00k/': 'tag_rachelc00k',
      'https://www.instagram.com/stories/rachelc00k/': 'rachelc00k_stories',
      'https://www.instagram.com/rachelc00k/tagged/': 'rachelc00k_tagged',
      'https://www.instagram.com/rachelc00k/channel/': 'rachelc00k_igtv',
      'https://www.instagram.com/p/Bu4CEfbhNk4/': 'post_Bu4CEfbhNk4',
      'https://www.instagram.com/rachelc00k/?pinned': 'rachelc00k_pinned',
      'https://www.instagram.com/rachelc00k/': 'rachelc00k',
    };

    for (final entry in cases.entries) {
      final uri = Uri.parse(entry.key);
      final ripper = InstagramRipper(uri);
      expect(ripper.canRip(uri), isTrue);
      expect(await ripper.getGID(uri), entry.value, reason: entry.key);
    }
  });

  test('InstagramRipper extracts shared-data JSON from Java script forms', () {
    final page = html.parse(r'''
      <html><body>
        <script type="text/javascript">window._sharedData = {"entry_data":{"ProfilePage":[{"graphql":{"user":{"id":"42"}}}]}};</script>
      </body></html>
    ''');

    expect(
      InstagramRipper.jsonStringByPath(
        InstagramRipper.jsonObjectFromDocument(page),
        'entry_data.ProfilePage[0].graphql.user.id',
      ),
      '42',
    );
  });

  test('InstagramRipper selects preload JavaScript like Java', () {
    final page = html.parse('''
      <html><head>
        <link rel="preload" href="/static/Consumer.js">
        <link rel="preload" href="/static/ProfilePageContainer.js">
      </head></html>
    ''');

    expect(
      InstagramRipper.preloadHref(
        page,
        const InstagramUrlMatch(InstagramUrlType.userProfile, 'user'),
      ),
      '/static/Consumer.js',
    );
    expect(
      InstagramRipper.preloadHref(
        page,
        const InstagramUrlMatch(InstagramUrlType.userTagged, 'user'),
      ),
      '/static/ProfilePageContainer.js',
    );
  });

  test('InstagramRipper extracts query hashes from JavaScript windows', () {
    expect(
      InstagramRipper.queryHashFromJavaScript(
        'queryId:"abcdef1234567890"; function loadProfilePageExtras(){}',
        const InstagramUrlMatch(InstagramUrlType.userProfile, 'user'),
      ),
      'abcdef1234567890',
    );
    expect(
      InstagramRipper.queryHashFromJavaScript(
        '"11111111"; requestNextTagMedia(); "22222222";',
        const InstagramUrlMatch(InstagramUrlType.hashtag, 'tag'),
      ),
      '22222222',
    );
  });

  test('InstagramRipper resolves id strings and media root paths', () {
    final profileJson = {
      'entry_data': {
        'ProfilePage': [
          {
            'graphql': {
              'user': {
                'id': '42',
                'edge_owner_to_timeline_media': {'edges': []}
              }
            }
          }
        ]
      }
    };
    final hashtagJson = {
      'data': {
        'hashtag': {'edge_hashtag_to_media': {}}
      }
    };

    expect(
      InstagramRipper.idStringFromJson(
        profileJson,
        const InstagramUrlMatch(InstagramUrlType.userProfile, 'user'),
      ),
      '42',
    );
    expect(
      InstagramRipper.mediaRootPath(
        hashtagJson,
        const InstagramUrlMatch(InstagramUrlType.hashtag, 'tag'),
      ),
      'data.hashtag.edge_hashtag_to_media',
    );
  });

  test('InstagramRipper parses stories with Java prefix ordering', () {
    final media = InstagramRipper.storyMediaFromJson({
      'data': {
        'reels_media': [
          {
            'items': [
              {
                'is_video': true,
                'taken_at_timestamp': 0,
                'video_resources': [
                  {'src': 'https://cdn.example.com/low.mp4'},
                  {'src': 'https://cdn.example.com/high.mp4'}
                ],
                'display_url': 'https://cdn.example.com/preview.jpg'
              },
              {
                'is_video': false,
                'taken_at_timestamp': 1,
                'display_url': 'https://cdn.example.com/image.jpg'
              }
            ]
          }
        ]
      }
    });

    expect(media.map((item) => item.url.toString()), [
      'https://cdn.example.com/high.mp4',
      'https://cdn.example.com/preview.jpg',
      'https://cdn.example.com/image.jpg',
    ]);
    expect(media.map((item) => item.prefix), [
      '1970-01-01_00-00-00_',
      '1970-01-01_00-00-00_preview_',
      '1970-01-01_00-00-01_',
    ]);
  });

  test('InstagramRipper recurses sidecars and builds timestamp prefixes', () {
    final item = {
      '__typename': 'GraphSidecar',
      'shortcode': 'SHORT',
      'taken_at_timestamp': 0,
      'edge_sidecar_to_children': {
        'edges': [
          {
            'node': {
              '__typename': 'GraphImage',
              'display_url': 'https://cdn.example.com/one.jpg'
            }
          },
          {
            'node': {
              '__typename': 'GraphVideo',
              'video_url': 'https://cdn.example.com/two.mp4?x=1'
            }
          }
        ]
      }
    };

    expect(InstagramRipper.prefixInfoForItem(item), [
      '1970-01-01_00-00-00_SHORT_',
      '1970-01-01_00-00-00_SHORT_',
    ]);
    expect(
        InstagramRipper.parseRootForUrls(item).map((url) => url.toString()), [
      'https://cdn.example.com/one.jpg',
      'https://cdn.example.com/two.mp4?x=1',
    ]);
  });
}
