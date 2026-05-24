import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/tumblr_ripper.dart';

void main() {
  test('matches Java GID behavior for subdomain, tag, post, and likes',
      () async {
    final ripper = TumblrRipper(Uri.parse('https://example.tumblr.com'));

    expect(await ripper.getGID(Uri.parse('https://example.tumblr.com')),
        'example.tumblr.com');
    expect(
      await ripper
          .getGID(Uri.parse('https://example.tumblr.com/tagged/my-tag_name')),
      'example.tumblr.com_tag_my+tag',
    );
    expect(await ripper.getGID(Uri.parse('https://example.tumblr.com/post/42')),
        'example.tumblr.com_post_42');
    expect(await ripper.getGID(Uri.parse('https://example.tumblr.com/likes')),
        'example_liked');
    expect(
        await ripper.getGID(Uri.parse('https://www.tumblr.com/liked/by/foo')),
        'foo_liked');
  });

  test('builds Java-compatible Tumblr API URLs', () {
    final tag = TumblrRipper.classifyUrl(
        Uri.parse('https://example.tumblr.com/tagged/my-tag'))!;
    expect(
      TumblrRipper.getTumblrApiUrl(tag, 'photo', 20, 'key'),
      'http://api.tumblr.com/v2/blog/example.tumblr.com/posts/photo?api_key=key&offset=20&tag=my+tag',
    );

    final post = TumblrRipper.classifyUrl(
        Uri.parse('https://example.tumblr.com/post/42'))!;
    expect(
      TumblrRipper.getTumblrApiUrl(post, 'post', 0, 'key'),
      'http://api.tumblr.com/v2/blog/example.tumblr.com/posts?id=42&api_key=key',
    );

    final likes = TumblrRipper.classifyUrl(
        Uri.parse('https://example.tumblr.com/likes'))!;
    expect(
      TumblrRipper.getTumblrApiUrl(likes, 'photo', 40, 'key'),
      'http://api.tumblr.com/v2/blog/example/likes?api_key=key&offset=40',
    );
  });

  test('extracts photos, video, audio, album art, and body images like Java',
      () {
    final media = TumblrRipper.mediaFromJson({
      'response': {
        'posts': [
          {
            'date': '2026-01-01',
            'photos': [
              {
                'original_size': {
                  'url': 'http://media.tumblr.com/foo_500.jpg',
                },
              },
            ],
          },
          {
            'date': '2026-01-02',
            'video_url': 'http://media.tumblr.com/video.mp4',
          },
          {
            'date': '2026-01-03',
            'audio_url': 'http://media.tumblr.com/audio.mp3',
            'album_art': 'http://media.tumblr.com/art_400.png',
          },
          {
            'date': '2026-01-04',
            'body': '<p><img src="http://media.tumblr.com/body_250.gif"></p>',
          },
        ],
      },
    }, TumblrAlbumType.subdomain);

    expect(media.map((item) => item.url.toString()), [
      'https://media.tumblr.com/foo_1280.jpg',
      'https://media.tumblr.com/video.mp4',
      'https://media.tumblr.com/audio.mp3',
      'https://media.tumblr.com/art_400.png',
      'https://media.tumblr.com/body_1280.gif',
    ]);
  });

  test('post mode stops after first post and likes use liked_posts', () {
    final postMedia = TumblrRipper.mediaFromJson({
      'response': {
        'posts': [
          {
            'date': '2026-01-01',
            'video_url': 'http://media.tumblr.com/one.mp4',
          },
          {
            'date': '2026-01-02',
            'video_url': 'http://media.tumblr.com/two.mp4',
          },
        ],
      },
    }, TumblrAlbumType.post);

    expect(postMedia.map((item) => item.url.toString()),
        ['https://media.tumblr.com/one.mp4']);

    final likedMedia = TumblrRipper.mediaFromJson({
      'response': {
        'liked_posts': [
          {
            'date': '2026-01-03',
            'video_url': 'http://media.tumblr.com/liked.mp4',
          },
        ],
      },
    }, TumblrAlbumType.liked);

    expect(likedMedia.map((item) => item.url.toString()),
        ['https://media.tumblr.com/liked.mp4']);
  });
}
