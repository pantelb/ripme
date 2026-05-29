import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/sinfest_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('SinfestRipper matches Java URL detection, host, domain, and GID',
      () async {
    final url = Uri.parse('http://sinfest.net/view.php?date=2000-01-17');
    final ripper = SinfestRipper(url);

    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(Uri.parse('https://sinfest.net/view.php?date=')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://www.sinfest.net/view.php?date=2000')),
      isFalse,
    );
    expect(ripper.getHost(), 'sinfest');
    expect(ripper.getDomain(), 'sinfest.net');
    expect(await ripper.getGID(url), '2000-01-17');
    expect(await ripper.getGID(Uri.parse('https://sinfest.net/view.php?date=')),
        '');

    await expectLater(
      ripper.getGID(Uri.parse('https://sinfest.net/archive.php')),
      throwsA(isA<FormatException>()),
    );
  });

  test('SinfestRipper extracts the last comic image like Java', () {
    final page = html.parse('''
      <html>
        <body>
          <table>
            <tbody>
              <tr><td><img src="first.gif"></td></tr>
              <tr><td><img src="btphp/comics/2000-01-17.gif"></td></tr>
            </tbody>
          </table>
        </body>
      </html>
    ''');

    expect(SinfestRipper.imageUrlsFromDocument(page), [
      'http://sinfest.net/btphp/comics/2000-01-17.gif',
    ]);
  });

  test('SinfestRipper follows Java td.style5 next-page rules', () {
    final page = html.parse('''
      <table>
        <tr>
          <td class="style5"><a href="view.php?date=2000-01-16"><img></a></td>
          <td class="style5"><a href="view.php?date=2000-01-18"><img></a></td>
        </tr>
      </table>
    ''');
    final emptyHref = html.parse('''
      <table><tr><td class="style5"><a href=""><img></a></td></tr></table>
    ''');
    final noMorePages = html.parse('''
      <table>
        <tr><td class="style5"><a href="view.php?date="><img></a></td></tr>
      </table>
    ''');

    expect(
      SinfestRipper.nextPageUrlFromDocument(page),
      Uri.parse('http://sinfest.net/view.php?date=2000-01-18'),
    );
    expect(SinfestRipper.nextPageUrlFromDocument(emptyHref), isNull);
    expect(
      () => SinfestRipper.nextPageUrlFromDocument(noMorePages),
      throwsA(isA<HttpException>()),
    );
  });

  test('SinfestRipper uses Java-style configurable ordered filenames',
      () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      SinfestRipper.fileNameForUrl(
        Uri.parse('http://sinfest.net/btphp/comics/2000-01-17.gif'),
        7,
      ),
      '007_2000-01-17.gif',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      SinfestRipper.fileNameForUrl(
        Uri.parse('http://sinfest.net/btphp/comics/2000-01-17.gif'),
        7,
      ),
      '2000-01-17.gif',
    );
  });
}
