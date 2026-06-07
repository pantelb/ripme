import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/vk_ripper.dart';
import 'package:ripme/ripper/rippers/vk_video_ripper.dart';

void main() {
  test('matches Java individual VK video URL support and GID parsing',
      () async {
    final uri = Uri.parse('https://vk.com/video123_456');
    final ripper = VkVideoRipper(uri);

    expect(ripper.getHost(), 'vk');
    expect(ripper.canRip(uri), isTrue);
    expect(
      ripper.canRip(Uri.parse('http://www.vk.com/video123_456?list=abc')),
      isTrue,
    );
    expect(ripper.canRip(Uri.parse('https://vk.com/videos123')), isFalse);
    expect(ripper.canRip(Uri.parse('https://vk.com/album123_456')), isFalse);
    expect(await ripper.getGID(uri), '123');
  });

  test('reuses Java VK video quality selection', () {
    final pageUrl = Uri.parse('https://vk.com/video123_456');
    const source = r'''
      {\"url240\":\"https:\/\/cdn.example.com\/small.mp4\"}
      {\"url1080\":\"https:\/\/cdn.example.com\/large.mp4?token=1\"}
    ''';

    expect(
      VkRipper.videoURLFromHtml(source, pageUrl).toString(),
      'https://cdn.example.com/large.mp4?token=1',
    );
  });

  test('builds Java-style individual video filename prefix', () {
    expect(
      VkVideoRipper.javaDownloadFileName(
        Uri.parse('https://cdn.example.com/path/large.mp4?token=1'),
        '123',
      ),
      'vk_123large.mp4',
    );
  });
}
