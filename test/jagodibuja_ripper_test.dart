import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/jagodibuja_ripper.dart';
import 'package:ripme/utils/http_utils.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    Http.delay = Future.delayed;
  });

  test('matches Java host, domain, broad URL support, and strict GID',
      () async {
    final url = Uri.parse('http://www.jagodibuja.com/comic-in-me/');
    final ripper = JagodibujaRipper(url);

    expect(ripper.getHost(), 'jagodibuja');
    expect(ripper.getDomain(), 'jagodibuja.com');
    expect(ripper.canRip(url), isTrue);
    expect(ripper.canRip(Uri.parse('https://jagodibuja.com/')), isTrue);
    expect(ripper.canRip(Uri.parse('https://example.com/comic')), isFalse);
    expect(await ripper.getGID(url), 'comic-in-me');
    expect(await ripper.getGID(Uri.parse('https://www.jagodibuja.com/')), '');
    await expectLater(
      ripper.getGID(Uri.parse('https://jagodibuja.com/comic-in-me/')),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      ripper.getGID(
        Uri.parse('https://www.jagodibuja.com/comic-in-me/?page=2'),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('extracts gallery comic-page links like Java', () {
    final page = html.parse('''
      <div class="gallery-icon"><a href="https://example.com/page-1"></a></div>
      <div class="gallery-icon"><span><a href="https://example.com/skip"></a></span></div>
      <section class="gallery-icon"><a href="https://example.com/skip2"></a></section>
      <div class="gallery-icon"><a></a></div>
    ''');

    expect(JagodibujaRipper.comicPageUrlsFromDocument(page), [
      'https://example.com/page-1',
      '',
    ]);
  });

  test('extracts full-size image href from comic page like Java', () {
    final page = html.parse('''
      <span class="full-size-link">
        <a href="https://cdn.example.com/full/page01.jpg">full size</a>
      </span>
    ''');

    expect(
      JagodibujaRipper.fullSizeHrefFromDocument(page),
      'https://cdn.example.com/full/page01.jpg',
    );
    expect(
      () => JagodibujaRipper.fullSizeHrefFromDocument(html.parse('<html>')),
      throwsStateError,
    );
  });

  test('loads comic pages, waits 500ms, and returns full-size URLs', () async {
    SharedPreferences.setMockInitialValues({
      'download.retries': 0,
      'page.timeout': 1000,
    });
    await Utils.init();

    final delays = <Duration>[];
    Http.delay = (duration) async {
      delays.add(duration);
    };

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.uri.path == '/page-1') {
        request.response.write('''
          <span class="full-size-link">
            <a href="https://cdn.example.com/full/page01.jpg"></a>
          </span>
        ''');
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });
    addTearDown(server.close);

    final ripper = JagodibujaRipper(
      Uri.parse('http://www.jagodibuja.com/comic-in-me/'),
    );
    final page = html.parse('''
      <div class="gallery-icon">
        <a href="http://127.0.0.1:${server.port}/page-1"></a>
      </div>
      <div class="gallery-icon">
        <a href="http://127.0.0.1:${server.port}/missing"></a>
      </div>
    ''');

    expect(await ripper.getURLsFromPage(page), [
      'https://cdn.example.com/full/page01.jpg',
    ]);
    expect(delays, [
      const Duration(milliseconds: 500),
      const Duration(milliseconds: 500),
    ]);
  });

  test('uses unprefixed Java filenames', () {
    expect(
      JagodibujaRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/full/page01.jpg'),
      ),
      'page01.jpg',
    );
  });
}
