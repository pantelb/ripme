import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/reddit_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
