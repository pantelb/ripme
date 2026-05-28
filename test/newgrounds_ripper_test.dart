import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/newgrounds_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('NewgroundsRipper matches Java host, domain, support, and GID',
      () async {
    final url = Uri.parse('https://zone-sama.newgrounds.com/art');
    final ripper = NewgroundsRipper(url);

    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(Uri.parse('http://zone-sama.newgrounds.com')),
      isTrue,
    );
    expect(ripper.getHost(), 'newgrounds');
    expect(ripper.getDomain(), 'newgrounds.com');
    expect(await ripper.getGID(url), 'zone-sama');
    expect(ripper.firstPageUrl().toString(),
        'https://zone-sama.newgrounds.com/art');
    await expectLater(
      ripper.getGID(Uri.parse('https://www.newgrounds.com/art')),
      completion('www'),
    );
    expect(
      () => NewgroundsRipper(Uri.parse('https://newgrounds.com/art')),
      throwsA(isA<FormatException>()),
    );
  });

  test('NewgroundsRipper parses thumbnails and probes detail pages like Java',
      () async {
    final page = html.parse(r'''
      <a href="https://www.newgrounds.com/art/view/zone-sama/my-title" class="item">
        <img src="//art.ngfiles.com/thumbnails/123000/678_full.jpg">
      </a>
      <a href="https://www.newgrounds.com/art/view/zone-sama\/second-title" class="item">
        <img src="//art.ngfiles.com/thumbnails/456000/999.jpg">
      </a>
      <a href="https://www.newgrounds.com/art/view/other-user/ignored" class="item">
        <img src="//art.ngfiles.com/thumbnails/000/111.jpg">
      </a>
    ''');
    final requestedDetailUrls = <Uri>[];
    var matches = 0;

    final urls = await NewgroundsRipper.imageUrlsFromDocument(
      page,
      username: 'zone-sama',
      onMatch: () => matches++,
      detailPageFetcher: (detailUrl) async {
        requestedDetailUrls.add(detailUrl);
        return html.parse(
          'asset: 678_zone-sama_my-title.gif',
        );
      },
    );

    expect(matches, 2);
    expect(requestedDetailUrls.map((uri) => uri.toString()), [
      'https://www.newgrounds.com/art/view/zone-sama/my-title',
      'https://www.newgrounds.com/art/view/zone-sama/second-title',
    ]);
    expect(urls, [
      'https://art.ngfiles.com/images/123000/678_zone-sama_my-title.gif',
    ]);
  });

  test('NewgroundsRipper skips detail pages that fail while checking extension',
      () async {
    final page = html.parse(r'''
      <a href="https://www.newgrounds.com/art/view/zone-sama/broken" class="item">
        <img src="//art.ngfiles.com/thumbnails/123000/678.jpg">
      </a>
      <a href="https://www.newgrounds.com/art/view/zone-sama\/working" class="item">
        <img src="//art.ngfiles.com/thumbnails/456000/999.jpg">
      </a>
    ''');

    final urls = await NewgroundsRipper.imageUrlsFromDocument(
      page,
      username: 'zone-sama',
      detailPageFetcher: (detailUrl) async {
        if (detailUrl.path.endsWith('/broken')) {
          throw const HttpException('boom');
        }
        return html.parse('asset: 999_zone-sama_working.png');
      },
    );

    expect(urls, [
      'https://art.ngfiles.com/images/456000/999_zone-sama_working.png',
    ]);
  });

  test('NewgroundsRipper mirrors Java pagination state and AJAX headers',
      () async {
    final ripper = NewgroundsRipper(
      Uri.parse('https://zone-sama.newgrounds.com/art'),
    );

    expect(ripper.nextPageUrl().toString(),
        'https://zone-sama.newgrounds.com/art/page/1');
    expect(
        NewgroundsRipper.ajaxHeaders, {'X-Requested-With': 'XMLHttpRequest'});
    expect(await ripper.getNextPage(html.parse('')), isNull);

    ripper.count = 60;
    expect(
      (await ripper.getNextPage(html.parse('')))!.toString(),
      'https://zone-sama.newgrounds.com/art/page/1',
    );
  });

  test('NewgroundsRipper uses Java-style ordered filenames', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(NewgroundsRipper.prefixForIndex(12), '012_');
    expect(
      NewgroundsRipper.fileNameForUrl(
        Uri.parse(
          'https://art.ngfiles.com/images/123000/678_zone-sama_my-title.gif',
        ),
        prefix: NewgroundsRipper.prefixForIndex(12),
      ),
      '012_678_zone-sama_my-title.gif',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(NewgroundsRipper.prefixForIndex(12), '');
  });
}
