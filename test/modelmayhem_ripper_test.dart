import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/modelmayhem_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, broad support, and strict GID', () async {
    final url =
        Uri.parse('https://www.modelmayhem.com/portfolio/4829413/viewall');
    final ripper = ModelmayhemRipper(url);

    expect(ripper.getHost(), 'modelmayhem');
    expect(ripper.getDomain(), 'modelmayhem.com');
    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(Uri.parse('https://photos.modelmayhem.com/example')),
      isTrue,
    );
    expect(
        ripper.canRip(Uri.parse('https://example.com/portfolio/1')), isFalse);
    expect(await ripper.getGID(url), '4829413');
    expect(
      await ripper.getGID(
        Uri.parse('http://www.modelmayhem.com/portfolio/4829413/viewall'),
      ),
      '4829413',
    );

    await expectLater(
      ripper.getGID(
        Uri.parse('https://www.modelmayhem.com/portfolio/4829413/viewall/'),
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      ripper.getGID(
        Uri.parse('https://modelmayhem.com/portfolio/4829413/viewall'),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('sends Java worksafe bypass cookie on first page request', () async {
    final cookies = <String>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      cookies.add(request.headers.value(HttpHeaders.cookieHeader) ?? '');
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.html
        ..write('<html></html>');
      await request.response.close();
    });

    final ripper =
        ModelmayhemRipper(Uri.parse('http://127.0.0.1:${server.port}/'));
    await ripper.getFirstPage();

    expect(cookies, ['worksafe=0']);
  });

  test('extracts Java gallery image URLs from table thumbnails', () {
    final page = html.parse('''
      <table>
        <tr class="a_pics">
          <td><div><a><img src="https://photos.example.com/one_m.jpg"></a></div></td>
        </tr>
        <tr class="a_pics">
          <td><div><a><img src="https://photos.example.com/two_m_m.png"></a></div></td>
        </tr>
        <tr class="a_pics">
          <td><div><a><img src="/relative_m.jpg"></a></div></td>
        </tr>
        <tr>
          <td><div><a><img src="https://photos.example.com/skipped_m.jpg"></a></div></td>
        </tr>
      </table>
    ''');

    expect(ModelmayhemRipper.imageUrlsFromDocument(page), [
      'https://photos.example.com/one.jpg',
      'https://photos.example.com/two.png',
    ]);
  });

  test('uses Java ordered filename prefixes when enabled', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(ModelmayhemRipper.prefixForIndex(7), '007_');
    expect(
      ModelmayhemRipper.fileNameForUrl(
        Uri.parse('https://photos.example.com/path/model.jpg'),
        prefix: ModelmayhemRipper.prefixForIndex(7),
      ),
      '007_model.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(ModelmayhemRipper.prefixForIndex(7), '');
    expect(
      ModelmayhemRipper.fileNameForUrl(
        Uri.parse('https://photos.example.com/path/model.jpg'),
        prefix: ModelmayhemRipper.prefixForIndex(7),
      ),
      'model.jpg',
    );
  });
}
