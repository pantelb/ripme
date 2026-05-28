import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/imgbox_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, broad URL support, and album GID', () async {
    final url = Uri.parse('https://imgbox.com/g/FJPF7t26FD');
    final ripper = ImgboxRipper(url);

    expect(ripper.getHost(), 'imgbox');
    expect(ripper.getDomain(), 'imgbox.com');
    expect(ripper.canRip(url), isTrue);
    expect(ripper.canRip(Uri.parse('https://www.imgbox.com/anything')), isTrue);
    expect(
        ripper.canRip(Uri.parse('https://example.com/g/FJPF7t26FD')), isFalse);
    expect(await ripper.getGID(url), 'FJPF7t26FD');
    expect(
      await ripper.getGID(Uri.parse('https://m.imgbox.com/g/ABC123')),
      'ABC123',
    );
    await expectLater(
      ripper.getGID(Uri.parse('https://imgbox.com/not-gallery/FJPF7t26FD')),
      throwsA(isA<FormatException>()),
    );
  });

  test('extracts boxed-content thumbnail images like Java', () {
    final page = html.parse('''
      <div class="boxed-content">
        <a><img src="https://thumbs.imgbox.com/ab/cd/sample_b.jpg"></a>
      </div>
      <section class="boxed-content">
        <a><img src="https://thumbs.imgbox.com/skip_b.jpg"></a>
      </section>
      <div class="boxed-content"><a><span>missing</span></a></div>
    ''');

    expect(ImgboxRipper.imageUrlsFromDocument(page), [
      'https://images.imgbox.com/ab/cd/sample_o.jpg',
    ]);
  });

  test('rewrites thumbnail URLs to original image URLs like Java', () {
    expect(
      ImgboxRipper.originalImageUrlFromThumbnail(
        'https://thumbs.imgbox.com/1-s/name_b.jpeg',
      ),
      'https://images.imgbox.com/i/name_o.jpeg',
    );
    expect(
      ImgboxRipper.originalImageUrlFromThumbnail(
        'https://thumbs.imgbox.com/9-s/name_b_b.png',
      ),
      'https://images.imgbox.com/i/name_o_o.png',
    );
  });

  test('uses Java-style configurable ordered filenames', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(ImgboxRipper.prefixForIndex(7), '007_');
    expect(
      ImgboxRipper.fileNameForUrl(
        Uri.parse('https://images.imgbox.com/i/name_o.jpg'),
        prefix: ImgboxRipper.prefixForIndex(7),
      ),
      '007_name_o.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(ImgboxRipper.prefixForIndex(7), '');
    expect(
      ImgboxRipper.fileNameForUrl(
        Uri.parse('https://images.imgbox.com/i/name_o.jpg'),
        prefix: ImgboxRipper.prefixForIndex(7),
      ),
      'name_o.jpg',
    );
  });
}
