import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/reddit_ripper.dart';

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
