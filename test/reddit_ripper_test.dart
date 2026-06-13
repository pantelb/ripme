import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/redgifs_ripper.dart';
import 'package:ripme/ripper/rippers/reddit_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    RedgifsRipper.getJsonForTesting = null;
    RedgifsRipper.resetAuthTokenForTesting();
  });

  test('builds Reddit JSON URLs like the Java ripper', () {
    expect(
      RedditRipper.getJsonUrl(
              Uri.parse('https://www.reddit.com/r/example/top?t=all'))
          .toString(),
      'https://www.reddit.com/r/example/top.json?t=all',
    );
    expect(
      RedditRipper.getJsonUrl(
              Uri.parse('https://www.reddit.com/gallery/abc123'))
          .toString(),
      'https://reddit.com/abc123.json',
    );
  });

  test('extracts Reddit GIDs for users, posts, galleries, and subreddits',
      () async {
    expect(
        await RedditRipper(Uri.parse('https://www.reddit.com/user/some_user'))
            .getGID(Uri.parse('https://www.reddit.com/user/some_user')),
        'user_some_user');
    expect(
        await RedditRipper(Uri.parse(
                'https://www.reddit.com/r/pics/comments/abc123/title'))
            .getGID(Uri.parse(
                'https://www.reddit.com/r/pics/comments/abc123/title')),
        'post_abc123');
    expect(
        await RedditRipper(Uri.parse('https://www.reddit.com/gallery/abc123'))
            .getGID(Uri.parse('https://www.reddit.com/gallery/abc123')),
        'post_abc123');
    expect(
        await RedditRipper(Uri.parse('https://www.reddit.com/r/pics'))
            .getGID(Uri.parse('https://www.reddit.com/r/pics')),
        'sub_pics');
  });

  test('extracts direct media and gallery media from listing JSON', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    final json = {
      'data': {
        'children': [
          {
            'kind': 't3',
            'data': {
              'id': 'abc123',
              'title': 'Gallery Post',
              'is_self': false,
              'url': 'https://i.redd.it/direct.jpg',
            },
          },
          {
            'kind': 't3',
            'data': {
              'id': 'def456',
              'title': 'Album Post',
              'is_self': false,
              'gallery_data': {
                'items': [
                  {'media_id': 'm1'},
                  {'media_id': 'm2'},
                ],
              },
              'media_metadata': {
                'm1': {
                  's': {
                    'u':
                        'https://preview.redd.it/one.jpg?width=800&amp;format=pjpg'
                  },
                },
                'm2': {
                  's': {
                    'gif':
                        'https://preview.redd.it/two.gif?format=mp4&amp;s=token'
                  },
                },
              },
            },
          },
        ],
      },
    };

    final media = await RedditRipper.extractMediaFromJson(json);

    expect(media.map((item) => item.url.toString()), [
      'https://i.redd.it/direct.jpg',
      'https://preview.redd.it/one.jpg?width=800&format=pjpg',
      'https://preview.redd.it/two.gif?format=mp4&s=token',
    ]);
    expect(media[1].subdirectory, 'Album Post');
    expect(media[1].prefix, 'def456-01-');
  });

  test('honors migrated Reddit filter and naming settings', () async {
    SharedPreferences.setMockInitialValues({
      'reddit.rip_by_upvote': true,
      'reddit.min_upvotes': 10,
      'reddit.max_upvotes': 20,
      'download.save_order': false,
      'reddit.use_sub_dirs': false,
      'album_titles.save': false,
    });
    await Utils.init();

    final json = {
      'data': {
        'children': [
          {
            'kind': 't3',
            'data': {
              'id': 'low',
              'title': 'Too Low',
              'score': 5,
              'is_self': false,
              'url': 'https://i.redd.it/low.jpg',
            },
          },
          {
            'kind': 't3',
            'data': {
              'id': 'ok',
              'title': 'Kept Gallery',
              'score': 15,
              'is_self': false,
              'gallery_data': {
                'items': [
                  {'media_id': 'm1'},
                ],
              },
              'media_metadata': {
                'm1': {
                  's': {'u': 'https://preview.redd.it/one.jpg?width=800'},
                },
              },
            },
          },
        ],
      },
    };

    final media = await RedditRipper.extractMediaFromJson(json);

    expect(media, hasLength(1));
    expect(media.single.url.toString(),
        'https://preview.redd.it/one.jpg?width=800');
    expect(media.single.prefix, 'ok-');
    expect(media.single.subdirectory, isNull);
  });

  test('builds Java-compatible Reddit download filenames', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    final media = await RedditRipper.extractMediaFromJson({
      'data': {
        'children': [
          {
            'kind': 't3',
            'data': {
              'id': 'abc123',
              'title': 'Direct Post',
              'is_self': false,
              'url': 'https://i.redd.it/direct.jpg?width=800',
            },
          },
          {
            'kind': 't3',
            'data': {
              'id': 'up123',
              'title': 'Upload Post',
              'is_self': false,
              'url': 'https://i.reddituploads.com/uploadid?fit=max',
            },
          },
          {
            'kind': 't3',
            'data': {
              'id': 'gal123',
              'title': 'Gallery Post',
              'is_self': false,
              'gallery_data': {
                'items': [
                  {'media_id': 'm1'},
                ],
              },
              'media_metadata': {
                'm1': {
                  's': {'u': 'https://preview.redd.it/one.jpg?width=800'},
                },
              },
            },
          },
        ],
      },
    });

    expect(RedditRipper.downloadFileNameFor(media[0]),
        'abc123-Direct Post-direct.jpg');
    expect(RedditRipper.downloadFileNameFor(media[1]),
        'up123-uploadid-Upload Post-.jpg');
    expect(RedditRipper.downloadFileNameFor(media[2]), 'gal123-01-one.jpg');

    final video = RedditMedia(
      url: Uri.parse('https://v.redd.it/vidid/DASH_720.mp4'),
      prefix: '',
      fileName: 'postid-vidid-Video Post-.mp4',
    );
    expect(RedditRipper.downloadFileNameFor(video),
        'postid-vidid-Video Post-.mp4');
  });

  test('selects Reddit DASH video with Java height-only semantics', () {
    final videoUrl = Uri.parse('https://v.redd.it/abc');

    expect(
      RedditRipper.redditVideoUrlFromManifest(
        parse('''
          <MPD><Period><AdaptationSet>
            <Representation bandwidth="9999999">
              <BaseURL>bandwidth-only.mp4</BaseURL>
            </Representation>
            <Representation height="360">
              <BaseURL>DASH_360.mp4</BaseURL>
            </Representation>
            <Representation height="720">
              <BaseURL>/DASH_720.mp4</BaseURL>
            </Representation>
          </AdaptationSet></Period></MPD>
        '''),
        videoUrl,
      ).toString(),
      'https://v.redd.it/abc//DASH_720.mp4',
    );

    expect(
      RedditRipper.redditVideoUrlFromManifest(
        parse('''
          <MPD><Period><AdaptationSet>
            <Representation bandwidth="9999999">
              <BaseURL>bandwidth-only.mp4</BaseURL>
            </Representation>
          </AdaptationSet></Period></MPD>
        '''),
        videoUrl,
      ).toString(),
      'https://v.redd.it/abc/null',
    );

    expect(
      RedditRipper.redditVideoUrlFromManifest(
        parse('''
          <MPD><Period><AdaptationSet>
            <Representation height="720"><BaseURL>first.mp4</BaseURL></Representation>
            <Representation height="720"><BaseURL>second.mp4</BaseURL></Representation>
          </AdaptationSet></Period></MPD>
        '''),
        videoUrl,
      ),
      isNull,
    );

    expect(
      () => RedditRipper.redditVideoUrlFromManifest(
        parse('''
          <MPD><Period><AdaptationSet>
            <Representation height="invalid">
              <BaseURL>invalid.mp4</BaseURL>
            </Representation>
          </AdaptationSet></Period></MPD>
        '''),
        videoUrl,
      ),
      throwsFormatException,
    );
  });

  test('matches Java single-link title behavior when subfolders are disabled',
      () async {
    SharedPreferences.setMockInitialValues({
      'reddit.use_sub_dirs': false,
      'album_titles.save': false,
    });
    await Utils.init();

    final media = await RedditRipper.extractMediaFromJson({
      'data': {
        'children': [
          {
            'kind': 't3',
            'data': {
              'id': 'abc123',
              'title': 'Title Still Kept',
              'is_self': false,
              'url': 'https://i.redd.it/direct.jpg',
            },
          },
        ],
      },
    });

    expect(RedditRipper.downloadFileNameFor(media.single),
        'abc123Title Still Keptdirect.jpg');
  });

  test('expands Imgur gifv links like Java RipUtils', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    final expanded = await RedditRipper.expandNonDirectUrl(
        Uri.parse('https://i.imgur.com/example.gifv?token=1'));
    expect(expanded.map((uri) => uri.toString()), [
      'https://i.imgur.com/example.mp4?token=1',
    ]);

    final media = await RedditRipper.extractMediaFromJson({
      'data': {
        'children': [
          {
            'kind': 't3',
            'data': {
              'id': 'abc123',
              'title': 'Imgur Gifv',
              'is_self': false,
              'url': 'https://i.imgur.com/example.gifv',
            },
          },
        ],
      },
    });

    expect(media.map((item) => item.url.toString()), [
      'https://i.imgur.com/example.mp4',
    ]);
    expect(RedditRipper.downloadFileNameFor(media.single),
        'abc123-Imgur Gifv-example.mp4');
  });

  test('expands Java RipUtils direct passthrough URLs', () async {
    expect(
      (await RedditRipper.expandNonDirectUrl(
        Uri.parse('https://v.redd.it/abc123/DASH_720.mp4'),
      ))
          .map((uri) => uri.toString()),
      ['https://v.redd.it/abc123/DASH_720.mp4'],
    );
    expect(
      (await RedditRipper.expandNonDirectUrl(
        Uri.parse('https://i.reddituploads.com/uploadid?fit=max&amp;s=token'),
      ))
          .map((uri) => uri.toString()),
      ['https://i.reddituploads.com/uploadid?fit=max&s=token'],
    );
    expect(
      (await RedditRipper.expandNonDirectUrl(
        Uri.parse('https://cdn.example.com/path/image.jpg?size=large'),
      ))
          .map((uri) => uri.toString()),
      ['https://cdn.example.com/path/image.jpg?size=large'],
    );
    expect(
      await RedditRipper.expandNonDirectUrl(
        Uri.parse('https://cdn.example.info/path/image.webp'),
      ),
      isEmpty,
    );
  });

  test('expands Redgifs singleton links like Java RipUtils', () async {
    RedgifsRipper.getJsonForTesting = (url, {headers}) async {
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

    expect(
      (await RedditRipper.expandNonDirectUrl(
        Uri.parse('https://www.redgifs.com/watch/exampleid-extra'),
      ))
          .map((uri) => uri.toString()),
      ['https://media.redgifs.com/exampleid.mp4'],
    );
  });

  test('leaves gifdeliverynetwork empty like Java RipUtils helper failure',
      () async {
    RedgifsRipper.getJsonForTesting = (url, {headers}) async {
      fail('gifdeliverynetwork should not fetch Redgifs JSON in RipUtils mode');
    };

    expect(
      await RedditRipper.expandNonDirectUrl(
        Uri.parse('https://www.gifdeliverynetwork.com/exampleid'),
      ),
      isEmpty,
    );
  });

  test('extracts Imgur page media from Java meta tags', () {
    final videoPage = parse('''
      <html><head>
      <meta property="og:video" content="https://i.imgur.com/video.mp4">
      </head></html>
    ''');
    expect(
        RedditRipper.imgurMediaFromPage(videoPage).map((uri) => uri.toString()),
        ['https://i.imgur.com/video.mp4']);

    final imagePage = parse('''
      <html><head>
      <meta name="twitter:image:src" content="//i.imgur.com/image.jpg">
      </head></html>
    ''');
    expect(
        RedditRipper.imgurMediaFromPage(imagePage).map((uri) => uri.toString()),
        ['https://i.imgur.com/image.jpg']);
  });

  test('extracts Soundgasm m4a links like Java RipUtils', () {
    final page = parse(r'''
      <html><body>
      <script>
        window.soundgasm = { m4a: "https://media.soundgasm.net/sounds/example.m4a" };
      </script>
      <script>
        window.other = { m4a: "https://media.soundgasm.net/sounds/second.m4a" };
      </script>
      </body></html>
    ''');

    expect(
      RedditRipper.soundgasmMediaFromPage(page).map((uri) => uri.toString()),
      [
        'https://media.soundgasm.net/sounds/example.m4a',
        'https://media.soundgasm.net/sounds/second.m4a',
      ],
    );
  });

  test('extracts Vidble album images like Java RipUtils', () {
    final page = parse(r'''
      <html><body>
      <div id="ContentPlaceHolder1_divContent">
        <img src="https://vidble.com/images/one_thumb.jpg">
        <img src="//vidble.com/images/two_small.png">
      </div>
      <img src="https://vidble.com/images/outside_t.jpg">
      </body></html>
    ''');

    expect(
      RedditRipper.vidbleMediaFromPage(page).map((uri) => uri.toString()),
      [
        'https://vidble.com/images/one.jpg',
        'https://vidble.com/images/two.png',
      ],
    );
  });

  test('extracts Erome image and video sources like Java RipUtils', () {
    final page = parse(r'''
      <html><body>
      <img class="img-front" data-src="//cdn.erome.com/image-one.jpg">
      <img class="img-front" src="https://cdn.erome.com/image-two.jpg">
      <video>
        <source label="HD" src="//cdn.erome.com/video-hd.mp4">
        <source label="SD" src="https://cdn.erome.com/video-sd.mp4">
      </video>
      </body></html>
    ''');

    expect(
      RedditRipper.eromeMediaFromPage(page).map((uri) => uri.toString()),
      [
        'https://cdn.erome.com/image-one.jpg',
        'https://cdn.erome.com/image-two.jpg',
        'https://cdn.erome.com/video-hd.mp4',
        'https://cdn.erome.com/video-sd.mp4',
      ],
    );
  });

  test('builds self-post HTML export with comments', () {
    final posts = RedditRipper.extractSelfPostHtmlFromJson([
      {
        'data': {
          'children': [
            {
              'kind': 't3',
              'data': {
                'id': 'abc123',
                'title': 'Self Post',
                'author': 'op_user',
                'subreddit': 'pics',
                'created': 1760000000,
                'is_self': true,
                'selftext': 'Body text',
                'selftext_html': '<p>Body <strong>text</strong></p>',
                'url':
                    'https://www.reddit.com/r/pics/comments/abc123/self_post',
              },
            },
          ],
        },
      },
      {
        'data': {
          'children': [
            {
              'kind': 't1',
              'data': {
                'name': 't1_comment',
                'author': 'commenter',
                'created': 1760000100,
                'body_html': '<p>First comment</p>',
                'replies': {
                  'data': {
                    'children': [
                      {
                        'kind': 't1',
                        'data': {
                          'name': 't1_reply',
                          'author': 'op_user',
                          'created': 1760000200,
                          'body_html': '<p>Nested reply</p>',
                        },
                      },
                    ],
                  },
                },
              },
            },
          ],
        },
      },
    ]);

    expect(posts, hasLength(1));
    expect(posts.single.id, 'abc123');
    expect(posts.single.title, 'Self Post');
    expect(posts.single.html, contains('<h1>Self Post</h1>'));
    expect(posts.single.html, contains('Body text'));
    expect(posts.single.html, contains('commenter'));
    expect(posts.single.html, contains('First comment'));
    expect(posts.single.html, contains('Nested reply'));
    expect(
        posts.single.html, contains('<span class="author op">op_user</span>'));
  });

  test('does not export self-post HTML from listing-only JSON', () {
    final posts = RedditRipper.extractSelfPostHtmlFromJson({
      'data': {
        'children': [
          {
            'kind': 't3',
            'data': {
              'id': 'abc123',
              'title': 'Listing Self Post',
              'author': 'op_user',
              'subreddit': 'pics',
              'created': 1760000000,
              'is_self': true,
              'selftext': 'Body text',
            },
          },
        ],
      },
    });

    expect(posts, isEmpty);
  });

  test('builds next page URL from listing after token', () {
    final next = RedditRipper.nextPageUrl(
      {
        'data': {
          'after': 'token123',
          'children': [],
        },
      },
      Uri.parse('https://www.reddit.com/r/pics.json?t=all'),
    );

    expect(next.toString(),
        'https://www.reddit.com/r/pics.json?t=all&after=token123');
  });
}
