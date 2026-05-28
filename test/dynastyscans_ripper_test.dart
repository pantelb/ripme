import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/dynastyscans_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, URL support, and GIDs', () async {
    final ripper = DynastyscansRipper(
      Uri.parse('https://dynasty-scans.com/chapters/under_one_roof_ch01'),
    );

    expect(ripper.canRip(ripper.url), isTrue);
    expect(ripper.getHost(), 'dynasty-scans');
    expect(ripper.getDomain(), 'dynasty-scans.com');
    expect(await ripper.getGID(ripper.url), 'under_one_roof_ch01');
  });

  test('extracts Java var pages JSON and image URLs', () {
    final page = parse(r'''
      <script>
        //<![CDATA[
        var pages = [{"image":"/system/releases/000/001/page001.jpg"},{"image":"/system/releases/000/001/page002.png"}]
        //]]>
      </script>
    ''');

    expect(
      DynastyscansRipper.pagesJsonText(page).trim(),
      '[{"image":"/system/releases/000/001/page001.jpg"},{"image":"/system/releases/000/001/page002.png"}]',
    );
    expect(
      DynastyscansRipper.urlsFromPage(page),
      [
        'https://dynasty-scans.com/system/releases/000/001/page001.jpg',
        'https://dynasty-scans.com/system/releases/000/001/page002.png',
      ],
    );
  });

  test('constructs next page URLs and stops at # like Java', () async {
    final ripper = DynastyscansRipper(
      Uri.parse('https://dynasty-scans.com/chapters/under_one_roof_ch01'),
    );

    expect(
      (await ripper.getNextPage(
        parse(
            '<a id="next_link" href="/chapters/under_one_roof_ch02">Next</a>'),
      ))
          .toString(),
      'https://dynasty-scans.com/chapters/under_one_roof_ch02',
    );
    expect(
        await ripper.getNextPage(parse('<a id="next_link" href="#">Next</a>')),
        isNull);
    expect(await ripper.getNextPage(parse('<main></main>')), isNull);
  });

  test('uses Java-style ordered filename prefixes', () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'download.save_order': true,
    });
    await Utils.init();

    expect(
      DynastyscansRipper.downloadFileName(
        Uri.parse('https://dynasty-scans.com/system/page.jpg?token=1'),
        4,
      ),
      '004_page.jpg',
    );

    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'download.save_order': false,
    });
    await Utils.init();

    expect(
      DynastyscansRipper.downloadFileName(
        Uri.parse('https://dynasty-scans.com/system/page.jpg'),
        4,
      ),
      'page.jpg',
    );
  });
}
