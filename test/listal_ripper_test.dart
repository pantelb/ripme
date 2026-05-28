import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/listal_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, broad support, and strict list GID',
      () async {
    final url = Uri.parse('https://www.listal.com/list/evolution-emma-stone');
    final ripper = ListalRipper(url);

    expect(ripper.getHost(), 'listal');
    expect(ripper.getDomain(), 'listal.com');
    expect(ripper.canRip(url), isTrue);
    expect(ripper.canRip(Uri.parse('https://images.listal.com/x')), isTrue);
    expect(ripper.canRip(Uri.parse('https://example.com/list/x')), isFalse);
    expect(await ripper.getGID(url), 'evolution-emma-stone');
    expect(ripper.urlTypeForTesting, ListalUrlType.list);

    await expectLater(
      ripper.getGID(Uri.parse('https://www.listal.com/list/my-list/')),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      ripper.getGID(Uri.parse('http://www.listal.com/list/my-list')),
      throwsA(isA<FormatException>()),
    );
  });

  test('matches Java folder GID rules for actor picture URLs', () async {
    final ripper =
        ListalRipper(Uri.parse('https://www.listal.com/chet-atkins/pictures'));

    expect(await ripper.getGID(ripper.url), 'chet-atkins');
    expect(ripper.urlTypeForTesting, ListalUrlType.folder);
    expect(
      await ripper.getFolderTypeGid('chet-atkins/pictures/'),
      'chet-atkins',
    );

    await expectLater(
      ripper.getGID(Uri.parse('https://www.listal.com/chet-atkins')),
      throwsA(isA<FormatException>()),
    );
  });

  test('extracts Java list and folder intermediate image URLs', () {
    final baseUri = Uri.parse('https://www.listal.com/source/page');
    final listPage = html.parse('''
      <div class="pure-g">
        <a href="/viewimage/11">image</a>
        <a href="https://cdn.example.com/viewimage/22">image</a>
        <a href="/profile/not-image">skip</a>
      </div>
    ''');
    final folderPage = html.parse('''
      <div id="browseimagescontainer">
        <div class="imagewrap-outer"><a href="/viewimage/33"></a></div>
        <div><a href="/viewimage/skip"></a></div>
      </div>
    ''');

    expect(ListalRipper.urlsForListType(listPage, baseUri), [
      'https://www.listal.com/viewimage/11h',
      'https://cdn.example.com/viewimage/22h',
    ]);
    expect(ListalRipper.urlsForFolderType(folderPage, baseUri), [
      'https://www.listal.com/viewimage/33h',
    ]);
  });

  test('extracts final pure-img source and Java image-page filenames',
      () async {
    final page = html.parse('''
      <img class="pure-img" src="https://images.example.com/full.jpg">
      <img class="pure-img" src="https://images.example.com/second.jpg">
    ''');
    expect(
      ListalRipper.imageUrlFromImagePage(page),
      'https://images.example.com/full.jpg',
    );
    expect(ListalRipper.imageUrlFromImagePage(html.parse('<main></main>')),
        isNull);

    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(ListalRipper.prefixForIndex(7), '007_');
    expect(
      ListalRipper.fileNameForImagePage(
        Uri.parse('https://www.listal.com/viewimage/12345h'),
        ListalRipper.prefixForIndex(7),
      ),
      '007_12345h.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(ListalRipper.prefixForIndex(7), '');
    expect(
      ListalRipper.fileNameForImagePage(
        Uri.parse('https://www.listal.com/viewimage/12345h'),
        ListalRipper.prefixForIndex(7),
      ),
      '12345h.jpg',
    );
  });

  test('posts list id and offset to load more list items', () async {
    final requests = <Map<String, String>>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      requests.add({
        'method': request.method,
        'body': body,
      });
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.html
        ..write('<div class="pure-g"><a href="/viewimage/44"></a></div>');
      await request.response.close();
    });

    final postUri = Uri.parse('http://127.0.0.1:${server.port}/item-list/');
    final ripper = ListalRipper(
      Uri.parse('https://www.listal.com/list/evolution-emma-stone'),
      postUri: postUri,
    );
    final page = await ripper.postNextListPage('9012', '30');

    expect(requests, [
      {'method': 'POST', 'body': 'listid=9012&offset=30'},
    ]);
    expect(ListalRipper.urlsForListType(page, postUri), [
      'http://127.0.0.1:${server.port}/viewimage/44h',
    ]);
  });
}
