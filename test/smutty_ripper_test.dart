import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/smutty_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('SmuttyRipper matches Java host, domain, broad support, and GIDs',
      () async {
    final url = Uri.parse('https://smutty.com/user/QUIGON/');
    final ripper = SmuttyRipper(url);

    expect(ripper.canRip(url), isTrue);
    expect(ripper.canRip(Uri.parse('https://www.smutty.com/anything')), isTrue);
    expect(
        ripper.canRip(Uri.parse('https://not-smutty.example/h/tag')), isFalse);
    expect(ripper.getHost(), 'smutty');
    expect(ripper.getDomain(), 'smutty.com');
    expect(await ripper.getGID(url), 'QUIGON');
    expect(await ripper.getGID(Uri.parse('https://smutty.com/h/red-head')),
        'red-head');
    expect(
      await ripper.getGID(Uri.parse('https://www.smutty.com/search/?q=%23tag')),
      'tag',
    );
    expect(
      await ripper.getGID(Uri.parse('https://m.smutty.com/search/?q=tag_name')),
      'tag_name',
    );

    await expectLater(
      ripper.getGID(Uri.parse('https://www.smutty.com/user/QUIGON/')),
      throwsA(isA<FormatException>()),
    );
  });

  test('SmuttyRipper rewrites thumbnails with Java string splitting', () {
    final page = html.parse('''
      <a class="l"><img src="//cdn.smutty.com/path/m/image.jpg"></a>
      <a class="l"><img src="//cdn.smutty.com/path/t/image.jpg"></a>
      <a class="x"><img src="//cdn.smutty.com/path/m/skipped.jpg"></a>
    ''');

    expect(SmuttyRipper.imageUrlsFromDocument(page), [
      'http://cdn.smutty.com/path/b/image.jpg',
      'http://cdn.smutty.com/path/t/image.jpg',
    ]);
  });

  test('SmuttyRipper prefixes absolute thumbnail URLs like Java', () {
    final page = html.parse('''
      <a class="l"><img src="https://cdn.smutty.com/path/m/image.jpg"></a>
    ''');

    expect(SmuttyRipper.imageUrlsFromDocument(page), [
      'http:https://cdn.smutty.com/path/b/image.jpg',
    ]);
  });

  test('SmuttyRipper follows Java next-page rules', () {
    final page = html.parse('<a class="next" href="/h/tag/2">next</a>');
    final emptyHref = html.parse('<a class="next" href="">next</a>');
    final noNext = html.parse('<a href="/h/tag/2">next</a>');

    expect(
      SmuttyRipper.nextPageUrlFromDocument(page),
      Uri.parse('https://smutty.com/h/tag/2'),
    );
    expect(
      () => SmuttyRipper.nextPageUrlFromDocument(emptyHref),
      throwsA(isA<HttpException>()),
    );
    expect(
      () => SmuttyRipper.nextPageUrlFromDocument(noNext),
      throwsA(isA<HttpException>()),
    );
  });

  test('SmuttyRipper uses Java-style configurable ordered filenames', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      SmuttyRipper.fileNameForUrl(
        Uri.parse('http://cdn.smutty.com/path/b/image.jpg?token=1'),
        7,
      ),
      '007_image.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      SmuttyRipper.fileNameForUrl(
        Uri.parse('http://cdn.smutty.com/path/b/image.jpg'),
        7,
      ),
      'image.jpg',
    );
  });
}
