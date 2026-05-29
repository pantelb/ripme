import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/oglaf_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('OglafRipper matches Java host, domain, support, GID, and title',
      () async {
    final url = Uri.parse('http://oglaf.com/plumes/');
    final ripper = OglafRipper(url);

    expect(ripper.canRip(url), isTrue);
    expect(ripper.canRip(Uri.parse('https://www.oglaf.com/plumes/')), isTrue);
    expect(ripper.getHost(), 'oglaf');
    expect(ripper.getDomain(), 'oglaf.com');
    expect(await ripper.getGID(url), 'plumes');
    expect(await ripper.getAlbumTitle(url), 'oglaf.com');

    await expectLater(
      ripper.getGID(Uri.parse('https://oglaf.com/plumes/')),
      throwsA(isA<FormatException>()),
    );
  });

  test('OglafRipper extracts strip image src attributes like Java', () {
    final page = html.parse('''
      <b><img id="strip" src="https://media.oglaf.com/comic/one.jpg"></b>
      <b><span><img id="strip" src="https://media.oglaf.com/comic/nested.jpg"></span></b>
      <div><img id="strip" src="https://media.oglaf.com/comic/outside.jpg"></div>
      <b><img id="other" src="https://media.oglaf.com/comic/other.jpg"></b>
    ''');

    expect(OglafRipper.stripImageUrlsFromPage(page), [
      'https://media.oglaf.com/comic/one.jpg',
    ]);
  });

  test('OglafRipper builds next page URLs from Java nav selector', () {
    final page = html.parse('''
      <div id="nav"><a href="/plumes/2"><div id="nx"></div></a></div>
    ''');
    final emptyHref = html.parse('''
      <div id="nav"><a href=""><div id="nx"></div></a></div>
    ''');
    final noNext = html.parse('<div id="nav"></div>');

    expect(
      OglafRipper.nextPageUrlFromPage(page),
      Uri.parse('http://oglaf.com/plumes/2'),
    );
    expect(OglafRipper.nextPageUrlFromPage(emptyHref), isNull);
    expect(OglafRipper.nextPageUrlFromPage(noNext), isNull);
  });

  test('OglafRipper uses Java-style configurable ordered filenames', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      OglafRipper.downloadFileName(
        Uri.parse('https://media.oglaf.com/comic/plumes.jpg'),
        7,
      ),
      '007_plumes.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      OglafRipper.downloadFileName(
        Uri.parse('https://media.oglaf.com/comic/plumes.jpg'),
        7,
      ),
      'plumes.jpg',
    );
  });
}
