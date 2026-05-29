import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/yuvutu_ripper.dart';

void main() {
  test('matches Java Yuvutu URL support and GID parsing', () async {
    final uri = Uri.parse(
      'http://www.yuvutu.com/modules.php?name=YuGallery&action=view&set_id=420333',
    );
    final ripper = YuvutuRipper(uri);

    expect(ripper.getHost(), 'yuvutu');
    expect(ripper.getDomain(), 'yuvutu.com');
    expect(ripper.canRip(uri), isTrue);
    expect(
      ripper.canRip(
        Uri.parse(
          'https://www.yuvutu.com/modules.php?name=YuGallery&action=view&set_id=420333',
        ),
      ),
      isFalse,
    );
    expect(
      ripper.canRip(
        Uri.parse(
          'http://www.yuvutu.com/modules.php?action=view&name=YuGallery&set_id=420333',
        ),
      ),
      isFalse,
    );
    expect(await ripper.getGID(uri), '420333');
  });

  test('extracts galleria image src attributes like Java', () {
    final page = parse('''
      <div id="galleria">
        <a><img src="https://cdn.example/one.jpg"></a>
        <a><img></a>
      </div>
    ''');

    expect(YuvutuRipper.imageUrlsFromDocument(page), [
      'https://cdn.example/one.jpg',
      '',
    ]);
  });

  test('uses Java-style ordered filenames', () {
    expect(
      YuvutuRipper.fileNameForUrl(
        Uri.parse('https://cdn.example/path/one.jpg'),
        prefix: YuvutuRipper.prefix(2),
      ),
      '002_one.jpg',
    );
  });
}
