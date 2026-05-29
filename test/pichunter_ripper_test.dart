import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/pichunter_ripper.dart';

void main() {
  test('PichunterRipper matches Java host, domain, support, and GIDs',
      () async {
    final ripper = PichunterRipper(
      Uri.parse('https://www.pichunter.com/models/Madison_Ivy'),
    );

    expect(ripper.getHost(), 'pichunter');
    expect(ripper.getDomain(), 'pichunter.com');
    expect(
      ripper.canRip(Uri.parse('https://www.pichunter.com/tags/blonde')),
      isTrue,
    );
    expect(
      ripper.canRip(
        Uri.parse('https://www.pichunter.com/models/Madison_Ivy/photos/2'),
      ),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://pichunter.com/models/Madison_Ivy')),
      isFalse,
    );

    expect(
      await ripper.getGID(
        Uri.parse('https://www.pichunter.com/models/Madison_Ivy'),
      ),
      'Madison_Ivy',
    );
    expect(
      await ripper.getGID(
        Uri.parse('https://www.pichunter.com/sites/site_name/photos/7/'),
      ),
      'site_name/photos/7/',
    );
    expect(
      await ripper.getGID(
        Uri.parse('https://www.pichunter.com/tags/all/redhead/3/'),
      ),
      'all/redhead/3/',
    );
    expect(
      await ripper.getGID(
        Uri.parse(
          'http://www.pichunter.com/gallery/3270642/Its_not_only_those_who',
        ),
      ),
      'Its_not_only_those_who',
    );
  });

  test('PichunterRipper extracts listing thumbnails like Java', () {
    final page = html.parse('''
      <html><body>
        <div class="thumbtable">
          <a class="thumb"><img src="http://img.example.com/a_i.jpg"></a>
          <a class="thumb"><img src="http://img.example.com/b_i.png"></a>
        </div>
      </body></html>
    ''');

    expect(PichunterRipper.imageUrlsFromDocument(page, isPhotoSet: false), [
      'http://img.example.com/a_o.jpg',
      'http://img.example.com/b_o.png',
    ]);
  });

  test('PichunterRipper extracts photo-set thumbnails like Java', () {
    final page = html.parse('''
      <html><body>
        <div class="flex-images">
          <figure><a class="item"><img src="http://img.example.com/c_i.jpg"></a></figure>
          <figure><a class="item"><img src="http://img.example.com/d_i.jpg"></a></figure>
        </div>
      </body></html>
    ''');

    expect(PichunterRipper.imageUrlsFromDocument(page, isPhotoSet: true), [
      'http://img.example.com/c_o.jpg',
      'http://img.example.com/d_o.jpg',
    ]);
  });

  test('PichunterRipper builds Java arrow pagination URLs', () {
    final page = html.parse('''
      <html><body>
        <div class="paperSpacings">
          <ul>
            <li class="arrow"><a href="/models/Madison_Ivy/photos/2">prev</a></li>
            <li class="arrow"><a href="/models/Madison_Ivy/photos/3">next</a></li>
          </ul>
        </div>
      </body></html>
    ''');
    final emptyHrefPage = html.parse('''
      <html><body>
        <div class="paperSpacings"><ul><li class="arrow"><a href=""></a></li></ul></div>
      </body></html>
    ''');

    expect(
      PichunterRipper.nextPageUrl(page).toString(),
      'http://www.pichunter.com/models/Madison_Ivy/photos/3',
    );
    expect(
      PichunterRipper.nextPageUrl(emptyHrefPage).toString(),
      'http://www.pichunter.com',
    );
  });

  test('PichunterRipper uses Java-style ordered filenames', () {
    expect(
      PichunterRipper.fileNameForUrl(
        Uri.parse('http://img.example.com/gallery/image_o.jpg'),
        12,
      ),
      '012_image_o.jpg',
    );
  });
}
