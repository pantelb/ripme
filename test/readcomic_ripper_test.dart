import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/abstract_ripper.dart';
import 'package:ripme/ripper/rippers/readcomic_ripper.dart';

void main() {
  test('ReadcomicRipper matches Java URL detection, host, domain, and GID',
      () async {
    final url = Uri.parse('https://read-comic.com/comic-name/');
    final ripper = ReadcomicRipper(url);

    expect(ripper.getHost(), 'read-comic');
    expect(ripper.getDomain(), 'read-comic.com');
    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(Uri.parse('http://read-comic.com/comic-name')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://www.read-comic.com/comic-name/')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://read-comic.com/comic0/')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://not-read-comic.com/anything')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://read-comic.com.evil/comic-name/')),
      isFalse,
    );

    expect(await ripper.getGID(url), 'comic-name');
    await expectLater(
      ripper.getGID(Uri.parse('https://www.read-comic.com/comic-name/')),
      throwsFormatException,
    );
    await expectLater(
      ripper.getGID(Uri.parse('https://read-comic.com/comic0/')),
      throwsFormatException,
    );
  });

  test('ReadcomicRipper extracts pinbin-copy image sources like Java', () {
    final page = html.parse('''
      <div class="pinbin-copy">
        <a><img src="https://cdn.example.com/001.jpg"></a>
        <a><img></a>
        <a><img src="https://cdn.example.com/002.jpg"></a>
      </div>
      <div class="separator"><a><img src="https://cdn.example.com/view.jpg"></a></div>
    ''');

    expect(ReadcomicRipper.imageUrlsFromDocument(page), [
      'https://cdn.example.com/001.jpg',
      '',
      'https://cdn.example.com/002.jpg',
    ]);
  });

  test('ReadcomicRipper keeps missing src entries in download queue like Java',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      request.response.headers.contentType = ContentType.html;
      request.response.write('''
        <div class="pinbin-copy">
          <a><img></a>
          <a><img src="https://cdn.example.com/002.jpg"></a>
        </div>
      ''');
      await request.response.close();
    });

    final ripper = _RecordingReadcomicRipper(
      Uri.parse('http://127.0.0.1:${server.port}/comic/'),
    );
    final tempDir = await Directory.systemTemp.createTemp('readcomic-test-');
    addTearDown(() => tempDir.delete(recursive: true));
    ripper.workingDir = tempDir;

    await ripper.rip();

    expect(ripper.downloads.map((download) => download.url.toString()), [
      '',
      'https://cdn.example.com/002.jpg',
    ]);
    expect(ripper.downloads.first.saveAs.path, endsWith('001_file'));
  });

  test('ReadcomicRipper applies inherited Viewcomic title cleanup', () {
    final page = html.parse(
      '<title>Example_Title | Viewcomic reading comics online for free….</title>',
    );

    expect(ReadcomicRipper.titleFromDocument(page), 'ExampleTitle');
  });

  test('ReadcomicRipper surfaces missing title failures like Java', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      request.response.headers.contentType = ContentType.html;
      request.response.write('<main>No title here</main>');
      await request.response.close();
    });

    final url = Uri.parse('http://127.0.0.1:${server.port}/comic/');
    final ripper = ReadcomicRipper(url);

    await expectLater(ripper.getAlbumTitle(url), throwsA(isA<TypeError>()));
  });

  test('ReadcomicRipper uses Java-style ordered filenames', () {
    expect(
      ReadcomicRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/page-001.jpg'),
        prefix: ReadcomicRipper.prefixForIndex(4),
      ),
      '004_page-001.jpg',
    );
  });
}

class _RecordingReadcomicRipper extends ReadcomicRipper {
  _RecordingReadcomicRipper(super.url);

  final downloads = <RipperDownload>[];

  @override
  Future<void> downloadFiles(Iterable<RipperDownload> downloads) async {
    this.downloads.addAll(downloads);
  }
}
