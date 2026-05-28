import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/nfsfw_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('NfsfwRipper matches Java URL sanitization, support, host, and GIDs',
      () async {
    final url = Uri.parse('http://nfsfw.com/gallery/v/Kitten/?g2_page=2');
    final nested = Uri.parse('http://nfsfw.com/gallery/v/Kitten/gif_001/');
    final ripper = NfsfwRipper(url);

    expect(NfsfwRipper.sanitizeUri(url).toString(),
        'http://nfsfw.com/gallery/v/Kitten/');
    expect(ripper.canRip(url), isTrue);
    expect(ripper.canRip(Uri.parse('http://m.nfsfw.com/gallery/v/Kitten/')),
        isTrue);
    expect(ripper.getHost(), 'nfsfw');
    expect(ripper.getDomain(), 'nfsfw.com');
    expect(await ripper.getGID(url), 'Kitten');
    expect(await ripper.getGID(Uri.parse('http://nfsfw.com/gallery/v/Kitten')),
        'Kitten');
    expect(await ripper.getGID(nested), 'Kitten__gif_001');
    await expectLater(
      ripper.getGID(Uri.parse('http://nfsfw.com/gallery/Kitten/')),
      throwsA(isA<FormatException>()),
    );
  });

  test('NfsfwRipper extracts image pages and subalbums like Java selectors',
      () {
    final page = html.parse('''
      <table>
        <td class="giItemCell"><div><a href="/gallery/v/Kitten/image1.html"></a></div></td>
        <td class="giItemCell"><div><a href="/gallery/v/Kitten/image2.html"></a></div></td>
        <td class="IMG"><a href="/gallery/v/Kitten/gif_001/"></a></td>
      </table>
    ''');

    expect(NfsfwRipper.imagePageUrlsFromDocument(page), [
      'http://nfsfw.com/gallery/v/Kitten/image1.html',
      'http://nfsfw.com/gallery/v/Kitten/image2.html',
    ]);
    expect(NfsfwRipper.subalbumUrlsFromDocument(page), [
      'http://nfsfw.com/gallery/v/Kitten/gif_001/',
    ]);
    expect(NfsfwRipper.pageContainsOnlySubalbums(page), isFalse);
  });

  test('NfsfwRipper detects queue-only subalbum pages like Java', () {
    final page = html.parse('''
      <table>
        <td class="IMG"><a href="/gallery/v/Kitten/gif_001/"></a></td>
        <td class="IMG"><a href="/gallery/v/Kitten/photos/"></a></td>
      </table>
    ''');

    expect(NfsfwRipper.pageContainsOnlySubalbums(page), isTrue);
  });

  test('NfsfwRipper follows next links before queued subalbums', () async {
    final ripper = NfsfwRipper(Uri.parse('http://nfsfw.com/gallery/v/Kitten/'));
    final first = html.parse('''
      <table>
      <a class="next" href="/gallery/v/Kitten/?g2_page=2">next</a>
      </table>
    ''');
    final subalbumOnly = html.parse('''
      <table>
      <td class="IMG"><a href="/gallery/v/Kitten/gif_001/"></a></td>
      </table>
    ''');

    await ripper.getURLsFromPage(first);
    expect((await ripper.getNextPage(first))!.toString(),
        'http://nfsfw.com/gallery/v/Kitten/?g2_page=2');

    await ripper.getURLsFromPage(subalbumOnly);
    expect((await ripper.getNextPage(subalbumOnly))!.toString(),
        'http://nfsfw.com/gallery/v/Kitten/gif_001/');
    expect(await ripper.getNextPage(html.parse('')), isNull);
  });

  test('NfsfwRipper resolves .gbBlock image pages and download metadata',
      () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();

    final ripper = NfsfwRipper(Uri.parse('http://nfsfw.com/gallery/v/Kitten/'));
    final tempDir = await Directory.systemTemp.createTemp('nfsfw_test_');
    addTearDown(() => tempDir.delete(recursive: true));
    ripper.workingDir = tempDir;

    final download = await ripper.downloadFromImagePage(
      Uri.parse('http://nfsfw.com/gallery/v/Kitten/image1.html'),
      index: 3,
      subdirectory: 'gif_001/',
      imagePageFetcher: (_) async => html.parse('''
        <div class="gbBlock"><img src="/gallery/d/1234-1/image.jpg"></div>
      '''),
    );

    expect(download, isNotNull);
    expect(download!.url.toString(),
        'http://nfsfw.com/gallery/d/1234-1/image.jpg');
    expect(download.headers,
        {'Referer': 'http://nfsfw.com/gallery/v/Kitten/image1.html'});
    expect(
      download.saveAs.path,
      endsWith(
        '${Platform.pathSeparator}gif_001${Platform.pathSeparator}003_image.jpg',
      ),
    );
  });

  test('NfsfwRipper returns null for image pages without .gbBlock images',
      () async {
    final ripper = NfsfwRipper(Uri.parse('http://nfsfw.com/gallery/v/Kitten/'));
    final tempDir = await Directory.systemTemp.createTemp('nfsfw_test_');
    addTearDown(() => tempDir.delete(recursive: true));
    ripper.workingDir = tempDir;

    final download = await ripper.downloadFromImagePage(
      Uri.parse('http://nfsfw.com/gallery/v/Kitten/image1.html'),
      index: 1,
      subdirectory: '',
      imagePageFetcher: (_) async => html.parse('<div></div>'),
    );

    expect(download, isNull);
  });

  test('NfsfwRipper omits ordered filename prefixes when disabled', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();

    expect(NfsfwRipper.prefixForIndex(3), '');
    expect(
      NfsfwRipper.fileNameForUrl(
        Uri.parse('http://nfsfw.com/gallery/d/1234-1/image.jpg'),
        prefix: NfsfwRipper.prefixForIndex(3),
      ),
      'image.jpg',
    );
  });
}
