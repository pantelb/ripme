import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/thechive_ripper.dart';

void main() {
  test('ThechiveRipper matches Java host, domain, support, and GIDs', () async {
    final postUrl = Uri.parse(
      'https://thechive.com/2019/03/16/beautiful-badasses/',
    );
    final userUrl = Uri.parse('https://i.thechive.com/witcheva');
    final postRipper = ThechiveRipper(postUrl);
    final userRipper = ThechiveRipper(userUrl);

    expect(postRipper.getHost(), 'thechive');
    expect(userRipper.getHost(), 'i.thechive');
    expect(postRipper.getDomain(), 'thechive.com');
    expect(postRipper.canRip(postUrl), isTrue);
    expect(userRipper.canRip(userUrl), isTrue);
    expect(postRipper.canRip(Uri.parse('https://thechive.com/not/a/post')),
        isFalse);

    expect(await postRipper.getGID(postUrl), 'beautiful-badasses');
    expect(await userRipper.getGID(userUrl), 'witcheva');
    expect(
      await userRipper.getGID(Uri.parse('https://i.thechive.com/user_123/x')),
      'user_123',
    );
    await expectLater(
      postRipper.getGID(Uri.parse('https://example.com/2019/03/16/post/')),
      throwsA(isA<FormatException>()),
    );
  });

  test('ThechiveRipper extracts CHIVE_GALLERY_ITEMS images like Java', () {
    final page = html.parse(r'''
      <script>
        var ignored = "<img src=\"https://ignored.example/a.jpg?w=1\">";
      </script>
      <script>
        var CHIVE_GALLERY_ITEMS = [
          "<img src=\"https://cdn.example.com/photo.jpg?quality=85&amp;w=600\">",
          "<img src=\"https://cdn.example.com/fallback.jpg?x=1\" data-gifsrc=\"https://cdn.example.com/anim.gif?w=500\">"
        ];
      </script>
    ''');

    expect(ThechiveRipper.urlsFromThechiveDocument(page), [
      'https://cdn.example.com/photo.jpg',
      'https://cdn.example.com/anim.gif',
    ]);
  });

  test('ThechiveRipper parses i.thechive JSON uploads like Java', () {
    final page = ThechiveRipper.urlsFromIDotJson(
      '''
      {
        "uploads": [
          {
            "mediaType": "gif",
            "mediaUrlOverlay": "//cdn.example.com/one.gif",
            "mediaGifFrameUrl": "//cdn.example.com/one.jpg",
            "activityId": "a1"
          },
          {
            "mediaType": "image",
            "mediaUrlOverlay": "//cdn.example.com/two.gif",
            "mediaGifFrameUrl": "//cdn.example.com/two.jpg",
            "activityId": "a2"
          }
        ]
      }
      ''',
      cookies: {'csrf': 'token'},
    );

    expect(page.urls, [
      'https://cdn.example.com/one.gif',
      'https://cdn.example.com/two.jpg',
    ]);
    expect(page.nextSeed, 'a2');
    expect(page.cookies, {'csrf': 'token'});

    final empty = ThechiveRipper.urlsFromIDotJson('{"uploads": []}');
    expect(empty.urls, isEmpty);
    expect(empty.nextSeed, isNull);
  });

  test('ThechiveRipper parses cookies and ordered filenames', () {
    expect(
      ThechiveRipper.cookiesFromSetCookieHeader(
        'a=1; Path=/, b=two; Domain=i.thechive.com',
      ),
      {'a': '1', 'b': 'two'},
    );
    expect(ThechiveRipper.stripAfterQuestionMark('https://x/y.jpg?w=1'),
        'https://x/y.jpg');
    expect(
      ThechiveRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/a:b.jpg?w=1'),
        ThechiveRipper.prefix(4),
      ),
      '004_a_b.jpg',
    );
  });
}
