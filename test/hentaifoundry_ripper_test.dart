import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/hentaifoundry_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, URL support, and GIDs', () async {
    final pictures = HentaifoundryRipper(
      Uri.parse('https://www.hentai-foundry.com/pictures/user/personalami'),
    );
    final stories = HentaifoundryRipper(
      Uri.parse('https://www.hentai-foundry.com/stories/user/Rakked'),
    );

    expect(pictures.canRip(pictures.url), isTrue);
    expect(stories.canRip(stories.url), isTrue);
    expect(pictures.getHost(), 'hentai-foundry');
    expect(pictures.getDomain(), 'hentai-foundry.com');
    expect(await pictures.getGID(pictures.url), 'personalami');
    expect(await stories.getGID(stories.url), 'Rakked');
  });

  test('builds Java filter POST data', () async {
    SharedPreferences.setMockInitialValues({
      'hentai-foundry.filter_order': 'date_new',
    });
    await Utils.init();

    final data = HentaifoundryRipper.filterFormData('csrf');

    expect(data['YII_CSRF_TOKEN'], 'csrf');
    expect(data['rating_nudity'], '3');
    expect(data['rating_yaoi'], '1');
    expect(data['filter_media'], 'A');
    expect(data['filter_order'], 'date_new');
    expect(data['filter_type'], '0');
  });

  test('extracts story PDF URLs and picture page URLs like Java', () {
    final page = parse('''
      <a class="pdfLink" href="/stories/user/Rakked/123/story.pdf">PDF</a>
      <div class="thumb_square"><a class="thumbLink" href="/pictures/user/personalami/123/title">ok</a></div>
      <div class="thumb_square"><a class="thumbLink" href="/bad/url">bad</a></div>
    ''');

    expect(HentaifoundryRipper.pdfUrlsFromPage(page), [
      'https://www.hentai-foundry.com/stories/user/Rakked/123/story.pdf',
    ]);
    expect(HentaifoundryRipper.imagePageUrlsFromPage(page), [
      'https://www.hentai-foundry.com/pictures/user/personalami/123/title',
    ]);
  });

  test('extracts full image URLs including resized thumbnail onclicks', () {
    final normal = parse('''
      <div class="boxbody"><img class="center" src="//pictures.hentai-foundry.com/a/art/full.jpg"></div>
    ''');
    final resized = parse(r'''
      <div class="boxbody"><img class="center" src="//thumbs.hentai-foundry.com/a/art/thumb.jpg"
        onclick="this.src='//pictures.hentai-foundry.com/a/art/full.jpg'; $(#resize_message).hide();"></div>
    ''');

    expect(
      HentaifoundryRipper.imageUrlFromImagePage(normal),
      'https://pictures.hentai-foundry.com/a/art/full.jpg',
    );
    expect(
      HentaifoundryRipper.imageUrlFromImagePage(resized),
      'https://pictures.hentai-foundry.com/a/art/full.jpg',
    );
  });

  test('uses Java-style configurable filename prefixes', () async {
    SharedPreferences.setMockInitialValues({
      'download.save_order': true,
      'hentai-foundry.use_prefix': true,
    });
    await Utils.init();
    expect(
      HentaifoundryRipper.fileNameForUrl(
        Uri.parse('https://pictures.hentai-foundry.com/a/art/image:name.jpg'),
        9,
      ),
      '009_image',
    );

    SharedPreferences.setMockInitialValues({
      'download.save_order': true,
      'hentai-foundry.use_prefix': false,
    });
    await Utils.init();
    expect(
      HentaifoundryRipper.fileNameForUrl(
        Uri.parse('https://pictures.hentai-foundry.com/a/art/image.jpg'),
        9,
      ),
      'image.jpg',
    );
  });
}
