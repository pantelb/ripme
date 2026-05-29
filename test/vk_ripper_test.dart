import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/vk_ripper.dart';

void main() {
  test('matches Java VK URL detection and GID parsing', () async {
    final cases = {
      'https://vk.com/photos45506334': 'photos45506334',
      'https://vk.com/album45506334_0': 'album45506334_0',
      'https://vk.com/album45506334_00?rev=1': 'album45506334_00?rev=1',
      'https://vk.com/videos45506334': 'videos45506334',
      'http://www.vk.com/videos-123_456?section=all':
          'videos-123_456?section=all',
    };

    for (final entry in cases.entries) {
      final uri = Uri.parse(entry.key);
      final ripper = VkRipper(uri);
      expect(ripper.canRip(uri), isTrue, reason: entry.key);
      expect(await ripper.getGID(uri), entry.value, reason: entry.key);
    }

    final individualVideo = Uri.parse('https://vk.com/video123_456');
    expect(VkRipper(individualVideo).canRip(individualVideo), isFalse);

    final profile = Uri.parse('https://vk.com/helga_model');
    expect(VkRipper(profile).canRip(profile), isTrue);
    await expectLater(
      VkRipper(profile).getGID(profile),
      throwsA(isA<FormatException>()),
    );
  });

  test('finds recursively nested photo object like Java', () {
    const jsonText =
        '{"payload":[0,["album-45984105_268691406",18,14,[{"id":"-45984105_457345201","base":"https://sun9-37.userapi.com/","tagged":[],"likes":0,"shares":0,"o_src":"https://sun9-65.userapi.com/c857520/v857520962/10e24c/DPxygc3XW5E.jpg","o_":["https://sun9-65.userapi.com/c857520/v857520962/10e24c/DPxygc3XW5E",130,98],"z_src":"https://sun9-41.userapi.com/c857520/v857520962/10e24a/EsDDQA36qKI.jpg","z_":["https://sun9-41.userapi.com/c857520/v857520962/10e24a/EsDDQA36qKI",1280,960],"w_src":"https://sun9-60.userapi.com/c857520/v857520962/10e24b/6ETsA15rAdU.jpg","w_":["https://sun9-60.userapi.com/c857520/v857520962/10e24b/6ETsA15rAdU",1405,1054]}]]],"langVersion":"4298"}';

    final found = VkRipper.findJSONObjectContainingPhotoId(
      '-45984105_457345201',
      jsonDecode(jsonText),
    );

    expect(found, isNotNull);
    expect(found!['id'], '-45984105_457345201');
    expect(found['w_src'], contains('6ETsA15rAdU.jpg'));
  });

  test('selects best source URL and fallback order like Java', () {
    final json = jsonDecode(
      '{"id":"-45984105_457345201","o_src":"https://example.com/o.jpg","o_":["https://example.com/o",130,98],"y_src":"https://example.com/y.jpg","y_":["https://example.com/y",807,605],"z_src":"https://example.com/z.jpg","z_":["https://example.com/z",1280,960]}',
    ) as Map<String, dynamic>;

    expect(VkRipper.getBestSourceUrl(json), 'https://example.com/z.jpg');

    expect(
      VkRipper.getBestSourceUrl({
        'x_src': 'https://example.com/x.jpg',
        'w_src': 'https://example.com/w.jpg',
      }),
      'https://example.com/x.jpg',
    );

    expect(
      VkRipper.getBestSourceUrl({
        'a_src': 'https://example.com/a.jpg',
        'a_': ['https://example.com/a', 10, 10],
        'b_src': 'https://example.com/b.jpg',
        'b_': ['https://example.com/b', 5, 20],
      }),
      'https://example.com/b.jpg',
    );
  });

  test('extracts unique photo ids after JavaScript unescape', () {
    final fragment = VkRipper.unescapeJavaScript(
      r'''\u003Cdiv\u003E
      \u003Ca onclick="return showPhoto(\'-1_2\', \'album\')" href="#"\u003E
      \u003C/a\u003E
      \u003Ca onclick="showPhoto(\'-1_2\')"\u003E\u003C/a\u003E
      \u003Ca onclick="showPhoto(\'-3_4\')"\u003E\u003C/a\u003E
      \u003C/div\u003E''',
    );
    final anchors = html.parseFragment(fragment).querySelectorAll('a');

    expect(VkRipper.photoIdsFromAnchors(anchors), ['-1_2', '-3_4']);
  });

  test('extracts VK video URL by Java quality preference', () {
    final pageUrl = Uri.parse('http://vk.com/video123_456');
    const source = r'''
      {"url240\":\"https:\/\/cdn.example.com\/small.mp4\"}
      {"url720\":\"https:\/\/cdn.example.com\/large.mp4?token=1\"}
    ''';

    expect(
      VkRipper.videoURLFromHtml(source, pageUrl).toString(),
      'https://cdn.example.com/large.mp4?token=1',
    );
    expect(
      () => VkRipper.videoURLFromHtml('<html></html>', pageUrl),
      throwsA(isA<HttpException>()),
    );
  });

  test('extracts video ids from VK all array and Java URL filenames', () {
    expect(
      VkRipper.videoIdsFromJsonPage({
        'all': [
          ['title', 123],
          ['title', '456'],
        ],
      }),
      [123, 456],
    );

    expect(
      VkRipper.javaUrlFileName('https://cdn.example.com/video.mp4?token=1'),
      'video.mp4',
    );
    expect(
      VkRipper.javaUrlFileName('https://cdn.example.com/video:bad.mp4'),
      'video',
    );
  });
}
