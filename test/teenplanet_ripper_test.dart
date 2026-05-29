import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/teenplanet_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('TeenplanetRipper matches Java host, domain, support, and GID',
      () async {
    final url = Uri.parse(
      'http://teenplanet.org/galleries/the-perfect-side-of-me-6588.html',
    );
    final ripper = TeenplanetRipper(url);

    expect(ripper.getHost(), 'teenplanet');
    expect(ripper.getDomain(), 'teenplanet.org');
    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(Uri.parse('http://www.teenplanet.org/galleries/a.html')),
      isTrue,
    );
    expect(ripper.canRip(Uri.parse('https://example.com/galleries/a.html')),
        isFalse);

    expect(await ripper.getGID(url), 'the-perfect-side-of-me-6588');
    await expectLater(
      ripper.getGID(Uri.parse('http://teenplanet.org/gallery/bad.html')),
      throwsA(isA<FormatException>()),
    );
  });

  test('TeenplanetRipper extracts thumbnail URLs like Java', () {
    final page = html.parse('''
      <div id="galleryImages">
        <a><img src="http://img.teenplanet.org/thumbs/one.jpg"></a>
        <a><img src="http://img.teenplanet.org/path/thumbs/two.png"></a>
        <a><img src=""></a>
        <a><img></a>
      </div>
      <img src="http://img.teenplanet.org/thumbs/outside.jpg">
    ''');

    expect(TeenplanetRipper.imageUrlsFromDocument(page), [
      'http://img.teenplanet.org/one.jpg',
      'http://img.teenplanet.org/path/two.png',
      '',
    ]);
  });

  test('TeenplanetRipper uses Java-style configurable ordered filenames',
      () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      TeenplanetRipper.fileNameForUrl(
        Uri.parse('http://img.teenplanet.org/one.jpg'),
        7,
      ),
      '007_one.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      TeenplanetRipper.fileNameForUrl(
        Uri.parse('http://img.teenplanet.org/one.jpg'),
        7,
      ),
      'one.jpg',
    );
  });
}
