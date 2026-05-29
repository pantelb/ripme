import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/tsumino_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('TsuminoRipper matches Java host, domain, support, and GIDs', () async {
    final url = Uri.parse(
      'http://www.tsumino.com/Book/Info/43528/sore-wa-kurokute',
    );
    final ripper = TsuminoRipper(url);

    expect(ripper.getHost(), 'tsumino');
    expect(ripper.getDomain(), 'tsumino.com');
    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(Uri.parse('https://www.tsumino.com/Book/Info/43528/')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://tsumino.com/Book/Info/43528/title')),
      isFalse,
    );

    expect(await ripper.getGID(url), '43528_sore-wa-kurokute');
    expect(
      await ripper.getGID(Uri.parse('https://www.tsumino.com/Book/Info/43528')),
      '43528',
    );
    await expectLater(
      ripper.getGID(Uri.parse('https://www.tsumino.com/Book/Read/43528')),
      throwsA(isA<FormatException>()),
    );
    expect(TsuminoRipper.albumIdFromUrl(url), '43528');
  });

  test('TsuminoRipper extracts tags and checks blacklists like Java', () {
    final page = html.parse('''
      <div id="Tag">
        <a>Smell</a>
        <a>Face Sitting</a>
      </div>
    ''');
    final tags = TsuminoRipper.tagsFromDocument(page);

    expect(tags, ['smell', 'face sitting']);
    expect(TsuminoRipper.checkTags(['test', 'one', 'Smell'], tags), 'smell');
    expect(
      TsuminoRipper.checkTags(['test', 'one', 'Face sitting'], tags),
      'face sitting',
    );
    expect(TsuminoRipper.checkTags(['nothing', 'one', 'null'], tags), isNull);
  });

  test('TsuminoRipper parses reader JSON from Java HTML wrapper', () {
    expect(
      TsuminoRipper.readerPageUrlsFromLoadResponse('''
        <html><head></head><body>{"reader_page_urls":["one.jpg","two space.png"]}</body></html>
      '''),
      ['one.jpg', 'two space.png'],
    );
  });

  test('TsuminoRipper builds encoded image URLs like Java', () {
    expect(
      TsuminoRipper.imageUrlsFromReaderPageUrls([
        'one.jpg',
        'two space.png',
        'folder/three+four.png',
      ]),
      [
        'http://www.tsumino.com/Image/Object?name=one.jpg',
        'http://www.tsumino.com/Image/Object?name=two+space.png',
        'http://www.tsumino.com/Image/Object?name=folder%2Fthree%2Bfour.png',
      ],
    );
  });

  test('TsuminoRipper uses Java-style configurable ordered filenames',
      () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      TsuminoRipper.fileNameForUrl(
        Uri.parse('http://www.tsumino.com/Image/Object?name=one.jpg'),
        7,
      ),
      '007_Object',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      TsuminoRipper.fileNameForUrl(
        Uri.parse('http://www.tsumino.com/Image/Object?name=one.jpg'),
        7,
      ),
      'Object',
    );
  });
}
