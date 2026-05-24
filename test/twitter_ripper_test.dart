import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/twitter_ripper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ripme/utils/utils.dart';

void main() {
  test('matches Java account and search URL classification', () async {
    final ripper = TwitterRipper(Uri.parse('https://twitter.com/example'));

    expect(await ripper.getGID(Uri.parse('https://twitter.com/example')),
        'account_example');
    expect(await ripper.getGID(Uri.parse('https://x.com/example/status/123')),
        'account_example');

    final search = TwitterRipper.classifyUrl(
        Uri.parse('https://twitter.com/search?q=from%3Aartist%20filter'))!;
    expect(search.type, TwitterAlbumType.search);
    expect(search.searchText, 'artist%20filter');
    expect(search.gid, 'search_artist_filter');
  });

  test('builds Java-compatible v1.1 API URLs', () async {
    SharedPreferences.setMockInitialValues({
      'twitter.exclude_replies': false,
      'twitter.max_items_request': 50,
    });
    await Utils.init();

    final account = TwitterRipper.classifyUrl(Uri.parse('https://x.com/user'))!;
    expect(
      TwitterRipper.getApiUrl(account, 123).toString(),
      'https://api.twitter.com/1.1/statuses/user_timeline.json?screen_name=user&include_entities=true&exclude_replies=false&trim_user=true&count=50&tweet_mode=extended&max_id=123',
    );

    final search =
        TwitterRipper.classifyUrl(Uri.parse('https://x.com/search?q=abc'))!;
    expect(
      TwitterRipper.getApiUrl(search, 0).toString(),
      'https://api.twitter.com/1.1/search/tweets.json?q=abc&include_entities=true&result_type=recent&count=100&tweet_mode=extended',
    );
  });

  test('extracts photo originals and highest video variants like Java', () {
    final page = TwitterRipper.mediaFromTweets({
      'tweets': [
        {
          'id': 20,
          'extended_entities': {
            'media': [
              {
                'type': 'photo',
                'media_url': 'https://pbs.twimg.com/media/photo.jpg',
              },
              {
                'type': 'video',
                'video_info': {
                  'variants': [
                    {
                      'content_type': 'application/x-mpegURL',
                      'url': 'hls.m3u8'
                    },
                    {'bitrate': 832000, 'url': 'https://video/low.mp4'},
                    {'bitrate': 2176000, 'url': 'https://video/high.mp4'},
                  ],
                },
              },
            ],
          },
        },
      ],
    }, ripRetweets: true);

    expect(page.lastMaxId, 20);
    expect(page.urls.map((url) => url.toString()), [
      'https://pbs.twimg.com/media/photo.jpg:orig',
      'https://video/high.mp4',
    ]);
  });

  test('honors retweet filtering and animated gif variant behavior', () {
    final page = TwitterRipper.mediaFromTweets({
      'tweets': [
        {
          'id': 10,
          'retweeted_status': {},
          'extended_entities': {
            'media': [
              {
                'type': 'photo',
                'media_url': 'https://pbs.twimg.com/media/retweet.jpg',
              },
            ],
          },
        },
        {
          'id': 9,
          'extended_entities': {
            'media': [
              {
                'type': 'animated_gif',
                'video_info': {
                  'variants': [
                    {'bitrate': 1, 'url': 'https://gif/first.mp4'},
                    {'bitrate': 2, 'url': 'https://gif/last.mp4'},
                  ],
                },
              },
            ],
          },
        },
      ],
    }, ripRetweets: false);

    expect(page.lastMaxId, 9);
    expect(page.urls.map((url) => url.toString()), ['https://gif/last.mp4']);
  });
}
