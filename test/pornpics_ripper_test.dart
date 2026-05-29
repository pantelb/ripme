import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/pornpics_ripper.dart';

void main() {
  test('PornpicsRipper matches Java URL detection, host, domain, and GID',
      () async {
    final url = Uri.parse('https://www.pornpics.com/galleries/gallery-id/');
    final ripper = PornpicsRipper(url);

    expect(ripper.getHost(), 'pornpics');
    expect(ripper.getDomain(), 'pornpics.com');
    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(Uri.parse('http://www.pornpics.com/galleries/gallery-id')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://pornpics.com/galleries/gallery-id/')),
      isFalse,
    );
    expect(
      ripper.canRip(
        Uri.parse('https://www.pornpics.com/galleries/gallery-id/page/2'),
      ),
      isFalse,
    );

    expect(await ripper.getGID(url), 'gallery-id');
  });

  test('PornpicsRipper extracts rel-link hrefs like Java', () {
    final page = html.parse('''
      <a class="rel-link" href="https://cdn.example.com/001.jpg"></a>
      <a class="rel-link" href="https://cdn.example.com/002.jpg"></a>
      <a href="https://cdn.example.com/outside.jpg"></a>
    ''');

    expect(PornpicsRipper.imageUrlsFromDocument(page), [
      'https://cdn.example.com/001.jpg',
      'https://cdn.example.com/002.jpg',
    ]);
  });

  test('PornpicsRipper uses Java-style ordered filenames', () {
    expect(
      PornpicsRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/image-001.jpg'),
        prefix: PornpicsRipper.prefixForIndex(9),
      ),
      '009_image-001.jpg',
    );
  });
}
