import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/ehentai_ripper.dart';
import 'package:ripme/utils/http_utils.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, URL support, and GIDs', () async {
    final ripper = EHentaiRipper(
      Uri.parse('https://e-hentai.org/g/1144492/e823bdf9a5/'),
    );

    expect(ripper.canRip(ripper.url), isTrue);
    expect(ripper.getHost(), 'e-hentai');
    expect(ripper.getDomain(), 'e-hentai.org');
    expect(await ripper.getGID(ripper.url), '1144492-e823bdf9a5');
  });

  test('extracts gallery image pages and tags like Java', () {
    final page = parse('''
      <div id="gdt">
        <a href="https://e-hentai.org/s/abc/1-1"><img></a>
        <span><a href="https://ignored.example"></a></span>
      </div>
      <table>
        <tr><td><div><a>yuri</a></div></td></tr>
        <tr><td><div><a>midnight on mars</a></div></td></tr>
      </table>
    ''');

    expect(
      EHentaiRipper.imagePageUrlsFromGallery(page),
      ['https://e-hentai.org/s/abc/1-1'],
    );
    expect(EHentaiRipper.tagsFromPage(page), ['yuri', 'midnight on mars']);
    expect(
      EHentaiRipper.checkTags(
          ['test', 'midnight on mars'], EHentaiRipper.tagsFromPage(page)),
      'midnight on mars',
    );
  });

  test('extracts image URLs from preferred and fallback selectors', () {
    expect(
      EHentaiRipper.imageUrlFromPage(
        parse(
            '<div class="sni"><a><img src="https://ehgt.org/full.jpg"></a></div>'),
      ),
      'https://ehgt.org/full.jpg',
    );
    expect(
      EHentaiRipper.imageUrlFromPage(
          parse('<img id="img" src="https://ehgt.org/fallback.png">')),
      'https://ehgt.org/fallback.png',
    );
    expect(EHentaiRipper.imageUrlFromPage(parse('<main></main>')), isNull);
  });

  test('constructs next page URLs with Java last-page and delay behavior',
      () async {
    final originalDelay = Http.delay;
    final delays = <Duration>[];
    Http.delay = (duration) async {
      delays.add(duration);
    };
    addTearDown(() {
      Http.delay = originalDelay;
    });

    final ripper = EHentaiRipper(
      Uri.parse('https://e-hentai.org/g/1144492/e823bdf9a5/'),
    );

    final next = await ripper.getNextPage(
      parse('''
        <div class="ptt">
          <a href="https://e-hentai.org/g/1144492/e823bdf9a5/?p=0">1</a>
          <a href="https://e-hentai.org/g/1144492/e823bdf9a5/?p=1">2</a>
        </div>
      '''),
    );

    expect(next.toString(), 'https://e-hentai.org/g/1144492/e823bdf9a5/?p=1');
    expect(delays, [EHentaiRipper.pageSleepTime]);
    expect(await ripper.getNextPage(parse('<main></main>')), isNull);
  });

  test('uses Java filename behavior including ehg manual filenames', () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'download.save_order': true,
    });
    await Utils.init();

    expect(
      EHentaiRipper.downloadFileName(
        Uri.parse('http://example.org/ehg/image.php?x=1&n=page_001.jpg'),
        2,
      ),
      '002_page_001.jpg',
    );
    expect(
      EHentaiRipper.downloadFileName(
        Uri.parse('https://ehgt.org/path/full.png?token=1'),
        2,
      ),
      '002_full.png',
    );

    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'download.save_order': false,
    });
    await Utils.init();

    expect(
      EHentaiRipper.downloadFileName(
        Uri.parse('https://ehgt.org/path/full.png'),
        2,
      ),
      'full.png',
    );
  });
}
