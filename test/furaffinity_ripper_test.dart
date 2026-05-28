import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/furaffinity_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java URL detection, host, domain, and GIDs', () async {
    final gallery = FuraffinityRipper(
      Uri.parse('https://www.furaffinity.net/gallery/mustardgas/'),
    );
    final scraps = FuraffinityRipper(
      Uri.parse('http://www.furaffinity.net/scraps/sssonic2/'),
    );

    expect(gallery.canRip(gallery.url), isTrue);
    expect(scraps.canRip(scraps.url), isTrue);
    expect(
      gallery.canRip(Uri.parse('https://www.furaffinity.net/view/12345/')),
      isFalse,
    );
    expect(gallery.getHost(), 'furaffinity');
    expect(gallery.getDomain(), 'furaffinity.net');
    expect(await gallery.getGID(gallery.url), 'mustardgas');
    expect(await scraps.getGID(scraps.url), 'sssonic2');
  });

  test('extracts gallery post links and download links like Java', () {
    final galleryPage = parse('''
      <figure class="t-image"><b><u><a href="/view/111/">one</a></u></b></figure>
      <figure class="t-image"><b><u><a href="/view/222/">two</a></u></b></figure>
      <a href="/view/ignored/">ignored</a>
    ''');
    final postPage = parse('''
      <a href="//d.furaffinity.net/art/user/1-preview.jpg">Preview</a>
      <a href="//d.furaffinity.net/art/user/1-full.png">Download</a>
    ''');

    expect(FuraffinityRipper.postUrlsFromPage(galleryPage), [
      'https://www.furaffinity.net/view/111/',
      'https://www.furaffinity.net/view/222/',
    ]);
    expect(
      FuraffinityRipper.imageFromPostPage(postPage),
      'https://d.furaffinity.net/art/user/1-full.png',
    );
    expect(FuraffinityRipper.imageFromPostPage(parse('<a>Nope</a>')), isNull);
  });

  test('uses the first right-link href for next page', () async {
    final ripper = FuraffinityRipper(
      Uri.parse('https://www.furaffinity.net/gallery/mustardgas/'),
    );
    final page = parse('''
      <a class="left" href="/gallery/mustardgas/1/">prev</a>
      <a class="right" href="/gallery/mustardgas/2/">next</a>
    ''');

    expect(
      (await ripper.getNextPage(page)).toString(),
      'https://www.furaffinity.net/gallery/mustardgas/2/',
    );
    expect(await ripper.getNextPage(parse('<main></main>')), isNull);
  });

  test('parses configured cookies and honors disabled login', () async {
    SharedPreferences.setMockInitialValues({
      'furaffinity.login': true,
      'furaffinity.cookies': 'a=one;b=two=extra; empty ; c = three ',
    });
    await Utils.init();

    final ripper = FuraffinityRipper(
      Uri.parse('https://www.furaffinity.net/gallery/mustardgas/'),
    )..setCookies();

    expect(ripper.cookiesForTesting, {
      'a': 'one',
      'b': 'two=extra',
      'c': 'three',
    });

    SharedPreferences.setMockInitialValues({'furaffinity.login': false});
    await Utils.init();
    ripper.setCookies();

    expect(ripper.cookiesForTesting, isEmpty);
  });

  test('uses Java-style ordered filename prefixes', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      FuraffinityRipper.fileNameForUrl(
        Uri.parse('https://d.furaffinity.net/art/user/bad:name.png?download'),
        7,
      ),
      '007_bad',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      FuraffinityRipper.fileNameForUrl(
        Uri.parse('https://d.furaffinity.net/art/user/file.jpg'),
        7,
      ),
      'file.jpg',
    );
  });
}
