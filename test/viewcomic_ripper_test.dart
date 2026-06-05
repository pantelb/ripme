import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/abstract_ripper.dart';
import 'package:ripme/ripper/rippers/viewcomic_ripper.dart';

void main() {
  test('ViewcomicRipper matches Java URL detection, host, domain, and GID',
      () async {
    final url = Uri.parse('https://view-comic.com/batman-no-mans-land-vol-1/');
    final ripper = ViewcomicRipper(url);

    expect(ripper.getHost(), 'view-comic');
    expect(ripper.getDomain(), 'view-comic.com');
    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(Uri.parse('http://view-comic.com/batman-no-mans-land')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://view-comic.com/batman/issue-1')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://not-view-comic.com/anything')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://view-comic.com.evil/batman')),
      isFalse,
    );
    expect(await ripper.getGID(url), 'batman-no-mans-land-vol-1');
    await expectLater(
      ripper.getGID(Uri.parse('https://view-comic.com/batman/issue-1')),
      throwsFormatException,
    );
  });

  test('ViewcomicRipper extracts separator image sources like Java', () {
    final page = html.parse('''
      <div class="separator"><a><img src="https://cdn.example.com/001.jpg"></a></div>
      <div class="separator"><a><img></a></div>
      <div class="pinbin-copy"><a><img src="https://cdn.example.com/readcomic.jpg"></a></div>
    ''');

    expect(ViewcomicRipper.imageUrlsFromDocument(page), [
      'https://cdn.example.com/001.jpg',
      '',
    ]);
  });

  test('ViewcomicRipper keeps missing src entries in download queue like Java',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      request.response.headers.contentType = ContentType.html;
      request.response.write('''
        <div class="separator"><a><img></a></div>
        <div class="separator">
          <a><img src="https://cdn.example.com/002.jpg"></a>
        </div>
      ''');
      await request.response.close();
    });

    final ripper = _RecordingViewcomicRipper(
      Uri.parse('http://127.0.0.1:${server.port}/comic/'),
    );
    final tempDir = await Directory.systemTemp.createTemp('viewcomic-test-');
    addTearDown(() => tempDir.delete(recursive: true));
    ripper.workingDir = tempDir;

    await ripper.rip();

    expect(ripper.downloads.map((download) => download.url.toString()), [
      '',
      'https://cdn.example.com/002.jpg',
    ]);
    expect(ripper.downloads.first.saveAs.path, endsWith('001_file'));
  });

  test('ViewcomicRipper applies Java title cleanup', () {
    final page = html.parse(
      '<title>Example_Title | Viewcomic reading comics online for free….</title>',
    );

    expect(ViewcomicRipper.titleFromDocument(page), 'ExampleTitle');
  });

  test('ViewcomicRipper surfaces missing title failures like Java', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      request.response.headers.contentType = ContentType.html;
      request.response.write('<main>No title here</main>');
      await request.response.close();
    });

    final url = Uri.parse('http://127.0.0.1:${server.port}/comic/');
    final ripper = ViewcomicRipper(url);

    await expectLater(ripper.getAlbumTitle(url), throwsA(isA<TypeError>()));
  });

  test('ViewcomicRipper uses Java-style ordered filenames', () {
    expect(
      ViewcomicRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/page.jpg'),
        prefix: ViewcomicRipper.prefixForIndex(3),
      ),
      '003_page.jpg',
    );
  });
}

class _RecordingViewcomicRipper extends ViewcomicRipper {
  _RecordingViewcomicRipper(super.url);

  final downloads = <RipperDownload>[];

  @override
  Future<void> downloadFiles(Iterable<RipperDownload> downloads) async {
    this.downloads.addAll(downloads);
  }
}
