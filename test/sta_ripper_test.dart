import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/sta_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('StaRipper matches Java host, domain, support, and strict GID',
      () async {
    final url = Uri.parse('https://sta.sh/01umpyuxi4js');
    final ripper = StaRipper(url);

    expect(ripper.getHost(), 'sta');
    expect(ripper.getDomain(), 'sta.sh');
    expect(ripper.canRip(url), isTrue);
    expect(
        ripper.canRip(Uri.parse('https://www.sta.sh/01umpyuxi4js')), isFalse);
    expect(
        ripper.canRip(Uri.parse('https://example.com/01umpyuxi4js')), isFalse);

    expect(await ripper.getGID(url), '01umpyuxi4js');
    await expectLater(
      ripper.getGID(Uri.parse('http://sta.sh/01umpyuxi4js')),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      ripper.getGID(Uri.parse('https://sta.sh/01umpyuxi4js?x=1')),
      throwsA(isA<FormatException>()),
    );
  });

  test('StaRipper extracts Java thumb and download selectors', () {
    final page = html.parse('''
      <span><span><a class="thumb" href="https://sta.sh/thumb-one">one</a></span></span>
      <span><span><a class="thumb" href="/relative">relative</a></span></span>
      <a class="thumb" href="https://sta.sh/not-nested">skip</a>
    ''');
    expect(StaRipper.thumbPageUrlsFromDocument(page), [
      'https://sta.sh/thumb-one',
      '/relative',
    ]);

    final thumbPage = html.parse(
      '<a class="dev-page-download" href="https://sta.sh/download/file">DL</a>',
    );
    expect(
      StaRipper.downloadLinkFromThumbPage(thumbPage),
      'https://sta.sh/download/file',
    );
    expect(StaRipper.downloadLinkFromThumbPage(html.parse('<html></html>')),
        isNull);
  });

  test('StaRipper validates absolute thumb URLs like Java checkURL', () {
    expect(StaRipper.isAbsoluteUrl('https://sta.sh/thumb-one'), isTrue);
    expect(StaRipper.isAbsoluteUrl('/relative'), isFalse);
    expect(StaRipper.isAbsoluteUrl('not a url'), isFalse);
  });

  test('StaRipper follows download redirects with Java cookies', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final requests = <HttpRequest>[];
    unawaited(() async {
      await for (final request in server) {
        requests.add(request);
        request.response.statusCode = HttpStatus.found;
        request.response.headers.set(
          HttpHeaders.locationHeader,
          'https://images.example.com/full.jpg',
        );
        await request.response.close();
      }
    }());

    final url = Uri.parse('http://127.0.0.1:${server.port}/download');
    final imageUrl = await StaRipper.imageLinkFromDownloadLink(
      url,
      cookies: {'a': '1', 'b': 'two'},
    );

    expect(imageUrl, 'https://images.example.com/full.jpg');
    expect(
        requests.single.headers.value(HttpHeaders.cookieHeader), 'a=1; b=two');
  });

  test('StaRipper parses Java response cookies and ordered filenames',
      () async {
    expect(
      StaRipper.cookiesFromSetCookieHeader(
        'a=1; Path=/, b=two; Domain=sta.sh',
      ),
      {'a': '1', 'b': 'two'},
    );

    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      StaRipper.fileNameForUrl(
        Uri.parse('https://images.example.com/full.jpg?token=1'),
        4,
      ),
      '004_full.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      StaRipper.fileNameForUrl(
          Uri.parse('https://images.example.com/full.jpg'), 4),
      'full.jpg',
    );
  });
}
