import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/wordpress_comic_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java explicit domain URL support and empty GID', () async {
    final supported = [
      'http://www.totempole666.com/comic/first-time-for-everything-00-cover/',
      'http://buttsmithy.com/archives/comic/p1',
      'http://themonsterunderthebed.net/?comic=test-post',
      'http://prismblush.com/comic/hella-trap-pg-01/',
      'http://www.konradokonski.com/sawdust/comic/get-up/',
      'http://www.konradokonski.com/aquartzbead/',
      'http://freeadultcomix.com/finders-feepaid-in-full-sparrow/',
      'http://thisis.delvecomic.com/NewWP/comic/in-too-deep/',
      'http://shipinbottle.pepsaga.com/?p=281',
      'https://8muses.download/lustomic-playkittens-josh-samuel-porn-comics-8-muses/',
      'http://spyingwithlana.com/comic/the-big-hookup/',
      'https://8muses.download/?s=lana',
      'https://8muses.download/page/2/?s=lana',
      'https://8muses.download/category/lana/',
      'https://comixfap.net/example/',
    ];

    for (final text in supported) {
      final uri = Uri.parse(text);
      final ripper = WordpressComicRipper(uri);
      expect(ripper.canRip(uri), isTrue, reason: text);
      expect(await ripper.getGID(uri), '', reason: text);
    }

    final comicsXxx = Uri.parse('https://comics-xxx.com/example/');
    expect(WordpressComicRipper(comicsXxx).canRip(comicsXxx), isFalse);
  });

  test('matches Java special album titles', () async {
    final cases = {
      'http://www.totempole666.com/comic/first-time-for-everything-00-cover/':
          'totempole666.com_The_cummoner',
      'http://buttsmithy.com/archives/comic/p1': 'buttsmithy.com_Alfie',
      'http://www.konradokonski.com/sawdust/comic/get-up/':
          'konradokonski.com_sawdust',
      'https://www.konradokonski.com/aquartzbead/':
          'konradokonski.com_aquartzbead',
      'http://freeadultcomix.com/finders-feepaid-in-full-sparrow/':
          'freeadultcomix.com_finders-feepaid-in-full-sparrow',
      'http://thisis.delvecomic.com/NewWP/comic/in-too-deep/':
          'thisis.delvecomic.com_Delve',
      'http://prismblush.com/comic/hella-trap-pg-01/':
          'prismblush.com_hella-trap-pg-01',
      'http://incase.buttsmithy.com/comic/example-page-1/':
          'incase.buttsmithy.com_example',
      'http://shipinbottle.pepsaga.com/?p=281':
          'shipinbottle.pepsaga.com_Ship_in_bottle',
      'https://8muses.download/example/': '8muses.download_example',
      'http://spyingwithlana.com/comic/the-big-hookup-page-1/':
          'spyingwithlana_the-big-hookup',
      'https://comixfap.net/example/': 'comixfap_example',
    };

    for (final entry in cases.entries) {
      final uri = Uri.parse(entry.key);
      expect(
        await WordpressComicRipper(uri).getAlbumTitle(uri),
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('extracts queue links and host-specific image URLs like Java', () async {
    final queueRipper =
        WordpressComicRipper(Uri.parse('https://8muses.download/?s=lana'));
    expect(queueRipper.pageContainsAlbums(queueRipper.url), isTrue);
    expect(await queueRipper.getAlbumsToQueue(parse('''
      <div id="post_masonry"><article><div><figure>
        <a href="https://8muses.download/post-one/"></a>
      </figure></div></article></div>
    ''')), ['https://8muses.download/post-one/']);

    final eight =
        WordpressComicRipper(Uri.parse('https://8muses.download/example/'));
    expect(await eight.getURLsFromPage(parse('''
      <div class="popup-gallery"><figure><a href="https://cdn.example.com/1.jpg"></a></figure></div>
    ''')), ['https://cdn.example.com/1.jpg']);

    final free =
        WordpressComicRipper(Uri.parse('http://freeadultcomix.com/example/'));
    expect(await free.getURLsFromPage(parse('''
      <div class="post-texto"><p><noscript><img class="aligncenter" src="https://cdn.example.com/free.jpg"></noscript></p></div>
    ''')), ['https://cdn.example.com/free.jpg']);
  });

  test('extracts theme image, title prefix, and next page like Java', () async {
    final ripper = WordpressComicRipper(
        Uri.parse('http://buttsmithy.com/archives/comic/p1'));
    final page = parse('''
      <meta property="og:title" content="Page 1">
      <div class="comic-table"><div id="comic"><a><img src="https://cdn.example.com/p1.jpg"></a></div></div>
      <a class="comic-nav-next" href="http://buttsmithy.com/archives/comic/p2"></a>
    ''');

    expect(
        await ripper.getURLsFromPage(page), ['https://cdn.example.com/p1.jpg']);
    expect(await ripper.getNextPage(page),
        Uri.parse('http://buttsmithy.com/archives/comic/p2'));
    expect(
      ripper.fileNameForUrl(Uri.parse('https://cdn.example.com/p1.jpg'), 1),
      'page1_p1.jpg',
    );
  });

  test('uses Java-style ordered filenames for non-title-prefix hosts',
      () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    final ripper = WordpressComicRipper(
      Uri.parse('http://prismblush.com/comic/hella-trap-pg-01/'),
    );
    expect(
      ripper.fileNameForUrl(Uri.parse('https://cdn.example.com/page.jpg'), 3),
      '003_page.jpg',
    );
  });
}
