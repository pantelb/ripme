import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/bato_ripper.dart';

void main() {
  test('BatoRipper matches Java chapter and series URL behavior', () async {
    final chapter = Uri.parse('https://bato.to/chapter/12345/');
    final series = Uri.parse('https://bato.to/series/67890/');
    final ripper = BatoRipper(chapter);

    expect(ripper.canRip(chapter), isTrue);
    expect(ripper.canRip(series), isTrue);
    expect(await ripper.getGID(chapter), '12345');
    expect(await ripper.getGID(series), '');
    expect(ripper.pageContainsAlbums(series), isTrue);
    await expectLater(
      ripper.getGID(Uri.parse('https://bato.to/title/12345')),
      throwsA(isA<FormatException>()),
    );
  });

  test('BatoRipper queues series chapter links like Java', () async {
    final ripper = BatoRipper(Uri.parse('https://bato.to/series/123/'));
    final page = html.parse('''
      <html><body>
        <div class="main">
          <div><a href="/chapter/1/"></a></div>
          <div><a href="/chapter/2/"></a></div>
        </div>
      </body></html>
    ''');

    expect(await ripper.getAlbumsToQueue(page), [
      'https://bato.to/chapter/1/',
      'https://bato.to/chapter/2/',
    ]);
  });

  test('BatoRipper scans imgHttps JSON arrays from scripts', () {
    const script = '''
      var ignored = true;
      imgHttps = ["https://cdn.example.com/1.jpg","https://cdn.example.com/2.png"];
    ''';

    expect(BatoRipper.scanForImageList(script),
        '["https://cdn.example.com/1.jpg","https://cdn.example.com/2.png"]');
  });

  test('BatoRipper extracts chapter image URLs from script data', () {
    final page = html.parse(r'''
      <html><body>
        <script>
          var other = [];
          imgHttps = ["https://cdn.example.com/1.jpg","https://cdn.example.com/2.png"];
        </script>
      </body></html>
    ''');

    expect(BatoRipper.imageUrlsFromDocument(page), [
      'https://cdn.example.com/1.jpg',
      'https://cdn.example.com/2.png',
    ]);
  });
}
