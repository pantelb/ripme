import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/twitch_video_ripper.dart';

void main() {
  test('matches Java Twitch clip URL detection and GID parsing', () async {
    final cases = {
      'https://clips.twitch.tv/FaithfulIncredulousPotTBCheesePull':
          'FaithfulIncredulousPotTBCheesePull',
      'https://clips.twitch.tv/': '',
      'https://clips.twitch.tv/ClipName?tt_medium=clips_api':
          'ClipName?tt_medium=clips_api',
    };

    for (final entry in cases.entries) {
      final uri = Uri.parse(entry.key);
      final ripper = TwitchVideoRipper(uri);
      expect(ripper.canRip(uri), isTrue, reason: entry.key);
      expect(await ripper.getGID(uri), entry.value, reason: entry.key);
    }

    final http = Uri.parse('http://clips.twitch.tv/ClipName');
    final www = Uri.parse('https://www.twitch.tv/videos/123');
    final wrongHost = Uri.parse('https://example.com/ClipName');
    expect(TwitchVideoRipper(http).canRip(http), isFalse);
    expect(TwitchVideoRipper(www).canRip(www), isFalse);
    expect(TwitchVideoRipper(wrongHost).canRip(wrongHost), isFalse);

    await expectLater(
      TwitchVideoRipper(http).getGID(http),
      throwsA(isA<FormatException>()),
    );
  });

  test('extracts first source URL from each script like Java', () {
    final page =
        Uri.parse('https://clips.twitch.tv/FaithfulIncredulousPotTBCheesePull');
    final document = TwitchVideoRipper.documentFromHtml(
      '''
      <html>
        <head><title>Clip Title</title></head>
        <body>
          <script>
            window.a = {"source":"https://cdn.example.com/first.mp4"};
            window.b = {"source":"https://cdn.example.com/ignored.mp4"};
          </script>
          <script>window.c = {"source":"https://cdn.example.com/second.mp4?sig=1"};</script>
          <script>window.d = {"other":"https://cdn.example.com/nope.mp4"};</script>
        </body>
      </html>
      ''',
      page,
    );

    expect(
      TwitchVideoRipper.videoUrlsFromDocument(document, page)
          .map((uri) => uri.toString()),
      [
        'https://cdn.example.com/first.mp4',
        'https://cdn.example.com/second.mp4?sig=1',
      ],
    );
  });

  test('throws Java no-script error but tolerates scripts without sources', () {
    final page =
        Uri.parse('https://clips.twitch.tv/FaithfulIncredulousPotTBCheesePull');
    final noScript = TwitchVideoRipper.documentFromHtml('<html></html>', page);
    final emptyScript = TwitchVideoRipper.documentFromHtml(
      '<html><script>window.foo = true;</script></html>',
      page,
    );

    expect(
      () => TwitchVideoRipper.videoUrlsFromDocument(noScript, page),
      throwsA(isA<HttpException>()),
    );
    expect(TwitchVideoRipper.videoUrlsFromDocument(emptyScript, page), isEmpty);
  });

  test('builds Java Twitch video filenames from title prefix and URL basename',
      () {
    expect(
      TwitchVideoRipper.javaDownloadFileName(
        Uri.parse('https://cdn.example.com/video.mp4?token=1'),
        'Clip Title',
      ),
      'twitch_Clip Titlevideo.mp4',
    );
    expect(
      TwitchVideoRipper.javaDownloadFileName(
        Uri.parse('https://cdn.example.com/video:bad.mp4'),
        'Clip Title',
      ),
      'twitch_Clip Titlevideo',
    );
  });

  test('builds video download requests with page title prefix', () {
    final page =
        Uri.parse('https://clips.twitch.tv/FaithfulIncredulousPotTBCheesePull');
    final document = TwitchVideoRipper.documentFromHtml(
      '''
      <html>
        <head><title>Friendly Twitch Clip</title></head>
        <body>
          <script>{"source":"https://cdn.example.com/video.mp4"}</script>
        </body>
      </html>
      ''',
      page,
    );

    final requests = TwitchVideoRipper.videoDownloadsFromDocument(
      document,
      page,
    );

    expect(requests, hasLength(1));
    expect(requests.single.url.toString(), 'https://cdn.example.com/video.mp4');
    expect(requests.single.fileName, 'twitch_Friendly Twitch Clipvideo.mp4');
  });
}
