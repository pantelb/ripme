import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/mrcong_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, gallery GIDs, and tag GIDs', () async {
    final gallery =
        Uri.parse('https://misskon.com/xiaoyu-vol-799-lin-xing-lan-87-anh/');
    final pagedGallery = Uri.parse(
        'https://www.misskon.com/xiaoyu-vol-799-lin-xing-lan-87-anh/2/');
    final tag = Uri.parse('https://misskon.com/tag/xr-uncensored/');
    final ripper = MrCongRipper(gallery);

    expect(ripper.getHost(), 'misskon');
    expect(ripper.getDomain(), 'misskon.com');
    expect(ripper.canRip(gallery), isTrue);
    expect(ripper.canRip(pagedGallery), isTrue);
    expect(ripper.canRip(tag), isTrue);
    expect(ripper.canRip(Uri.parse('https://mrcong.com/example/')), isFalse);
    expect(await ripper.getGID(gallery), 'xiaoyu-vol-799-lin-xing-lan-87-anh');
    expect(await ripper.getGID(pagedGallery),
        'xiaoyu-vol-799-lin-xing-lan-87-anh');
    expect(await ripper.getGID(tag), 'xr-uncensored');
    expect(ripper.tagPageForTesting, isTrue);

    await expectLater(
      ripper.getGID(Uri.parse('https://misskon.com/tag/xr-uncensored')),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      ripper.getGID(Uri.parse('https://misskon.com/gallery_name/')),
      throwsA(isA<FormatException>()),
    );
  });

  test('normalizes first pages and builds Java-compatible next page URLs', () {
    expect(
      MrCongRipper.rootGalleryUrl(
        Uri.parse('https://misskon.com/xiaoyu-vol-799-lin-xing-lan-87-anh/2/'),
      ).toString(),
      'https://misskon.com/xiaoyu-vol-799-lin-xing-lan-87-anh/',
    );
    expect(
      MrCongRipper.rootGalleryUrl(
        Uri.parse('https://misskon.com/xiaoyu-vol-799-lin-xing-lan-87-anh'),
      ).toString(),
      'https://misskon.com/xiaoyu-vol-799-lin-xing-lan-87-anh/',
    );
    expect(
      MrCongRipper.rootTagUrl(
        Uri.parse('https://misskon.com/tag/xr-uncensored/page/9/'),
      ).toString(),
      'https://misskon.com/tag/xr-uncensored/page/1/',
    );

    expect(
      MrCongRipper.nextPageUrl(
        Uri.parse('https://misskon.com/gallery/'),
        currPageNum: 1,
        lastPageNum: 3,
        tagPage: false,
      ).toString(),
      'https://misskon.com/gallery/2',
    );
    expect(
      MrCongRipper.nextPageUrl(
        Uri.parse('https://misskon.com/gallery/2'),
        currPageNum: 2,
        lastPageNum: 3,
        tagPage: false,
      ).toString(),
      'https://misskon.com/gallery/3/',
    );
    expect(
      MrCongRipper.nextPageUrl(
        Uri.parse('https://misskon.com/tag/xr-uncensored/'),
        currPageNum: 1,
        lastPageNum: 2,
        tagPage: true,
      ).toString(),
      'https://misskon.com/tag/xr-uncensored/page/2',
    );
    expect(
      MrCongRipper.nextPageUrl(
        Uri.parse('https://misskon.com/gallery/3/'),
        currPageNum: 3,
        lastPageNum: 3,
        tagPage: false,
      ),
      isNull,
    );
  });

  test('extracts max page numbers using Java selectors', () {
    final gallery = html.parse('''
      <div class="page-link"><a>1</a><a>2</a><a>4</a></div>
    ''');
    final tag = html.parse('''
      <div class="pagination"><a>1</a><a>7</a></div>
    ''');

    expect(MrCongRipper.maxPageNumber(gallery, tagPage: false), 4);
    expect(MrCongRipper.maxPageNumber(tag, tagPage: true), 7);
    expect(
        MrCongRipper.maxPageNumber(html.parse('<main></main>'), tagPage: false),
        1);
  });

  test('extracts gallery images and tag child gallery URLs like Java', () {
    final gallery = html.parse('''
      <p><img data-src="https://cdn.example.com/one.jpg" src="thumb.jpg"></p>
      <p><img src="https://cdn.example.com/two.jpg"></p>
      <p><span><img src="https://cdn.example.com/skipped.jpg"></span></p>
      <p><img></p>
    ''');
    final tag = html.parse('''
      <h2><a href="https://misskon.com/gallery-one/">one</a></h2>
      <h2><a href="https://misskon.com/">home</a></h2>
      <h2><a href="https://misskon.com/gallery-two/">two</a></h2>
    ''');

    expect(MrCongRipper.imageUrlsFromDocument(gallery), [
      'https://cdn.example.com/one.jpg',
      'https://cdn.example.com/two.jpg',
      '',
    ]);
    expect(MrCongRipper.tagGalleryUrlsFromDocument(tag), [
      'https://misskon.com/gallery-one/',
      'https://misskon.com/gallery-two/',
    ]);
  });

  test('uses Java-style configurable ordered filenames', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(MrCongRipper.prefixForIndex(9), '009_');
    expect(
      MrCongRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/page01.jpg'),
        prefix: MrCongRipper.prefixForIndex(9),
      ),
      '009_page01.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(MrCongRipper.prefixForIndex(9), '');
    expect(
      MrCongRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/page01.jpg'),
        prefix: MrCongRipper.prefixForIndex(9),
      ),
      'page01.jpg',
    );
  });
}
