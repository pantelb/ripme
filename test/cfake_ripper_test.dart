import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/cfake_ripper.dart';

void main() {
  test(
    'CfakeRipper matches Java URL detection, host, domain, and GID',
    () async {
      final url = Uri.parse(
        'https://cfake.com/images/celebrity/Zooey_Deschanel/1264',
      );
      final ripper = CfakeRipper(url);

      expect(ripper.canRip(url), isTrue);
      expect(
        ripper.canRip(
          Uri.parse(
            'https://www.cfake.com/images/celebrity/Zooey_Deschanel/1264',
          ),
        ),
        isFalse,
      );
      expect(ripper.getHost(), 'cfake');
      expect(ripper.getDomain(), 'cfake.com');
      expect(await ripper.getGID(url), 'Zooey_Deschanel');
      await expectLater(
        ripper.getGID(
          Uri.parse('https://cfake.com/images/celebrity/Zooey_Deschanel'),
        ),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('CfakeRipper extracts gallery thumbnails as full photo URLs', () {
    final page = html.parse('''
      <html><body>
        <div id="media_content">
          <div class="responsive">
            <div class="gallery">
              <a href="/ignored"><img src="/medias/thumbs/2025/one_cfake.jpg"></a>
              <a href="/ignored"><img src="/medias/thumbs/2024/two_cfake.png"></a>
            </div>
          </div>
        </div>
      </body></html>
    ''');

    expect(CfakeRipper.imageUrlsFromDocument(page), [
      'https://cfake.com/medias/photos/2025/one_cfake.jpg',
      'https://cfake.com/medias/photos/2024/two_cfake.png',
    ]);
  });

  test('CfakeRipper follows Java pagination span rules', () async {
    final ripper = CfakeRipper(
      Uri.parse('https://cfake.com/images/celebrity/Zooey_Deschanel/1264'),
    );
    final nextPage = html.parse('''
      <div id="wrapper_path">
        <div id="content_path">
          <div id="num_page">
            <a href="/images/celebrity/Zooey_Deschanel/1264/2"><span>Next</span></a>
          </div>
        </div>
      </div>
    ''');
    final lastPage = html.parse('''
      <div id="wrapper_path">
        <div id="content_path">
          <div id="num_page"><a href="/last">Last</a></div>
        </div>
      </div>
    ''');

    expect(
      (await ripper.getNextPage(nextPage)).toString(),
      'https://cfake.com/images/celebrity/Zooey_Deschanel/1264/2',
    );
    expect(await ripper.getNextPage(lastPage), isNull);
    expect(await ripper.getNextPage(html.parse('<html></html>')), isNull);
  });

  test('CfakeRipper uses Java-style ordered filenames', () {
    expect(CfakeRipper.prefixForIndex(7), '007_');
    expect(
      CfakeRipper.fileNameForUrl(
        Uri.parse('https://cfake.com/medias/photos/2025/one_cfake.jpg'),
        prefix: '007_',
      ),
      '007_one_cfake.jpg',
    );
  });
}
