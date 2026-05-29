import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/rule34_ripper.dart';

void main() {
  test('Rule34Ripper matches Java URL detection, host, domain, and GID',
      () async {
    final url =
        Uri.parse('https://rule34.xxx/index.php?page=post&s=list&tags=bimbo');
    final ripper = Rule34Ripper(url);

    expect(ripper.getHost(), 'rule34');
    expect(ripper.getDomain(), 'rule34.xxx');
    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(
        Uri.parse('http://rule34.xxx/index.php?page=post&s=list&tags=bimbo'),
      ),
      isTrue,
    );
    expect(
      ripper.canRip(
        Uri.parse(
            'https://www.rule34.xxx/index.php?page=post&s=list&tags=bimbo'),
      ),
      isFalse,
    );
    expect(
      ripper.canRip(
        Uri.parse('https://rule34.xxx/index.php?s=list&page=post&tags=bimbo'),
      ),
      isFalse,
    );

    expect(await ripper.getGID(url), 'bimbo');
  });

  test('Rule34Ripper constructs Java-compatible DAPI page URLs', () async {
    final ripper = Rule34Ripper(
      Uri.parse('https://rule34.xxx/index.php?page=post&s=list&tags=tag+one'),
    );

    expect(
      (await ripper.getAPIUrl()).toString(),
      'https://rule34.xxx/index.php?page=dapi&s=post&q=index&limit=100&tags=tag+one',
    );
  });

  test('Rule34Ripper paginates by appending Java pid values', () async {
    final ripper = Rule34Ripper(
      Uri.parse('https://rule34.xxx/index.php?page=post&s=list&tags=bimbo'),
    );
    final page =
        html.parse('<posts><post file_url="https://img/1.jpg" /></posts>');

    expect(
      (await ripper.getNextPage(page)).toString(),
      'https://rule34.xxx/index.php?page=dapi&s=post&q=index&limit=100&tags=bimbo&pid=1',
    );
    expect(
      (await ripper.getNextPage(page)).toString(),
      'https://rule34.xxx/index.php?page=dapi&s=post&q=index&limit=100&tags=bimbo&pid=2',
    );
  });

  test('Rule34Ripper throws Java no-more-pages error on API limit marker',
      () async {
    final ripper = Rule34Ripper(
      Uri.parse('https://rule34.xxx/index.php?page=post&s=list&tags=bimbo'),
    );
    final page = html.parse('Search error: API limited due to abuse');

    expect(ripper.getNextPage(page), throwsA(isA<IOException>()));
  });

  test('Rule34Ripper extracts post file_url values like Java', () {
    final page = html.parse('''
      <posts>
        <post file_url="https://img.example.com/one.jpg"></post>
        <post file_url="https://img.example.com/two.png"></post>
        <post id="3"></post>
      </posts>
    ''');

    expect(Rule34Ripper.fileUrlsFromDocument(page), [
      'https://img.example.com/one.jpg',
      'https://img.example.com/two.png',
      '',
    ]);
  });

  test('Rule34Ripper uses Java-style ordered filenames', () {
    expect(
      Rule34Ripper.fileNameForUrl(
        Uri.parse('https://img.example.com/path/image.jpg'),
        prefix: Rule34Ripper.prefixForIndex(7),
      ),
      '007_image.jpg',
    );
  });
}
